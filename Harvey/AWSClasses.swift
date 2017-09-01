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
                
//                print("AC - COGNITO ID: \(String(describing: Constants.credentialsProvider.identityId))")
                // Ensure that the Cognito ID is still valid and is not older than an hour (AWS will invalidate if older)
                if Constants.credentialsProvider.identityId != nil && Constants.Data.lastCredentials - NSDate().timeIntervalSinceNow < 3600
                {
                    // The Cognito ID is valid, so check for a Blobjot ID and then make the request
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
//        print("AC - IN GET COGNITO ID: \(String(describing: requestToCall.facebookToken))")
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
//        print("AC - GET HARVEY ID")
        // If the Identity ID is still valid, ensure that the current userID is not nil
        if Constants.Data.currentUser.userID != nil
        {
//            print("AC - CURRENT USER ID: \(String(describing: Constants.Data.currentUser.userID))")
            // The user is already logged in so go ahead and register for notifications
//            UtilityFunctions().registerPushNotifications()
            
            // FIRING REQUEST
            // All login info is current; go ahead and fire the needed method
            self.requestToCall.facebookToken = facebookToken
            self.requestToCall.makeRequest()
        }
        else
        {
//            print("AC - FB TOKEN: \(String(describing: facebookToken.tokenString))")
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
class AWSLoginUser : AWSRequestObject
{
    var secondaryAwsRequestObject: AWSRequestObject?
    
    required init(secondaryAwsRequestObject: AWSRequestObject?)
    {
        self.secondaryAwsRequestObject = secondaryAwsRequestObject
    }
    
    // FBSDK METHOD - Get user data from FB before attempting to log in via AWS
    override func makeRequest()
    {
        print("AC - FBSDK - COGNITO ID: \(String(describing: Constants.credentialsProvider.identityId))")
        let fbRequest = FBSDKGraphRequest(graphPath: "me", parameters: ["fields": "id, email, name, picture"]) //parameters: ["fields": "id,email,name,picture"])
        print("FBSDK - MAKING GRAPH CALL")
        fbRequest?.start
            {(connection: FBSDKGraphRequestConnection?, result: Any?, error: Error?) in
                
                if error != nil
                {
                    print("FBSDK - Error Getting Info \(String(describing: error))")
//                    CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: "FBSDK - Error Getting Info" + error!.localizedDescription)
                    
                    // Record the server request attempt
                    Constants.Data.serverTries += 1
                    
                    // Try again
                    AWSPrepRequest(requestToCall: AWSLoginUser(secondaryAwsRequestObject: nil), delegate: self.awsRequestDelegate!).prepRequest()
                }
                else
                {
                    if let resultDict = result as? [String:AnyObject]
                    {
//                        if let resultPicture = resultDict["picture"] as? [String:AnyObject]
//                        {
//                            if let resultPictureData = resultPicture["data"] as? [String:AnyObject]
//                            {
//                                print("FBSDK - IMAGE URL : \(resultPictureData["url"])")
//                            }
//                        }
                        
                        if let facebookName = resultDict["name"]
                        {
                            var facebookImageUrl = "none"
                            if let resultPicture = resultDict["picture"] as? [String:AnyObject]
                            {
                                if let resultPictureData = resultPicture["data"] as? [String:AnyObject]
                                {
                                    facebookImageUrl = resultPictureData["url"]! as! String
                                }
                            }
                            self.loginUser((facebookName as! String), facebookThumbnailUrl: facebookImageUrl)
                        }
                        else
                        {
                            print("FBSDK - Error Processing Facebook Name")
//                            CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: "FBSDK - Error Processing Facebook Name" + error!.localizedDescription)
                            
                            // Record the server request attempt
                            Constants.Data.serverTries += 1
                            
                            // Try again
                            AWSPrepRequest(requestToCall: AWSLoginUser(secondaryAwsRequestObject: nil), delegate: self.awsRequestDelegate!).prepRequest()
                        }
                    }
                    else
                    {
                        print("FBSDK - Error Processing Result")
//                        CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: "FBSDK - Error Processing Result" + error!.localizedDescription)
                        
                        // Record the server request attempt
                        Constants.Data.serverTries += 1
                        
                        // Try again
                        AWSPrepRequest(requestToCall: AWSLoginUser(secondaryAwsRequestObject: nil), delegate: self.awsRequestDelegate!).prepRequest()
                    }
                }
        }
    }
    
    // Log in the user or create a new user
    func loginUser(_ facebookName: String, facebookThumbnailUrl: String)
    {
        print("AC - LU - FACEBOOK TOKEN: \(String(describing: self.facebookToken))")
        print("AC - LU - COGNITO ID: \(String(describing: Constants.credentialsProvider.identityId))")
        let json: NSDictionary = ["facebook_id" : self.facebookToken!.userID]
        
        let lambdaInvoker = AWSLambdaInvoker.default()
        lambdaInvoker.invokeFunction("Harvey-LoginUser", jsonObject: json, completionHandler:
            { (responseData, err) -> Void in
                
                if (err != nil)
                {
                    print("AC - FBSDK LOGIN - ERROR: \(String(describing: err))")
//                    CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: err.debugDescription)
                    
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
                    // Create a user object to save the data
                    let currentUser = User()
                    currentUser.userID = responseData as? String
                    currentUser.facebookID = self.facebookToken!.userID
                    currentUser.userName = facebookName
                    currentUser.userImage = UIImage(named: "PROFILE_DEFAULT.png")
                    
                    // The response will be the userID associated with the facebookID used, save the current user globally
                    Constants.Data.currentUser = currentUser
                    
//                    // Save the new login data to Core Data
//                    CoreDataFunctions().currentUserSave(user: currentUser)
                    
//                    // Reset the global User list with Core Data
//                    UtilityFunctions().resetUserListWithCoreData()
                    
//                    UtilityFunctions().registerPushNotifications()
                    
                    // If the secondary request object is not nil, process the carried (second) request; no need to
                    // pass the login response to the parent view controller since it did not explicitly call the login request
                    if let secondaryAwsRequestObject = self.secondaryAwsRequestObject
                    {
                        AWSPrepRequest(requestToCall: secondaryAwsRequestObject, delegate: self.awsRequestDelegate!).prepRequest()
                    }
                    else
                    {
                        // Notify the parent view that the AWS Login call completed successfully
                        if let parentVC = self.awsRequestDelegate
                        {
                            parentVC.processAwsReturn(self, success: true)
                        }
                    }
                    
                    // Download the user image
                    // Create a session object with the default configuration
                    if let url = URL(string: "http://graph.facebook.com/" + self.facebookToken!.userID + "/picture?type=large")
//                    if let url = URL(string: facebookThumbnailUrl)
                    {
                        let request = URLRequest(url: url)
                        let session = URLSession(configuration: .default)
                        let getFbImage = session.dataTask(with: request)
                        { (data, response, error) in
                            if let e = error
                            {
                                print("AC - FB IMAGE ERROR: \(e)")
                            }
                            else
                            {
                                if let res = response as? HTTPURLResponse
                                {
                                    print("AC - FB IMAGE RESPONSE CODE: \(res.statusCode)")
                                    if let imageData = data
                                    {
                                        Constants.Data.currentUser.userImage = UIImage(data: imageData)
                                    }
                                    else
                                    {
                                        print("AC - FB IMAGE IS NIL")
                                    }
                                }
                                else
                                {
                                    print("AC - FB IMAGE - NO RESPONSE CODE")
                                }
                            }
                        }
                        getFbImage.resume()
                    }
                }
        })
    }
}

class AWSLogoutUser
{
    
}

class AWSGetMapData : AWSRequestObject
{
    var userLocation: Float?
    
    required init(userLocation: Float?)
    {
        if let userLocation = userLocation
        {
            self.userLocation = userLocation
        }
    }
    
    // Use this request function when a Blob is within range of the user's location and the extra Blob data is needed
    override func makeRequest()
    {
//        print("AC-GMD: REQUESTING MAP DATA: \(String(describing: self.userLocation))")
        
        // Create a JSON object with the passed Blob ID and an indicator of whether or not the Blob data should be filtered (0 for no, 1 for yes)
        let json: NSDictionary = ["user_location" : self.userLocation]
        
        let lambdaInvoker = AWSLambdaInvoker.default()
        lambdaInvoker.invokeFunction("Harvey-GetMapData", jsonObject: json, completionHandler:
            { (response, err) -> Void in
                
                if (err != nil)
                {
                    print("AC-GMD: GET MAP DATA ERROR: \(String(describing: err))")
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
//                    print("AC-GMD RESPONSE:")
//                    print(response)
                    
                    // The data request was successful - reset all data arrays
                    Constants.Data.allSpot = [Spot]()
                    Constants.Data.allSpotRequest = [SpotRequest]()
                    Constants.Data.allHydro = [DataHydro]()
                    
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
                                        let addHydro = DataHydro()
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
//                                    print("AC-GMD - ADDED HYDRO DATA: \(addHydro.title)")
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
//                                    print("AC-GMD - ADDED SPOT RESPONSE DATA: \(addSpotRequest.title)")
                                    }
                                }
                            }
                        }
                        
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
                                        // First extract the SpotContent data
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
                                        addSpot.userID = spotRaw["user_id"] as! String
                                        addSpot.status = spotRaw["status"] as! String
                                        addSpot.lat = spotRaw["lat"] as! Double
                                        addSpot.lng = spotRaw["lng"] as! Double
                                        addSpot.spotContent = spotContent
                                        Constants.Data.allSpot.append(addSpot)
//                                    print("AC-GMD - ADDED SPOT DATA: \(addSpot.title)")
                                    }
                                }
                            }
                        }
                        
                        // Notify the parent view that the AWS call completed successfully
                        if let parentVC = self.awsRequestDelegate
                        {
//                            print("AC-GMD - CALLED PARENT")
                            parentVC.processAwsReturn(self, success: true)
                        }
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
        
        // Create some JSON to send the Spot data - everything must be a string
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
        
        // Create some JSON to send the SpotRequest data - everything must be a string
        var json = [String: Any]()
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
                    // Now that the SpotRequest has been created, add it to the global array
                    Constants.Data.allSpotRequest.append(self.spotRequest)
                    
                    // Notify the parent view that the AWS call completed successfully
                    if let parentVC = self.awsRequestDelegate
                    {
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
    
    required init(bucket: String!, uploadKey: String!, mediaURL: URL!)
    {
        self.bucket = bucket
        self.uploadKey = uploadKey
        self.mediaURL = mediaURL
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
        let json: NSDictionary = ["request" : randomIdType.rawValue]
        
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
