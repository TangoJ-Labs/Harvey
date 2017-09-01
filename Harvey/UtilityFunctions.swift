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
