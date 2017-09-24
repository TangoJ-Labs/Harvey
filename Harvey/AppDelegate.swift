//
//  AppDelegate.swift
//  Harvey
//
//  Created by Sean Hart on 8/28/17.
//  Copyright © 2017 TangoJ Labs, LLC. All rights reserved.
//

import AWSCore
import AWSCognito
import CoreData
import FBSDKCoreKit
import FBSDKLoginKit
import GoogleMaps
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, AWSRequestDelegate
{
    var window: UIWindow?
    let navController = UINavigationController()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool
    {
        print("didFinishLaunchingWithOptions")
        if let infoDict = Bundle.main.infoDictionary
        {
            if let bundleVersion =  infoDict["CFBundleShortVersionString"]
            {
                print("AD - BUNDLE VERSION: \(bundleVersion)")
                Constants.Settings.appVersion = bundleVersion as! String
            }
        }
        print("AD-TIMESTAMP: \(Date().timeIntervalSince1970)")
        print("AD-TIMESTAMP - 12hr: \(Date().timeIntervalSince1970 - (60 * 60 * 12))")
        // Google Maps Prep
        GMSServices.provideAPIKey(Constants.Settings.gKey)
//        GMSPlacesClient.provideAPIKey(Constants.Settings.gKey)
        
        // AWS Cognito Prep
        let configuration = AWSServiceConfiguration(region: Constants.Strings.awsRegion, credentialsProvider: Constants.credentialsProvider)
        AWSServiceManager.default().defaultServiceConfiguration = configuration
        
        // FacebookSDK Prep
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
        
        UIApplication.shared.isStatusBarHidden = false
        UIApplication.shared.statusBarStyle = Constants.Settings.statusBarStyle
        
        // Check to see if the facebook user id is already in the FBSDK
        if let facebookToken = FBSDKAccessToken.current()
        {
            print(facebookToken.tokenString)
            // Request the global app settings
            AWSPrepRequest(requestToCall: AWSGetSettings(), delegate: self as AWSRequestDelegate).prepRequest()
            
            // Try to retrieve the current user from Core Data
            let currentUser = CoreDataFunctions().currentUserRetrieve()
            if currentUser.userID != nil
            {
                Constants.Data.currentUser = currentUser
            }
            else
            {
                // The user data is missing - log the user out and have them log in again
                let loginManager = FBSDKLoginManager()
                loginManager.logOut()
                
                pushLoginVC()
            }
            
            // Prepare the root View Controller and make visible
            let mapViewController = MapViewController()
            if let status = Constants.Data.currentUser.status
            {
                if status != "eula_privacy_none"
                {
                    mapViewController.showAgreement = false
                    
                }
            }
            self.navController.pushViewController(mapViewController, animated: false)
            self.navController.navigationBar.barTintColor = Constants.Colors.colorOrangeOpaque
            
            self.window = UIWindow(frame: UIScreen.main.bounds)
            self.window!.rootViewController = self.navController
            self.window!.makeKeyAndVisible()
        }
        else
        {
            print("AD - NOT LOGGED IN")
            pushLoginVC()
        }
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication)
    {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication)
    {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication)
    {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication)
    {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
        // For the FacebookSDK
        FBSDKAppEvents.activateApp()
    }

    func applicationWillTerminate(_ application: UIApplication)
    {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        self.saveContext()
    }
    
    // For the FacebookSDK
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool
    {
        return FBSDKApplicationDelegate.sharedInstance().application(application, open: url, sourceApplication: sourceApplication, annotation: annotation)
    }
    
    
    // MARK: CUSTOM METHODS
    
    func pushLoginVC()
    {
        // Prepare the root View Controller and make visible
        let loginViewController = LoginViewController()
        self.navController.pushViewController(loginViewController, animated: false)
        self.navController.navigationBar.barTintColor = Constants.Colors.colorOrangeOpaque
        
        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.window!.rootViewController = self.navController
        self.window!.makeKeyAndVisible()
    }

    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer =
        {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: "Harvey")
        container.loadPersistentStores(completionHandler:
            { (storeDescription, error) in
            if let error = error as NSError?
            {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving support

    func saveContext ()
    {
        let context = persistentContainer.viewContext
        if context.hasChanges
        {
            do
            {
                try context.save()
            }
            catch
            {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    
    // MARK: AWS DELEGATE METHODS
    
    func showLoginScreen()
    {
        print("AD - SHOW LOGIN SCREEN")
    }
    
    func processAwsReturn(_ objectType: AWSRequestObject, success: Bool)
    {
        DispatchQueue.main.async(execute:
            {
                // Process the return data based on the method used
                switch objectType
                {
                case _ as AWSGetSettings:
                    if success
                    {
                        print("AD - SETTINGS RETURN - SUCCESS")
                    }
                    else
                    {
                        print("AD - SETTINGS RETURN - FAILURE")
                    }
                default:
                    print("AD-DEFAULT: THERE WAS AN ISSUE WITH THE DATA RETURNED FROM AWS")
                }
        })
    }
}

