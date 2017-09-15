//
//  AWSClasses.swift
//  Harvey
//
//  Created by Sean Hart on 8/29/17.
//  Copyright © 2017 tangojlabs. All rights reserved.
//

import AWSCognito
import AWSLambda
import AWSS3
import FBSDKLoginKit
import Foundation
import GoogleMaps


// Create a protocol with functions declared in other View Controllers implementing this protocol (delegate)
protocol AWSRequestDelegate
{
    // A general handler to indicate that an AWS Method finished
    func processAwsReturn(_ requestCalled: AWSRequestObject, success: Bool)
    
    // A function all views should have to show a log in screen if needed
    func showLoginScreen()
}

class MyProvider : NSObject, AWSIdentityProviderManager
{
    var tokens: [NSString : NSString]?
    
    init(tokens: [NSString : NSString])
    {
        self.tokens = tokens
    }
    
    func logins() -> AWSTask<NSDictionary>
    {
        return AWSTask(result: tokens! as NSDictionary)
    }
}

class AWSPrepRequest
{
    // Add a delegate variable which the parent view controller can pass its own delegate instance to and have access to the protocol
    // (and have its own functions called that are listed in the protocol)
    var awsRequestDelegate: AWSRequestDelegate!
    
    var requestToCall: AWSRequestObject!
    
    required init(requestToCall: AWSRequestObject, delegate: AWSRequestDelegate)
    {
        self.requestToCall = requestToCall
        self.awsRequestDelegate = delegate
        self.requestToCall.awsRequestDelegate = delegate
    }
    
    // Use this method to call all other AWS methods to ensure that the user's credentials are still valid
    func prepRequest()
    {
        // If the server refresh time is past the minimum length, refresh the refresh loop catchers
        if Date().timeIntervalSince1970 - Constants.Data.serverLastRefresh > Constants.Settings.maxServerTryRefreshTime
        {
            Constants.Data.serverTries = 0
            Constants.Data.serverLastRefresh = Date().timeIntervalSince1970
        }
        
        // Ensure that the app is not continuously failing to access the server
        if Constants.Data.serverTries <= Constants.Settings.maxServerTries
        {
            // Check to see if the facebook user id is already in the FBSDK
            if let facebookToken = FBSDKAccessToken.current()
            {
                // Assign the Facebook Token to the AWSRequestObject
                self.requestToCall.facebookToken = facebookToken
                
                print("AC-PREP - COGNITO ID: \(String(describing: Constants.credentialsProvider.identityId))")
                // Ensure that the Cognito ID is still valid and is not older than an hour (AWS will invalidate if older)
                if Constants.credentialsProvider.identityId != nil && Constants.Data.lastCredentials - NSDate().timeIntervalSinceNow < 3600
                {
                    // The Cognito ID is valid, so check for a Harvey ID and then make the request
                    self.getHarveyID(facebookToken: facebookToken)
                }
                else
                {
                    // If the Cognito credentials have expired, request the credentials again (Cognito Identity ID) and use the current Facebook info
                    self.getCognitoID()
                }
            }
            else
            {
                print("***** USER NEEDS TO LOG IN AGAIN *****")
                
                if let parentVC = self.awsRequestDelegate
                {
                    print("AC-PREP-LOGIN - CHECK 1")
                    // Check to see if the parent viewcontroller is already the MapViewController.  If so, call the MVC showLoginScreen function
                    // Otherwise, launch a new MapViewController and show the login screen
                    if parentVC is MapViewController
                    {
                        print("AC-PREP-LOGIN - CHECK 2")
                        // PARENT VC IS EQUAL TO MVC
                        parentVC.showLoginScreen()
                    }
                    else
                    {
                        print("AC-PREP-LOGIN - CHECK 3")
                        // PARENT VC IS NOT EQUAL TO MVC
                        let newMapViewController = MapViewController()
                        if let rootNavController = UIApplication.shared.windows[0].rootViewController?.navigationController
                        {
                            print("AC-PREP-LOGIN - CHECK 4")
                            rootNavController.pushViewController(newMapViewController, animated: true)
                        }
                    }
                }
            }
        }
        else
        {
            // Reset the server try count since the request cycle was stopped - the user can manually try again if needed
            Constants.Data.serverTries = 0
            Constants.Data.serverLastRefresh = Date().timeIntervalSince1970
        }
    }
    
    // Once the Facebook token is gained, request a Cognito Identity ID
    func getCognitoID()
    {
        print("AC-PREP - IN GET COGNITO ID: \(String(describing: requestToCall.facebookToken))")
        if let token = requestToCall.facebookToken
        {
//            print("AC - GETTING COGNITO ID: \(String(describing: Constants.credentialsProvider.identityId))")
//            print("AC - TOKEN: \(AWSIdentityProviderFacebook), \(token.tokenString)")
            // Authenticate the user in AWS Cognito
            Constants.credentialsProvider.logins = [AWSIdentityProviderFacebook: token.tokenString]
            
//            let identityProviderManager = MyProvider(tokens: [AWSIdentityProviderFacebook as NSString : token.tokenString as NSString])
//            let customProviderManager = CustomIdentityProvider(tokens: [AWSIdentityProviderFacebook as NSString: token.tokenString as NSString])
//            Constants.credentialsProvider = AWSCognitoCredentialsProvider(
//                regionType: Constants.Strings.awsRegion
//                , identityPoolId: Constants.Strings.awsCognitoIdentityPoolID
//                , identityProviderManager: customProviderManager
//            )
            
            // Retrieve your Amazon Cognito ID
            Constants.credentialsProvider.getIdentityId().continue(
                {(task: AWSTask!) -> AnyObject! in
                    
                    if (task.error != nil)
                    {
//                        print("AC - AWS COGNITO GET IDENTITY ID - ERROR: " + task.error!.localizedDescription)
//                        CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: task.error!.localizedDescription)
                        
                        // Record the server request attempt
                        Constants.Data.serverTries += 1
                        
                        // Go ahead and move to the next login step
                        self.getHarveyID(facebookToken: token)
                    }
                    else
                    {
                        // the task result will contain the identity id
                        let cognitoId = task.result
//                        print("AC - AWS COGNITO GET IDENTITY ID - AWS COGNITO ID: \(String(describing: cognitoId))")
//                        print("AC - AWS COGNITO GET IDENTITY ID - CHECK IDENTITY ID: \(String(describing: Constants.credentialsProvider.identityId))")
                        
                        // Save the current time to mark when the last CognitoID was saved
                        Constants.Data.lastCredentials = NSDate().timeIntervalSinceNow
                        
                        // Request extra facebook data for the user ON THE MAIN THREAD
                        DispatchQueue.main.async(execute:
                            {
//                                print("AC - GOT COGNITO ID - GETTING NEW AWS ID")
                                self.getHarveyID(facebookToken: token)
                        });
                    }
                    return nil
            })
        }
    }
    
    // After ensuring that the Cognito ID is valid, so check for a Blobjot ID and then make the request
    func getHarveyID(facebookToken: FBSDKAccessToken!)
    {
        print("AC-PREP - GET HARVEY ID")
        // If the Identity ID is still valid, ensure that the current userID is not nil
        if Constants.Data.currentUser.userID != nil
        {
            print("AC-PREP - CURRENT USER ID: \(String(describing: Constants.Data.currentUser.userID))")
            // The user is already logged in so go ahead and register for notifications
//            UtilityFunctions().registerPushNotifications()
            
            // FIRING REQUEST
            // All login info is current; go ahead and fire the needed method
            self.requestToCall.facebookToken = facebookToken
            self.requestToCall.makeRequest()
        }
        else
        {
            print("AC-PREP - FB TOKEN: \(String(describing: facebookToken.tokenString))")
            // The current ID is nil, so request it from AWS, but store the previous request and call it when the user is logged in
            let awsLoginUser = AWSLoginUser(secondaryAwsRequestObject: self.requestToCall)
            awsLoginUser.awsRequestDelegate = self.awsRequestDelegate
            awsLoginUser.facebookToken = facebookToken
            awsLoginUser.makeRequest()
        }
    }
}


/// A base class to group membership of all AWS request functions
class AWSRequestObject
{
    // Add a delegate variable which the parent view controller can pass its own delegate instance to and have access to the protocol
    // (and have its own functions called that are listed in the protocol)
    var awsRequestDelegate: AWSRequestDelegate?
    
    var facebookToken: FBSDKAccessToken?
    
    func makeRequest() {}
}


/**
 Properties:
 - secondaryAwsRequestObject- An optional property that allows the original request to be carried by the login request, when the login request is fired by the prepRequest class due to no user being logged in.  This property should not be used for AWSLoginUser calls based directly on user interaction
 */
class AWSLoginUser: AWSRequestObject, RequestDelegate
{
    var secondaryAwsRequestObject: AWSRequestObject?
    var newUser: Bool = false
    var banned: Bool = false
    var user: User?
    
    required init(secondaryAwsRequestObject: AWSRequestObject?)
    {
        self.secondaryAwsRequestObject = secondaryAwsRequestObject
    }
    
    // FBSDK METHOD - Get user data from FB before attempting to log in via AWS
    override func makeRequest()
    {
        if let fbToken = facebookToken
        {
            RequestPrep(requestToCall: FBGetUserData(me: true, facebookID: fbToken.userID), delegate: self as RequestDelegate).prepRequest()
        }
    }
    
    // Log in the user or create a new user
    func loginUser(_ facebookName: String, facebookThumbnailUrl: String)
    {
        print("AC-LU - FACEBOOK TOKEN: \(String(describing: self.facebookToken))")
        print("AC-LU - COGNITO ID: \(String(describing: Constants.credentialsProvider.identityId))")
        if let fbToken = facebookToken
        {
            var json = [String : Any]()
            json["app_version"] = Constants.Settings.appVersion
            json["facebook_id"] = fbToken.userID
            
            let lambdaInvoker = AWSLambdaInvoker.default()
            lambdaInvoker.invokeFunction("Harvey-LoginUser", jsonObject: json, completionHandler:
                { (responseData, err) -> Void in
                    
                    if (err != nil)
                    {
                        print("AC-LU - FBSDK LOGIN - ERROR: \(String(describing: err))")
//                        CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: err.debugDescription)
                        
                        // Record the login attempt
                        Constants.Data.serverTries += 1
                        
                        DispatchQueue.main.async(execute:
                            {
                                // Notify the parent view that the AWS call completed with an error
                                if let parentVC = self.awsRequestDelegate
                                {
                                    parentVC.processAwsReturn(self, success: false)
                                    
                                    // Try again
                                    AWSPrepRequest(requestToCall: self, delegate: parentVC).prepRequest()
                                }
                        })
                        
                    }
                    else if (responseData != nil)
                    {
                        // Convert the response to JSON with keys and AnyObject values
                        if let responseJson = responseData as? [String: AnyObject]
                        {
                            if let status = responseJson["status"] as? String
                            {
                                print("AC-LU - loginUser - status: \(status)")
                                if status == "banned"
                                {
                                    self.banned = true
                                    
                                    // Notify the parent view that the AWS call failed - it will check for a banned user
                                    if let parentVC = self.awsRequestDelegate
                                    {
                                        parentVC.processAwsReturn(self, success: false)
                                    }
                                }
                                else
                                {
                                    if let userID = responseJson["user_id"] as? String
                                    {
                                        print("AC-LU -LOGIN: \(responseJson)")
                                        // Create a user object to save the data - all data should be available in the response
                                        let currentUser = User()
                                        currentUser.userID = userID
                                        currentUser.facebookID = self.facebookToken!.userID
                                        currentUser.name = facebookName
                                        currentUser.image = UIImage(named: "PROFILE_DEFAULT.png")
                                        currentUser.status = status
                                        if let type = responseJson["type"] as? String
                                        {
                                            currentUser.type = type
                                        }
                                        if let timestamp = responseJson["timestamp"] as? Double
                                        {
                                            currentUser.datetime = Date(timeIntervalSince1970: timestamp)
                                        }
                                        else
                                        {
                                            currentUser.datetime = Date(timeIntervalSinceNow: 0)
                                        }
                                        
                                        // Set the created user as the passed user for access by parent classes
                                        self.user = currentUser
                                        
                                        // The response will be the userID associated with the facebookID used, save the current user globally
                                        Constants.Data.currentUser = currentUser
                                        
                                        // Save the new login data to Core Data
                                        CoreDataFunctions().currentUserSave(user: currentUser, deleteUser: false)
                                        
//                                        // Reset the global User list with Core Data
//                                        UtilityFunctions().resetUserListWithCoreData()
//                                        
//                                        UtilityFunctions().registerPushNotifications()
                                        
                                        // Check whether the user is a new user, or has logged in before - still in use (9/7/2017)?
                                        if let newUserInt = responseJson["new_user"] as? Int
                                        {
                                            if newUserInt == 1
                                            {
                                                self.newUser = true
                                            }
                                        }
                                        
                                        // If the secondary request object is not nil, process the carried (second) request; no need to
                                        // pass the login response to the parent view controller since it did not explicitly call the login request
                                        if let secondaryAwsRequestObject = self.secondaryAwsRequestObject
                                        {
                                            print("AC-LU -loginUser - secondary fire")
                                            AWSPrepRequest(requestToCall: secondaryAwsRequestObject, delegate: self.awsRequestDelegate!).prepRequest()
                                        }
                                        else
                                        {
                                            print("AC-LU -loginUser - else")
                                            // Notify the parent view that the AWS Login call completed successfully
                                            if let parentVC = self.awsRequestDelegate
                                            {
                                                parentVC.processAwsReturn(self, success: true)
                                            }
                                        }
                                        
                                        print("AC-LU -loginUser - call RC-FBI FOR USER: \(self.facebookToken!.userID)")
                                        // Go ahead and download the user image and make available
                                        RequestPrep(requestToCall: FBDownloadUserImage(facebookID: self.facebookToken!.userID, largeImage: true), delegate: self as RequestDelegate).prepRequest()
                                    }
                                }
                            }
                        }
                    }
            })
        }
    }
    
    func processRequestReturn(_ requestCalled: RequestObject, success: Bool)
    {
        // Process the return data based on the method used
        switch requestCalled
        {
        case let fbGetUserData as FBGetUserData:
            if success
            {
                if let name = fbGetUserData.facebookName
                {
                    if let thumbnailUrl = fbGetUserData.facebookThumbnailUrl
                    {
                        self.loginUser(name, facebookThumbnailUrl: thumbnailUrl)
                    }
                }
            }
            else
            {
                print("AC-LU -FBGetUserData FAILURE")
            }
        case _ as FBDownloadUserImage:
            if success
            {
                print("AC-LU -FBDownloadUserImage SUCCESS")
            }
            else
            {
                print("AC-LU -FBDownloadUserImage FAILURE")
            }
        default:
            print("AC-LU -processRequestReturn DEFAULT")
        }
    }
}

class AWSLogoutUser
{
    
}


// MARK: USER

class AWSCheckUser : AWSRequestObject
{
    var facebookID: String!
    var newUser: Bool = true
    
    required init(facebookID: String)
    {
        self.facebookID = facebookID
    }
    
    // Use this request function when a Blob is within range of the user's location and the extra Blob data is needed
    override func makeRequest()
    {
        print("AC-CID: SENDING REQUEST")
        
        // Create a JSON object with the passed Blob ID and an indicator of whether or not the Blob data should be filtered (0 for no, 1 for yes)
        var json = [String : Any]()
        json["app_version"] = Constants.Settings.appVersion
        json["facebook_id"] = facebookID
        
        let lambdaInvoker = AWSLambdaInvoker.default()
        lambdaInvoker.invokeFunction("Harvey-App-CheckUser", jsonObject: json, completionHandler:
            { (response, err) -> Void in
                
                if (err != nil)
                {
                    print("AC-CID: GET DATA ERROR: \(String(describing: err))")
//                    CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: err.debugDescription)
                    
                    // Record the server request attempt
                    Constants.Data.serverTries += 1
                    
                    // Notify the parent view that the AWS call completed with an error
                    if let parentVC = self.awsRequestDelegate
                    {
                        parentVC.processAwsReturn(self, success: false)
                    }
                }
                else if (response != nil)
                {
                    print("AC-CID RESPONSE:")
//                    print(response)
                    
                    // Convert the response to JSON with keys and AnyObject values
                    if let responseJson = response as? [String: AnyObject]
                    {
                        if let userExistsInt = responseJson["user_exists"] as? Int
                        {
                            if userExistsInt == 1
                            {
                                self.newUser = false
                            }
                            
                            // Notify the parent view that the AWS call completed successfully
                            if let parentVC = self.awsRequestDelegate
                            {
                                print("AC-GHD - CALLED PARENT")
                                parentVC.processAwsReturn(self, success: true)
                            }
                        }
                    }
                }
        })
    }
}

class AWSUpdateUser : AWSRequestObject
{
    var userID: String!
    var facebookID: String?
    var type: String?
    var status: String?
    
    required init(userID: String)
    {
        self.userID = userID
    }
    
    // Use this request function when a Blob is within range of the user's location and the extra Blob data is needed
    override func makeRequest()
    {
        print("AC-UU: SENDING REQUEST")
        
        // Create a JSON object with the passed Blob ID and an indicator of whether or not the Blob data should be filtered (0 for no, 1 for yes)
        var json = [String : Any]()
        json["app_version"] = Constants.Settings.appVersion
        json["user_id"] = userID
        if let facebookID = self.facebookID
        {
            json["facebook_id"] = facebookID
        }
        if let type = self.type
        {
            json["type"] = type
        }
        if let status = self.status
        {
            json["status"] = status
        }
        
        let lambdaInvoker = AWSLambdaInvoker.default()
        lambdaInvoker.invokeFunction("Harvey-App-UpdateUser", jsonObject: json, completionHandler:
            { (response, err) -> Void in
                
                if (err != nil)
                {
                    print("AC-UU: GET DATA ERROR: \(String(describing: err))")
//                    CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: err.debugDescription)
                    
                    // Record the server request attempt
                    Constants.Data.serverTries += 1
                    
                    // Notify the parent view that the AWS call completed with an error
                    if let parentVC = self.awsRequestDelegate
                    {
                        parentVC.processAwsReturn(self, success: false)
                    }
                }
                else if (response != nil)
                {
                    print("AC-UU RESPONSE:")
//                    print(response)
                    
                    // Convert the response to JSON with keys and AnyObject values
                    if let responseJson = response as? [String: AnyObject]
                    {
                        if let response = responseJson["response"] as? String
                        {
                            if response == "success"
                            {
                                // Notify the parent view that the AWS call completed successfully
                                if let parentVC = self.awsRequestDelegate
                                {
                                    parentVC.processAwsReturn(self, success: true)
                                }
                            }
                            else
                            {
                                // Notify the parent view that the AWS call completed with a failure
                                if let parentVC = self.awsRequestDelegate
                                {
                                    parentVC.processAwsReturn(self, success: false)
                                }
                            }
                        }
                    }
                }
        })
    }
}

class AWSGetUsers: AWSRequestObject, RequestDelegate
{
    // Use this request function to query all current users
    override func makeRequest()
    {
        print("AC-GU: SENDING REQUEST")
        
        // Create a JSON object with the passed Blob ID and an indicator of whether or not the Blob data should be filtered (0 for no, 1 for yes)
        var json = [String : Any]()
        json["app_version"] = Constants.Settings.appVersion
        json["key"] = "value"
        
        let lambdaInvoker = AWSLambdaInvoker.default()
        lambdaInvoker.invokeFunction("Harvey-GetUsers", jsonObject: json, completionHandler:
            { (response, err) -> Void in
                
                if (err != nil)
                {
                    print("AC-GU: GET DATA ERROR: \(String(describing: err))")
//                    CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: err.debugDescription)
                    
                    // Record the server request attempt
                    Constants.Data.serverTries += 1
                    
                    // Notify the parent view that the AWS call completed with an error
                    if let parentVC = self.awsRequestDelegate
                    {
                        parentVC.processAwsReturn(self, success: false)
                    }
                }
                else if (response != nil)
                {
                    print("AC-GU RESPONSE:")
//                    print(response)
                    
                    // Convert the response to JSON with keys and AnyObject values
                    if let responseArray = response as? [AnyObject]
                    {
                        print("AC-GU - CHECK 1")
//                        // Create a local array to hold all downloaded users
//                        var downloadedUsers = [User]()
                        
                        for arrayObject in responseArray
                        {
                            print("AC-GU - CHECK 2")
                            if let responseJson = arrayObject as? [String: AnyObject]
                            {
                                print("AC-GU - CHECK 3: \(responseJson)")
                                if let facebookID = responseJson["facebook_id"] as? String
                                {
                                    print("AC-GU - CHECK 4: \(facebookID)")
                                    let newUser = User()
                                    newUser.userID = responseJson["user_id"] as! String
                                    newUser.facebookID = facebookID
                                    newUser.type = responseJson["type"] as! String
                                    newUser.status = responseJson["status"] as! String
                                    newUser.datetime = Date(timeIntervalSince1970: responseJson["timestamp"] as! Double)
                                    
                                    // Check to see if any data currently exists that is not included in the new data
                                    var userExists = false
                                    userCheckLoop: for userCheck in Constants.Data.allUsers
                                    {
                                        // Check using the FBID since at least that should exist
                                        if userCheck.facebookID == facebookID
                                        {
                                            // If the user already exists, update with newly downloaded data
                                            userExists = true
                                            userCheck.userID = newUser.userID
                                            userCheck.type = newUser.type
                                            userCheck.status = newUser.status
                                            userCheck.datetime = newUser.datetime
                                            break userCheckLoop
                                        }
                                    }
                                    if !userExists
                                    {
                                        Constants.Data.allUsers.append(newUser)
                                    }
                                    
                                    // Save the current user data to Core Data
                                    CoreDataFunctions().userSave(user: newUser, deleteUser: false)
                                    
                                    // Request FB data for the user
                                    RequestPrep(requestToCall: FBGetUserData(me: false, facebookID: newUser.facebookID), delegate: self as RequestDelegate).prepRequest()
                                }
                            }
                        }
                        
//                        // Replace the global user array with the new data
//                        Constants.Data.allUsers = downloadedUsers
//                        for dUser in downloadedUsers
//                        {
//                            Constants.Data.allUsers.append(dUser)
//                        }
                        
                        // Refresh the user connections
                        UtilityFunctions().updateUserConnections()
                        
                        // Notify the parent view that the AWS call completed successfully
                        if let parentVC = self.awsRequestDelegate
                        {
                            print("AC-GU - CALLED PARENT")
                            parentVC.processAwsReturn(self, success: true)
                        }
                    }
                    else
                    {
                        // Notify the parent view that the AWS call completed with an error
                        if let parentVC = self.awsRequestDelegate
                        {
                            parentVC.processAwsReturn(self, success: false)
                        }
                    }
                }
        })
    }
    
    func processRequestReturn(_ requestCalled: RequestObject, success: Bool)
    {
        // Process the return data based on the method used
        switch requestCalled
        {
        case let fbGetUserData as FBGetUserData:
            if success
            {
                print("AC-FBGetUserData SUCCESS")
            }
            else
            {
                print("AC-FBGetUserData FAILURE")
            }
        default:
            print("AC-processRequestReturn DEFAULT")
        }
    }
}


// MARK: USER CONNECTION

class AWSGetUserConnections: AWSRequestObject
{
    // Use this request function to query all connections for the current users
    override func makeRequest()
    {
        print("AC-GUC: SENDING REQUEST")
        
        // Create a JSON object with the passed Blob ID and an indicator of whether or not the Blob data should be filtered (0 for no, 1 for yes)
        var json = [String : Any]()
        json["app_version"] = Constants.Settings.appVersion
        json["user_id"] = Constants.Data.currentUser.userID
        
        let lambdaInvoker = AWSLambdaInvoker.default()
        lambdaInvoker.invokeFunction("Harvey-GetUserConnections", jsonObject: json, completionHandler:
            { (response, err) -> Void in
                
                if (err != nil)
                {
                    print("AC-GUC: GET DATA ERROR: \(String(describing: err))")
//                    CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: err.debugDescription)
                    
                    // Record the server request attempt
                    Constants.Data.serverTries += 1
                    
                    // Notify the parent view that the AWS call completed with an error
                    if let parentVC = self.awsRequestDelegate
                    {
                        parentVC.processAwsReturn(self, success: false)
                    }
                }
                else if (response != nil)
                {
                    print("AC-GUC RESPONSE:")
//                    print(response)
                    
                    // Convert the response to JSON with keys and AnyObject values
                    if let responseArray = response as? [AnyObject]
                    {
                        // Currently, the only concern is blocked users, so add all blocked userIDs to the global list and update the user status' in the global user list
                        // Create a local array to hold all downloaded users
                        var blockedUserIDs = [String]()
                        
                        for arrayObject in responseArray
                        {
                            if let responseJson = arrayObject as? [String: AnyObject]
                            {
                                if let connection = responseJson["connection"] as? String
                                {
                                    if connection == "block"
                                    {
                                        blockedUserIDs.append(responseJson["target_user_id"] as! String)
                                    }
                                }
                            }
                        }
                        
                        // Replace the global connection array with the new data
                        Constants.Data.allUserBlockList = blockedUserIDs
                        
                        // Refresh the user connections
                        UtilityFunctions().updateUserConnections()
                        UtilityFunctions().removeBlockedUsersFromGlobalSpotArray()
                        
                        // Notify the parent view that the AWS call completed successfully
                        if let parentVC = self.awsRequestDelegate
                        {
                            print("AC-GUC - CALLED PARENT")
                            parentVC.processAwsReturn(self, success: true)
                        }
                    }
                    else
                    {
                        // Notify the parent view that the AWS call completed with an error
                        if let parentVC = self.awsRequestDelegate
                        {
                            parentVC.processAwsReturn(self, success: false)
                        }
                    }
                }
        })
    }
}

class AWSPutUserConnection: AWSRequestObject
{
    var targetUserID: String!
    var connection: String!
    
    required init(targetUserID: String!, connection: String!)
    {
        self.targetUserID = targetUserID
        self.connection = connection
    }
    
    // Use this request function to query all current users
    override func makeRequest()
    {
        print("AC-PUC: SENDING REQUEST")
        
        // Create a JSON object with the passed Blob ID and an indicator of whether or not the Blob data should be filtered (0 for no, 1 for yes)
        var json = [String : Any]()
        json["app_version"] = Constants.Settings.appVersion
        json["user_id"] = Constants.Data.currentUser.userID
        json["target_user_id"] = targetUserID
        json["connection"] = connection
        
        let lambdaInvoker = AWSLambdaInvoker.default()
        lambdaInvoker.invokeFunction("Harvey-PutUserConnection", jsonObject: json, completionHandler:
            { (response, err) -> Void in
                
                if (err != nil)
                {
                    print("AC-PUC: GET DATA ERROR: \(String(describing: err))")
//                    CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: err.debugDescription)
                    
                    // Record the server request attempt
                    Constants.Data.serverTries += 1
                    
                    // Notify the parent view that the AWS call completed with an error
                    if let parentVC = self.awsRequestDelegate
                    {
                        parentVC.processAwsReturn(self, success: false)
                    }
                }
                else if (response != nil)
                {
                    print("AC-PUC RESPONSE:")
//                    print(response)
                    
                    // Notify the parent view that the AWS call completed successfully
                    if let parentVC = self.awsRequestDelegate
                    {
                        print("AC-PUC - CALLED PARENT")
                        parentVC.processAwsReturn(self, success: true)
                    }
                }
        })
    }
}


// MARK: SPOT

class AWSGetSpotData : AWSRequestObject
{
    var userLocation = [String : Double]()
    
    required init(userLocation: [String : Double]!)
    {
        if let userLocation = userLocation
        {
            self.userLocation = userLocation
        }
    }
    
    // Use this request function when a Blob is within range of the user's location and the extra Blob data is needed
    override func makeRequest()
    {
        print("AC-GSD: REQUESTING DATA: \(String(describing: self.userLocation))")
        
        // Create a JSON object with the passed Blob ID and an indicator of whether or not the Blob data should be filtered (0 for no, 1 for yes)
        var json = [String : Any]()
        json["app_version"] = Constants.Settings.appVersion
        json["user_location"] = userLocation
        
        let lambdaInvoker = AWSLambdaInvoker.default()
        lambdaInvoker.invokeFunction("Harvey-GetSpotData", jsonObject: json, completionHandler:
            { (response, err) -> Void in
                
                if (err != nil)
                {
                    print("AC-GSD: GET DATA ERROR: \(String(describing: err))")
//                    CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: err.debugDescription)
                    
                    // Record the server request attempt
                    Constants.Data.serverTries += 1
                    
                    // Notify the parent view that the AWS call completed with an error
                    if let parentVC = self.awsRequestDelegate
                    {
                        parentVC.processAwsReturn(self, success: false)
                    }
                }
                else if (response != nil)
                {
//                    print("AC-GSD RESPONSE:")
//                    print(response)
                    
                    // The data request was successful - reset the data arrays
                    Constants.Data.allSpot = [Spot]()
                    Constants.Data.allSpotRequest = [SpotRequest]()
                    
                    // Convert the response to JSON with keys and AnyObject values
                    if let allData = response as? [String: AnyObject]
                    {
                        // Convert the response to an array of AnyObjects
                        // EXTRACT SPOT DATA
                        if let allSpotRaw = allData["spot"] as? [Any]
                        {
                            // Loop through each AnyObject (Blob) in the array
                            for newSpot in allSpotRaw
                            {
                                // Convert the response to JSON with keys and AnyObject values
                                // Then convert the AnyObject values to Strings or Numbers depending on their key
                                if let spotRaw = newSpot as? [String: AnyObject]
                                {
                                    if let spotID = spotRaw["spot_id"]
                                    {
                                        // First check whether the user is blocked
                                        let userID = spotRaw["user_id"] as! String
                                        
                                        var userBlocked = false
                                        blockLoop: for blockedID in Constants.Data.allUserBlockList
                                        {
                                            if blockedID == userID
                                            {
                                                userBlocked = true
                                                
                                                break blockLoop
                                            }
                                        }
                                        if !userBlocked
                                        {
                                            // Extract the SpotContent data
                                            // Create an empty array to hold the SpotContent Objects
                                            var spotContent = [SpotContent]()
                                            if let spotContentArray = spotRaw["spot_content"] as? [Any]
                                            {
                                                for spotContentObject in spotContentArray
                                                {
                                                    if let spotContentRaw = spotContentObject as? [String: AnyObject]
                                                    {
                                                        if let contentID = spotContentRaw["content_id"]
                                                        {
                                                            let addSpotContent = SpotContent()
                                                            addSpotContent.contentID = contentID as! String
                                                            addSpotContent.spotID = spotContentRaw["spot_id"] as! String
                                                            addSpotContent.datetime = Date(timeIntervalSince1970: spotContentRaw["timestamp"] as! Double)
                                                            addSpotContent.type = Constants().contentType(spotContentRaw["type"] as! Int)
                                                            addSpotContent.status = spotContentRaw["status"] as! String
                                                            addSpotContent.lat = spotContentRaw["lat"] as! Double
                                                            addSpotContent.lng = spotContentRaw["lng"] as! Double
                                                            spotContent.append(addSpotContent)
                                                        }
                                                    }
                                                }
                                            }
                                            
                                            let addSpot = Spot()
                                            addSpot.spotID = spotID as! String
                                            addSpot.datetime = Date(timeIntervalSince1970: spotRaw["timestamp"] as! Double)
                                            addSpot.userID = userID
                                            addSpot.status = spotRaw["status"] as! String
                                            addSpot.lat = spotRaw["lat"] as! Double
                                            addSpot.lng = spotRaw["lng"] as! Double
                                            addSpot.spotContent = spotContent
                                            Constants.Data.allSpot.append(addSpot)
//                                            print("AC-GSD - ADDED SPOT DATA: \(addSpot.spotID)")
                                        }
                                    }
                                }
                            }
                        }
                        // Convert the response to an array of AnyObjects
                        // EXTRACT SPOT REQUEST DATA
                        if let allSpotRequestRaw = allData["spot_request"] as? [Any]
                        {
                            // Loop through each AnyObject (Blob) in the array
                            for newSpotRequest in allSpotRequestRaw
                            {
                                // Convert the response to JSON with keys and AnyObject values
                                // Then convert the AnyObject values to Strings or Numbers depending on their key
                                if let spotRequestRaw = newSpotRequest as? [String: AnyObject]
                                {
                                    if let requestID = spotRequestRaw["request_id"]
                                    {
                                        let addSpotRequest = SpotRequest()
                                        addSpotRequest.requestID = requestID as? String
                                        addSpotRequest.datetime = Date(timeIntervalSince1970: spotRequestRaw["timestamp"] as! Double)
                                        addSpotRequest.userID = spotRequestRaw["user_id"] as! String
                                        addSpotRequest.status = spotRequestRaw["status"] as! String
                                        addSpotRequest.lat = spotRequestRaw["lat"] as! Double
                                        addSpotRequest.lng = spotRequestRaw["lng"] as! Double
                                        Constants.Data.allSpotRequest.append(addSpotRequest)
//                                        print("AC-GSRD - ADDED SPOT RESPONSE DATA: \(String(describing: addSpotRequest.requestID))")
                                    }
                                }
                            }
                        }
                    }
                    
//                    // Refresh the spots based on user connection
//                    UtilityFunctions().removeBlockedUsersFromGlobalSpotArray()
                    
                    // Notify the parent view that the AWS call completed successfully
                    if let parentVC = self.awsRequestDelegate
                    {
                        print("AC-GSD - CALLED PARENT")
                        parentVC.processAwsReturn(self, success: true)
                    }
                }
        })
    }
}

class AWSPutSpotData : AWSRequestObject
{
    var spot: Spot!
    
    required init(spot: Spot!)
    {
        self.spot = spot
    }
    
    // Upload data to Lambda for transfer to DynamoDB
    override func makeRequest()
    {
//        print("SENDING DATA TO LAMBDA")
        
        // Create some JSON to send the Spot data
        // First add all the spotContent objects as JSON
        var jsonSpotContent = [[String: Any]]()
        for content in spot.spotContent
        {
            var json = [String: Any]()
            json["content_id"] = content.contentID
            json["spot_id"]    = content.spotID
            json["timestamp"]  = String(content.datetime.timeIntervalSince1970)
            json["type"]       = String(content.type.rawValue)
            json["lat"]        = String(content.lat)
            json["lng"]        = String(content.lng)
            jsonSpotContent.append(json)
        }
        
        // Second add all Spot data to the json
        var json = [String: Any]()
        json["app_version"] = Constants.Settings.appVersion
        json["spot_id"]      = spot.spotID
        json["user_id"]      = spot.userID
        json["timestamp"]    = String(spot.datetime.timeIntervalSince1970)
        json["lat"]          = String(spot.lat)
        json["lng"]          = String(spot.lng)
        json["spot_content"] = jsonSpotContent
        
        print("LAMBDA JSON: \(json)")
        let lambdaInvoker = AWSLambdaInvoker.default()
        lambdaInvoker.invokeFunction("Harvey-PutSpotData", jsonObject: json, completionHandler:
            { (response, err) -> Void in
                
                if (err != nil)
                {
                    print("SENDING DATA TO LAMBDA ERROR: \(String(describing: err))")
//                    CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: err.debugDescription)
                    
                    // Record the server request attempt
                    Constants.Data.serverTries += 1
                    
                    // Notify the parent view that the AWS call completed with an error
                    if let parentVC = self.awsRequestDelegate
                    {
                        parentVC.processAwsReturn(self, success: false)
                    }
                }
                else if (response != nil)
                {
                    // Now that the Spot has been created, add it to the global array
                    Constants.Data.allSpot.append(self.spot)
                    
                    // And remove any SpotRequests that are fulfilled by the Spot
                    for (srIndex, sRequest) in Constants.Data.allSpotRequest.enumerated()
                    {
                        let srCoords = CLLocation(latitude: sRequest.lat, longitude: sRequest.lng)
                        let spotCoords = CLLocation(latitude: self.spot.lat, longitude: self.spot.lng)
                        
                        if spotCoords.distance(from: srCoords) <= Constants.Dim.spotRadius
                        {
                            Constants.Data.allSpotRequest.remove(at: srIndex)
                        }
                    }
                    
                    // Notify the parent view that the AWS call completed successfully
                    if let parentVC = self.awsRequestDelegate
                    {
                        parentVC.processAwsReturn(self, success: true)
                    }
                }
        })
    }
}

class AWSUpdateSpotContentData : AWSRequestObject
{
    var contentID: String!
    var spotID: String!
    var statusUpdate: String!
    
    required init(contentID: String!, spotID: String!, statusUpdate: String!)
    {
        self.contentID = contentID
        self.spotID = spotID
        self.statusUpdate = statusUpdate
    }
    
    // Upload data to Lambda for transfer to DynamoDB
    override func makeRequest()
    {
        // Create some JSON to send the SpotContent update data
        var json = [String: Any]()
        json["app_version"]   = Constants.Settings.appVersion
        json["content_id"]    = contentID
        json["status_update"] = statusUpdate
        
        let lambdaInvoker = AWSLambdaInvoker.default()
        lambdaInvoker.invokeFunction("Harvey-UpdateSpotContentData", jsonObject: json, completionHandler:
            { (response, err) -> Void in
                
                if (err != nil)
                {
                    print("SENDING DATA TO LAMBDA ERROR: \(String(describing: err))")
//                    CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: err.debugDescription)
                    
                    // Record the server request attempt
                    Constants.Data.serverTries += 1
                    
                    // Notify the parent view that the AWS call completed with an error
                    if let parentVC = self.awsRequestDelegate
                    {
                        parentVC.processAwsReturn(self, success: false)
                    }
                }
                else if (response != nil)
                {
                    // Now that the SpotContent has been updated, update the global array
                    globalSpotLoop: for spotObject in Constants.Data.allSpot
                    {
                        if spotObject.spotID == self.spotID
                        {
                            spotContentLoop: for (index, spotContentObject) in spotObject.spotContent.enumerated()
                            {
                                if spotContentObject.contentID == self.contentID
                                {
                                    // Remove the SpotContent object
                                    spotObject.spotContent.remove(at: index)
                                    
                                    break spotContentLoop
                                }
                            }
                            
                            break globalSpotLoop
                        }
                    }
                    
                    // Notify the parent view that the AWS call completed successfully
                    if let parentVC = self.awsRequestDelegate
                    {
                        parentVC.processAwsReturn(self, success: true)
                    }
                }
        })
    }
}

class AWSPutSpotRequestData : AWSRequestObject
{
    var spotRequest: SpotRequest!
    
    required init(spotRequest: SpotRequest!)
    {
        self.spotRequest = spotRequest
    }
    
    // Upload data to Lambda for transfer to DynamoDB
    override func makeRequest()
    {
        //        print("SENDING DATA TO LAMBDA")
        
        // Create some JSON to send the SpotRequest data
        var json = [String: Any]()
        json["app_version"] = Constants.Settings.appVersion
        json["request_id"] = spotRequest.requestID
        json["user_id"]    = spotRequest.userID
        json["timestamp"]  = String(spotRequest.datetime.timeIntervalSince1970)
        json["lat"]        = String(spotRequest.lat)
        json["lng"]        = String(spotRequest.lng)
        json["status"]     = spotRequest.status
        
        print("LAMBDA JSON: \(json)")
        let lambdaInvoker = AWSLambdaInvoker.default()
        lambdaInvoker.invokeFunction("Harvey-PutSpotRequestData", jsonObject: json, completionHandler:
            { (response, err) -> Void in
                
                if (err != nil)
                {
                    print("SENDING DATA TO LAMBDA ERROR: \(String(describing: err))")
//                    CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: err.debugDescription)
                    
                    // Record the server request attempt
                    Constants.Data.serverTries += 1
                    
                    // Notify the parent view that the AWS call completed with an error
                    if let parentVC = self.awsRequestDelegate
                    {
                        parentVC.processAwsReturn(self, success: false)
                    }
                }
                else if (response != nil)
                {
                    // Now that the SpotRequest has been created, add it to the global array if it is active
                    if self.spotRequest.status == "active"
                    {
                        Constants.Data.allSpotRequest.append(self.spotRequest)
                    }
                    
                    // Notify the parent view that the AWS call completed successfully
                    if let parentVC = self.awsRequestDelegate
                    {
                        parentVC.processAwsReturn(self, success: true)
                    }
                }
        })
    }
}


// MARK: SHELTER

class AWSGetShelterData : AWSRequestObject
{
    var userLocation = [String : Double]()
    
    required init(userLocation: [String : Double]!)
    {
        if let userLocation = userLocation
        {
            self.userLocation = userLocation
        }
    }
    
    // Use this request function when a Blob is within range of the user's location and the extra Blob data is needed
    override func makeRequest()
    {
        print("AC-GSHD: REQUESTING DATA: \(String(describing: self.userLocation))")
        
        // Create a JSON object with the passed Blob ID and an indicator of whether or not the Blob data should be filtered (0 for no, 1 for yes)
        var json = [String : Any]()
        json["app_version"] = Constants.Settings.appVersion
        json["user_location"] = userLocation
        
        let lambdaInvoker = AWSLambdaInvoker.default()
        lambdaInvoker.invokeFunction("Harvey-GetShelterData", jsonObject: json, completionHandler:
            { (response, err) -> Void in
                
                if (err != nil)
                {
                    print("AC-GSHD: GET DATA ERROR: \(String(describing: err))")
//                    CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: err.debugDescription)
                    
                    // Record the server request attempt
                    Constants.Data.serverTries += 1
                    
                    // Notify the parent view that the AWS call completed with an error
                    if let parentVC = self.awsRequestDelegate
                    {
                        parentVC.processAwsReturn(self, success: false)
                    }
                }
                else if (response != nil)
                {
//                    print("AC-GSHD RESPONSE:")
//                    print(response)
                    
                    // The data request was successful - reset the data array
                    Constants.Data.allShelter = [Shelter]()
                    
                    // Convert the response to JSON with keys and AnyObject values
                    if let allData = response as? [String: AnyObject]
                    {
                        // Convert the response to an array of AnyObjects
                        // EXTRACT SHELTER DATA
                        if let allShelterRaw = allData["shelter"] as? [Any]
                        {
                            // Loop through each AnyObject (Blob) in the array
                            for newShelter in allShelterRaw
                            {
                                // Convert the response to JSON with keys and AnyObject values
                                // Then convert the AnyObject values to Strings or Numbers depending on their key
                                if let shelterRaw = newShelter as? [String: AnyObject]
                                {
                                    if let shelterID = shelterRaw["shelter_id"]
                                    {
                                        let addShelter = Shelter()
                                        addShelter.shelterID = shelterID as! String
                                        addShelter.datetime = Date(timeIntervalSince1970: shelterRaw["timestamp"] as! Double)
                                        addShelter.name = shelterRaw["name"] as! String
                                        addShelter.address = shelterRaw["address"] as! String
                                        addShelter.city = shelterRaw["city"] as! String
                                        addShelter.lat = shelterRaw["lat"] as! Double
                                        addShelter.lng = shelterRaw["lng"] as! Double
                                        if shelterRaw["phone"] as! String != "na"
                                        {
                                            addShelter.phone = shelterRaw["phone"] as? String
                                        }
                                        if shelterRaw["website"] as! String != "na"
                                        {
                                            addShelter.website = shelterRaw["website"] as? String
                                        }
                                        if shelterRaw["info"] as! String != "na"
                                        {
                                            addShelter.info = shelterRaw["info"] as? String
                                        }
                                        if shelterRaw["type"] as! String != "na"
                                        {
                                            addShelter.type = shelterRaw["type"] as! String
                                        }
                                        if shelterRaw["condition"] as! String != "na"
                                        {
                                            addShelter.condition = shelterRaw["condition"] as! String
                                        }
                                        Constants.Data.allShelter.append(addShelter)
//                                        print("AC-GSHD - ADDED SHELTER DATA: \(addShelter.name)")
                                    }
                                }
                            }
                        }
                    }
                    // Notify the parent view that the AWS call completed successfully
                    if let parentVC = self.awsRequestDelegate
                    {
                        print("AC-GSHD - CALLED PARENT")
                        parentVC.processAwsReturn(self, success: true)
                    }
                }
        })
    }
}


// MARK: HAZARD

class AWSGetHazardData : AWSRequestObject
{
    // Use this request function to request all active Hazard data
    override func makeRequest()
    {
        print("AC-GH: REQUESTING DATA")
        
        // Create a JSON object with the current app version
        var json = [String : Any]()
        json["app_version"] = Constants.Settings.appVersion
        
        let lambdaInvoker = AWSLambdaInvoker.default()
        lambdaInvoker.invokeFunction("Harvey-GetHazardData", jsonObject: json, completionHandler:
            { (response, err) -> Void in
                
                if (err != nil)
                {
                    print("AC-GH: GET DATA ERROR: \(String(describing: err))")
//                    CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: err.debugDescription)
                    
                    // Record the server request attempt
                    Constants.Data.serverTries += 1
                    
                    // Notify the parent view that the AWS call completed with an error
                    if let parentVC = self.awsRequestDelegate
                    {
                        parentVC.processAwsReturn(self, success: false)
                    }
                }
                else if (response != nil)
                {
                    print("AC-GH RESPONSE:")
                    print(response)
                    
                    // Convert the response to JSON with keys and AnyObject values
                    if let allData = response as? [String: AnyObject]
                    {
                        // Convert the response to an array of AnyObjects
                        // EXTRACT HAZARD DATA
                        if let allHazardRaw = allData["hazard"] as? [Any]
                        {
                            // Loop through each AnyObject in the array
                            for newHazard in allHazardRaw
                            {
                                // Convert the response to JSON with keys and AnyObject values
                                // Then convert the AnyObject values to Strings or Numbers depending on their key
                                if let hazardRaw = newHazard as? [String: AnyObject]
                                {
                                    // Double-check one of the key values before moving on
                                    if let hazardID = hazardRaw["hazard_id"]
                                    {
                                        let addHazard = Hazard()
                                        addHazard.hazardID = hazardID as? String
                                        addHazard.userID = hazardRaw["user_id"] as! String
                                        addHazard.datetime = Date(timeIntervalSince1970: hazardRaw["timestamp"] as! Double)
                                        addHazard.lat = hazardRaw["lat"] as! Double
                                        addHazard.lng = hazardRaw["lng"] as! Double
                                        addHazard.status = hazardRaw["status"] as! String
                                        addHazard.type = Constants().hazardType(hazardRaw["type"] as! Int)
                                        
                                        // Check to see if the hazard already exists
                                        var hazardExists = false
                                        hazardLoop: for hazard in Constants.Data.allHazard
                                        {
                                            if hazard.hazardID! == hazardID as! String
                                            {
                                                // It already exists, so update the values
                                                hazardExists = true
                                                
                                                hazard.userID = addHazard.userID
                                                hazard.datetime = addHazard.datetime
                                                hazard.lat = addHazard.lat
                                                hazard.lng = addHazard.lng
                                                hazard.status = addHazard.status
                                                hazard.type = addHazard.type
                                                
                                                break hazardLoop
                                            }
                                        }
                                        if !hazardExists
                                        {
                                            // It does not exist, so add it to the list
                                            Constants.Data.allHazard.append(addHazard)
                                        }
                                        print("AC-GH - ADDED/UPDATED HAZARD DATA: \(addHazard.hazardID)")
                                    }
                                }
                            }
                        }
                    }
                    // Notify the parent view that the AWS call completed successfully
                    if let parentVC = self.awsRequestDelegate
                    {
                        print("AC-GH - CALLED PARENT")
                        parentVC.processAwsReturn(self, success: true)
                    }
                }
        })
    }
}

class AWSPutHazardData: AWSRequestObject
{
    var hazard: Hazard!
    
    required init(hazard: Hazard!)
    {
        self.hazard = hazard
    }
    
    // Use this request function to update or create a new Hazard db entry
    override func makeRequest()
    {
        print("AC-PH: SENDING REQUEST")
        
        // Ensure that the hazard ID has been added
        if let hazardID = hazard.hazardID
        {
            print("AC-PH - HAZARD STATUS: \(hazard.status)")
            // Create a JSON object with the passed data
            var json = [String : Any]()
            json["hazard_id"] = hazardID
            json["user_id"] = Constants.Data.currentUser.userID
            json["timestamp"] = String(hazard.datetime.timeIntervalSince1970)
            json["lat"] = String(hazard.lat)
            json["lng"] = String(hazard.lng)
            json["type"] = String(hazard.type.rawValue)
            json["status"] = hazard.status
            
            let lambdaInvoker = AWSLambdaInvoker.default()
            lambdaInvoker.invokeFunction("Harvey-PutHazardData", jsonObject: json, completionHandler:
                { (response, err) -> Void in
                    
                    if (err != nil)
                    {
                        print("AC-PH: GET DATA ERROR: \(String(describing: err))")
//                        CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: err.debugDescription)
                        
                        // Record the server request attempt
                        Constants.Data.serverTries += 1
                        
                        // Notify the parent view that the AWS call completed with an error
                        if let parentVC = self.awsRequestDelegate
                        {
                            parentVC.processAwsReturn(self, success: false)
                        }
                    }
                    else if (response != nil)
                    {
                        print("AC-PH RESPONSE:")
                        print(response)
                        
                        // Now add the new Hazard to the global array if it was not deleted
                        if self.hazard.status == "active"
                        {
                            Constants.Data.allHazard.append(self.hazard)
                        }
                        
                        // Notify the parent view that the AWS call completed successfully
                        if let parentVC = self.awsRequestDelegate
                        {
                            print("AC-PH - CALLED PARENT")
                            parentVC.processAwsReturn(self, success: true)
                        }
                    }
            })
        }
    }
}


// MARK: SOS

class AWSGetSOSData : AWSRequestObject
{
    // Use this request function to request all SOS data
    override func makeRequest()
    {
        print("AC-SOS: REQUESTING DATA")
        
        // Create a JSON object with the passed Blob ID and an indicator of whether or not the Blob data should be filtered (0 for no, 1 for yes)
        var json = [String : Any]()
        json["app_version"] = Constants.Settings.appVersion
        
        let lambdaInvoker = AWSLambdaInvoker.default()
        lambdaInvoker.invokeFunction("Harvey-GetSOSData", jsonObject: json, completionHandler:
            { (response, err) -> Void in
                
                if (err != nil)
                {
                    print("AC-SOS: GET DATA ERROR: \(String(describing: err))")
//                    CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: err.debugDescription)
                    
                    // Record the server request attempt
                    Constants.Data.serverTries += 1
                    
                    // Notify the parent view that the AWS call completed with an error
                    if let parentVC = self.awsRequestDelegate
                    {
                        parentVC.processAwsReturn(self, success: false)
                    }
                }
                else if (response != nil)
                {
                    print("AC-SOS RESPONSE:")
                    print(response)
                    
                    // The data request was successful - reset the data array
                    Constants.Data.allSOS = [SOS]()
                    
                    // Convert the response to JSON with keys and AnyObject values
                    if let allData = response as? [String: AnyObject]
                    {
                        // Convert the response to an array of AnyObjects
                        // EXTRACT SOS DATA
                        if let allSOSRaw = allData["sos"] as? [Any]
                        {
                            // Loop through each AnyObject in the array
                            for newSOS in allSOSRaw
                            {
                                // Convert the response to JSON with keys and AnyObject values
                                // Then convert the AnyObject values to Strings or Numbers depending on their key
                                if let sosRaw = newSOS as? [String: AnyObject]
                                {
                                    if let userID = sosRaw["user_id"]
                                    {
                                        let addSOS = SOS()
                                        addSOS.userID = userID as! String
                                        addSOS.datetime = Date(timeIntervalSince1970: sosRaw["timestamp"] as! Double)
                                        addSOS.lat = sosRaw["lat"] as! Double
                                        addSOS.lng = sosRaw["lng"] as! Double
                                        addSOS.status = sosRaw["status"] as! String
                                        addSOS.type = sosRaw["type"] as! String
                                        
                                        Constants.Data.allSOS.append(addSOS)
                                        print("AC-SOS - ADDED SOS DATA: \(addSOS.status)")
                                    }
                                }
                            }
                        }
                    }
                    
                    // Notify the parent view that the AWS call completed successfully
                    if let parentVC = self.awsRequestDelegate
                    {
                        print("AC-SOS - CALLED PARENT")
                        parentVC.processAwsReturn(self, success: true)
                    }
                }
        })
    }
}

class AWSUpdateSOSData: AWSRequestObject
{
    var sos: SOS!
    
    required init(sos: SOS!)
    {
        self.sos = sos
    }
    
    // Use this request function to query all current users
    override func makeRequest()
    {
        print("AC-USOS: SENDING REQUEST")
        
        // Create a JSON object with the passed Blob ID and an indicator of whether or not the Blob data should be filtered (0 for no, 1 for yes)
        var json = [String : Any]()
        json["user_id"] = Constants.Data.currentUser.userID
        json["timestamp"] = String(sos.datetime.timeIntervalSince1970)
        json["lat"] = String(sos.lat)
        json["lng"] = String(sos.lng)
        json["status"] = sos.status
        json["type"] = sos.type
        if let sosID = sos.sosID
        {
            json["sos_id"] = sosID
        }
        
        let lambdaInvoker = AWSLambdaInvoker.default()
        lambdaInvoker.invokeFunction("Harvey-UpdateSOSLatest", jsonObject: json, completionHandler:
            { (response, err) -> Void in
                
                if (err != nil)
                {
                    print("AC-USOS: GET DATA ERROR: \(String(describing: err))")
//                    CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: err.debugDescription)
                    
                    // Record the server request attempt
                    Constants.Data.serverTries += 1
                    
                    // Notify the parent view that the AWS call completed with an error
                    if let parentVC = self.awsRequestDelegate
                    {
                        parentVC.processAwsReturn(self, success: false)
                    }
                }
                else if (response != nil)
                {
                    print("AC-USOS RESPONSE:")
                    print(response)
                    
                    // Notify the parent view that the AWS call completed successfully
                    if let parentVC = self.awsRequestDelegate
                    {
                        print("AC-USOS - CALLED PARENT")
                        parentVC.processAwsReturn(self, success: true)
                    }
                }
        })
    }
}


// MARK: HYDRO

class AWSGetHydroData : AWSRequestObject
{
    var userLocation = [String : Double]()
    
    required init(userLocation: [String : Double]!)
    {
        if let userLocation = userLocation
        {
            self.userLocation = userLocation
        }
    }
    
    // Use this request function when a Blob is within range of the user's location and the extra Blob data is needed
    override func makeRequest()
    {
        print("AC-GHD: REQUESTING DATA: \(String(describing: self.userLocation))")
        
        // Create a JSON object with the passed Blob ID and an indicator of whether or not the Blob data should be filtered (0 for no, 1 for yes)
        var json = [String : Any]()
        json["app_version"] = Constants.Settings.appVersion
        json["user_location"] = userLocation
        
        let lambdaInvoker = AWSLambdaInvoker.default()
        lambdaInvoker.invokeFunction("Harvey-GetHydroData", jsonObject: json, completionHandler:
            { (response, err) -> Void in
                
                if (err != nil)
                {
                    print("AC-GHD: GET DATA ERROR: \(String(describing: err))")
                    //                    CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: err.debugDescription)
                    
                    // Record the server request attempt
                    Constants.Data.serverTries += 1
                    
                    // Notify the parent view that the AWS call completed with an error
                    if let parentVC = self.awsRequestDelegate
                    {
                        parentVC.processAwsReturn(self, success: false)
                    }
                }
                else if (response != nil)
                {
//                    print("AC-GHD RESPONSE:")
//                    print(response)
                    
                    // The data request was successful - reset the data array
                    Constants.Data.allHydro = [Hydro]()
                    
                    // Convert the response to JSON with keys and AnyObject values
                    if let allData = response as? [String: AnyObject]
                    {
                        // Convert the response to an array of AnyObjects
                        // EXTRACT HYDRO DATA
                        if let allHydroRaw = allData["hydro"] as? [Any]
                        {
                            // Loop through each AnyObject (Blob) in the array
                            for newHydro in allHydroRaw
                            {
                                // Convert the response to JSON with keys and AnyObject values
                                // Then convert the AnyObject values to Strings or Numbers depending on their key
                                if let hydroRaw = newHydro as? [String: AnyObject]
                                {
                                    if let readingID = hydroRaw["reading_id"]
                                    {
                                        let addHydro = Hydro()
                                        addHydro.readingID = readingID as! String
                                        addHydro.datetime = Date(timeIntervalSince1970: hydroRaw["timestamp"] as! Double)
                                        addHydro.gaugeID = hydroRaw["gauge_id"] as! String
                                        addHydro.title = hydroRaw["title"] as! String
                                        addHydro.lat = hydroRaw["lat"] as! Double
                                        addHydro.lng = hydroRaw["lng"] as! Double
                                        if let obs = hydroRaw["obs"]
                                        {
                                            addHydro.obs = obs as? String
                                        }
                                        if let obs2 = hydroRaw["obs_2"]
                                        {
                                            addHydro.obs2 = obs2 as? String
                                        }
                                        if let obsCat = hydroRaw["obs_cat"]
                                        {
                                            addHydro.obsCat = obsCat as? String
                                        }
                                        if let obsTime = hydroRaw["obs_time"]
                                        {
                                            addHydro.obsTime = obsTime as? String
                                        }
                                        if let projHigh = hydroRaw["proj_high"]
                                        {
                                            addHydro.projHigh = projHigh as? String
                                        }
                                        if let projHigh2 = hydroRaw["proj_high_2"]
                                        {
                                            addHydro.projHigh2 = projHigh2 as? String
                                        }
                                        if let projHighCat = hydroRaw["proj_high_cat"]
                                        {
                                            addHydro.projHighCat = projHighCat as? String
                                        }
                                        if let projHighTime = hydroRaw["proj_high_time"]
                                        {
                                            addHydro.projHighTime = projHighTime as? String
                                        }
                                        if let projLast = hydroRaw["proj_last"]
                                        {
                                            addHydro.projLast = projLast as? String
                                        }
                                        if let projLast2 = hydroRaw["proj_last_2"]
                                        {
                                            addHydro.projLast2 = projLast2 as? String
                                        }
                                        if let projLastCat = hydroRaw["proj_last_cat"]
                                        {
                                            addHydro.projLastCat = projLastCat as? String
                                        }
                                        if let projLastTime = hydroRaw["proj_last_time"]
                                        {
                                            addHydro.projLastTime = projLastTime as? String
                                        }
                                        if let projRec = hydroRaw["proj_rec"]
                                        {
                                            addHydro.projRec = projRec as? String
                                        }
                                        if let projRec2 = hydroRaw["proj_rec_2"]
                                        {
                                            addHydro.projRec2 = projRec2 as? String
                                        }
                                        if let projRecCat = hydroRaw["proj_rec_cat"]
                                        {
                                            addHydro.projRecCat = projRecCat as? String
                                        }
                                        if let projRecTime = hydroRaw["proj_rec_time"]
                                        {
                                            addHydro.projRecTime = projRecTime as? String
                                        }
                                        Constants.Data.allHydro.append(addHydro)
//                                    print("AC-GHD - ADDED HYDRO DATA: \(addHydro.title)")
                                    }
                                }
                            }
                        }
                    }
                    
                    // Notify the parent view that the AWS call completed successfully
                    if let parentVC = self.awsRequestDelegate
                    {
                        print("AC-GHD - CALLED PARENT")
                        parentVC.processAwsReturn(self, success: true)
                    }
                }
        })
    }
}


class AWSUploadMediaToBucket : AWSRequestObject
{
    var bucket: String!
    var uploadKey: String!
    var mediaURL: URL!
    var imageIndex: Int!
    
    required init(bucket: String!, uploadKey: String!, mediaURL: URL!, imageIndex: Int!)
    {
        self.bucket = bucket
        self.uploadKey = uploadKey
        self.mediaURL = mediaURL
        self.imageIndex = imageIndex
    }
    
    // Upload a file to AWS S3
    override func makeRequest()
    {
//        print("UPLOADING FILE: \(uploadKey) TO BUCKET: \(bucket)")
        
        let uploadRequest = AWSS3TransferManagerUploadRequest()
        uploadRequest?.bucket = bucket
        uploadRequest?.key =  uploadKey
        uploadRequest?.body = mediaURL //URL(fileURLWithPath: mediaFilePath)
        uploadRequest?.acl = AWSS3ObjectCannedACL.authenticatedRead
        
        let transferManager = AWSS3TransferManager.default()
        transferManager?.upload(uploadRequest).continue(
            { (task) -> AnyObject! in
                
                if let error = task.error
                {
                    if error._domain == AWSS3TransferManagerErrorDomain as String
                        && AWSS3TransferManagerErrorType(rawValue: error._code) == AWSS3TransferManagerErrorType.paused
                    {
                        print("Upload paused.")
//                        CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: "MEDIA UPLOAD PAUSED")
                    }
                    else
                    {
                        print("Upload failed: [\(error)]")
//                        CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: error.localizedDescription)
                        
                        // Record the server request attempt
                        Constants.Data.serverTries += 1
                    }
                    
                    // Notify the parent view that the AWS call completed with an error
                    if let parentVC = self.awsRequestDelegate
                    {
                        parentVC.processAwsReturn(self, success: false)
                    }
                    
                }
                else if let exception = task.exception
                {
                    print("Upload failed: [\(exception)]")
//                    CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: exception.debugDescription)
                    
                    // Record the server request attempt
                    Constants.Data.serverTries += 1
                    
                    // Notify the parent view that the AWS call completed with an error
                    if let parentVC = self.awsRequestDelegate
                    {
                        parentVC.processAwsReturn(self, success: false)
                    }
                    
                }
                else
                {
                    print("Upload succeeded")
                    
                    // Notify the parent view that the AWS call completed successfully
                    if let parentVC = self.awsRequestDelegate
                    {
                        parentVC.processAwsReturn(self, success: true)
                    }
                }
                return nil
        })
    }
}

class AWSGetMediaImage : AWSRequestObject
{
    var spotContent: SpotContent!
    var contentImage: UIImage?
    
    required init(spotContent: SpotContent)
    {
        self.spotContent = spotContent
    }
    
    // Download Blob Image
    override func makeRequest()
    {
//        print("AC - GMI - ATTEMPTING TO DOWNLOAD IMAGE: \(self.spotContent.contentID)")
        
        // Verify the type of Blob (image)
        if self.spotContent.type == Constants.ContentType.image
        {
            if let contentID = self.spotContent.contentID
            {
                let downloadingFilePath = NSTemporaryDirectory() + contentID + ".jpg" // + Constants.Settings.frameImageFileType)
                let downloadingFileURL = URL(fileURLWithPath: downloadingFilePath)
                let transferManager = AWSS3TransferManager.default()
                
                // Download the Frame
                let downloadRequest : AWSS3TransferManagerDownloadRequest = AWSS3TransferManagerDownloadRequest()
                downloadRequest.bucket = Constants.Strings.S3BucketMedia
                downloadRequest.key =  contentID + ".jpg"
                downloadRequest.downloadingFileURL = downloadingFileURL
                
                transferManager?.download(downloadRequest).continue(
                    { (task) -> AnyObject! in
                        
                        if let error = task.error
                        {
                            if error._domain == AWSS3TransferManagerErrorDomain as String
                                && AWSS3TransferManagerErrorType(rawValue: error._code) == AWSS3TransferManagerErrorType.paused
                            {
                                print("AC - GMI - 3: Download paused.")
//                                CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: "IMAGE NOT DOWNLOADED")
                            }
                            else
                            {
                                print("AC - GMI - 3: Download failed: [\(error)]")
//                                CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: error.localizedDescription)
                                
                                // Record the server request attempt
                                Constants.Data.serverTries += 1
                            }
                            
                            // Notify the parent view that the AWS call completed with an error
                            if let parentVC = self.awsRequestDelegate
                            {
                                parentVC.processAwsReturn(self, success: false)
                            }
                        }
                        else if let exception = task.exception
                        {
                            print("AC - GMI - 3: Download failed: [\(exception)]")
//                            CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: exception.debugDescription)
                            
                            // Record the server request attempt
                            Constants.Data.serverTries += 1
                            
                            // Notify the parent view that the AWS call completed with an error
                            if let parentVC = self.awsRequestDelegate
                            {
                                parentVC.processAwsReturn(self, success: false)
                            }
                        }
                        else
                        {
                            // Assign the image to the Preview Image View
                            if FileManager().fileExists(atPath: downloadingFilePath)
                            {
                                self.spotContent.imageFilePath = downloadingFilePath
                                
                                let imageData = try? Data(contentsOf: URL(fileURLWithPath: downloadingFilePath))
                                
                                // Save the image to the local UIImage
                                self.contentImage = UIImage(data: imageData!)
                                
                                // Notify the parent view that the AWS call completed successfully
                                if let parentVC = self.awsRequestDelegate
                                {
                                    parentVC.processAwsReturn(self, success: true)
                                }
                            }
                            else
                            {
                                print("AC - GMI - FRAME FILE NOT AVAILABLE")
//                                CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: "IMAGE NOT DOWNLOADED")
                                
                                // Notify the parent view that the AWS call completed with an error
                                if let parentVC = self.awsRequestDelegate
                                {
                                    parentVC.processAwsReturn(self, success: false)
                                }
                            }
                        }
                        return nil
                })
            }
        }
        else
        {
            print("AC - GMI - VIDEOS ARE NOT CURRENTLY SUPPORTED")
        }
    }
}

/**
 Properties:
 - randomIdType- The string passed to AWS to indicate what type of random ID is being requested.  Should be either:
 -- "random_media_id" - an ID type for new media
 -- "random_user_image_id" - an ID type for user images
 */
class AWSGetRandomID : AWSRequestObject
{
    var randomID: String?
    var randomIdType: Constants.randomIdType!
    
    required init(randomIdType: Constants.randomIdType!)
    {
        self.randomIdType = randomIdType
    }
    
    // Request a random MediaID
    override func makeRequest()
    {
//        print("AC-GRID - GET RANDOM ID FOR: \(randomIdType)")
        // Create some JSON to send the logged in userID
        var json = [String : Any]()
        json["app_version"] = Constants.Settings.appVersion
        json["request"] = randomIdType.rawValue
        
        let lambdaInvoker = AWSLambdaInvoker.default()
        lambdaInvoker.invokeFunction("Harvey-CreateRandomID", jsonObject: json, completionHandler:
            { (response, err) -> Void in
                
                if (err != nil)
                {
                    print("GET RANDOM ID ERROR: \(String(describing: err))")
//                    CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: err.debugDescription)
                    
                    // Record the server request attempt
                    Constants.Data.serverTries += 1
                    
                    // Notify the parent view that the AWS call completed with an error
                    if let parentVC = self.awsRequestDelegate
                    {
                        parentVC.processAwsReturn(self, success: false)
                    }
                    
                }
                else if (response != nil)
                {
//                    print("AC-GRID - RESPONSE: \(String(describing: response))")
                    // Convert the response to a String
                    if let newRandomID = response as? String
                    {
                        self.randomID = newRandomID
                        
                        // Notify the parent view that the AWS call completed successfully
                        if let parentVC = self.awsRequestDelegate
                        {
                            parentVC.processAwsReturn(self, success: true)
                        }
                    }
                }
        })
    }
}
