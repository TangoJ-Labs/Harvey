//
//  CoreDataFunctions.swift
//  Harvey
//
//  Created by Sean Hart on 9/2/17.
//  Copyright © 2017 tangojlabs. All rights reserved.
//

import CoreData
import UIKit


class CoreDataFunctions: AWSRequestDelegate
{
    
    // MARK: TUTORIAL VIEWS
    func tutorialViewSave(tutorialView: TutorialView)
    {
        // Try to retrieve the Tutorial Views data from Core Data
        var tutorialViewArray = [TutorialView]()
        let moc = DataController().managedObjectContext
        let tutorialViewFetch: NSFetchRequest<TutorialView> = TutorialView.fetchRequest()
        // Create an empty Tutorial Views list in case the Core Data request fails
        do
        {
            tutorialViewArray = try moc.fetch(tutorialViewFetch)
        }
        catch
        {
            fatalError("Failed to fetch TutorialView: \(error)")
        }
        // If the return has no content, no Tutorial Views have been saved
        if tutorialViewArray.count == 0
        {
            // Save the Tutorial Views data in Core Data
            let entity = NSEntityDescription.insertNewObject(forEntityName: "TutorialView", into: moc) as! TutorialView
            if let tutorialMapViewDatetime = tutorialView.tutorialMapViewDatetime
            {
                entity.setValue(tutorialMapViewDatetime, forKey: "tutorialMapViewDatetime")
            }
        }
        else
        {
            // Replace the Tutorial Views data to ensure that the latest data is used
            if let tutorialMapViewDatetime = tutorialView.tutorialMapViewDatetime
            {
                tutorialViewArray[0].tutorialMapViewDatetime = tutorialMapViewDatetime
            }
        }
        // Save the Entity
        do
        {
            try moc.save()
        }
        catch
        {
            fatalError("Failure to save context: \(error)")
        }
    }
    
    func tutorialViewRetrieve() -> TutorialView
    {
        // Access Core Data
        // Retrieve the Tutorial Views data from Core Data
        let moc = DataController().managedObjectContext
        let tutorialViewFetch: NSFetchRequest<TutorialView> = TutorialView.fetchRequest()
        
        // Create an empty Tutorial Views list in case the Core Data request fails
        var tutorialViewsArray = [TutorialView]()
        // Create a new Tutorial Views entity
        let tutorialView = NSEntityDescription.insertNewObject(forEntityName: "TutorialView", into: moc) as! TutorialView
        do
        {
            tutorialViewsArray = try moc.fetch(tutorialViewFetch)
        }
        catch
        {
            fatalError("Failed to fetch TutorialView: \(error)")
        }
        if tutorialViewsArray.count > 0
        {
            // Sometimes more than one record may be saved - use the one with the most data
            var tutorialViewHighestDataCount: Int = 0
            var tutorialViewArrayIndexUse: Int = 0
            for (tvIndex, tutorialView) in tutorialViewsArray.enumerated()
            {
                var tutorialViewDataCount: Int = 0
                if tutorialView.tutorialMapViewDatetime != nil
                {
                    tutorialViewDataCount += 1
                }
                if tutorialViewDataCount > tutorialViewHighestDataCount
                {
                    tutorialViewHighestDataCount = tutorialViewDataCount
                    tutorialViewArrayIndexUse = tvIndex
                }
            }
            
            if let tutorialMapViewDatetime = tutorialViewsArray[tutorialViewArrayIndexUse].tutorialMapViewDatetime
            {
                tutorialView.setValue(tutorialMapViewDatetime, forKey: "tutorialMapViewDatetime")
            }
        }
        print("CD-TVR: CHECK A: \(tutorialView.tutorialMapViewDatetime)")
        return tutorialView
    }
    
    
    // MARK: MAP SETTINGS
    func mapSettingSaveFromGlobalSettings()
    {
        print("CD: SAVE MAP SETTING HYDRO: \(Constants.Settings.menuMapHydro)")
        print("CD: SAVE MAP SETTING SPOT: \(Constants.Settings.menuMapSpot)")
        print("CD: SAVE MAP SETTING TRAFFIC: \(Constants.Settings.menuMapTraffic)")
        print("CD: SAVE MAP SETTING TIME: \(Constants.Settings.menuMapTimeFilter)")
        // Try to retrieve the Map Settings data from Core Data
        var mapSettingArray = [MapSetting]()
        let moc = DataController().managedObjectContext
        let mapSettingFetch: NSFetchRequest<MapSetting> = MapSetting.fetchRequest()
        // Create an empty Map Settings list in case the Core Data request fails
        do
        {
            mapSettingArray = try moc.fetch(mapSettingFetch)
        }
        catch
        {
            fatalError("Failed to fetch MapSetting: \(error)")
        }
        // If the return has no content, no Map Settings have been saved
        if mapSettingArray.count == 0
        {
            // Save the Map Setting data in Core Data
            let entity = NSEntityDescription.insertNewObject(forEntityName: "MapSetting", into: moc) as! MapSetting
            entity.setValue(Int32(Constants.Settings.menuMapHydro.rawValue), forKey: "menuMapHydro")
            entity.setValue(Int32(Constants.Settings.menuMapSpot.rawValue), forKey: "menuMapSpot")
            entity.setValue(Int32(Constants.Settings.menuMapTraffic.rawValue), forKey: "menuMapTraffic")
            entity.setValue(Int32(Constants.Settings.menuMapTimeFilter.rawValue), forKey: "menuMapTimeFilter")
        }
        else
        {
            // Replace the Map Setting data to ensure that the latest data is used
            mapSettingArray[0].menuMapHydro = Int32(Constants.Settings.menuMapHydro.rawValue)
            mapSettingArray[0].menuMapSpot = Int32(Constants.Settings.menuMapSpot.rawValue)
            mapSettingArray[0].menuMapTraffic = Int32(Constants.Settings.menuMapTraffic.rawValue)
            mapSettingArray[0].menuMapTimeFilter = Int32(Constants.Settings.menuMapTimeFilter.rawValue)
        }
        // Save the Entity
        do
        {
            try moc.save()
        }
        catch
        {
            fatalError("Failure to save context: \(error)")
        }
    }
//    func mapSettingSave(mapSetting: MapSetting)
//    {
//        // Try to retrieve the Map Settings data from Core Data
//        var mapSettingArray = [MapSetting]()
//        let moc = DataController().managedObjectContext
//        let mapSettingFetch: NSFetchRequest<MapSetting> = MapSetting.fetchRequest()
//        // Create an empty Map Settings list in case the Core Data request fails
//        do
//        {
//            mapSettingArray = try moc.fetch(mapSettingFetch)
//        }
//        catch
//        {
//            fatalError("Failed to fetch MapSetting: \(error)")
//        }
//        // If the return has no content, no Map Settings have been saved
//        if mapSettingArray.count == 0
//        {
//            // Save the Map Setting data in Core Data
//            let entity = NSEntityDescription.insertNewObject(forEntityName: "MapSetting", into: moc) as! MapSetting
//            if let menuMapHydro = mapSetting.menuMapHydro
//            {
//                entity.setValue(menuMapHydro, forKey: "menuMapHydro")
//            }
//            if let menuMapSpot = mapSetting.menuMapSpot
//            {
//                entity.setValue(menuMapSpot, forKey: "menuMapSpot")
//            }
//            if let menuMapTraffic = mapSetting.menuMapTraffic
//            {
//                entity.setValue(menuMapTraffic, forKey: "menuMapTraffic")
//            }
//            if let menuMapTimeFilter = mapSetting.menuMapTimeFilter
//            {
//                entity.setValue(menuMapTimeFilter, forKey: "menuMapTimeFilter")
//            }
//        }
//        else
//        {
//            // Replace the Map Setting data to ensure that the latest data is used
//            if let menuMapHydro = mapSetting.menuMapHydro
//            {
//                mapSettingArray[0].menuMapHydro = menuMapHydro
//            }
//            if let menuMapSpot = mapSetting.menuMapSpot
//            {
//                mapSettingArray[0].menuMapSpot = menuMapSpot
//            }
//            if let menuMapTraffic = mapSetting.menuMapTraffic
//            {
//                mapSettingArray[0].menuMapTraffic = menuMapTraffic
//            }
//            if let menuMapTimeFilter = mapSetting.menuMapTimeFilter
//            {
//                mapSettingArray[0].menuMapTimeFilter = menuMapTimeFilter
//            }
//        }
//        // Save the Entity
//        do
//        {
//            try moc.save()
//        }
//        catch
//        {
//            fatalError("Failure to save context: \(error)")
//        }
//    }
    
    func mapSettingRetrieve() -> [MapSetting]
    {
        // Try to retrieve the Map Setting setting from Core Data
        let moc = DataController().managedObjectContext
        let mapSettingFetch: NSFetchRequest<MapSetting> = MapSetting.fetchRequest()
        
        // Create an empty MapSetting list in case the Core Data request fails
        var mapSetting = [MapSetting]()
        do
        {
            mapSetting = try moc.fetch(mapSettingFetch)
        }
        catch
        {
            fatalError("Failed to fetch locationManagerSetting: \(error)")
        }
        
        // Only return the first entity - only one should be saved
        return mapSetting
    }
    
    
//    // MARK: LOGS - ERRORS
//    func logErrorSave(function: String, errorString: String)
//    {
//        let timestamp: Double = Date().timeIntervalSince1970
//        
//        // Save a log entry for a function or AWS error
//        let moc = DataController().managedObjectContext
//        let entity = NSEntityDescription.insertNewObject(forEntityName: "LogError", into: moc)
//        entity.setValue(function, forKey: "function")
//        entity.setValue(errorString, forKey: "errorString")
//        entity.setValue(timestamp, forKey: "timestamp")
//        
//        // Save the Entity
//        do
//        {
//            try moc.save()
//        }
//        catch
//        {
//            fatalError("Failure to save context: \(error)")
//        }
//    }
//    
//    func logErrorRetrieve(andDelete: Bool) -> [LogError]
//    {
//        // Retrieve the Blob notification data from Core Data
//        let moc = DataController().managedObjectContext
//        let logErrorFetch: NSFetchRequest<LogError> = LogError.fetchRequest()
//        
//        // Create an empty blobNotifications list in case the Core Data request fails
//        var logErrors = [LogError]()
//        do
//        {
//            logErrors = try moc.fetch(logErrorFetch)
//            
//            // If indicated, delete each object one at a time
//            if andDelete
//            {
//                for logError in logErrors
//                {
//                    moc.delete(logError)
//                }
//                
//                // Save the Deletions
//                do
//                {
//                    try moc.save()
//                }
//                catch
//                {
//                    fatalError("Failure to save context: \(error)")
//                }
//            }
//        }
//        catch
//        {
//            fatalError("Failed to fetch log errors: \(error)")
//        }
//        
//        // logErrors will return EVEN IF DELETED (they are not deleted from array, just Core Data)
//        return logErrors
//    }
//    
//    
//    // MARK: LOGS - USERFLOW
//    
//    func logUserflowSave(viewController: String, action: String)
//    {
//        let timestamp: Double = Date().timeIntervalSince1970
//        
//        // Save a log entry for a function or AWS error
//        let moc = DataController().managedObjectContext
//        let entity = NSEntityDescription.insertNewObject(forEntityName: "LogUserflow", into: moc)
//        entity.setValue(viewController, forKey: "viewController")
//        entity.setValue(action, forKey: "action")
//        entity.setValue(timestamp, forKey: "timestamp")
//        
//        // Save the Entity
//        do
//        {
//            try moc.save()
//        }
//        catch
//        {
//            fatalError("Failure to save context: \(error)")
//        }
//    }
//    
//    func logUserflowRetrieve(andDelete: Bool) -> [LogUserflow]
//    {
//        // Retrieve the Blob notification data from Core Data
//        let moc = DataController().managedObjectContext
//        let logUserflowFetch: NSFetchRequest<LogUserflow> = LogUserflow.fetchRequest()
//        
//        // Create an empty blobNotifications list in case the Core Data request fails
//        var logUserflows = [LogUserflow]()
//        do
//        {
//            logUserflows = try moc.fetch(logUserflowFetch)
//            
//            // If indicated, delete each object one at a time
//            if andDelete
//            {
//                for logUserflow in logUserflows
//                {
//                    moc.delete(logUserflow)
//                }
//                
//                // Save the Deletions
//                do
//                {
//                    try moc.save()
//                }
//                catch
//                {
//                    fatalError("Failure to save context: \(error)")
//                }
//            }
//        }
//        catch
//        {
//            fatalError("Failed to fetch log errors: \(error)")
//        }
//        
//        // logUserflows will return EVEN IF DELETED (they are not deleted from array, just Core Data)
//        return logUserflows
//    }
//    
//    
//    
//    // MARK: CORE DATA PROCESSING FUNCTIONS
//    
//    // Called when the app starts up - process the logs saved in the previous session and upload to AWS
//    func processLogs()
//    {
//        // Retrieve the Error Logs
//        let logErrors = logErrorRetrieve(andDelete: false)
//        
//        var logErrorArray = [[String]]()
//        for logError in logErrors
//        {
//            var logErrorSubArray = [String]()
//            logErrorSubArray.append(logError.function!)
//            logErrorSubArray.append(String(format:"%f", (logError.timestamp?.doubleValue)!))
//            logErrorSubArray.append(logError.errorString!)
//            
//            logErrorArray.append(logErrorSubArray)
//        }
//        
//        // Upload to AWS
//        AWSPrepRequest(requestToCall: AWSLog(logType: Constants.LogType.error, logArray: logErrorArray), delegate: self as AWSRequestDelegate).prepRequest()
//        
//        // Delete all Error Logs
//        _ = logErrorRetrieve(andDelete: true)
//        
//        // Retrieve the Userflow Logs
//        let logUserflows = logUserflowRetrieve(andDelete: false)
//        
//        var logUserflowArray = [[String]]()
//        for logUserflow in logUserflows
//        {
//            var logUserflowSubArray = [String]()
//            logUserflowSubArray.append(logUserflow.viewController!)
//            logUserflowSubArray.append(String(format:"%f", (logUserflow.timestamp?.doubleValue)!))
//            logUserflowSubArray.append(logUserflow.action!)
//            
//            logUserflowArray.append(logUserflowSubArray)
//        }
//        
//        // Upload to AWS
//        AWSPrepRequest(requestToCall: AWSLog(logType: Constants.LogType.userflow, logArray: logUserflowArray), delegate: self as AWSRequestDelegate).prepRequest()
//        
//        // Delete all Userflow Logs
//        _ = logUserflowRetrieve(andDelete: true)
//    }
    
    
    // MARK: AWS DELEGATE METHODS
    
    func showLoginScreen()
    {
        print("CDF - SHOW LOGIN SCREEN")
    }
    
    func processAwsReturn(_ objectType: AWSRequestObject, success: Bool)
    {
        DispatchQueue.main.async(execute:
            {
                // Process the return data based on the method used
                switch objectType
                {
//                case _ as AWSLog:
//                    if !success
//                    {
//                        print("CDF - AWSLog ERROR")
//                    }
                default:
                    print("CDF - DEFAULT: THERE WAS AN ISSUE WITH THE DATA RETURNED FROM AWS")
                }
        })
    }
    
}
