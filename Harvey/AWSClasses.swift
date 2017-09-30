//
//  AWSClasses.swift
//  Harvey
//
//  Created by Sean Hart on 8/29/17.
//  Copyright © 2017 TangoJ Labs, LLC. All rights reserved.
//

import AWSCognito
//import AWSLambda
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
                    self.getHarveyID(cognitoID: Constants.credentialsProvider.identityId, facebookToken: facebookToken)
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
                    // Check to see if the parent viewcontroller is already the MapViewController.  If so, call the MVC showLoginScreen function
                    // Otherwise, launch a new MapViewController and show the login screen
                    if parentVC is MapViewController
                    {
                        // PARENT VC IS EQUAL TO MVC
                        parentVC.showLoginScreen()
                    }
                    else
                    {
                        // PARENT VC IS NOT EQUAL TO MVC
                        let newMapViewController = MapViewController()
                        if let rootNavController = UIApplication.shared.windows[0].rootViewController?.navigationController
                        {
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
        print("AC-PREP - IN GET COGNITO ID: \(String(describing: requestToCall.facebookToken?.tokenString))")
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
                        print("AC - AWS COGNITO GET IDENTITY ID - ERROR: " + task.error!.localizedDescription)
//                        CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: task.error!.localizedDescription)
                        
                        // Record the server request attempt
                        Constants.Data.serverTries += 1
                        
                        // Go ahead and move to the next login step
                        self.getHarveyID(cognitoID: Constants.credentialsProvider.identityId, facebookToken: token)
                    }
                    else
                    {
                        // the task result will contain the identity id
                        let cognitoId = task.result
                        print("AC - AWS COGNITO GET IDENTITY ID - AWS COGNITO ID: \(String(describing: cognitoId))")
//                        print("AC - AWS COGNITO GET IDENTITY ID - CHECK IDENTITY ID: \(String(describing: Constants.credentialsProvider.identityId))")
                        
                        // Save the current time to mark when the last CognitoID was saved
                        Constants.Data.lastCredentials = NSDate().timeIntervalSinceNow
                        
                        // Request extra facebook data for the user ON THE MAIN THREAD
                        DispatchQueue.main.async(execute:
                            {
                                print("AC - GOT COGNITO ID - GETTING NEW AWS ID")
                                self.getHarveyID(cognitoID: cognitoId! as String, facebookToken: token)
                        });
                    }
                    return nil
            })
        }
    }
    
    // After ensuring that the Cognito ID is valid, so check for a Harvey ID and then make the request
    func getHarveyID(cognitoID: String!, facebookToken: FBSDKAccessToken!)
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
class AWSLoginUser : AWSRequestObject, RequestDelegate
{
    let url = URL(string: Constants.Strings.urlLogin)
    
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
        print("AC-L: SET UP LOGIN USER")
        if let fbToken = facebookToken
        {
            RequestPrep(requestToCall: FBGetUserData(me: true, facebookID: fbToken.userID), delegate: self as RequestDelegate).prepRequest()
        }
    }
    
    // Log in the user or create a new user
    func loginUser(_ facebookName: String, facebookThumbnailUrl: String)
    {
        print("AC-L - FACEBOOK TOKEN: \(String(describing: self.facebookToken))")
        print("AC-L - COGNITO ID: \(String(describing: Constants.credentialsProvider.identityId))")
        if let fbToken = facebookToken
        {
            print("AC-L: FIRING LOGIN USER")
            
            var json = [String: Any]()
            json["app_version"] = Constants.Settings.appVersion
            json["identity_id"] = Constants.credentialsProvider.identityId
            json["login_provider"] = "graph.facebook.com"
            json["login_token"] = fbToken.tokenString
            json["facebook_id"] = fbToken.userID
            let jsonData = try? JSONSerialization.data(withJSONObject: json)
            
            var request = URLRequest(url: url!)
            request.httpMethod = "POST"
            request.timeoutInterval = Constants.Settings.requestTimeout
            request.httpBody = jsonData
            request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            let session = URLSession(configuration: .default)
            let dataTask = session.dataTask(with: request)
            { (responseData, response, error) in
                if let err = error
                {
                    self.recordError(stage: "URLRequest", error: err as? String)
                }
                else if let res = response as? HTTPURLResponse
                {
                    print("AC-L - RESPONSE CODE: \(res.statusCode)")
                    if let data = responseData
                    {
                        do
                        {
                            let jsonData = try JSONSerialization.jsonObject(with: data, options: [JSONSerialization.ReadingOptions.allowFragments])
                            print("AC-L - JSON DATA: \(json)")
                            // Convert the data to JSON with keys and AnyObject values
                            if let json = jsonData as? [String: AnyObject]
                            {
                                print("AC-L - JSON: \(json)")
                                // EXTRACT THE RESPONSE STRING
                                if let response = json["response"] as? String
                                {
                                    print("AC-L - RESPONSE: \(response)")
                                    if response == "success"
                                    {
                                        // Convert the response to JSON with keys and AnyObject values
                                        if let responseJson = json["login_data"] as? [String: AnyObject]
                                        {
                                            if let status = responseJson["status"] as? String
                                            {
                                                print("AC-L - loginUser - status: \(status)")
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
                                                        print("AC-L -LOGIN: \(responseJson)")
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
                                                        
//                                                        // Reset the global User list with Core Data
//                                                        UtilityFunctions().resetUserListWithCoreData()
//
//                                                        UtilityFunctions().registerPushNotifications()
                                                        
                                                        // Check whether the user is a new user, or has logged in before - still in use (9/7/2017)?
                                                        if let newUserInt = responseJson["new_user"] as? Int
                                                        {
                                                            if newUserInt == 1
                                                            {
                                                                self.newUser = true
                                                            }
                                                        }
                                                        
                                                        // SETTINGS MUST BE SENT HERE TOO - IF NOT LOGGED IN WHEN APP STARTS, APP DELEGATE WILL NOT CALL SETTINGS
                                                        // Save the passed settings
                                                        if let settings = responseJson["settings"] as? [String: AnyObject]
                                                        {
                                                            print("AC-L - SETTINGS: \(settings)")
                                                        }
                                                        
                                                        // If the secondary request object is not nil, process the carried (second) request; no need to
                                                        // pass the login response to the parent view controller since it did not explicitly call the login request
                                                        if let secondaryAwsRequestObject = self.secondaryAwsRequestObject
                                                        {
                                                            print("AC-L -loginUser - secondary fire")
                                                            AWSPrepRequest(requestToCall: secondaryAwsRequestObject, delegate: self.awsRequestDelegate!).prepRequest()
                                                        }
                                                        else
                                                        {
                                                            print("AC-L -loginUser - else")
                                                            // Notify the parent view that the AWS Login call completed successfully
                                                            if let parentVC = self.awsRequestDelegate
                                                            {
                                                                parentVC.processAwsReturn(self, success: true)
                                                            }
                                                        }
                                                        
                                                        print("AC-L -loginUser - call RC-FBI FOR USER: \(self.facebookToken!.userID)")
                                                        // Go ahead and download the user image and make available
                                                        RequestPrep(requestToCall: FBDownloadUserImage(facebookID: self.facebookToken!.userID, largeImage: true), delegate: self as RequestDelegate).prepRequest()
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    else
                                    {
                                        self.recordError(stage: "response - fail", error: response)
                                    }
                                }
                                else
                                {
                                    self.recordError(stage: "response", error: nil)
                                }
                            }
                            else
                            {
                                self.recordError(stage: "JSON", error: nil)
                            }
                        }
                        catch let error as NSError
                        {
                            self.recordError(stage: "JSONSerlialization", error: error.description)
                        }
                    }
                    else
                    {
                        self.recordError(stage: "Response Data - else", error: nil)
                    }
                }
                else
                {
                    self.recordError(stage: "URLRequest - else", error: nil)
                }
            }
            dataTask.resume()
        }
    }
    
    func recordError(stage: String!, error: String?)
    {
        print("AC-L: GET DATA ERROR AT STAGE: \(stage), ERROR: \(String(describing: error))")
//        CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: err.debugDescription)
        
        // Record the server request attempt
        Constants.Data.serverTries += 1
        
        // Notify the parent view that the AWS call completed with an error
        if let parentVC = self.awsRequestDelegate
        {
            parentVC.processAwsReturn(self, success: false)
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
                print("AC-L -FBGetUserData FAILURE")
            }
        case _ as FBDownloadUserImage:
            if success
            {
                print("AC-L -FBDownloadUserImage SUCCESS")
            }
            else
            {
                print("AC-L -FBDownloadUserImage FAILURE")
            }
        default:
            print("AC-L -processRequestReturn DEFAULT")
        }
    }
}

class AWSLogoutUser
{
    
}


/**
 Properties:
 - randomIdType- The string passed to AWS to indicate what type of random ID is being requested.  Should be either:
 -- "random_media_id" - an ID type for new media
 -- "random_user_image_id" - an ID type for user images
 */
class AWSCreateRandomID : AWSRequestObject
{
    let url = URL(string: Constants.Strings.urlRandomId)
    
    var randomID: String?
    var randomIdType: Constants.randomIdType!
    
    required init(randomIdType: Constants.randomIdType!)
    {
        self.randomIdType = randomIdType
    }
    
    override func makeRequest()
    {
        print("AC-CRI: CREATE RANDOM ID FOR TYPE: \(self.randomIdType)")
        
        var json = [String: Any]()
        json["app_version"] = Constants.Settings.appVersion
        json["request"] = randomIdType.rawValue
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        
        var request = URLRequest(url: url!)
        request.httpMethod = "POST"
        request.timeoutInterval = Constants.Settings.requestTimeout
        request.httpBody = jsonData
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        let session = URLSession(configuration: .default)
        let dataTask = session.dataTask(with: request)
        { (responseData, response, error) in
            if let err = error
            {
                self.recordError(stage: "URLRequest", error: err as? String)
            }
            else if let res = response as? HTTPURLResponse
            {
                print("AC-CRI - RESPONSE CODE: \(res.statusCode)")
                if let data = responseData
                {
                    do
                    {
                        let jsonData = try JSONSerialization.jsonObject(with: data, options: [JSONSerialization.ReadingOptions.allowFragments])
                        print("AC-CRI - JSON DATA: \(json)")
                        // Convert the data to JSON with keys and AnyObject values
                        if let json = jsonData as? [String: AnyObject]
                        {
                            print("AC-CRI - JSON: \(json)")
                            // EXTRACT THE RESPONSE STRING
                            if let response = json["response"] as? String
                            {
                                print("AC-CRI - RESPONSE: \(response)")
                                if response == "success"
                                {
                                    // Convert the response to a String
                                    if let newRandomID = json["random_id"] as? String
                                    {
                                        self.randomID = newRandomID
                                        
                                        // Notify the parent view that the AWS call completed successfully
                                        if let parentVC = self.awsRequestDelegate
                                        {
                                            parentVC.processAwsReturn(self, success: true)
                                        }
                                    }
                                }
                                else
                                {
                                    self.recordError(stage: "response - fail", error: response)
                                }
                            }
                            else
                            {
                                self.recordError(stage: "response", error: nil)
                            }
                        }
                        else
                        {
                            self.recordError(stage: "JSON", error: nil)
                        }
                    }
                    catch let error as NSError
                    {
                        self.recordError(stage: "JSONSerlialization", error: error.description)
                    }
                }
                else
                {
                    self.recordError(stage: "Response Data - else", error: nil)
                }
            }
            else
            {
                self.recordError(stage: "URLRequest - else", error: nil)
            }
        }
        dataTask.resume()
    }
    
    func recordError(stage: String!, error: String?)
    {
        print("AC-CRI: GET DATA ERROR AT STAGE: \(stage), ERROR: \(String(describing: error))")
//        CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: err.debugDescription)
        
        // Record the server request attempt
        Constants.Data.serverTries += 1
        
        // Notify the parent view that the AWS call completed with an error
        if let parentVC = self.awsRequestDelegate
        {
            parentVC.processAwsReturn(self, success: false)
        }
    }
}

class AWSSettings : AWSRequestObject
{
    let url = URL(string: Constants.Strings.urlSettings)
    
    override func makeRequest()
    {
        print("AC-STGS: REQUESTING SETTINGS")
        
        var json = [String: Any]()
        json["app_version"] = Constants.Settings.appVersion
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        
        var request = URLRequest(url: url!)
        request.httpMethod = "POST"
        request.timeoutInterval = Constants.Settings.requestTimeout
        request.httpBody = jsonData
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        let session = URLSession(configuration: .default)
        let dataTask = session.dataTask(with: request)
        { (responseData, response, error) in
            if let err = error
            {
                self.recordError(stage: "URLRequest", error: err as? String)
            }
            else if let res = response as? HTTPURLResponse
            {
                print("AC-STGS - RESPONSE CODE: \(res.statusCode)")
                if let data = responseData
                {
                    do
                    {
                        let json = try JSONSerialization.jsonObject(with: data, options: [JSONSerialization.ReadingOptions.allowFragments])
                        print("AC-STGS - JSON: \(json)")
                        // Convert the data to JSON with keys and AnyObject values
                        if let allData = json as? [String: AnyObject]
                        {
                            print("AC-STGS - ALL DATA: \(allData)")
                            // EXTRACT THE RESPONSE STRING
                            if let response = allData["response"] as? String
                            {
                                print("AC-STGS - RESPONSE: \(response)")
                                if response == "success"
                                {
                                    // Convert the response to an array of AnyObjects
                                    // EXTRACT SETTINGS DATA
                                    if let allSettingsRaw = allData["settings"] as? [String: AnyObject]
                                    {
                                        print("AC-STGS - ALL SETTINGS: \(allSettingsRaw)")
                                        
                                        // Notify the parent view that the AWS call completed successfully
                                        if let parentVC = self.awsRequestDelegate
                                        {
                                            print("AC-STGS - CALLED PARENT")
                                            parentVC.processAwsReturn(self, success: true)
                                        }
                                    }
                                    else
                                    {
                                        self.recordError(stage: "Settings Data - else", error: nil)
                                    }
                                }
                                else
                                {
                                    self.recordError(stage: "response - fail", error: response)
                                }
                            }
                            else
                            {
                                self.recordError(stage: "response", error: nil)
                            }
                        }
                        else
                        {
                            self.recordError(stage: "JSON", error: nil)
                        }
                    }
                    catch let error as NSError
                    {
                        self.recordError(stage: "JSONSerlialization", error: error.description)
                    }
                }
                else
                {
                    self.recordError(stage: "Response Data - else", error: nil)
                }
            }
            else
            {
                self.recordError(stage: "URLRequest - else", error: nil)
            }
        }
        dataTask.resume()
    }
    
    func recordError(stage: String!, error: String?)
    {
        print("AC-STGS: GET DATA ERROR AT STAGE: \(stage), ERROR: \(String(describing: error))")
//        CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: err.debugDescription)
        
        // Record the server request attempt
        Constants.Data.serverTries += 1
        
        // Notify the parent view that the AWS call completed with an error
        if let parentVC = self.awsRequestDelegate
        {
            parentVC.processAwsReturn(self, success: false)
        }
    }
}


// MARK: USER

class AWSUserCheckFbId : AWSRequestObject
{
    let url = URL(string: Constants.Strings.urlUserCheck)
    
    var facebookID: String!
    var newUser: Bool = true
    
    required init(facebookID: String)
    {
        self.facebookID = facebookID
    }
    
    override func makeRequest()
    {
        print("AC-UCFB: REQUESTING USER CHECK FOR FB ID: \(facebookID)")
        
        if let facebookToken = FBSDKAccessToken.current()
        {
            var json = [String: Any]()
            json["app_version"] = Constants.Settings.appVersion
            json["identity_id"] = Constants.credentialsProvider.identityId
            json["login_provider"] = "graph.facebook.com"
            json["login_token"] = facebookToken.tokenString
            json["facebook_id"] = facebookID
            let jsonData = try? JSONSerialization.data(withJSONObject: json)
            
            var request = URLRequest(url: url!)
            request.httpMethod = "POST"
            request.timeoutInterval = Constants.Settings.requestTimeout
            request.httpBody = jsonData
            request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            let session = URLSession(configuration: .default)
            let dataTask = session.dataTask(with: request)
            { (responseData, response, error) in
                if let err = error
                {
                    self.recordError(stage: "URLRequest", error: err as? String)
                }
                else if let res = response as? HTTPURLResponse
                {
                    print("AC-UCFB - RESPONSE CODE: \(res.statusCode)")
                    if let data = responseData
                    {
                        do
                        {
                            let json = try JSONSerialization.jsonObject(with: data, options: [JSONSerialization.ReadingOptions.allowFragments])
                            print("AC-UCFB - JSON: \(json)")
                            // Convert the data to JSON with keys and AnyObject values
                            if let allData = json as? [String: AnyObject]
                            {
                                print("AC-UCFB - ALL DATA: \(allData)")
                                // EXTRACT THE RESPONSE STRING
                                if let response = allData["response"] as? String
                                {
                                    print("AC-UCFB - RESPONSE: \(response)")
                                    if response == "success"
                                    {
                                        // Convert the response to an Integer
                                        if let userExistsInt = allData["user_exists"] as? Int
                                        {
                                            print("AC-UCFB - USER EXISTS INT: \(userExistsInt)")
                                            if userExistsInt == 1
                                            {
                                                self.newUser = false
                                            }
                                            
                                            // Notify the parent view that the AWS call completed successfully
                                            if let parentVC = self.awsRequestDelegate
                                            {
                                                print("AC-UCFB - CALLED PARENT")
                                                parentVC.processAwsReturn(self, success: true)
                                            }
                                        }
                                        else
                                        {
                                            self.recordError(stage: "USER EXISTS CHECK - else", error: nil)
                                        }
                                    }
                                    else
                                    {
                                        self.recordError(stage: "response - fail", error: response)
                                    }
                                }
                                else
                                {
                                    self.recordError(stage: "response", error: nil)
                                }
                            }
                            else
                            {
                                self.recordError(stage: "JSON", error: nil)
                            }
                        }
                        catch let error as NSError
                        {
                            self.recordError(stage: "JSONSerlialization", error: error.description)
                        }
                    }
                    else
                    {
                        self.recordError(stage: "Response Data - else", error: nil)
                    }
                }
                else
                {
                    self.recordError(stage: "URLRequest - else", error: nil)
                }
            }
            dataTask.resume()
        }
        else
        {
            self.recordError(stage: "FBToken", error: nil)
        }
    }
    
    func recordError(stage: String!, error: String?)
    {
        print("AC-UCFB: GET DATA ERROR AT STAGE: \(stage), ERROR: \(String(describing: error))")
//        CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: err.debugDescription)
        
        // Record the server request attempt
        Constants.Data.serverTries += 1
        
        // Notify the parent view that the AWS call completed with an error
        if let parentVC = self.awsRequestDelegate
        {
            parentVC.processAwsReturn(self, success: false)
        }
    }
}

class AWSUserUpdate : AWSRequestObject
{
    let url = URL(string: Constants.Strings.urlUserUpdate)
    
    var userID: String!
    var facebookID: String?
    var type: String?
    var status: String?
    
    required init(userID: String)
    {
        self.userID = userID
    }
    
    override func makeRequest()
    {
        print("AC-UU: SENDING USER UPDATE FOR USER: \(userID)")
        
        if let facebookToken = FBSDKAccessToken.current()
        {
            var json = [String : Any]()
            json["app_version"] = Constants.Settings.appVersion
            json["identity_id"] = Constants.credentialsProvider.identityId
            json["login_provider"] = "graph.facebook.com"
            json["login_token"] = facebookToken.tokenString
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
            let jsonData = try? JSONSerialization.data(withJSONObject: json)
            
            var request = URLRequest(url: url!)
            request.httpMethod = "POST"
            request.timeoutInterval = Constants.Settings.requestTimeout
            request.httpBody = jsonData
            request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            let session = URLSession(configuration: .default)
            let dataTask = session.dataTask(with: request)
            { (responseData, response, error) in
                if let err = error
                {
                    self.recordError(stage: "URLRequest", error: err as? String)
                }
                else if let res = response as? HTTPURLResponse
                {
                    print("AC-UU - RESPONSE CODE: \(res.statusCode)")
                    if let data = responseData
                    {
                        do
                        {
                            let json = try JSONSerialization.jsonObject(with: data, options: [JSONSerialization.ReadingOptions.allowFragments])
                            print("AC-UU - JSON: \(json)")
                            // Convert the data to JSON with keys and AnyObject values
                            if let allData = json as? [String: AnyObject]
                            {
                                print("AC-UU - ALL DATA: \(allData)")
                                // EXTRACT THE RESPONSE STRING
                                if let response = allData["response"] as? String
                                {
                                    print("AC-UU - RESPONSE: \(response)")
                                    if response == "success"
                                    {
                                        // Update the user in the global data and in Core Data
                                        userLoop: for user in Constants.Data.allUsers
                                        {
                                            if user.userID == self.userID
                                            {
                                                // Replace the updated data
                                                if let facebookID = self.facebookID
                                                {
                                                    user.facebookID = facebookID
                                                }
                                                if let type = self.type
                                                {
                                                    user.type = type
                                                }
                                                if let status = self.status
                                                {
                                                    user.status = status
                                                }
                                                
                                                // Save to Core Data
                                                CoreDataFunctions().userSave(user: user, deleteUser: false)
                                                break userLoop
                                            }
                                        }
                                        
                                        // Check whether the user is the currentUser and update
                                        if Constants.Data.currentUser.userID == self.userID
                                        {
                                            // Replace the updated data
                                            if let facebookID = self.facebookID
                                            {
                                                Constants.Data.currentUser.facebookID = facebookID
                                            }
                                            if let type = self.type
                                            {
                                                Constants.Data.currentUser.type = type
                                            }
                                            if let status = self.status
                                            {
                                                Constants.Data.currentUser.status = status
                                            }
                                            
                                            // Save to Core Data
                                            CoreDataFunctions().currentUserSave(user: Constants.Data.currentUser, deleteUser: false)
                                        }
                                        
                                        // Notify the parent view that the AWS call completed successfully
                                        if let parentVC = self.awsRequestDelegate
                                        {
                                            print("AC-UU - CALLED PARENT")
                                            parentVC.processAwsReturn(self, success: true)
                                        }
                                    }
                                    else
                                    {
                                        self.recordError(stage: "response - fail", error: response)
                                    }
                                }
                                else
                                {
                                    self.recordError(stage: "response", error: nil)
                                }
                            }
                            else
                            {
                                self.recordError(stage: "JSON", error: nil)
                            }
                        }
                        catch let error as NSError
                        {
                            self.recordError(stage: "JSONSerlialization", error: error.description)
                        }
                    }
                    else
                    {
                        self.recordError(stage: "Response Data - else", error: nil)
                    }
                }
                else
                {
                    self.recordError(stage: "URLRequest - else", error: nil)
                }
            }
            dataTask.resume()
        }
    }
    
    func recordError(stage: String!, error: String?)
    {
        print("AC-UU: GET DATA ERROR AT STAGE: \(stage), ERROR: \(String(describing: error))")
//        CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: err.debugDescription)
        
        // Record the server request attempt
        Constants.Data.serverTries += 1
        
        // Notify the parent view that the AWS call completed with an error
        if let parentVC = self.awsRequestDelegate
        {
            parentVC.processAwsReturn(self, success: false)
        }
    }
}

class AWSUserQueryActive : AWSRequestObject, RequestDelegate
{
    let url = URL(string: Constants.Strings.urlUserQueryActive)
    
    override func makeRequest()
    {
        print("AC-UQA: REQUESTING ALL USER DATA")
        
        if let facebookToken = FBSDKAccessToken.current()
        {
            var json = [String : Any]()
            json["app_version"] = Constants.Settings.appVersion
            json["identity_id"] = Constants.credentialsProvider.identityId
            json["login_provider"] = "graph.facebook.com"
            json["login_token"] = facebookToken.tokenString
            let jsonData = try? JSONSerialization.data(withJSONObject: json)
            
            var request = URLRequest(url: url!)
            request.httpMethod = "POST"
            request.timeoutInterval = Constants.Settings.requestTimeout
            request.httpBody = jsonData
            request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            let session = URLSession(configuration: .default)
            let dataTask = session.dataTask(with: request)
            { (responseData, response, error) in
                if let err = error
                {
                    self.recordError(stage: "URLRequest", error: err as? String)
                }
                else if let res = response as? HTTPURLResponse
                {
                    print("AC-UQA - RESPONSE CODE: \(res.statusCode)")
                    if let data = responseData
                    {
                        do
                        {
                            let jsonData = try JSONSerialization.jsonObject(with: data, options: [JSONSerialization.ReadingOptions.allowFragments])
                            print("AC-UQA - JSON DATA: \(jsonData)")
                            // Convert the response to JSON with keys and AnyObject values
                            if let json = jsonData as? [String: AnyObject]
                            {
                                print("AC-UQA - JSON: \(json)")
                                // EXTRACT THE RESPONSE STRING
                                if let response = json["response"] as? String
                                {
                                    print("AC-UQA - RESPONSE: \(response)")
                                    if response == "success"
                                    {
                                        if let userData = json["users"] as? [AnyObject]
                                        {
                                            for userObject in userData
                                            {
                                                print("AC-UQA - CHECK 2")
                                                if let userJson = userObject as? [String: AnyObject]
                                                {
                                                    print("AC-UQA - CHECK 3: \(userJson)")
                                                    if let facebookID = userJson["facebook_id"] as? String
                                                    {
                                                        print("AC-UQA - CHECK 4: \(facebookID)")
                                                        let newUser = User()
                                                        newUser.userID = userJson["user_id"] as! String
                                                        newUser.facebookID = facebookID
                                                        newUser.type = userJson["type"] as! String
                                                        newUser.status = userJson["status"] as! String
                                                        newUser.datetime = Date(timeIntervalSince1970: userJson["timestamp"] as! Double)
                                                        
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
                                                    else
                                                    {
                                                        self.recordError(stage: "fbid", error: nil)
                                                    }
                                                }
                                                else
                                                {
                                                    self.recordError(stage: "json", error: nil)
                                                }
                                            }
                                            
                                            //                                // Replace the global user array with the new data
                                            //                                Constants.Data.allUsers = downloadedUsers
                                            //                                for dUser in downloadedUsers
                                            //                                {
                                            //                                    Constants.Data.allUsers.append(dUser)
                                            //                                }
                                            
                                            // Refresh the user connections
                                            UtilityFunctions().updateUserConnections()
                                            
                                            // Notify the parent view that the AWS call completed successfully
                                            if let parentVC = self.awsRequestDelegate
                                            {
                                                print("AC-UQA - CALLED PARENT")
                                                parentVC.processAwsReturn(self, success: true)
                                            }
                                        }
                                    }
                                    else
                                    {
                                        self.recordError(stage: "response - fail", error: response)
                                    }
                                }
                                else
                                {
                                    self.recordError(stage: "response", error: nil)
                                }
                            }
                            else
                            {
                                self.recordError(stage: "json", error: nil)
                            }
                        }
                        catch let error as NSError
                        {
                            self.recordError(stage: "JSONSerlialization", error: error.description)
                        }
                    }
                    else
                    {
                        self.recordError(stage: "Response Data - else", error: nil)
                    }
                }
                else
                {
                    self.recordError(stage: "URLRequest - else", error: nil)
                }
            }
            dataTask.resume()
        }
    }
    
    func recordError(stage: String!, error: String?)
    {
        print("AC-UQA: GET DATA ERROR AT STAGE: \(stage), ERROR: \(String(describing: error))")
//        CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: err.debugDescription)
        
        // Record the server request attempt
        Constants.Data.serverTries += 1
        
        // Notify the parent view that the AWS call completed with an error
        if let parentVC = self.awsRequestDelegate
        {
            parentVC.processAwsReturn(self, success: false)
        }
    }
    
    func processRequestReturn(_ requestCalled: RequestObject, success: Bool)
    {
        // Process the return data based on the method used
        switch requestCalled
        {
        case _ as FBGetUserData:
            if success
            {
                print("AC-UQA: FBGetUserData SUCCESS")
            }
            else
            {
                print("AC-UQA: FBGetUserData FAILURE")
            }
        default:
            print("AC-UQA: processRequestReturn DEFAULT")
        }
    }
}

// MARK: USER CONNECTION

class AWSUserConnectionQuery : AWSRequestObject
{
    let url = URL(string: Constants.Strings.urlUserConnectionQuery)
    
    var userID: String!
    
    required init(userID: String)
    {
        self.userID = userID
    }
    
    override func makeRequest()
    {
        print("AC-UCQ: GET USER CONNECTIONS FOR USER: \(userID)")
        
        if let facebookToken = FBSDKAccessToken.current()
        {
            var json = [String : Any]()
            json["app_version"] = Constants.Settings.appVersion
            json["identity_id"] = Constants.credentialsProvider.identityId
            json["login_provider"] = "graph.facebook.com"
            json["login_token"] = facebookToken.tokenString
            json["user_id"] = self.userID
            let jsonData = try? JSONSerialization.data(withJSONObject: json)
            
            var request = URLRequest(url: url!)
            request.httpMethod = "POST"
            request.timeoutInterval = Constants.Settings.requestTimeout
            request.httpBody = jsonData
            request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            let session = URLSession(configuration: .default)
            let dataTask = session.dataTask(with: request)
            { (responseData, response, error) in
                if let err = error
                {
                    self.recordError(stage: "URLRequest", error: err.localizedDescription)
                }
                else if let res = response as? HTTPURLResponse
                {
                    print("AC-UCQ - RESPONSE CODE: \(res.statusCode)")
                    if let data = responseData
                    {
                        do
                        {
                            let jsonData = try JSONSerialization.jsonObject(with: data, options: [JSONSerialization.ReadingOptions.allowFragments])
                            print("AC-UCQ - JSON DATA: \(jsonData)")
                            // Convert the data to JSON with keys and AnyObject values
                            if let json = jsonData as? [String: AnyObject]
                            {
                                print("AC-UCQ - JSON: \(json)")
                                // EXTRACT THE RESPONSE STRING
                                if let response = json["response"] as? String
                                {
                                    print("AC-UCQ - RESPONSE: \(response)")
                                    if response == "success"
                                    {
                                        if let connectionData = json["user_connections"] as? [AnyObject]
                                        {
                                            // Currently, the only concern is blocked users, so add all blocked userIDs to the global list and update the user status' in the global user list
                                            // Create a local array to hold all downloaded users
                                            var blockedUserIDs = [String]()
                                            
                                            for connectionObject in connectionData
                                            {
                                                print("AC-UCQ - CHECK 2")
                                                if let connectionJson = connectionObject as? [String: AnyObject]
                                                {
                                                    if let connection = connectionJson["connection"] as? String
                                                    {
                                                        if connection == "block"
                                                        {
                                                            blockedUserIDs.append(connectionJson["target_user_id"] as! String)
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
                                                print("AC-UCQ - CALLED PARENT")
                                                parentVC.processAwsReturn(self, success: true)
                                            }
                                        }
                                        else
                                        {
                                            self.recordError(stage: "JSON ARRAY", error: nil)
                                        }
                                    }
                                    else
                                    {
                                        self.recordError(stage: "response - fail", error: response)
                                    }
                                }
                                else
                                {
                                    self.recordError(stage: "response", error: nil)
                                }
                            }
                            else
                            {
                                self.recordError(stage: "JSON", error: nil)
                            }
                        }
                        catch let error as NSError
                        {
                            self.recordError(stage: "JSONSerlialization", error: error.description)
                        }
                    }
                    else
                    {
                        self.recordError(stage: "Response Data - else", error: nil)
                    }
                }
                else
                {
                    self.recordError(stage: "URLRequest - else", error: nil)
                }
            }
            dataTask.resume()
        }
    }
    
    func recordError(stage: String!, error: String?)
    {
        print("AC-UCQ: GET DATA ERROR AT STAGE: \(stage), ERROR: \(String(describing: error))")
//        CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: err.debugDescription)
        
        // Record the server request attempt
        Constants.Data.serverTries += 1
        
        // Notify the parent view that the AWS call completed with an error
        if let parentVC = self.awsRequestDelegate
        {
            parentVC.processAwsReturn(self, success: false)
        }
    }
}

class AWSUserConnectionPut : AWSRequestObject
{
    let url = URL(string: Constants.Strings.urlUserConnectionPut)
    
    var targetUserID: String!
    var connection: String!
    
    required init(targetUserID: String!, connection: String!)
    {
        self.targetUserID = targetUserID
        self.connection = connection
    }
    
    override func makeRequest()
    {
        print("AC-UCP: ADDING CONNECTION FOR USER ID: \(targetUserID)")
        
        if let facebookToken = FBSDKAccessToken.current()
        {
            var json = [String: Any]()
            json["app_version"] = Constants.Settings.appVersion
            json["identity_id"] = Constants.credentialsProvider.identityId
            json["login_provider"] = "graph.facebook.com"
            json["login_token"] = facebookToken.tokenString
            json["user_id"] = Constants.Data.currentUser.userID
            json["target_user_id"] = targetUserID
            json["connection"] = connection
            let jsonData = try? JSONSerialization.data(withJSONObject: json)
            
            var request = URLRequest(url: url!)
            request.httpMethod = "POST"
            request.timeoutInterval = Constants.Settings.requestTimeout
            request.httpBody = jsonData
            request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            let session = URLSession(configuration: .default)
            let dataTask = session.dataTask(with: request)
            { (responseData, response, error) in
                if let err = error
                {
                    self.recordError(stage: "URLRequest", error: err as? String)
                }
                else if let res = response as? HTTPURLResponse
                {
                    print("AC-UCP - RESPONSE CODE: \(res.statusCode)")
                    if let data = responseData
                    {
                        do
                        {
                            let jsonData = try JSONSerialization.jsonObject(with: data, options: [JSONSerialization.ReadingOptions.allowFragments])
                            print("AC-UCP - JSON DATA: \(json)")
                            // Convert the data to JSON with keys and AnyObject values
                            if let json = jsonData as? [String: AnyObject]
                            {
                                print("AC-UCP - JSON: \(json)")
                                // EXTRACT THE RESPONSE STRING
                                if let response = json["response"] as? String
                                {
                                    print("AC-UCP - RESPONSE: \(response)")
                                    if response == "success"
                                    {
                                        // Notify the parent view that the AWS call completed successfully
                                        if let parentVC = self.awsRequestDelegate
                                        {
                                            print("AC-UCP - CALLED PARENT")
                                            parentVC.processAwsReturn(self, success: true)
                                        }
                                    }
                                    else
                                    {
                                        self.recordError(stage: "response - fail", error: response)
                                    }
                                }
                                else
                                {
                                    self.recordError(stage: "response", error: nil)
                                }
                            }
                            else
                            {
                                self.recordError(stage: "JSON", error: nil)
                            }
                        }
                        catch let error as NSError
                        {
                            self.recordError(stage: "JSONSerlialization", error: error.description)
                        }
                    }
                    else
                    {
                        self.recordError(stage: "Response Data - else", error: nil)
                    }
                }
                else
                {
                    self.recordError(stage: "URLRequest - else", error: nil)
                }
            }
            dataTask.resume()
        }
        else
        {
            self.recordError(stage: "FBToken", error: nil)
        }
    }
    
    func recordError(stage: String!, error: String?)
    {
        print("AC-UCP: GET DATA ERROR AT STAGE: \(stage), ERROR: \(String(describing: error))")
//        CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: err.debugDescription)
        
        // Record the server request attempt
        Constants.Data.serverTries += 1
        
        // Notify the parent view that the AWS call completed with an error
        if let parentVC = self.awsRequestDelegate
        {
            parentVC.processAwsReturn(self, success: false)
        }
    }
}


// MARK: SKILLS

class AWSSkillQuery : AWSRequestObject
{
    let url = URL(string: Constants.Strings.urlSkillQuery)
    
    var userID: String!
    
    required init(userID: String!)
    {
        self.userID = userID
    }
    
    override func makeRequest()
    {
        print("AC-SKQ: RECALL SKILLS FOR USER: \(self.userID)")
        
        if let facebookToken = FBSDKAccessToken.current()
        {
            var json = [String: Any]()
            json["app_version"] = Constants.Settings.appVersion
            json["identity_id"] = Constants.credentialsProvider.identityId
            json["login_provider"] = "graph.facebook.com"
            json["login_token"] = facebookToken.tokenString
            json["user_id"] = userID
            let jsonData = try? JSONSerialization.data(withJSONObject: json)
            
            var request = URLRequest(url: url!)
            request.httpMethod = "POST"
            request.timeoutInterval = Constants.Settings.requestTimeout
            request.httpBody = jsonData
            request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            let session = URLSession(configuration: .default)
            let dataTask = session.dataTask(with: request)
            { (responseData, response, error) in
                if let err = error
                {
                    self.recordError(stage: "URLRequest", error: err as? String)
                }
                else if let res = response as? HTTPURLResponse
                {
                    print("AC-SKQ - RESPONSE CODE: \(res.statusCode)")
                    if let data = responseData
                    {
                        do
                        {
                            let jsonData = try JSONSerialization.jsonObject(with: data, options: [JSONSerialization.ReadingOptions.allowFragments])
                            print("AC-SKQ - JSON DATA: \(json)")
                            // Convert the data to JSON with keys and AnyObject values
                            if let json = jsonData as? [String: AnyObject]
                            {
                                print("AC-SKQ - JSON: \(json)")
                                // EXTRACT THE RESPONSE STRING
                                if let response = json["response"] as? String
                                {
                                    print("AC-SKQ - RESPONSE: \(response)")
                                    if response == "success"
                                    {
                                        if let skillJson = json["skills"] as? [String: AnyObject]
                                        {
                                            // Unwrap the general list of skills that should exist - use these to set default values since the user
                                            // might not have a saved history of all of these skills - default to 'no experience' (0)
                                            if let skillSettings = skillJson["skill_settings"] as? [String: AnyObject]
                                            {
                                                // Unwrap the settings' sibling json block - this will hold the user's saved skill settings
                                                if let skillLevels = skillJson["skill_levels"] as? [AnyObject]
                                                {
                                                    // FIRST, loop through all saved skill settings and add the user's saved skill
                                                    // This skill list only includes the skill type and this user's level - the settings list will have the 'order' property
                                                    var skillObjects = [Skill]()
                                                    for skillJson in skillLevels
                                                    {
                                                        // Each skill object is in json format
                                                        if let skill = skillJson as? [String: AnyObject]
                                                        {
                                                            let skillID = skill["skill_id"] as! String
                                                            let skillType = skill["skill"] as! String
                                                            let skillLevel = skill["level"] as! Int
                                                            
                                                            // Default the order to 0 if it does not exist in the settings list
                                                            var order: Int = 0
                                                            orderLoop: for orderEnt in skillSettings
                                                            {
                                                                // Once the skill type setting is found, convert the value to Int (the order value)
                                                                if orderEnt.key == skillType
                                                                {
                                                                    if let orderValue = orderEnt.value as? Int
                                                                    {
                                                                        order = orderValue
                                                                        break orderLoop
                                                                    }
                                                                }
                                                            }
                                                            
                                                            // Create the Skill object
                                                            let addSkill = Skill(skillID: skillID, skill: skillType, userID: Constants.Data.currentUser.userID)
                                                            addSkill.order = order
                                                            addSkill.level = Constants().experience(skillLevel)
                                                            skillObjects.append(addSkill)
                                                            
                                                            // Save the updated / new skill to Core Data
                                                            CoreDataFunctions().skillSave(skill: addSkill, deleteSkill: false)
                                                        }
                                                    }
                                                    
                                                    // Now check the reverse - loop through the settings and ensure that all passed settings are saved
                                                    // If not, save the missing setting with the default setting of 'no experience' (0)
                                                    for skillSetting in skillSettings
                                                    {
                                                        var skillExists = false
                                                        userSkillLoop: for userSkill in skillObjects
                                                        {
                                                            if userSkill.skill == skillSetting.key
                                                            {
                                                                skillExists = true
                                                                break userSkillLoop
                                                            }
                                                        }
                                                        if !skillExists
                                                        {
                                                            // Cast the skill Setting value to Int - this is the skill order value
                                                            // Then create a skill Object using the default level value (0)
                                                            // The skillID is created using the userID and the skill type concatenated with a "-"
                                                            let skillType = skillSetting.key
                                                            let skillID = Constants.Data.currentUser.userID + "-" + skillType
                                                            let addSkill = Skill(skillID: skillID, skill: skillType, userID: Constants.Data.currentUser.userID)
                                                            addSkill.level = Constants().experience(0)
                                                            if let skillOrder = skillSetting.value as? Int
                                                            {
                                                                addSkill.order = skillOrder
                                                            }
                                                            skillObjects.append(addSkill)
                                                            
                                                            // Save the updated / new skill to Core Data
                                                            CoreDataFunctions().skillSave(skill: addSkill, deleteSkill: false)
                                                        }
                                                    }
                                                    // Now replace the global skill list with the updated version
                                                    Constants.Data.skills = skillObjects
                                                }
                                            }
                                            
                                            // Notify the parent view that the AWS call completed successfully
                                            if let parentVC = self.awsRequestDelegate
                                            {
                                                print("AC-SKQ - CALLED PARENT")
                                                parentVC.processAwsReturn(self, success: true)
                                            }
                                        }
                                    }
                                    else
                                    {
                                        self.recordError(stage: "response - fail", error: response)
                                    }
                                }
                                else
                                {
                                    self.recordError(stage: "response", error: nil)
                                }
                            }
                            else
                            {
                                self.recordError(stage: "JSON", error: nil)
                            }
                        }
                        catch let error as NSError
                        {
                            self.recordError(stage: "JSONSerlialization", error: error.description)
                        }
                    }
                    else
                    {
                        self.recordError(stage: "Response Data - else", error: nil)
                    }
                }
                else
                {
                    self.recordError(stage: "URLRequest - else", error: nil)
                }
            }
            dataTask.resume()
        }
    }
    
    func recordError(stage: String!, error: String?)
    {
        print("AC-SKQ: GET DATA ERROR AT STAGE: \(stage), ERROR: \(String(describing: error))")
//        CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: err.debugDescription)
        
        // Record the server request attempt
        Constants.Data.serverTries += 1
        
        // Notify the parent view that the AWS call completed with an error
        if let parentVC = self.awsRequestDelegate
        {
            parentVC.processAwsReturn(self, success: false)
        }
    }
}

class AWSSkillPut : AWSRequestObject
{
    let url = URL(string: Constants.Strings.urlSkillPut)
    
    var skills: [Skill]!
    
    required init(skills: [Skill]!)
    {
        self.skills = skills
    }
    
    override func makeRequest()
    {
        print("AC-SKP: PUT SKILLS")
        
        if let facebookToken = FBSDKAccessToken.current()
        {
            // Create some JSON to send the Skill data
            // This method is only used to send the current user's skills to the db
            var skillDict = [Any]()
            for skill in skills
            {
                var skillObj = [String: Any]()
                skillObj["skill"] = skill.skill
                skillObj["user_id"] = skill.userID
                skillObj["level"] = String(describing: skill.level.rawValue)
                skillDict.append(skillObj)
            }
            
            var json = [String: Any]()
            json["app_version"] = Constants.Settings.appVersion
            json["identity_id"] = Constants.credentialsProvider.identityId
            json["login_provider"] = "graph.facebook.com"
            json["login_token"] = facebookToken.tokenString
            json["user_id"] = Constants.Data.currentUser.userID
            json["skills"] = skillDict
            let jsonData = try? JSONSerialization.data(withJSONObject: json)
            
            var request = URLRequest(url: url!)
            request.httpMethod = "POST"
            request.timeoutInterval = Constants.Settings.requestTimeout
            request.httpBody = jsonData
            request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            let session = URLSession(configuration: .default)
            let dataTask = session.dataTask(with: request)
            { (responseData, response, error) in
                if let err = error
                {
                    self.recordError(stage: "URLRequest", error: err as? String)
                }
                else if let res = response as? HTTPURLResponse
                {
                    print("AC-SKP - RESPONSE CODE: \(res.statusCode)")
                    if let data = responseData
                    {
                        do
                        {
                            let jsonData = try JSONSerialization.jsonObject(with: data, options: [JSONSerialization.ReadingOptions.allowFragments])
                            print("AC-SKP - JSON DATA: \(json)")
                            // Convert the data to JSON with keys and AnyObject values
                            if let json = jsonData as? [String: AnyObject]
                            {
                                print("AC-SKP - JSON: \(json)")
                                // EXTRACT THE RESPONSE STRING
                                if let response = json["response"] as? String
                                {
                                    print("AC-SKP - RESPONSE: \(response)")
                                    if response == "success"
                                    {
                                        print("AC-PSK - UPLOAD SUCCESS")
                                        // Notify the parent view that the AWS call completed successfully
                                        if let parentVC = self.awsRequestDelegate
                                        {
                                            parentVC.processAwsReturn(self, success: true)
                                        }
                                    }
                                    else
                                    {
                                        self.recordError(stage: "response - fail", error: response)
                                    }
                                }
                                else
                                {
                                    self.recordError(stage: "response", error: nil)
                                }
                            }
                            else
                            {
                                self.recordError(stage: "JSON", error: nil)
                            }
                        }
                        catch let error as NSError
                        {
                            self.recordError(stage: "JSONSerlialization", error: error.description)
                        }
                    }
                    else
                    {
                        self.recordError(stage: "Response Data - else", error: nil)
                    }
                }
                else
                {
                    self.recordError(stage: "URLRequest - else", error: nil)
                }
            }
            dataTask.resume()
        }
    }
    
    func recordError(stage: String!, error: String?)
    {
        print("AC-SKP: GET DATA ERROR AT STAGE: \(stage), ERROR: \(String(describing: error))")
//        CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: err.debugDescription)
        
        // Record the server request attempt
        Constants.Data.serverTries += 1
        
        // Notify the parent view that the AWS call completed with an error
        if let parentVC = self.awsRequestDelegate
        {
            parentVC.processAwsReturn(self, success: false)
        }
    }
}


// MARK: STRUCTURE

class AWSStructureQuery : AWSRequestObject
{
    let url = URL(string: Constants.Strings.urlStructureQuery)
    
    override func makeRequest()
    {
        print("AC-STRQ: STRUCTURE QUERY")
        
        if let facebookToken = FBSDKAccessToken.current()
        {
            // Create some JSON to send the Structure data
            var json = [String: Any]()
            json["app_version"] = Constants.Settings.appVersion
            json["identity_id"] = Constants.credentialsProvider.identityId
            json["login_provider"] = "graph.facebook.com"
            json["login_token"] = facebookToken.tokenString
            json["user_id"] = Constants.Data.currentUser.userID
            let jsonData = try? JSONSerialization.data(withJSONObject: json)
            
            var request = URLRequest(url: url!)
            request.httpMethod = "POST"
            request.timeoutInterval = Constants.Settings.requestTimeout
            request.httpBody = jsonData
            request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            let session = URLSession(configuration: .default)
            let dataTask = session.dataTask(with: request)
            { (responseData, response, error) in
                if let err = error
                {
                    self.recordError(stage: "URLRequest", error: err as? String)
                }
                else if let res = response as? HTTPURLResponse
                {
                    print("AC-STRQ - RESPONSE CODE: \(res.statusCode)")
                    if let data = responseData
                    {
                        do
                        {
                            let jsonData = try JSONSerialization.jsonObject(with: data, options: [JSONSerialization.ReadingOptions.allowFragments])
                            print("AC-STRQ - JSON DATA: \(json)")
                            // Convert the data to JSON with keys and AnyObject values
                            if let json = jsonData as? [String: AnyObject]
                            {
                                print("AC-STRQ - JSON: \(json)")
                                // EXTRACT THE RESPONSE STRING
                                if let response = json["response"] as? String
                                {
                                    print("AC-STRQ - RESPONSE: \(response)")
                                    if response == "success"
                                    {
                                        print("AC-STRQ - QUERY SUCCESS")
                                        
                                        var structureList = [Structure]()
                                        
                                        
                                        // Notify the parent view that the AWS call completed successfully
                                        if let parentVC = self.awsRequestDelegate
                                        {
                                            parentVC.processAwsReturn(self, success: true)
                                        }
                                    }
                                    else
                                    {
                                        self.recordError(stage: "response - fail", error: response)
                                    }
                                }
                                else
                                {
                                    self.recordError(stage: "response", error: nil)
                                }
                            }
                            else
                            {
                                self.recordError(stage: "JSON", error: nil)
                            }
                        }
                        catch let error as NSError
                        {
                            self.recordError(stage: "JSONSerlialization", error: error.description)
                        }
                    }
                    else
                    {
                        self.recordError(stage: "Response Data - else", error: nil)
                    }
                }
                else
                {
                    self.recordError(stage: "URLRequest - else", error: nil)
                }
            }
            dataTask.resume()
        }
    }
    
    func recordError(stage: String!, error: String?)
    {
        print("AC-STRQ: GET DATA ERROR AT STAGE: \(stage), ERROR: \(String(describing: error))")
//        CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: err.debugDescription)
        
        // Record the server request attempt
        Constants.Data.serverTries += 1
        
        // Notify the parent view that the AWS call completed with an error
        if let parentVC = self.awsRequestDelegate
        {
            parentVC.processAwsReturn(self, success: false)
        }
    }
}

class AWSStructurePut : AWSRequestObject
{
    let url = URL(string: Constants.Strings.urlStructurePut)
    
    var structure: Structure!
    
    required init(structure: Structure!)
    {
        self.structure = structure
    }
    
    override func makeRequest()
    {
        print("AC-STRP: STRUCTURE PUT")
        
        if let facebookToken = FBSDKAccessToken.current()
        {
            // Create some JSON to send the Structure data
            var json = [String: Any]()
            json["app_version"] = Constants.Settings.appVersion
            json["identity_id"] = Constants.credentialsProvider.identityId
            json["login_provider"] = "graph.facebook.com"
            json["login_token"] = facebookToken.tokenString
            json["structure_id"] = structure.structureID
            json["user_id"] = Constants.Data.currentUser.userID
            json["lat"] = String(structure.lat)
            json["lng"] = String(structure.lng)
            json["datetime"] = String(structure.datetime.timeIntervalSince1970)
            json["type"] = String(structure.type.rawValue)
            json["stage"] = String(structure.stage.rawValue)
            let jsonData = try? JSONSerialization.data(withJSONObject: json)
            
            var request = URLRequest(url: url!)
            request.httpMethod = "POST"
            request.timeoutInterval = Constants.Settings.requestTimeout
            request.httpBody = jsonData
            request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            let session = URLSession(configuration: .default)
            let dataTask = session.dataTask(with: request)
            { (responseData, response, error) in
                if let err = error
                {
                    self.recordError(stage: "URLRequest", error: err as? String)
                }
                else if let res = response as? HTTPURLResponse
                {
                    print("AC-STRP - RESPONSE CODE: \(res.statusCode)")
                    if let data = responseData
                    {
                        do
                        {
                            let jsonData = try JSONSerialization.jsonObject(with: data, options: [JSONSerialization.ReadingOptions.allowFragments])
                            print("AC-STRP - JSON DATA: \(json)")
                            // Convert the data to JSON with keys and AnyObject values
                            if let json = jsonData as? [String: AnyObject]
                            {
                                print("AC-STRP - JSON: \(json)")
                                // EXTRACT THE RESPONSE STRING
                                if let response = json["response"] as? String
                                {
                                    print("AC-STRP - RESPONSE: \(response)")
                                    if response == "success"
                                    {
                                        print("AC-STRP - UPLOAD SUCCESS")
                                        // Notify the parent view that the AWS call completed successfully
                                        if let parentVC = self.awsRequestDelegate
                                        {
                                            parentVC.processAwsReturn(self, success: true)
                                        }
                                    }
                                    else
                                    {
                                        self.recordError(stage: "response - fail", error: response)
                                    }
                                }
                                else
                                {
                                    self.recordError(stage: "response", error: nil)
                                }
                            }
                            else
                            {
                                self.recordError(stage: "JSON", error: nil)
                            }
                        }
                        catch let error as NSError
                        {
                            self.recordError(stage: "JSONSerlialization", error: error.description)
                        }
                    }
                    else
                    {
                        self.recordError(stage: "Response Data - else", error: nil)
                    }
                }
                else
                {
                    self.recordError(stage: "URLRequest - else", error: nil)
                }
            }
            dataTask.resume()
        }
    }
    
    func recordError(stage: String!, error: String?)
    {
        print("AC-STRP: GET DATA ERROR AT STAGE: \(stage), ERROR: \(String(describing: error))")
//        CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: err.debugDescription)
        
        // Record the server request attempt
        Constants.Data.serverTries += 1
        
        // Notify the parent view that the AWS call completed with an error
        if let parentVC = self.awsRequestDelegate
        {
            parentVC.processAwsReturn(self, success: false)
        }
    }
}


// MARK: REPAIR

class AWSRepairPut : AWSRequestObject
{
    let url = URL(string: Constants.Strings.urlRepairPut)
    
    var repairs: [Repair]!
    
    required init(repairs: [Repair]!)
    {
        self.repairs = repairs
    }
    
    override func makeRequest()
    {
        print("AC-RP: PUT REPAIR")
        
        if let facebookToken = FBSDKAccessToken.current()
        {
            // Create some JSON to send the Skill data
            // This method is only used to send the structure repairs to the db
            var repairDict = [Any]()
            for repair in repairs
            {
                var repairObj = [String: Any]()
                repairObj["structure_id"] = repair.structureID
                repairObj["repair"] = repair.repair
                repairObj["stage"] = String(describing: repair.stage.rawValue)
                repairDict.append(repairObj)
            }
            
            var json = [String: Any]()
            json["app_version"] = Constants.Settings.appVersion
            json["identity_id"] = Constants.credentialsProvider.identityId
            json["login_provider"] = "graph.facebook.com"
            json["login_token"] = facebookToken.tokenString
            json["user_id"] = Constants.Data.currentUser.userID
            json["repairs"] = repairDict
            let jsonData = try? JSONSerialization.data(withJSONObject: json)
            
            var request = URLRequest(url: url!)
            request.httpMethod = "POST"
            request.timeoutInterval = Constants.Settings.requestTimeout
            request.httpBody = jsonData
            request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            let session = URLSession(configuration: .default)
            let dataTask = session.dataTask(with: request)
            { (responseData, response, error) in
                if let err = error
                {
                    self.recordError(stage: "URLRequest", error: err as? String)
                }
                else if let res = response as? HTTPURLResponse
                {
                    print("AC-RP - RESPONSE CODE: \(res.statusCode)")
                    if let data = responseData
                    {
                        do
                        {
                            let jsonData = try JSONSerialization.jsonObject(with: data, options: [JSONSerialization.ReadingOptions.allowFragments])
                            print("AC-RP - JSON DATA: \(json)")
                            // Convert the data to JSON with keys and AnyObject values
                            if let json = jsonData as? [String: AnyObject]
                            {
                                print("AC-RP - JSON: \(json)")
                                // EXTRACT THE RESPONSE STRING
                                if let response = json["response"] as? String
                                {
                                    print("AC-RP - RESPONSE: \(response)")
                                    if response == "success"
                                    {
                                        print("AC-RP - UPLOAD SUCCESS")
                                        // Notify the parent view that the AWS call completed successfully
                                        if let parentVC = self.awsRequestDelegate
                                        {
                                            parentVC.processAwsReturn(self, success: true)
                                        }
                                    }
                                    else
                                    {
                                        self.recordError(stage: "response - fail", error: response)
                                    }
                                }
                                else
                                {
                                    self.recordError(stage: "response", error: nil)
                                }
                            }
                            else
                            {
                                self.recordError(stage: "JSON", error: nil)
                            }
                        }
                        catch let error as NSError
                        {
                            self.recordError(stage: "JSONSerlialization", error: error.description)
                        }
                    }
                    else
                    {
                        self.recordError(stage: "Response Data - else", error: nil)
                    }
                }
                else
                {
                    self.recordError(stage: "URLRequest - else", error: nil)
                }
            }
            dataTask.resume()
        }
    }
    
    func recordError(stage: String!, error: String?)
    {
        print("AC-RP: GET DATA ERROR AT STAGE: \(stage), ERROR: \(String(describing: error))")
//        CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: err.debugDescription)
        
        // Record the server request attempt
        Constants.Data.serverTries += 1
        
        // Notify the parent view that the AWS call completed with an error
        if let parentVC = self.awsRequestDelegate
        {
            parentVC.processAwsReturn(self, success: false)
        }
    }
}


// MARK: SPOT

class AWSSpotQueryActive : AWSRequestObject
{
    let url = URL(string: Constants.Strings.urlSpotQueryActive)
    
    var userLocation = [String : Double]()
    
    required init(userLocation: [String : Double]!)
    {
        if let userLocation = userLocation
        {
            self.userLocation = userLocation
        }
    }
    
    override func makeRequest()
    {
        print("AC-SQ: REQUESTING SPOT AND SPOT REQUEST DATA, USER LOC: \(userLocation)")
        
        if let facebookToken = FBSDKAccessToken.current()
        {
            var json = [String: Any]()
            json["app_version"] = Constants.Settings.appVersion
            json["identity_id"] = Constants.credentialsProvider.identityId
            json["login_provider"] = "graph.facebook.com"
            json["login_token"] = facebookToken.tokenString
            json["user_location"] = userLocation
            let jsonData = try? JSONSerialization.data(withJSONObject: json)
            
            var request = URLRequest(url: url!)
            request.httpMethod = "POST"
            request.timeoutInterval = Constants.Settings.requestTimeout
            request.httpBody = jsonData
            request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            let session = URLSession(configuration: .default)
            let dataTask = session.dataTask(with: request)
            { (responseData, response, error) in
                if let err = error
                {
                    self.recordError(stage: "URLRequest", error: err as? String)
                }
                else if let res = response as? HTTPURLResponse
                {
                    print("AC-SQ - RESPONSE CODE: \(res.statusCode)")
                    if let data = responseData
                    {
                        do
                        {
                            let jsonData = try JSONSerialization.jsonObject(with: data, options: [JSONSerialization.ReadingOptions.allowFragments])
                            print("AC-SQ - JSON DATA: \(json)")
                            // Convert the data to JSON with keys and AnyObject values
                            if let json = jsonData as? [String: AnyObject]
                            {
                                print("AC-SQ - JSON: \(json)")
                                // EXTRACT THE RESPONSE STRING
                                if let response = json["response"] as? String
                                {
                                    print("AC-SQ - RESPONSE: \(response)")
                                    if response == "success"
                                    {
                                        // The data request was successful - reset the data arrays
                                        Constants.Data.allSpot = [Spot]()
                                        Constants.Data.allSpotRequest = [SpotRequest]()
                                        
                                        // Convert the response to an array of AnyObjects
                                        // EXTRACT SPOT DATA
                                        if let allSpotRaw = json["spot"] as? [Any]
                                        {
                                            // Loop through each AnyObject (Spot) in the array
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
                                                                            print("AC-SQ - ADDED SPOT CONTENT DATA: \(contentID)")
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
                                                            print("AC-SQ - ADDED SPOT DATA: \(addSpot.spotID)")
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                        // Convert the response to an array of AnyObjects
                                        // EXTRACT SPOT REQUEST DATA
                                        if let allSpotRequestRaw = json["spot_request"] as? [Any]
                                        {
                                            // Loop through each AnyObject (Spot) in the array
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
//                                                        print("AC-SQ - ADDED SPOT RESPONSE DATA: \(String(describing: addSpotRequest.requestID))")
                                                    }
                                                }
                                            }
                                        }
                                        
                                        //                    // Refresh the spots based on user connection
                                        //                    UtilityFunctions().removeBlockedUsersFromGlobalSpotArray()
                                        
                                        // Notify the parent view that the AWS call completed successfully
                                        if let parentVC = self.awsRequestDelegate
                                        {
                                            print("AC-SQ - CALLED PARENT")
                                            parentVC.processAwsReturn(self, success: true)
                                        }
                                    }
                                    else
                                    {
                                        self.recordError(stage: "response - fail", error: response)
                                    }
                                }
                                else
                                {
                                    self.recordError(stage: "response", error: nil)
                                }
                            }
                            else
                            {
                                self.recordError(stage: "JSON", error: nil)
                            }
                        }
                        catch let error as NSError
                        {
                            self.recordError(stage: "JSONSerlialization", error: error.description)
                        }
                    }
                    else
                    {
                        self.recordError(stage: "Response Data - else", error: nil)
                    }
                }
                else
                {
                    self.recordError(stage: "URLRequest - else", error: nil)
                }
            }
            dataTask.resume()
        }
        else
        {
            self.recordError(stage: "FBToken", error: nil)
        }
    }
    
    func recordError(stage: String!, error: String?)
    {
        print("AC-SQ: GET DATA ERROR AT STAGE: \(stage), ERROR: \(String(describing: error))")
//        CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: err.debugDescription)
        
        // Record the server request attempt
        Constants.Data.serverTries += 1
        
        // Notify the parent view that the AWS call completed with an error
        if let parentVC = self.awsRequestDelegate
        {
            parentVC.processAwsReturn(self, success: false)
        }
    }
}

class AWSSpotPut : AWSRequestObject
{
    let url = URL(string: Constants.Strings.urlSpotPut)
    
    var spot: Spot!
    
    required init(spot: Spot!)
    {
        self.spot = spot
    }
    
    override func makeRequest()
    {
        print("AC-SP: PUT SPOT: \(spot)")
        
        if let facebookToken = FBSDKAccessToken.current()
        {
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
            json["identity_id"] = Constants.credentialsProvider.identityId
            json["login_provider"] = "graph.facebook.com"
            json["login_token"] = facebookToken.tokenString
            json["spot_id"]      = spot.spotID
            json["user_id"]      = spot.userID
            json["timestamp"]    = String(spot.datetime.timeIntervalSince1970)
            json["lat"]          = String(spot.lat)
            json["lng"]          = String(spot.lng)
            json["spot_content"] = jsonSpotContent
            let jsonData = try? JSONSerialization.data(withJSONObject: json)
            
            var request = URLRequest(url: url!)
            request.httpMethod = "POST"
            request.timeoutInterval = Constants.Settings.requestTimeout
            request.httpBody = jsonData
            request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            let session = URLSession(configuration: .default)
            let dataTask = session.dataTask(with: request)
            { (responseData, response, error) in
                if let err = error
                {
                    self.recordError(stage: "URLRequest", error: err as? String)
                }
                else if let res = response as? HTTPURLResponse
                {
                    print("AC-SP - RESPONSE CODE: \(res.statusCode)")
                    if let data = responseData
                    {
                        do
                        {
                            let jsonData = try JSONSerialization.jsonObject(with: data, options: [JSONSerialization.ReadingOptions.allowFragments])
                            print("AC-SP - JSON DATA: \(json)")
                            // Convert the data to JSON with keys and AnyObject values
                            if let json = jsonData as? [String: AnyObject]
                            {
                                print("AC-SP - JSON: \(json)")
                                // EXTRACT THE RESPONSE STRING
                                if let response = json["response"] as? String
                                {
                                    print("AC-SP - RESPONSE: \(response)")
                                    if response == "success"
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
                                            print("AC-SP - CALLED PARENT")
                                            parentVC.processAwsReturn(self, success: true)
                                        }
                                    }
                                    else
                                    {
                                        self.recordError(stage: "response - fail", error: response)
                                    }
                                }
                                else
                                {
                                    self.recordError(stage: "response", error: nil)
                                }
                            }
                            else
                            {
                                self.recordError(stage: "JSON", error: nil)
                            }
                        }
                        catch let error as NSError
                        {
                            self.recordError(stage: "JSONSerlialization", error: error.description)
                        }
                    }
                    else
                    {
                        self.recordError(stage: "Response Data - else", error: nil)
                    }
                }
                else
                {
                    self.recordError(stage: "URLRequest - else", error: nil)
                }
            }
            dataTask.resume()
        }
        else
        {
            self.recordError(stage: "FBToken", error: nil)
        }
    }
    
    func recordError(stage: String!, error: String?)
    {
        print("AC-SP: GET DATA ERROR AT STAGE: \(stage), ERROR: \(String(describing: error))")
//        CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: err.debugDescription)
        
        // Record the server request attempt
        Constants.Data.serverTries += 1
        
        // Notify the parent view that the AWS call completed with an error
        if let parentVC = self.awsRequestDelegate
        {
            parentVC.processAwsReturn(self, success: false)
        }
    }
}

class AWSSpotContentStatusUpdate : AWSRequestObject
{
    let url = URL(string: Constants.Strings.urlSpotContentStatusUpdate)
    
    var contentID: String!
    var spotID: String!
    var statusUpdate: String!
    
    required init(contentID: String!, spotID: String!, statusUpdate: String!)
    {
        self.contentID = contentID
        self.spotID = spotID
        self.statusUpdate = statusUpdate
    }
    
    override func makeRequest()
    {
        print("AC-SCSU: UPDATING SPOT CONTENT: \(self.contentID) TO STATUS: \(self.statusUpdate)")
        
        if let facebookToken = FBSDKAccessToken.current()
        {
            var json = [String: Any]()
            json["app_version"] = Constants.Settings.appVersion
            json["identity_id"] = Constants.credentialsProvider.identityId
            json["login_provider"] = "graph.facebook.com"
            json["login_token"] = facebookToken.tokenString
            json["content_id"]    = contentID
            json["status_update"] = statusUpdate
            let jsonData = try? JSONSerialization.data(withJSONObject: json)
            
            var request = URLRequest(url: url!)
            request.httpMethod = "POST"
            request.timeoutInterval = Constants.Settings.requestTimeout
            request.httpBody = jsonData
            request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            let session = URLSession(configuration: .default)
            let dataTask = session.dataTask(with: request)
            { (responseData, response, error) in
                if let err = error
                {
                    self.recordError(stage: "URLRequest", error: err as? String)
                }
                else if let res = response as? HTTPURLResponse
                {
                    print("AC-SCSU - RESPONSE CODE: \(res.statusCode)")
                    if let data = responseData
                    {
                        do
                        {
                            let jsonData = try JSONSerialization.jsonObject(with: data, options: [JSONSerialization.ReadingOptions.allowFragments])
                            print("AC-SCSU - JSON DATA: \(json)")
                            // Convert the data to JSON with keys and AnyObject values
                            if let json = jsonData as? [String: AnyObject]
                            {
                                print("AC-SCSU - JSON: \(json)")
                                // EXTRACT THE RESPONSE STRING
                                if let response = json["response"] as? String
                                {
                                    print("AC-SCSU - RESPONSE: \(response)")
                                    if response == "success"
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
                                            print("AC-SCSU - CALLED PARENT")
                                            parentVC.processAwsReturn(self, success: true)
                                        }
                                    }
                                    else
                                    {
                                        self.recordError(stage: "response - fail", error: response)
                                    }
                                }
                                else
                                {
                                    self.recordError(stage: "response", error: nil)
                                }
                            }
                            else
                            {
                                self.recordError(stage: "JSON", error: nil)
                            }
                        }
                        catch let error as NSError
                        {
                            self.recordError(stage: "JSONSerlialization", error: error.description)
                        }
                    }
                    else
                    {
                        self.recordError(stage: "Response Data - else", error: nil)
                    }
                }
                else
                {
                    self.recordError(stage: "URLRequest - else", error: nil)
                }
            }
            dataTask.resume()
        }
        else
        {
            self.recordError(stage: "FBToken", error: nil)
        }
    }
    
    func recordError(stage: String!, error: String?)
    {
        print("AC-SCSU: GET DATA ERROR AT STAGE: \(stage), ERROR: \(String(describing: error))")
//        CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: err.debugDescription)
        
        // Record the server request attempt
        Constants.Data.serverTries += 1
        
        // Notify the parent view that the AWS call completed with an error
        if let parentVC = self.awsRequestDelegate
        {
            parentVC.processAwsReturn(self, success: false)
        }
    }
}

class AWSSpotRequestPut : AWSRequestObject
{
    let url = URL(string: Constants.Strings.urlSpotRequestPut)
    
    var spotRequest: SpotRequest!
    
    required init(spotRequest: SpotRequest!)
    {
        self.spotRequest = spotRequest
    }
    
    override func makeRequest()
    {
        print("AC-SRP: PUT SPOT REQUEST: \(self.spotRequest)")
        
        if let facebookToken = FBSDKAccessToken.current()
        {
            var json = [String: Any]()
            json["app_version"] = Constants.Settings.appVersion
            json["identity_id"] = Constants.credentialsProvider.identityId
            json["login_provider"] = "graph.facebook.com"
            json["login_token"] = facebookToken.tokenString
            json["request_id"] = spotRequest.requestID
            json["user_id"]    = spotRequest.userID
            json["timestamp"]  = String(spotRequest.datetime.timeIntervalSince1970)
            json["lat"]        = String(spotRequest.lat)
            json["lng"]        = String(spotRequest.lng)
            json["status"]     = spotRequest.status
            let jsonData = try? JSONSerialization.data(withJSONObject: json)
            
            var request = URLRequest(url: url!)
            request.httpMethod = "POST"
            request.timeoutInterval = Constants.Settings.requestTimeout
            request.httpBody = jsonData
            request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            let session = URLSession(configuration: .default)
            let dataTask = session.dataTask(with: request)
            { (responseData, response, error) in
                if let err = error
                {
                    self.recordError(stage: "URLRequest", error: err as? String)
                }
                else if let res = response as? HTTPURLResponse
                {
                    print("AC-SRP - RESPONSE CODE: \(res.statusCode)")
                    if let data = responseData
                    {
                        do
                        {
                            let jsonData = try JSONSerialization.jsonObject(with: data, options: [JSONSerialization.ReadingOptions.allowFragments])
                            print("AC-SRP - JSON DATA: \(json)")
                            // Convert the data to JSON with keys and AnyObject values
                            if let json = jsonData as? [String: AnyObject]
                            {
                                print("AC-SRP - JSON: \(json)")
                                // EXTRACT THE RESPONSE STRING
                                if let response = json["response"] as? String
                                {
                                    print("AC-SRP - RESPONSE: \(response)")
                                    if response == "success"
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
                                    else
                                    {
                                        self.recordError(stage: "response - fail", error: response)
                                    }
                                }
                                else
                                {
                                    self.recordError(stage: "response", error: nil)
                                }
                            }
                            else
                            {
                                self.recordError(stage: "JSON", error: nil)
                            }
                        }
                        catch let error as NSError
                        {
                            self.recordError(stage: "JSONSerlialization", error: error.description)
                        }
                    }
                    else
                    {
                        self.recordError(stage: "Response Data - else", error: nil)
                    }
                }
                else
                {
                    self.recordError(stage: "URLRequest - else", error: nil)
                }
            }
            dataTask.resume()
        }
        else
        {
            self.recordError(stage: "FBToken", error: nil)
        }
    }
    
    func recordError(stage: String!, error: String?)
    {
        print("AC-SRP: GET DATA ERROR AT STAGE: \(stage), ERROR: \(String(describing: error))")
//        CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: err.debugDescription)
        
        // Record the server request attempt
        Constants.Data.serverTries += 1
        
        // Notify the parent view that the AWS call completed with an error
        if let parentVC = self.awsRequestDelegate
        {
            parentVC.processAwsReturn(self, success: false)
        }
    }
}


// MARK: SHELTER

class AWSShelterQuery : AWSRequestObject
{
    let url = URL(string: Constants.Strings.urlShelterQueryActive)
    var userLocation = [String : Double]()
    
    required init(userLocation: [String : Double]!)
    {
        if let userLocation = userLocation
        {
            self.userLocation = userLocation
        }
    }
    
    override func makeRequest()
    {
        print("AC-SHQ: REQUESTING DATA: \(String(describing: self.userLocation))")
        
        if let facebookToken = FBSDKAccessToken.current()
        {
            var json = [String: Any]()
            json["app_version"] = Constants.Settings.appVersion
            json["identity_id"] = Constants.credentialsProvider.identityId
            json["login_provider"] = "graph.facebook.com"
            json["login_token"] = facebookToken.tokenString
            let jsonData = try? JSONSerialization.data(withJSONObject: json)
            
            var request = URLRequest(url: url!)
            request.httpMethod = "POST"
            request.timeoutInterval = Constants.Settings.requestTimeout
            request.httpBody = jsonData
            request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            let session = URLSession(configuration: .default)
            let dataTask = session.dataTask(with: request)
            { (responseData, response, error) in
                if let err = error
                {
                    self.recordError(stage: "URLRequest", error: err as? String)
                }
                else if let res = response as? HTTPURLResponse
                {
                    print("AC-SHQ - RESPONSE CODE: \(res.statusCode)")
                    if let data = responseData
                    {
//                        let resData = String(data: data, encoding: String.Encoding.utf8)
                        do
                        {
                            let json = try JSONSerialization.jsonObject(with: data, options: [JSONSerialization.ReadingOptions.allowFragments])
                            print("AC-SHQ - JSON: \(json)")
                            // Convert the data to JSON with keys and AnyObject values
                            if let allData = json as? [String: AnyObject]
                            {
                                print("AC-SHQ - ALL DATA: \(allData)")
                                // EXTRACT THE RESPONSE STRING
                                if let response = allData["response"] as? String
                                {
                                    print("AC-SHQ - RESPONSE: \(response)")
                                    if response == "success"
                                    {
                                        // Convert the response to an array of AnyObjects
                                        // EXTRACT SHELTER DATA
                                        if let allShelterRaw = allData["shelter"] as? [Any]
                                        {
                                            print("AC-SHQ - ALL SHELTER: \(allShelterRaw)")
                                            // Loop through each AnyObject in the array
                                            for newShelter in allShelterRaw
                                            {
                                                print("AC-SHQ - SHELTER: \(newShelter)")
                                                // Convert the response to JSON with keys and AnyObject values
                                                // Then convert the AnyObject values to Strings or Numbers depending on their key
                                                if let shelterRaw = newShelter as? [String: AnyObject]
                                                {
                                                    // Double-check one of the key values before moving on
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
//                                                        Constants.Data.allShelter.append(addShelter)
                                                        
                                                        // Check to see if the hazard already exists
                                                        var shelterExists = false
                                                        shelterLoop: for shelter in Constants.Data.allShelter
                                                        {
                                                            if shelter.shelterID! == shelterID as! String
                                                            {
                                                                // It already exists, so update the values
                                                                shelterExists = true
                                                                
                                                                shelter.datetime = addShelter.datetime
                                                                shelter.name = addShelter.name
                                                                shelter.address = addShelter.address
                                                                shelter.city = addShelter.city
                                                                shelter.lat = addShelter.lat
                                                                shelter.lng = addShelter.lng
                                                                shelter.phone = addShelter.phone
                                                                shelter.website = addShelter.website
                                                                shelter.info = addShelter.info
                                                                shelter.type = addShelter.type
                                                                shelter.condition = addShelter.condition
                                                                
                                                                break shelterLoop
                                                            }
                                                        }
                                                        if !shelterExists
                                                        {
                                                            // It does not exist, so add it to the list
                                                            Constants.Data.allShelter.append(addShelter)
                                                        }
                                                        print("AC-SHQ - ADDED/UPDATED HAZARD DATA: \(String(describing: addShelter.shelterID))")
                                                    }
                                                    else
                                                    {
                                                        self.recordError(stage: "Shelter ID - else", error: nil)
                                                    }
                                                }
                                                else
                                                {
                                                    self.recordError(stage: "Shelter Object - else", error: nil)
                                                }
                                            }
                                            
                                            // Notify the parent view that the AWS call completed successfully
                                            if let parentVC = self.awsRequestDelegate
                                            {
                                                print("AC-SHQ - CALLED PARENT")
                                                parentVC.processAwsReturn(self, success: true)
                                            }
                                        }
                                        else
                                        {
                                            self.recordError(stage: "Shelter Data - else", error: nil)
                                        }
                                    }
                                    else
                                    {
                                        self.recordError(stage: "response - fail", error: response)
                                    }
                                }
                                else
                                {
                                    self.recordError(stage: "response", error: nil)
                                }
                            }
                            else
                            {
                                self.recordError(stage: "JSON", error: nil)
                            }
                        }
                        catch let error as NSError
                        {
                            self.recordError(stage: "JSONSerlialization", error: error.description)
                        }
                    }
                    else
                    {
                        self.recordError(stage: "Response Data - else", error: nil)
                    }
                }
                else
                {
                    self.recordError(stage: "URLRequest - else", error: nil)
                }
            }
            dataTask.resume()
        }
        else
        {
            self.recordError(stage: "FBToken", error: nil)
        }
    }
    
    func recordError(stage: String!, error: String?)
    {
        print("AC-SHQ: GET DATA ERROR AT STAGE: \(stage), ERROR: \(String(describing: error))")
//        CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: err.debugDescription)
        
        // Record the server request attempt
        Constants.Data.serverTries += 1
        
        // Notify the parent view that the AWS call completed with an error
        if let parentVC = self.awsRequestDelegate
        {
            parentVC.processAwsReturn(self, success: false)
        }
    }
}


// MARK: HAZARD

class AWSHazardQuery: AWSRequestObject
{
    let url = URL(string: Constants.Strings.urlHazardQueryActive)
    
    override func makeRequest()
    {
        if let facebookToken = FBSDKAccessToken.current()
        {
            var json = [String: Any]()
            json["app_version"] = Constants.Settings.appVersion
            json["identity_id"] = Constants.credentialsProvider.identityId
            json["login_provider"] = "graph.facebook.com"
            json["login_token"] = facebookToken.tokenString
            let jsonData = try? JSONSerialization.data(withJSONObject: json)
            
            print("AC-HQ")
            var request = URLRequest(url: url!)
            request.httpMethod = "POST"
            request.timeoutInterval = Constants.Settings.requestTimeout
            request.httpBody = jsonData
            request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            let session = URLSession(configuration: .default)
            let dataTask = session.dataTask(with: request)
            { (responseData, response, error) in
                if let err = error
                {
                    self.recordError(stage: "URLRequest", error: err as? String)
                }
                else if let res = response as? HTTPURLResponse
                {
                    print("AC-HQ - RESPONSE CODE: \(res.statusCode)")
                    if let data = responseData
                    {
//                        let resData = String(data: data, encoding: String.Encoding.utf8)
                        do
                        {
                            let json = try JSONSerialization.jsonObject(with: data, options: [JSONSerialization.ReadingOptions.allowFragments])
                            print("AC-HQ - JSON: \(json)")
                            // Convert the data to JSON with keys and AnyObject values
                            if let allData = json as? [String: AnyObject]
                            {
                                print("AC-HQ - ALL DATA: \(allData)")
                                // EXTRACT THE RESPONSE STRING
                                if let response = allData["response"] as? String
                                {
                                    print("AC-HQ - RESPONSE: \(response)")
                                    if response == "success"
                                    {
                                        // Convert the response to an array of AnyObjects
                                        // EXTRACT HAZARD DATA
                                        if let allHazardRaw = allData["hazard"] as? [Any]
                                        {
                                            print("AC-HQ - ALL HAZARD: \(allHazardRaw)")
                                            // Loop through each AnyObject in the array
                                            for newHazard in allHazardRaw
                                            {
                                                print("AC-HQ - HAZARD:")
                                                print(newHazard)
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
                                                        print("AC-HQ - ADDED/UPDATED HAZARD DATA: \(String(describing: addHazard.hazardID))")
                                                    }
                                                    else
                                                    {
                                                        self.recordError(stage: "Hazard ID - else", error: nil)
                                                    }
                                                }
                                                else
                                                {
                                                    self.recordError(stage: "Hazard Object - else", error: nil)
                                                }
                                            }
                                            
                                            // Notify the parent view that the AWS call completed successfully
                                            if let parentVC = self.awsRequestDelegate
                                            {
                                                print("AC-HQ - CALLED PARENT")
                                                parentVC.processAwsReturn(self, success: true)
                                            }
                                        }
                                        else
                                        {
                                            self.recordError(stage: "Hazard Data - else", error: nil)
                                        }
                                    }
                                    else
                                    {
                                        self.recordError(stage: "response - fail", error: response)
                                    }
                                }
                                else
                                {
                                    self.recordError(stage: "response", error: nil)
                                }
                            }
                            else
                            {
                                self.recordError(stage: "JSON", error: nil)
                            }
                        }
                        catch let error as NSError
                        {
                            self.recordError(stage: "JSONSerlialization", error: error.description)
                        }
                    }
                    else
                    {
                        self.recordError(stage: "Response Data - else", error: nil)
                    }
                }
                else
                {
                    self.recordError(stage: "URLRequest - else", error: nil)
                }
            }
            dataTask.resume()
        }
        else
        {
            self.recordError(stage: "FBToken", error: nil)
        }
    }
    
    func recordError(stage: String!, error: String?)
    {
        print("AC-HQ: GET DATA ERROR AT STAGE: \(stage), ERROR: \(String(describing: error))")
//        CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: err.debugDescription)
        
        // Record the server request attempt
        Constants.Data.serverTries += 1
        
        // Notify the parent view that the AWS call completed with an error
        if let parentVC = self.awsRequestDelegate
        {
            parentVC.processAwsReturn(self, success: false)
        }
    }
}

class AWSHazardPut: AWSRequestObject
{
    let url = URL(string: Constants.Strings.urlHazardPut)
    var hazard: Hazard!
    
    required init(hazard: Hazard!)
    {
        self.hazard = hazard
    }
    
    override func makeRequest()
    {
        print("AC-PH: SENDING REQUEST")
        // Ensure that the hazard ID has been added
        if let hazardID = hazard.hazardID
        {
            print("AC-PH - HAZARD STATUS: \(hazard.status)")
            // Check whether the FB Token is still available
            if let facebookToken = FBSDKAccessToken.current()
            {
                print("AC-PH - FB TOKEN: \(facebookToken)")
                // Create a JSON object with the passed data
                var json = [String : Any]()
                json["app_version"] = Constants.Settings.appVersion
                json["identity_id"] = Constants.credentialsProvider.identityId
                json["login_provider"] = "graph.facebook.com"
                json["login_token"] = facebookToken.tokenString
                json["hazard_id"] = hazardID
                json["user_id"] = Constants.Data.currentUser.userID
                json["timestamp"] = String(hazard.datetime.timeIntervalSince1970)
                json["lat"] = String(hazard.lat)
                json["lng"] = String(hazard.lng)
                json["type"] = String(hazard.type.rawValue)
                json["status"] = hazard.status
                let jsonData = try? JSONSerialization.data(withJSONObject: json)
                
                var request = URLRequest(url: url!)
                request.httpMethod = "POST"
                request.timeoutInterval = Constants.Settings.requestTimeout
                request.httpBody = jsonData
                request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
                let session = URLSession(configuration: .default)
                let dataTask = session.dataTask(with: request)
                { (responseData, response, error) in
                    if let err = error
                    {
                        self.recordError(stage: "URLRequest", error: err as? String)
                    }
                    else if let res = response as? HTTPURLResponse
                    {
                        print("AC-PH - RESPONSE CODE: \(res.statusCode)")
                        if let data = responseData
                        {
                            do
                            {
                                let json = try JSONSerialization.jsonObject(with: data, options: [])
                                print("AC-PH RESPONSE: \(json)")
                                
                                // Convert the data to JSON with keys and AnyObject values
                                if let allData = json as? [String: AnyObject]
                                {
                                    print("AC-PH - ALL DATA: \(allData)")
                                    // EXTRACT THE RESPONSE STRING
                                    if let response = allData["response"] as? String
                                    {
                                        print("AC-PH - RESPONSE: \(response)")
                                        if response == "success"
                                        {
                                            // Now add the new Hazard to the global array if it was not deleted
                                            if self.hazard.status == "active"
                                            {
                                                Constants.Data.allHazard.append(self.hazard)
                                            }
                                            
                                            // Notify the parent view that the AWS call completed successfully
                                            if let parentVC = self.awsRequestDelegate
                                            {
                                                print("AC-GH - CALLED PARENT")
                                                parentVC.processAwsReturn(self, success: true)
                                            }
                                        }
                                        else
                                        {
                                            self.recordError(stage: "response", error: response)
                                        }
                                    }
                                }
                                
                            }
                            catch let error as NSError
                            {
                                self.recordError(stage: "JSONSerialization", error: error.description)
                            }
                        }
                        else
                        {
                            self.recordError(stage: "data", error: nil)
                        }
                    }
                    else
                    {
                        self.recordError(stage: "URLRequest - else", error: nil)
                    }
                }
                dataTask.resume()
            }
            else
            {
                self.recordError(stage: "FBToken", error: nil)
            }
        }
    }
    
    func recordError(stage: String!, error: String?)
    {
        print("AC-PH: GET DATA ERROR AT STAGE: \(stage), ERROR: \(String(describing: error))")
//        CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: err.debugDescription)
        
        // Record the server request attempt
        Constants.Data.serverTries += 1
        
        // Notify the parent view that the AWS call completed with an error
        if let parentVC = self.awsRequestDelegate
        {
            parentVC.processAwsReturn(self, success: false)
        }
    }
}


// MARK: HYDRO

class AWSHydroQuery : AWSRequestObject
{
    let url = URL(string: Constants.Strings.urlHydroQuery)
    
    var userLocation = [String : Double]()
    
    required init(userLocation: [String : Double]!)
    {
        if let userLocation = userLocation
        {
            self.userLocation = userLocation
        }
    }
    
    override func makeRequest()
    {
        print("AC-HQ: PUT SKILLS")
        
        if let facebookToken = FBSDKAccessToken.current()
        {
            // Create some JSON to send the data
            var json = [String: Any]()
            json["app_version"] = Constants.Settings.appVersion
            json["identity_id"] = Constants.credentialsProvider.identityId
            json["login_provider"] = "graph.facebook.com"
            json["login_token"] = facebookToken.tokenString
            json["user_location"] = userLocation
            let jsonData = try? JSONSerialization.data(withJSONObject: json)
            
            var request = URLRequest(url: url!)
            request.httpMethod = "POST"
            request.timeoutInterval = Constants.Settings.requestTimeout
            request.httpBody = jsonData
            request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            let session = URLSession(configuration: .default)
            let dataTask = session.dataTask(with: request)
            { (responseData, response, error) in
                if let err = error
                {
                    self.recordError(stage: "URLRequest", error: err as? String)
                }
                else if let res = response as? HTTPURLResponse
                {
                    print("AC-HQ - RESPONSE CODE: \(res.statusCode)")
                    if let data = responseData
                    {
                        do
                        {
                            let jsonData = try JSONSerialization.jsonObject(with: data, options: [JSONSerialization.ReadingOptions.allowFragments])
                            print("AC-HQ - JSON DATA: \(json)")
                            // Convert the data to JSON with keys and AnyObject values
                            if let json = jsonData as? [String: AnyObject]
                            {
                                print("AC-HQ - JSON: \(json)")
                                // EXTRACT THE RESPONSE STRING
                                if let response = json["response"] as? String
                                {
                                    print("AC-HQ - RESPONSE: \(response)")
                                    if response == "success"
                                    {
                                        // The data request was successful - reset the data array
                                        Constants.Data.allHydro = [Hydro]()
                                        
                                        // Convert the response to an array of AnyObjects
                                        // EXTRACT HYDRO DATA
                                        if let allHydroRaw = json["hydro"] as? [Any]
                                        {
                                            // Loop through each AnyObject (Hydro) in the array
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
//                                                        print("AC-GHD - ADDED HYDRO DATA: \(addHydro.title)")
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
                                    else
                                    {
                                        self.recordError(stage: "response - fail", error: response)
                                    }
                                }
                                else
                                {
                                    self.recordError(stage: "response", error: nil)
                                }
                            }
                            else
                            {
                                self.recordError(stage: "JSON", error: nil)
                            }
                        }
                        catch let error as NSError
                        {
                            self.recordError(stage: "JSONSerlialization", error: error.description)
                        }
                    }
                    else
                    {
                        self.recordError(stage: "Response Data - else", error: nil)
                    }
                }
                else
                {
                    self.recordError(stage: "URLRequest - else", error: nil)
                }
            }
            dataTask.resume()
        }
    }
    
    func recordError(stage: String!, error: String?)
    {
        print("AC-HQ: GET DATA ERROR AT STAGE: \(stage), ERROR: \(String(describing: error))")
//        CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: err.debugDescription)
        
        // Record the server request attempt
        Constants.Data.serverTries += 1
        
        // Notify the parent view that the AWS call completed with an error
        if let parentVC = self.awsRequestDelegate
        {
            parentVC.processAwsReturn(self, success: false)
        }
    }
}


// MARK: SOS

class AWSSOSQuery : AWSRequestObject
{
    let url = URL(string: "")
    
    var userLocation = [String : Double]()
    
    required init(userLocation: [String : Double]!)
    {
        if let userLocation = userLocation
        {
            self.userLocation = userLocation
        }
    }
    
    override func makeRequest()
    {
        print("AC-SOSQ: QUERY SOS")
        
        if let facebookToken = FBSDKAccessToken.current()
        {
            // Create some JSON to send the data
            var json = [String: Any]()
            json["app_version"] = Constants.Settings.appVersion
            json["identity_id"] = Constants.credentialsProvider.identityId
            json["login_provider"] = "graph.facebook.com"
            json["login_token"] = facebookToken.tokenString
            json["user_location"] = userLocation
            let jsonData = try? JSONSerialization.data(withJSONObject: json)
            
            var request = URLRequest(url: url!)
            request.httpMethod = "POST"
            request.timeoutInterval = Constants.Settings.requestTimeout
            request.httpBody = jsonData
            request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            let session = URLSession(configuration: .default)
            let dataTask = session.dataTask(with: request)
            { (responseData, response, error) in
                if let err = error
                {
                    self.recordError(stage: "URLRequest", error: err as? String)
                }
                else if let res = response as? HTTPURLResponse
                {
                    print("AC-SOSQ - RESPONSE CODE: \(res.statusCode)")
                    if let data = responseData
                    {
                        do
                        {
                            let jsonData = try JSONSerialization.jsonObject(with: data, options: [JSONSerialization.ReadingOptions.allowFragments])
                            print("AC-SOSQ - JSON DATA: \(json)")
                            // Convert the data to JSON with keys and AnyObject values
                            if let json = jsonData as? [String: AnyObject]
                            {
                                print("AC-SOSQ - JSON: \(json)")
                                // EXTRACT THE RESPONSE STRING
                                if let response = json["response"] as? String
                                {
                                    print("AC-SOSQ - RESPONSE: \(response)")
                                    if response == "success"
                                    {
                                        // Convert the response to an array of AnyObjects
                                        // EXTRACT SOS DATA
                                        if let allSOSRaw = json["sos"] as? [Any]
                                        {
                                            var latestSOS = [SOS]()
                                            
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
                                                        
                                                        latestSOS.append(addSOS)
                                                        print("AC-SOSQ - ADDED SOS DATA: \(addSOS.status)")
                                                    }
                                                }
                                            }
                                            Constants.Data.allSOS = latestSOS
                                        }
                                        
                                        // Notify the parent view that the AWS call completed successfully
                                        if let parentVC = self.awsRequestDelegate
                                        {
                                            print("AC-SOSQ - CALLED PARENT")
                                            parentVC.processAwsReturn(self, success: true)
                                        }
                                    }
                                    else
                                    {
                                        self.recordError(stage: "response - fail", error: response)
                                    }
                                }
                                else
                                {
                                    self.recordError(stage: "response", error: nil)
                                }
                            }
                            else
                            {
                                self.recordError(stage: "JSON", error: nil)
                            }
                        }
                        catch let error as NSError
                        {
                            self.recordError(stage: "JSONSerlialization", error: error.description)
                        }
                    }
                    else
                    {
                        self.recordError(stage: "Response Data - else", error: nil)
                    }
                }
                else
                {
                    self.recordError(stage: "URLRequest - else", error: nil)
                }
            }
            dataTask.resume()
        }
    }
    
    func recordError(stage: String!, error: String?)
    {
        print("AC-SOSQ: GET DATA ERROR AT STAGE: \(stage), ERROR: \(String(describing: error))")
//        CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: err.debugDescription)
        
        // Record the server request attempt
        Constants.Data.serverTries += 1
        
        // Notify the parent view that the AWS call completed with an error
        if let parentVC = self.awsRequestDelegate
        {
            parentVC.processAwsReturn(self, success: false)
        }
    }
}

class AWSSOSPut : AWSRequestObject
{
    let url = URL(string: "")
    
    var sos: SOS!
    
    required init(sos: SOS!)
    {
        self.sos = sos
    }
    
    override func makeRequest()
    {
        print("AC-SOSP: PUT SOS")
        
        if let facebookToken = FBSDKAccessToken.current()
        {
            // Create some JSON to send the data
            var json = [String: Any]()
            json["app_version"] = Constants.Settings.appVersion
            json["identity_id"] = Constants.credentialsProvider.identityId
            json["login_provider"] = "graph.facebook.com"
            json["login_token"] = facebookToken.tokenString
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
            let jsonData = try? JSONSerialization.data(withJSONObject: json)
            
            var request = URLRequest(url: url!)
            request.httpMethod = "POST"
            request.timeoutInterval = Constants.Settings.requestTimeout
            request.httpBody = jsonData
            request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            let session = URLSession(configuration: .default)
            let dataTask = session.dataTask(with: request)
            { (responseData, response, error) in
                if let err = error
                {
                    self.recordError(stage: "URLRequest", error: err as? String)
                }
                else if let res = response as? HTTPURLResponse
                {
                    print("AC-SOSP - RESPONSE CODE: \(res.statusCode)")
                    if let data = responseData
                    {
                        do
                        {
                            let jsonData = try JSONSerialization.jsonObject(with: data, options: [JSONSerialization.ReadingOptions.allowFragments])
                            print("AC-SOSP - JSON DATA: \(json)")
                            // Convert the data to JSON with keys and AnyObject values
                            if let json = jsonData as? [String: AnyObject]
                            {
                                print("AC-SOSP - JSON: \(json)")
                                // EXTRACT THE RESPONSE STRING
                                if let response = json["response"] as? String
                                {
                                    print("AC-SOSP - RESPONSE: \(response)")
                                    if response == "success"
                                    {
                                        // Notify the parent view that the AWS call completed successfully
                                        if let parentVC = self.awsRequestDelegate
                                        {
                                            print("AC-SOSP - CALLED PARENT")
                                            parentVC.processAwsReturn(self, success: true)
                                        }
                                    }
                                    else
                                    {
                                        self.recordError(stage: "response - fail", error: response)
                                    }
                                }
                                else
                                {
                                    self.recordError(stage: "response", error: nil)
                                }
                            }
                            else
                            {
                                self.recordError(stage: "JSON", error: nil)
                            }
                        }
                        catch let error as NSError
                        {
                            self.recordError(stage: "JSONSerlialization", error: error.description)
                        }
                    }
                    else
                    {
                        self.recordError(stage: "Response Data - else", error: nil)
                    }
                }
                else
                {
                    self.recordError(stage: "URLRequest - else", error: nil)
                }
            }
            dataTask.resume()
        }
    }
    
    func recordError(stage: String!, error: String?)
    {
        print("AC-SOSP: GET DATA ERROR AT STAGE: \(stage), ERROR: \(String(describing: error))")
//        CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: err.debugDescription)
        
        // Record the server request attempt
        Constants.Data.serverTries += 1
        
        // Notify the parent view that the AWS call completed with an error
        if let parentVC = self.awsRequestDelegate
        {
            parentVC.processAwsReturn(self, success: false)
        }
    }
}


// MARK: S3 CLASSES

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
    
    // Download SpotContent Image
    override func makeRequest()
    {
//        print("AC - GMI - ATTEMPTING TO DOWNLOAD IMAGE: \(self.spotContent.contentID)")
        
        // Verify the type of content (image)
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
