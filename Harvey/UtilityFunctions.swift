//
//  UtilityFunctions.swift
//  Harvey
//
//  Created by Sean Hart on 8/28/17.
//  Copyright © 2017 tangojlabs. All rights reserved.
//

import AWSCognito
import UIKit

class UtilityFunctions: AWSRequestDelegate
{
    // Create an alert screen with only an acknowledgment option (an "OK" button)
    func createAlertOkView(_ title: String, message: String) -> UIAlertController
    {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default)
        { (result : UIAlertAction) -> Void in
            print("OK")
        }
        alertController.addAction(okAction)
        
        return alertController
    }
    // Create an alert screen with only an acknowledgment option (an "OK" button)
    func createAlertOkViewInTopVC(_ title: String, message: String)
    {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default)
        { (result : UIAlertAction) -> Void in
            print("OK")
        }
        alertController.addAction(okAction)
//        self.present(alertController, animated: true, completion: nil)
//        alertController.show()
    }
    
    //https://www.hackingwithswift.com/example-code/media/how-to-save-a-uiimage-to-a-file-using-uiimagepngrepresentation
    // Save an image to a local png file
    func generateImageUrl(image: UIImage, fileName: String) -> URL
    {
        let fileURL = URL(fileURLWithPath: fileName)
        if let data = UIImagePNGRepresentation(image) {
            let filename = getDocumentsDirectory().appendingPathComponent("\(fileName).jpg")
            try? data.write(to: filename)
        }
        
        return fileURL
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
    func updateUserConnections()
    {
        for user in Constants.Data.allUsers
        {
            let previousSetting = user.connection
            var userBlocked = false
            for blockedUserID in Constants.Data.allUserBlockList
            {
                if user.userID == blockedUserID
                {
                    userBlocked = true
                    user.connection = "blocked"
                }
            }
            if !userBlocked
            {
                user.connection = "na"
            }
            // Only re-save the user data if the connection setting changed
            if previousSetting != user.connection
            {
                // Save the current user data to Core Data
                CoreDataFunctions().userSave(user: user, deleteUser: false)
            }
        }
    }
    
    
    // MARK: AWS DELEGATE METHODS
    
    func showLoginScreen()
    {
        print("BAVC - SHOW LOGIN SCREEN")
    }
    
    func processAwsReturn(_ objectType: AWSRequestObject, success: Bool)
    {
//        DispatchQueue.main.async(execute:
//            {
//                // Process the return data based on the method used
//                switch objectType
//                {
//                case _ as AWSGetSingleUserData:
//                    // Updates to the UserData are commanded from FBGetUserProfileData, so no action is needed
//                    print("UF-FBGUPD RETURN")
//                default:
//                    print("UF-DEFAULT: THERE WAS AN ISSUE WITH THE DATA RETURNED FROM AWS")
//                }
//        })
    }
}
