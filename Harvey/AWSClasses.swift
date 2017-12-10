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
                
//                print("AC-PREP - COGNITO ID: \(String(describing: Constants.credentialsProvider.identityId))")
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
//        print("AC-PREP - IN GET COGNITO ID: \(String(describing: requestToCall.facebookToken?.tokenString))")
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
//                        print("AC - AWS COGNITO GET IDENTITY ID - AWS COGNITO ID: \(String(describing: cognitoId))")
//                        print("AC - AWS COGNITO GET IDENTITY ID - CHECK IDENTITY ID: \(String(describing: Constants.credentialsProvider.identityId))")
                        
                        // Save the current time to mark when the last CognitoID was saved
                        Constants.Data.lastCredentials = NSDate().timeIntervalSinceNow
                        
                        // Request extra facebook data for the user ON THE MAIN THREAD
                        DispatchQueue.main.async(execute:
                            {
//                                print("AC - GOT COGNITO ID - GETTING NEW AWS ID")
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
//        print("AC-PREP - GET HARVEY ID")
        // If the Identity ID is still valid, ensure that the current userID is not nil
        if Constants.Data.currentUser.userID != nil
        {
//            print("AC-PREP - CURRENT USER ID: \(String(describing: Constants.Data.currentUser.userID))")
            // The user is already logged in so go ahead and register for notifications
//            UtilityFunctions().registerPushNotifications()
            
            // FIRING REQUEST
            // All login info is current; go ahead and fire the needed method
            self.requestToCall.facebookToken = facebookToken
            self.requestToCall.makeRequest()
        }
        else
        {
//            print("AC-PREP - FB TOKEN: \(String(describing: facebookToken.tokenString))")
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
        if let fbToken = facebookToken
        {
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
                    print("AC-LU - RESPONSE CODE: \(res.statusCode)")
                    if let data = responseData
                    {
                        do
                        {
                            let jsonData = try JSONSerialization.jsonObject(with: data, options: [JSONSerialization.ReadingOptions.allowFragments])
                            // Convert the data to JSON with keys and AnyObject values
                            if let json = jsonData as? [String: AnyObject]
                            {
                                // EXTRACT THE RESPONSE STRING
                                if let response = json["response"] as? String
                                {
                                    if response == "success"
                                    {
                                        // Convert the response to JSON with keys and AnyObject values
                                        if let responseJson = json["login_data"] as? [String: AnyObject]
                                        {
                                            if let status = responseJson["status"] as? String
                                            {
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
                                                        CoreDataFunctions().currentUserSave(user: currentUser)
                                                        
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
//                                                            print("AC-L -loginUser - secondary fire")
                                                            AWSPrepRequest(requestToCall: secondaryAwsRequestObject, delegate: self.awsRequestDelegate!).prepRequest()
                                                        }
                                                        else
                                                        {
//                                                            print("AC-L -loginUser - else")
                                                            // Notify the parent view that the AWS Login call completed successfully
                                                            if let parentVC = self.awsRequestDelegate
                                                            {
                                                                parentVC.processAwsReturn(self, success: true)
                                                            }
                                                        }
                                                        
//                                                        print("AC-L -loginUser - call RC-FBI FOR USER: \(self.facebookToken!.userID)")
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
//                        print("AC-CRI - JSON DATA: \(json)")
                        // Convert the data to JSON with keys and AnyObject values
                        if let json = jsonData as? [String: AnyObject]
                        {
//                            print("AC-CRI - JSON: \(json)")
                            // EXTRACT THE RESPONSE STRING
                            if let response = json["response"] as? String
                            {
//                                print("AC-CRI - RESPONSE: \(response)")
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
//                        print("AC-STGS - JSON: \(json)")
                        // Convert the data to JSON with keys and AnyObject values
                        if let allData = json as? [String: AnyObject]
                        {
//                            print("AC-STGS - ALL DATA: \(allData)")
                            // EXTRACT THE RESPONSE STRING
                            if let response = allData["response"] as? String
                            {
//                                print("AC-STGS - RESPONSE: \(response)")
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
//                                            print("AC-STGS - CALLED PARENT")
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
//                            print("AC-UCFB - JSON: \(json)")
                            // Convert the data to JSON with keys and AnyObject values
                            if let allData = json as? [String: AnyObject]
                            {
//                                print("AC-UCFB - ALL DATA: \(allData)")
                                // EXTRACT THE RESPONSE STRING
                                if let response = allData["response"] as? String
                                {
//                                    print("AC-UCFB - RESPONSE: \(response)")
                                    if response == "success"
                                    {
                                        // Convert the response to an Integer
                                        if let userExistsInt = allData["user_exists"] as? Int
                                        {
//                                            print("AC-UCFB - USER EXISTS INT: \(userExistsInt)")
                                            if userExistsInt == 1
                                            {
                                                self.newUser = false
                                            }
                                            
                                            // Notify the parent view that the AWS call completed successfully
                                            if let parentVC = self.awsRequestDelegate
                                            {
//                                                print("AC-UCFB - CALLED PARENT")
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
//                            print("AC-UU - JSON: \(json)")
                            // Convert the data to JSON with keys and AnyObject values
                            if let allData = json as? [String: AnyObject]
                            {
//                                print("AC-UU - ALL DATA: \(allData)")
                                // EXTRACT THE RESPONSE STRING
                                if let response = allData["response"] as? String
                                {
//                                    print("AC-UU - RESPONSE: \(response)")
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
                                                CoreDataFunctions().userSave(user: user)
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
                                            CoreDataFunctions().currentUserSave(user: Constants.Data.currentUser)
                                        }
                                        
                                        // Notify the parent view that the AWS call completed successfully
                                        if let parentVC = self.awsRequestDelegate
                                        {
//                                            print("AC-UU - CALLED PARENT")
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
                                                        CoreDataFunctions().userSave(user: newUser)
                                                        
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
                                            if let skillSettings = skillJson["skill_types"] as? [String: AnyObject]
                                            {
                                                // Unwrap the settings' sibling json block - this will hold the user's saved skill settings
                                                if let skillLevels = skillJson["skill_levels"] as? [AnyObject]
                                                {
                                                    print("AC-SKQ - SKILL LEVELS: \(skillLevels)")
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
                                                            
                                                            print("AC-SKQ - skillType: \(skillType)")
                                                            // Default the order to 0 and icon to nil if they do not exist in the settings list
                                                            var title: String = ""
                                                            var order: Int = 0
                                                            var icon: UIImage?
                                                            // Find the skill needed
                                                            if let skillSettingObj = skillSettings[skillType]
                                                            {
                                                                // Create a json object
                                                                if let skillSettingJson = skillSettingObj as? [String: AnyObject]
                                                                {
                                                                    if let skillTitleSetting = skillSettingJson["title"] as? String
                                                                    {
                                                                        print("AC-SKQ - skill title: \(skillTitleSetting)")
                                                                        title = skillTitleSetting
                                                                    }
                                                                    if let skillOrderSetting = skillSettingJson["order"] as? Int
                                                                    {
                                                                        print("AC-SKQ - skill order: \(skillOrderSetting)")
                                                                        order = skillOrderSetting
                                                                    }
                                                                    if let skillIconFilename = skillSettingJson["image"] as? String
                                                                    {
                                                                        print("AC-SKQ - skill icon: \(skillIconFilename)")
                                                                        icon = UIImage(named: skillIconFilename)
                                                                    }
                                                                }
                                                            }
                                                            
                                                            // Create the Skill object
                                                            let addSkill = Skill(skillID: skillID, skill: skillType, userID: Constants.Data.currentUser.userID)
                                                            addSkill.title = title
                                                            addSkill.order = order
                                                            addSkill.level = Constants().experience(skillLevel)
                                                            if let iconImage = icon
                                                            {
                                                                addSkill.icon = iconImage
                                                            }
                                                            skillObjects.append(addSkill)
                                                            
                                                            // Save the updated / new skill to Core Data
                                                            CoreDataFunctions().skillSave(skill: addSkill)
                                                        }
                                                    }
                                                    
                                                    print("AC-SKQ - CHECKING SKILL SETTINGS")
                                                    // Now check the reverse - loop through the settings and ensure that all passed settings are saved
                                                    // If not, save the missing setting with the default setting of 'no experience' (0)
                                                    for skillSetting in skillSettings
                                                    {
                                                        print("AC-SKQ - SKILL SETTING: \(skillSetting)")
                                                        print("AC-SKQ - SKILL SETTING KEY: \(skillSetting.key)")
                                                        if let skillSettingJson = skillSetting.value as? [String: AnyObject]
                                                        {
                                                            print("AC-SKQ - SKILL SETTING JSON: \(skillSettingJson)")
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
                                                                print("AC-SKQ - SKILL DOES NOT EXIST")
                                                                // Cast the skill Setting value to Int - this is the skill order value
                                                                // Then create a skill Object using the default level value (0)
                                                                // The skillID is created using the userID and the skill type concatenated with a "-"
                                                                let skillType = skillSetting.key
                                                                let skillID = Constants.Data.currentUser.userID + "-" + skillType
                                                                let addSkill = Skill(skillID: skillID, skill: skillType, userID: Constants.Data.currentUser.userID)
                                                                if let skillTitle = skillSettingJson["title"] as? String
                                                                {
                                                                    addSkill.title = skillTitle
                                                                }
                                                                if let skillOrder = skillSettingJson["order"] as? Int
                                                                {
                                                                    addSkill.order = skillOrder
                                                                }
                                                                if let skillIconFilename = skillSettingJson["image"] as? String
                                                                {
                                                                    addSkill.icon = UIImage(named: skillIconFilename)
                                                                }
                                                                addSkill.level = Constants().experience(0)
                                                                skillObjects.append(addSkill)
                                                                
                                                                // Save the updated / new skill to Core Data
                                                                CoreDataFunctions().skillSave(skill: addSkill)
                                                            }
                                                        }
                                                    }
                                                    print("AC-SKQ - SAVING SKILLS GLOBALLY")
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
// Will return data for the passed structureID - get the structure ID from the structureUser data returned
class AWSStructureQuery : AWSRequestObject
{
    let url = URL(string: Constants.Strings.urlStructureQuery)
    
    var structureID: String!
    required init(structureID: String!)
    {
        self.structureID = structureID
    }
    
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
            json["structure_id"] = self.structureID
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
                                        // Create an empty json to hold the repair settings
                                        var repairSettingTypes = [String: AnyObject]()
                                        var repairSettingStages = [String: AnyObject]()
                                        if let repairSettingsJson = json["repair_settings"] as? [String: AnyObject]
                                        {
                                            if let repairSettingTypesJson = repairSettingsJson["types"] as? [String: AnyObject]
                                            {
                                                repairSettingTypes = repairSettingTypesJson
                                            }
                                            if let repairSettingStagesJson = repairSettingsJson["stages"] as? [String: AnyObject]
                                            {
                                                repairSettingStages = repairSettingStagesJson
                                            }
                                        }
                                        print("AC-STRQ - QUERY SUCCESS")
                                        if let structureData = json["structures"] as? [AnyObject]
                                        {
                                            for structureObject in structureData
                                            {
                                                print("AC-STRQ - CHECK 2")
                                                if let structureJson = structureObject as? [String: AnyObject]
                                                {
                                                    print("AC-STRQ - CHECK 3: \(structureJson)")
                                                    // Run a check on one json item to see if the data type is correct
                                                    if let structureID = structureJson["structure_id"] as? String
                                                    {
                                                        print("AC-STRQ - CHECK 4: \(structureID)")
                                                        let newStruct = Structure()
                                                        newStruct.structureID = structureID
                                                        newStruct.datetime = Date(timeIntervalSince1970: structureJson["timestamp"] as! Double)
                                                        newStruct.lat = structureJson["lat"] as! Double
                                                        newStruct.lng = structureJson["lng"] as! Double
                                                        newStruct.type = Constants().structureType(structureJson["type"] as! Int)
                                                        newStruct.stage = Constants().structureStage(structureJson["stage"] as! Int)
                                                        if let imageID = structureJson["image_id"] as? String
                                                        {
                                                            newStruct.imageID = imageID
                                                        }
                                                        
                                                        // Check to see if any data currently exists that is not included in the new data
                                                        var structureExists = false
                                                        structureCheckLoop: for structureCheck in Constants.Data.structures
                                                        {
                                                            // Check using the structureID
                                                            if structureCheck.structureID == structureID
                                                            {
                                                                // If the user already exists, update with newly downloaded data
                                                                structureExists = true
                                                                structureCheck.datetime = newStruct.datetime
                                                                structureCheck.lat = newStruct.lat
                                                                structureCheck.lng = newStruct.lng
                                                                structureCheck.type = newStruct.type
                                                                structureCheck.stage = newStruct.stage
                                                                if let imageID = newStruct.imageID
                                                                {
                                                                    structureCheck.imageID = imageID
                                                                }
                                                                break structureCheckLoop
                                                            }
                                                        }
                                                        if !structureExists
                                                        {
                                                            Constants.Data.structures.append(newStruct)
                                                        }
                                                        
                                                        // Save the current user data to Core Data
                                                        CoreDataFunctions().structureSave(structure: newStruct)
                                                        
                                                        // Now extract the structure users and save them separately
                                                        print("AC-STRQ - CHECK 5: \(structureID)")
                                                        if let usersData = structureJson["users"] as? [AnyObject]
                                                        {
                                                            for structureUserObject in usersData
                                                            {
                                                                print("AC-STRQ - CHECK 6")
                                                                if let structureUserJson = structureUserObject as? [String: AnyObject]
                                                                {
                                                                    print("AC-STRQ - CHECK 7: \(structureUserJson)")
                                                                    let newStructUser = StructureUser()
                                                                    newStructUser.structureID = structureUserJson["structure_id"] as! String
                                                                    newStructUser.userID = structureUserJson["user_id"] as! String
                                                                    newStructUser.datetime = Date(timeIntervalSince1970: structureUserJson["timestamp"] as! Double)
                                                                    
                                                                    // Check to see if any data currently exists that is not included in the new data
                                                                    var structureUserExists = false
                                                                    structureUserCheckLoop: for structureUserCheck in Constants.Data.structureUsers
                                                                    {
                                                                        // Check using the structureID
                                                                        if structureUserCheck.structureID == newStructUser.structureID && structureUserCheck.userID == newStructUser.userID
                                                                        {
                                                                            // If the structureUser already exists, update with newly downloaded data
                                                                            structureUserExists = true
                                                                            break structureUserCheckLoop
                                                                        }
                                                                    }
                                                                    if !structureUserExists
                                                                    {
                                                                        Constants.Data.structureUsers.append(newStructUser)
                                                                    }
                                                                    print("AC-STRQ - CHECK 8: \(Constants.Data.structureUsers.count)")
                                                                    
                                                                    // Save the current user data to Core Data
                                                                    CoreDataFunctions().structureUserSave(structureUser: newStructUser)
                                                                }
                                                            }
                                                        }
                                                    }
                                                    else
                                                    {
                                                        self.recordError(stage: "structureID", error: nil)
                                                    }
                                                    
                                                    if let repairData = structureJson["repairs"] as? [AnyObject]
                                                    {
                                                        print("AC-STRQ-RQ - CHECK 1")
                                                        // Create a local array to hold the new entities
                                                        var newRepairs = [Repair]()
                                                        for repairObject in repairData
                                                        {
                                                            print("AC-STRQ-RQ - CHECK 2")
                                                            if let repairJson = repairObject as? [String: AnyObject]
                                                            {
                                                                print("AC-STRQ-RQ - CHECK 3: \(repairJson)")
                                                                // Run a check on one json item to see if the data type is correct
                                                                if let repairID = repairJson["repair_id"] as? String
                                                                {
                                                                    print("AC-STRQ-RQ - CHECK 4: \(repairID), \(self.structureID)")
                                                                    
                                                                    let newRepair = Repair()
                                                                    newRepair.repairID = repairID
                                                                    newRepair.structureID = self.structureID
                                                                    newRepair.repair = repairJson["repair"] as! String
                                                                    newRepair.datetime = Date(timeIntervalSince1970: repairJson["timestamp"] as! Double)
                                                                    newRepair.stage = Constants().repairStage(repairJson["stage"] as! Int)
                                                                    if let repairImages = repairJson["repair_images"] as? [AnyObject]
                                                                    {
                                                                        var repairImagesObjects = [RepairImage]()
                                                                        for repairImageObject in repairImages
                                                                        {
                                                                            if let repairImageJson = repairImageObject as? [String: AnyObject]
                                                                            {
                                                                                let newRepairImage = RepairImage()
                                                                                newRepairImage.imageID = repairImageJson["image_id"] as! String
                                                                                newRepairImage.repairID = repairID
                                                                                newRepairImage.datetime = newRepair.datetime
                                                                                repairImagesObjects.append(newRepairImage)
                                                                            }
                                                                        }
                                                                        newRepair.repairImages = repairImagesObjects
                                                                    }
                                                                    // Try to find the repair in the settings list and assign the order and add the image
                                                                    if let repairSetting = repairSettingTypes[newRepair.repair]
                                                                    {
                                                                        if let repairSettingJson = repairSetting as? [String: AnyObject]
                                                                        {
                                                                            newRepair.title = repairSettingJson["title"] as! String
                                                                            newRepair.order = repairSettingJson["order"] as! Int
                                                                            print("AC-STRQ-RQ - ADDED REPAIR ORDER: \(newRepair.repair): Title: \(newRepair.title) Order: \(newRepair.order)")
                                                                            
                                                                            if let repairSettingSkills = repairSettingJson["skills"] as? [String]
                                                                            {
                                                                                newRepair.skillsNeeded = repairSettingSkills
                                                                            }
                                                                            
                                                                            let repairIconFilename = repairSettingJson["image"] as! String
                                                                            newRepair.icon = UIImage(named: repairIconFilename)
                                                                            print("AC-STRQ-RQ - ADDED REPAIR ICON: \(newRepair.icon) FROM IMAGE: \(repairIconFilename)")
                                                                        }
                                                                    }
                                                                    newRepairs.append(newRepair)
                                                                    
                                                                    // Save the repair data to the global array
                                                                    UtilityFunctions().repairAddToGlobalList(repair: newRepair)
                                                                    
                                                                    // Save the current user data to Core Data
                                                                    CoreDataFunctions().repairSave(repair: newRepair)
                                                                }
                                                                else
                                                                {
                                                                    self.recordError(stage: "structureID", error: nil)
                                                                }
                                                            }
                                                            else
                                                            {
                                                                self.recordError(stage: "json", error: nil)
                                                            }
                                                        }
                                                        
                                                        // Save the repair to the appropriate global structure object
                                                        structureLoop: for structure in Constants.Data.structures
                                                        {
                                                            if structure.structureID == self.structureID
                                                            {
                                                                structure.repairs = newRepairs
                                                                break structureLoop
                                                            }
                                                        }
                                                        
                                                        // Notify the parent view that the AWS call completed successfully
                                                        if let parentVC = self.awsRequestDelegate
                                                        {
                                                            print("AC-RQ - CALLED PARENT")
                                                            parentVC.processAwsReturn(self, success: true)
                                                        }
                                                    } // END OF REPAIR LOOP
                                                    
                                                }
                                                else
                                                {
                                                    self.recordError(stage: "json", error: nil)
                                                }
                                                
                                            }
                                            
                                            // Notify the parent view that the AWS call completed successfully
                                            if let parentVC = self.awsRequestDelegate
                                            {
                                                print("AC-STRQ - CALLED PARENT")
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

// Upload the Structure data to the db - a StructureUser entry should also be uploaded in parallel
class AWSStructurePut : AWSRequestObject
{
    let url = URL(string: Constants.Strings.urlStructurePut)
    
    var newStruct = 0
    var structure: Structure!
    required init(structure: Structure!, new: Bool!)
    {
        self.structure = structure
        if new == true
        {
            self.newStruct = 1
        }
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
            json["new_structure"] = String(newStruct)
            json["structure_id"] = structure.structureID
            json["user_id"] = Constants.Data.currentUser.userID
            json["lat"] = String(structure.lat)
            json["lng"] = String(structure.lng)
            json["timestamp"] = String(structure.datetime.timeIntervalSince1970)
            json["type"] = String(structure.type.rawValue)
            json["image_id"] = structure.imageID
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

// Upload a change to the Structure status
class AWSStructureDelete : AWSRequestObject
{
    let url = URL(string: Constants.Strings.urlStructureDelete)
    
    var structure: Structure!
    required init(structure: Structure!)
    {
        self.structure = structure
    }
    
    override func makeRequest()
    {
        print("AC-STRD: STRUCTURE DELETE")
        
        if let facebookToken = FBSDKAccessToken.current()
        {
            // Create some JSON to send the Structure data
            var json = [String: Any]()
            json["app_version"] = Constants.Settings.appVersion
            json["identity_id"] = Constants.credentialsProvider.identityId
            json["login_provider"] = "graph.facebook.com"
            json["login_token"] = facebookToken.tokenString
            json["new_structure"] = String(0)
            json["structure_id"] = structure.structureID
            json["user_id"] = Constants.Data.currentUser.userID
            json["lat"] = String(structure.lat)
            json["lng"] = String(structure.lng)
            json["timestamp"] = String(structure.datetime.timeIntervalSince1970)
            json["type"] = String(structure.type.rawValue)
            json["image_id"] = structure.imageID
            json["stage"] = String(structure.stage.rawValue)
            json["status"] = "deleted"
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
                    print("AC-STRD - RESPONSE CODE: \(res.statusCode)")
                    if let data = responseData
                    {
                        do
                        {
                            let jsonData = try JSONSerialization.jsonObject(with: data, options: [JSONSerialization.ReadingOptions.allowFragments])
                            print("AC-STRD - JSON DATA: \(json)")
                            // Convert the data to JSON with keys and AnyObject values
                            if let json = jsonData as? [String: AnyObject]
                            {
                                print("AC-STRD - JSON: \(json)")
                                // EXTRACT THE RESPONSE STRING
                                if let response = json["response"] as? String
                                {
                                    print("AC-STRD - RESPONSE: \(response)")
                                    if response == "success"
                                    {
                                        print("AC-STRD - UPLOAD SUCCESS")
                                        // Delete the structure from the global arrays
                                        structLoop: for (sIndex, structr) in Constants.Data.structures.enumerated()
                                        {
                                            if structr.structureID == self.structure.structureID
                                            {
                                                Constants.Data.structures.remove(at: sIndex)
                                                break structLoop
                                            }
                                        }
                                        CoreDataFunctions().structureDelete(structureID: self.structure.structureID)
                                        for (suIndex, structUser) in Constants.Data.structureUsers.enumerated()
                                        {
                                            if structUser.structureID == self.structure.structureID
                                            {
                                                Constants.Data.structureUsers.remove(at: suIndex)
                                            }
                                        }
                                        CoreDataFunctions().structureUserDelete(structureID: self.structure.structureID)
                                        
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
        print("AC-STRD: GET DATA ERROR AT STAGE: \(stage), ERROR: \(String(describing: error))")
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


// MARK: STRUCTURE-USER
// Return all structureIDs connected to the current user
class AWSStructureUserQuery : AWSRequestObject
{
    let url = URL(string: Constants.Strings.urlStructureUserQuery)
    var structureID: String?
    var userID: String?
    
    override func makeRequest()
    {
        print("AC-STRUQ: STRUCTURE-USER QUERY")
        
        if let facebookToken = FBSDKAccessToken.current()
        {
            // Create some JSON to send the Structure data
            var json = [String: Any]()
            json["app_version"] = Constants.Settings.appVersion
            json["identity_id"] = Constants.credentialsProvider.identityId
            json["login_provider"] = "graph.facebook.com"
            json["login_token"] = facebookToken.tokenString
            if let uID = self.userID
            {
                json["user_id"] = uID
            }
            if let sID = self.structureID
            {
                json["structure_id"] = sID
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
                    print("AC-STRUQ - RESPONSE CODE: \(res.statusCode)")
                    if let data = responseData
                    {
                        do
                        {
                            let jsonData = try JSONSerialization.jsonObject(with: data, options: [JSONSerialization.ReadingOptions.allowFragments])
                            print("AC-STRUQ - JSON DATA: \(jsonData)")
                            // Convert the data to JSON with keys and AnyObject values
                            if let json = jsonData as? [String: AnyObject]
                            {
                                print("AC-STRUQ - JSON: \(json)")
                                // EXTRACT THE RESPONSE STRING
                                if let response = json["response"] as? String
                                {
                                    print("AC-STRUQ - RESPONSE: \(response)")
                                    if response == "success"
                                    {
                                        print("AC-STRUQ - QUERY SUCCESS")
                                        if let structureUserData = json["structure_users"] as? [AnyObject]
                                        {
                                            print("AC-STRUQ - CHECK 1")
                                            // Create a local array to hold the new entities
                                            var newStructureUsers = [StructureUser]()
                                            for structureUserObject in structureUserData
                                            {
                                                print("AC-STRUQ - CHECK 2")
                                                if let structureUserJson = structureUserObject as? [String: AnyObject]
                                                {
                                                    print("AC-STRUQ - CHECK 3: \(structureUserJson)")
                                                    // Run a check on one json item to see if the data type is correct
                                                    if let structureID = structureUserJson["structure_id"] as? String
                                                    {
                                                        let userID = structureUserJson["user_id"] as! String
                                                        print("AC-STRUQ - CHECK 4: \(structureID), \(userID)")
                                                        
                                                        let newStructUser = StructureUser()
                                                        newStructUser.structureID = structureID
                                                        newStructUser.userID = userID
                                                        newStructUser.datetime = Date(timeIntervalSince1970: structureUserJson["timestamp"] as! Double)
                                                        
                                                        // Check to see if any data currently exists that is not included in the new data
                                                        var structureUserExists = false
                                                        structureUserCheckLoop: for structureUserCheck in Constants.Data.structureUsers
                                                        {
                                                            // Check using the structureID
                                                            if structureUserCheck.structureID == structureID && structureUserCheck.userID == userID
                                                            {
                                                                // If the structureUser already exists, update with newly downloaded data
                                                                structureUserExists = true
                                                                break structureUserCheckLoop
                                                            }
                                                        }
                                                        if !structureUserExists
                                                        {
                                                            Constants.Data.structureUsers.append(newStructUser)
                                                        }
                                                        
                                                        // Save the current user data to Core Data
                                                        CoreDataFunctions().structureUserSave(structureUser: newStructUser)
                                                    }
                                                    else
                                                    {
                                                        self.recordError(stage: "structureID", error: nil)
                                                    }
                                                }
                                                else
                                                {
                                                    self.recordError(stage: "json", error: nil)
                                                }
                                            }
                                            
                                            // Notify the parent view that the AWS call completed successfully
                                            if let parentVC = self.awsRequestDelegate
                                            {
                                                print("AC-STRUQ - CALLED PARENT")
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
        print("AC-STRUQ: GET DATA ERROR AT STAGE: \(stage), ERROR: \(String(describing: error))")
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

// Upload the Structure data to the db - a StructureUser entry should also be uploaded in parallel
class AWSStructureUserPut : AWSRequestObject
{
    let url = URL(string: Constants.Strings.urlStructureUserPut)
    
    var structureID: String!
    var userID: String!
    var timestamp: Double!
    required init(structureID: String!, userID: String!, timestamp: Double!)
    {
        self.structureID = structureID
        self.userID = userID
        self.timestamp = timestamp
    }
    
    override func makeRequest()
    {
        print("AC-STRUP: STRUCTURE-USER PUT")
        if let facebookToken = FBSDKAccessToken.current()
        {
            // Create some JSON to send the Structure data
            var json = [String: Any]()
            json["app_version"] = Constants.Settings.appVersion
            json["identity_id"] = Constants.credentialsProvider.identityId
            json["login_provider"] = "graph.facebook.com"
            json["login_token"] = facebookToken.tokenString
//            json["structure_user_id"] = structureID + "-" + userID
            json["structure_id"] = structureID
            json["user_id"] = userID
            json["timestamp"] = String(timestamp)
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
                    print("AC-STRUP - RESPONSE CODE: \(res.statusCode)")
                    if let data = responseData
                    {
                        do
                        {
                            let jsonData = try JSONSerialization.jsonObject(with: data, options: [JSONSerialization.ReadingOptions.allowFragments])
                            print("AC-STRUP - JSON DATA: \(json)")
                            // Convert the data to JSON with keys and AnyObject values
                            if let json = jsonData as? [String: AnyObject]
                            {
                                print("AC-STRUP - JSON: \(json)")
                                // EXTRACT THE RESPONSE STRING
                                if let response = json["response"] as? String
                                {
                                    print("AC-STRUP - RESPONSE: \(response)")
                                    if response == "success"
                                    {
                                        print("AC-STRUP - UPLOAD SUCCESS")
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
        print("AC-STRUP: GET DATA ERROR AT STAGE: \(stage), ERROR: \(String(describing: error))")
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

// Return all repairs connected to the passed structureID
class AWSRepairQuery : AWSRequestObject
{
    let url = URL(string: Constants.Strings.urlRepairQuery)
    
    var structureID: String!
    var repairs = [Repair]()
    required init(structureID: String!)
    {
        self.structureID = structureID
    }
    
    override func makeRequest()
    {
        print("AC-RQ: STRUCTURE-USER QUERY")
        
        if let facebookToken = FBSDKAccessToken.current()
        {
            // Create some JSON to send the Structure data
            var json = [String: Any]()
            json["app_version"] = Constants.Settings.appVersion
            json["identity_id"] = Constants.credentialsProvider.identityId
            json["login_provider"] = "graph.facebook.com"
            json["login_token"] = facebookToken.tokenString
            json["structure_id"] = self.structureID
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
                    print("AC-RQ - RESPONSE CODE: \(res.statusCode)")
                    if let data = responseData
                    {
                        do
                        {
                            let jsonData = try JSONSerialization.jsonObject(with: data, options: [JSONSerialization.ReadingOptions.allowFragments])
                            print("AC-RQ - JSON DATA: \(json)")
                            // Convert the data to JSON with keys and AnyObject values
                            if let json = jsonData as? [String: AnyObject]
                            {
                                print("AC-RQ - JSON: \(json)")
                                // EXTRACT THE RESPONSE STRING
                                if let response = json["response"] as? String
                                {
                                    print("AC-RQ - RESPONSE: \(response)")
                                    if response == "success"
                                    {
                                        print("AC-RQ - QUERY SUCCESS")
                                        // Create an empty json to hold the repair settings
                                        var repairSettingTypes = [String: AnyObject]()
                                        var repairSettingStages = [String: AnyObject]()
                                        if let repairSettingsJson = json["repair_settings"] as? [String: AnyObject]
                                        {
                                            if let repairSettingTypesJson = repairSettingsJson["types"] as? [String: AnyObject]
                                            {
                                                repairSettingTypes = repairSettingTypesJson
                                            }
                                            if let repairSettingStagesJson = repairSettingsJson["stages"] as? [String: AnyObject]
                                            {
                                                repairSettingStages = repairSettingStagesJson
                                            }
                                        }
                                        if let repairData = json["repairs"] as? [AnyObject]
                                        {
                                            print("AC-RQ - CHECK 1")
                                            // Create a local array to hold the new entities
                                            var newRepairs = [Repair]()
                                            for repairObject in repairData
                                            {
                                                print("AC-RQ - CHECK 2")
                                                if let repairJson = repairObject as? [String: AnyObject]
                                                {
                                                    print("AC-RQ - CHECK 3: \(repairJson)")
                                                    // Run a check on one json item to see if the data type is correct
                                                    if let repairID = repairJson["repair_id"] as? String
                                                    {
                                                        print("AC-RQ - CHECK 4: \(repairID), \(self.structureID)")
                                                        
                                                        let newRepair = Repair()
                                                        newRepair.repairID = repairID
                                                        newRepair.structureID = self.structureID
                                                        newRepair.repair = repairJson["repair"] as! String
                                                        newRepair.datetime = Date(timeIntervalSince1970: repairJson["timestamp"] as! Double)
                                                        newRepair.stage = Constants().repairStage(repairJson["stage"] as! Int)
                                                        if let repairImages = repairJson["repair_images"] as? [AnyObject]
                                                        {
                                                            var repairImagesObjects = [RepairImage]()
                                                            for repairImageObject in repairImages
                                                            {
                                                                if let repairImageJson = repairImageObject as? [String: AnyObject]
                                                                {
                                                                    let newRepairImage = RepairImage()
                                                                    newRepairImage.imageID = repairImageJson["image_id"] as! String
                                                                    newRepairImage.repairID = repairID
                                                                    newRepairImage.datetime = newRepair.datetime
                                                                    repairImagesObjects.append(newRepairImage)
                                                                }
                                                            }
                                                            newRepair.repairImages = repairImagesObjects
                                                        }
                                                        // Try to find the repair in the settings list and assign the order and add the image
                                                        if let repairSetting = repairSettingTypes[newRepair.repair]
                                                        {
                                                            if let repairSettingJson = repairSetting as? [String: AnyObject]
                                                            {
                                                                newRepair.title = repairSettingJson["title"] as! String
                                                                newRepair.order = repairSettingJson["order"] as! Int
                                                                print("AC-RQ - ADDED REPAIR ORDER: \(newRepair.repair): Title: \(newRepair.title) Order: \(newRepair.order)")
                                                                
                                                                if let repairSettingSkills = repairSettingJson["skills"] as? [String]
                                                                {
                                                                    newRepair.skillsNeeded = repairSettingSkills
                                                                }
                                                                
                                                                let repairIconFilename = repairSettingJson["image"] as! String
                                                                newRepair.icon = UIImage(named: repairIconFilename)
                                                                print("AC-RQ - ADDED REPAIR ICON: \(newRepair.icon) FROM IMAGE: \(repairIconFilename)")
                                                            }
                                                        }
                                                        newRepairs.append(newRepair)
                                                        
                                                        // Save the downloaded repair data to the local array to pass to the parent VC
                                                        self.repairs.append(newRepair)
                                                        
                                                        // Save the repair data to the global array
                                                        UtilityFunctions().repairAddToGlobalList(repair: newRepair)
                                                        
                                                        // Save the current user data to Core Data
                                                        CoreDataFunctions().repairSave(repair: newRepair)
                                                    }
                                                    else
                                                    {
                                                        self.recordError(stage: "structureID", error: nil)
                                                    }
                                                }
                                                else
                                                {
                                                    self.recordError(stage: "json", error: nil)
                                                }
                                            }
                                            
                                            // Save the repair to the appropriate global structure object
                                            structureLoop: for structure in Constants.Data.structures
                                            {
                                                if structure.structureID == self.structureID
                                                {
                                                    structure.repairs = newRepairs
                                                    break structureLoop
                                                }
                                            }
                                            
                                            // Notify the parent view that the AWS call completed successfully
                                            if let parentVC = self.awsRequestDelegate
                                            {
                                                print("AC-RQ - CALLED PARENT")
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
        print("AC-RQ: GET DATA ERROR AT STAGE: \(stage), ERROR: \(String(describing: error))")
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

class AWSRepairPut : AWSRequestObject
{
    let url = URL(string: Constants.Strings.urlRepairPut)
    
    var repair: Repair!
    var updatedImages: Int = 0 // 0=False, 1=True
    required init(repair: Repair!, newImages: Bool!)
    {
        self.repair = repair
        if newImages
        {
            updatedImages = 1
        }
    }
    
    override func makeRequest()
    {
        print("AC-RP: PUT REPAIR")
        if let facebookToken = FBSDKAccessToken.current()
        {
            // Create some JSON to send the Skill data
            // Add all associated RepairImages to a json array
            var repairImageDict = [Any]()
            for repairImage in repair.repairImages
            {
                var repairImageObj = [String: Any]()
                repairImageObj["image_id"] = repairImage.imageID
                repairImageObj["repair_id"] = repairImage.repairID
                repairImageObj["timestamp"] = String(describing: repairImage.datetime.timeIntervalSince1970)
                repairImageObj["status"] = "active"
                repairImageDict.append(repairImageObj)
            }
            
            var json = [String: Any]()
            json["app_version"] = Constants.Settings.appVersion
            json["identity_id"] = Constants.credentialsProvider.identityId
            json["login_provider"] = "graph.facebook.com"
            json["login_token"] = facebookToken.tokenString
            json["user_id"] = Constants.Data.currentUser.userID
            json["structure_id"] = repair.structureID
            json["repair"] = repair.repair
            json["stage"] = String(describing: repair.stage.rawValue)
            json["timestamp"] = String(repair.datetime.timeIntervalSince1970)
            json["status"] = "active"
            json["repair_images"] = repairImageDict
            json["updated_images"] = String(updatedImages)
            let jsonData = try? JSONSerialization.data(withJSONObject: json)
            print("AC-RP: PUT REPAIR JSON: \(json)")
            
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

class AWSDownloadMediaImage : AWSRequestObject
{
    var imageID: String!
    var imageParentID: String?
    var imageFilePath: String?
    var contentImage: UIImage?
    
    required init(imageID: String)
    {
        self.imageID = imageID
    }
    
    // Download SpotContent Image
    override func makeRequest()
    {
        print("AC-DMI - ATTEMPTING TO DOWNLOAD IMAGE: \(imageID)")
        
        imageFilePath = NSTemporaryDirectory() + imageID + ".jpg" // + Constants.Settings.frameImageFileType)
        let imageFileURL = URL(fileURLWithPath: imageFilePath!)
        let transferManager = AWSS3TransferManager.default()
        
        // Download the Frame
        let downloadRequest : AWSS3TransferManagerDownloadRequest = AWSS3TransferManagerDownloadRequest()
        downloadRequest.bucket = Constants.Strings.S3BucketMedia
        downloadRequest.key =  imageID + ".jpg"
        downloadRequest.downloadingFileURL = imageFileURL
        transferManager?.download(downloadRequest).continue(
            { (task) -> AnyObject! in
                print("AC-DMI - TASK: \(task)")
                if let error = task.error
                {
                    if error._domain == AWSS3TransferManagerErrorDomain as String
                        && AWSS3TransferManagerErrorType(rawValue: error._code) == AWSS3TransferManagerErrorType.paused
                    {
                        print("AC-DMI - Download paused.")
//                        CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: "IMAGE NOT DOWNLOADED")
                    }
                    else
                    {
                        print("AC-DMI - Download failed: [\(error)]")
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
                    print("AC-DMI - Download failed: [\(exception)]")
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
                    print("AC-DMI - COMPLETED")
                    // Assign the image to the Preview Image View
                    if FileManager().fileExists(atPath: self.imageFilePath!)
                    {
                        let imageData = try? Data(contentsOf: URL(fileURLWithPath: self.imageFilePath!))
                        
                        // Save the image to the local UIImage
                        self.contentImage = UIImage(data: imageData!)
                        
                        // Notify the parent view that the AWS call completed successfully
                        if let parentVC = self.awsRequestDelegate
                        {
                            print("AC-DMI - CALLING PARENT")
                            parentVC.processAwsReturn(self, success: true)
                        }
                    }
                    else
                    {
                        print("AC-DMI - FRAME FILE NOT AVAILABLE")
//                        CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: "IMAGE NOT DOWNLOADED")
                        
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
