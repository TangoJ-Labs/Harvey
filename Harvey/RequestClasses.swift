//
//  RequestClasses.swift
//  Harvey
//
//  Created by Sean Hart on 9/8/17.
//  Copyright © 2017 TangoJ Labs, LLC. All rights reserved.
//

import FBSDKLoginKit
import UIKit


// Create a protocol with functions declared in other View Controllers implementing this protocol (delegate)
protocol RequestDelegate
{
    // A general handler to indicate that a Method finished
    func processRequestReturn(_ requestCalled: RequestObject, success: Bool)
}

/// A base class to group membership of all request functions
class RequestObject
{
    // Add a delegate variable which the parent view controller can pass its own delegate instance to and have access to the protocol
    // (and have its own functions called that are listed in the protocol)
    var requestDelegate: RequestDelegate?
    
    func makeRequest() {}
}

class RequestPrep
{
    // Add a delegate variable which the parent view controller can pass its own delegate instance to and have access to the protocol
    // (and have its own functions called that are listed in the protocol)
    var awsRequestDelegate: RequestDelegate!
    
    var requestToCall: RequestObject!
    
    required init(requestToCall: RequestObject, delegate: RequestDelegate)
    {
        self.requestToCall = requestToCall
        self.awsRequestDelegate = delegate
        self.requestToCall.requestDelegate = delegate
    }
    
    // Use this method to call passed requests
    func prepRequest()
    {
        self.requestToCall.makeRequest()
    }
}

class FBGetUserData: RequestObject, RequestDelegate
{
    var me: Bool!
    var facebookID: String!
    var graphString: String = "me"
    
    var facebookName: String?
    var facebookThumbnailUrl: String?
    
    required init(me: Bool!, facebookID: String!)
    {
        self.me = me
        self.facebookID = facebookID
        
        if !me
        {
            graphString = facebookID
        }
    }
    
    override func makeRequest()
    {
        print("RC-FBUD - MAKING GRAPH CALL")
        print("RC-FBUD: ME: \(me)")
        print("RC-FBUD: \(facebookID)")
        print("RC-FBUD: \(graphString)")
        let fbRequest = FBSDKGraphRequest(graphPath: graphString, parameters: ["fields": "id, email, name, picture"])
        fbRequest?.start
            {(connection: FBSDKGraphRequestConnection?, result: Any?, error: Error?) in
                
                if error != nil
                {
                    print("RC-FBUD - Error Getting Info \(String(describing: error))")
//                    CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: "FBSDK - Error Getting Info" + error!.localizedDescription)
                    
                    // Notify the parent view that the request completed with an error
                    if let parentVC = self.requestDelegate
                    {
                        parentVC.processRequestReturn(self, success: false)
                    }
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
                            self.facebookName = facebookName as? String
                            
                            if let resultPicture = resultDict["picture"] as? [String:AnyObject]
                            {
                                if let resultPictureData = resultPicture["data"] as? [String:AnyObject]
                                {
                                    self.facebookThumbnailUrl = resultPictureData["url"]! as? String
                                    
                                    // Now download the user thumbnail
                                    RequestPrep(requestToCall: FBDownloadUserImage(facebookID: self.facebookID, largeImage: false), delegate: self as RequestDelegate).prepRequest()
                                }
                            }
                            
                            // Loop through the user list and add the new data - don't rely on it being added by request class
                            userLoop: for user in Constants.Data.allUsers
                            {
                                if user.facebookID == self.facebookID
                                {
                                    user.name = self.facebookName
                                    
                                    // Save the new data to Core Data
                                    CoreDataFunctions().userSave(user: user)
                                    break userLoop
                                }
                            }
                            // If the user has just logged in, the currentUser facebookID may not have been assigned yet - only assign new values if it exists - otherwise, the values will be passed and assigned when more data exists
                            print("RC-FBUD UPDATE CURRENT USER NAME")
                            if Constants.Data.currentUser.facebookID != nil
                            {
                                print("RC-FBUD CURRENT USER: \(Constants.Data.currentUser.facebookID)")
                                print("RC-FBUD USER ADDING: \(self.facebookID)")
                                if Constants.Data.currentUser.facebookID == self.facebookID
                                {
                                    Constants.Data.currentUser.name = self.facebookName
                                    print("RC-FBUD UPDATED CURRENT USER NAME")
                                    // Save the new data to Core Data
                                    CoreDataFunctions().currentUserSave(user: Constants.Data.currentUser)
                                }
                            }
                            
                            // Notify the parent view that the request completed successfully
                            if let parentVC = self.requestDelegate
                            {
                                print("RC-FBUD - CALLED PARENT")
                                parentVC.processRequestReturn(self, success: true)
                            }
                        }
                        else
                        {
                            print("RC-FBUD - Error Processing Facebook Name")
//                            CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: "FBSDK - Error Processing Facebook Name" + error!.localizedDescription)
                            
                            // Notify the parent view that the request completed with an error
                            if let parentVC = self.requestDelegate
                            {
                                parentVC.processRequestReturn(self, success: false)
                            }
                        }
                    }
                    else
                    {
                        print("RC-FBUD - Error Processing Result")
//                        CoreDataFunctions().logErrorSave(function: NSStringFromClass(type(of: self)), errorString: "FBSDK - Error Processing Result" + error!.localizedDescription)
                        
                        // Notify the parent view that the request completed with an error
                        if let parentVC = self.requestDelegate
                        {
                            parentVC.processRequestReturn(self, success: false)
                        }
                    }
                }
        }
    }
    
    func processRequestReturn(_ requestCalled: RequestObject, success: Bool)
    {
        // Process the return data based on the method used
        switch requestCalled
        {
        case _ as FBDownloadUserImage:
            if success
            {
                print("AC-FBDownloadUserImage SUCCESS")
            }
            else
            {
                print("AC-FBDownloadUserImage FAILURE")
            }
        default:
            print("AC-processRequestReturn DEFAULT")
        }
    }
}

class FBDownloadUserImage: RequestObject
{
    var facebookID: String!
    var large: Bool = false
    var sizeString: String = "small"
    
    required init(facebookID: String!, largeImage: Bool?)
    {
        self.facebookID = facebookID
        if let large = largeImage
        {
            self.large = large
            if large
            {
                self.sizeString = "large"
            }
        }
    }
    
    // FBSDK METHOD - Get user data from FB before attempting to log in via AWS
    override func makeRequest()
    {
        print("RC-FBI: \(facebookID) - \(sizeString)")
        // Download the user image
        // Create a session object with the default configuration
        if let url = URL(string: "http://graph.facebook.com/" + facebookID + "/picture?type=" + sizeString)
        {
            let request = URLRequest(url: url)
            let session = URLSession(configuration: .default)
            let getFbImage = session.dataTask(with: request)
            { (data, response, error) in
                if let e = error
                {
                    print("RC-FBI ERROR: \(e)")
                    
                    // Notify the parent view that the request completed with an error
                    if let parentVC = self.requestDelegate
                    {
                        parentVC.processRequestReturn(self, success: false)
                    }
                }
                else
                {
                    if let res = response as? HTTPURLResponse
                    {
                        print("RC-FBI RESPONSE CODE: \(res.statusCode) FOR: \(self.facebookID), \(self.large)")
                        if let imageData = data
                        {
                            let userImage = UIImage(data: imageData)
                            
                            // Add the user image to the proper user in the global array
                            // Go ahead and save each image in the other if the other is empty
                            userLoop: for user in Constants.Data.allUsers
                            {
                                if user.facebookID == self.facebookID
                                {
                                    // If the large image was requested, save it to the main user image, otherwise just save it to the thumbnail
                                    if self.large
                                    {
                                        user.image = userImage
                                        if user.thumbnail == nil
                                        {
                                            user.thumbnail = userImage
                                        }
                                    }
                                    else
                                    {
                                        user.thumbnail = userImage
                                        if user.image == nil
                                        {
                                            user.image = userImage
                                        }
                                    }
                                    
                                    // Save the new data to Core Data
                                    CoreDataFunctions().userSave(user: user)
                                    break userLoop
                                }
                            }
                            
                            // Modify the global current user - only assign if the fbID exists
                            // If the large image does not exist, save the small one in its place, and vice-versa
                            // request may have been made prior to assigning current user values
                            if Constants.Data.currentUser.facebookID != nil
                            {
                                if Constants.Data.currentUser.facebookID == self.facebookID
                                {
                                    // If the large image was requested, save it to the main user image, otherwise just save it to the thumbnail
                                    if self.large
                                    {
                                        Constants.Data.currentUser.image = userImage
                                        if Constants.Data.currentUser.thumbnail == nil
                                        {
                                            Constants.Data.currentUser.thumbnail = userImage
                                        }
                                    }
                                    else
                                    {
                                        Constants.Data.currentUser.thumbnail = userImage
                                        if Constants.Data.currentUser.image == nil
                                        {
                                            Constants.Data.currentUser.image = userImage
                                        }
                                    }
                                    
                                    // Save the new data to Core Data
                                    CoreDataFunctions().currentUserSave(user: Constants.Data.currentUser)
                                }
                            }
                            
                            // Notify the parent view that the request completed successfully
                            if let parentVC = self.requestDelegate
                            {
                                parentVC.processRequestReturn(self, success: true)
                            }
                        }
                        else
                        {
                            print("RC-FBI IS NIL")
                            // Notify the parent view that the request completed with an error
                            if let parentVC = self.requestDelegate
                            {
                                parentVC.processRequestReturn(self, success: false)
                            }
                        }
                    }
                    else
                    {
                        print("RC-FBI - NO RESPONSE CODE")
                        // Notify the parent view that the request completed with an error
                        if let parentVC = self.requestDelegate
                        {
                            parentVC.processRequestReturn(self, success: false)
                        }
                    }
                }
            }
            getFbImage.resume()
        }
    }
}

class APITest: RequestObject
{
    let url = URL(string: "http://192.168.1.5:5000/api/app/test")
    
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
            
            print("RC-API TEST")
            var request = URLRequest(url: url!)
            request.httpMethod = "POST"
            request.timeoutInterval = Constants.Settings.requestTimeout
            request.httpBody = jsonData
            request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            let session = URLSession(configuration: .default)
            let apiTest = session.dataTask(with: request)
            { (data, response, error) in
                if let res = response as? HTTPURLResponse
                {
                    print("RC-API TEST - RESPONSE CODE: \(res.statusCode)")
                }
                if let e = error
                {
                    print("RC-API TEST: \(e)")
                    
                    // Notify the parent view that the request completed with an error
                    if let parentVC = self.requestDelegate
                    {
                        parentVC.processRequestReturn(self, success: false)
                    }
                }
                else
                {
                    if let returnData = String(data: data as! Data, encoding: .utf8)
                    {
                        print("RC-API TEST - RETURN DATA: \(returnData)")
                    }
                    else
                    {
                        print("RC-API TEST - RETURN DATA ERROR")
                        // Notify the parent view that the request completed with an error
                        if let parentVC = self.requestDelegate
                        {
                            parentVC.processRequestReturn(self, success: false)
                        }
                    }
                }
            }
            apiTest.resume()
        }
        else
        {
            
        }
    }
}
