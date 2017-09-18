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
//        moc.mergePolicy = NSMergePolicy.overwrite
        moc.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
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
        moc.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
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
        print("CD-TVR: CHECK A: \(String(describing: tutorialView.tutorialMapViewDatetime))")
        return tutorialView
    }
    
    
    // MARK: CURRENT USER
    func currentUserSave(user: User, deleteUser: Bool)
    {
        print("CD-CUS - USER NAME: \(String(describing: user.name))")
        let moc = DataController().managedObjectContext
//        moc.mergePolicy = NSMergePolicy.overwrite
        moc.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
//        // Delete the current data
//        let deleteFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "CurrentUser")
//        let deleteRequest = NSBatchDeleteRequest(fetchRequest: deleteFetch)
//        do
//        {
//            let result = try moc.execute(deleteRequest)
//            print("CD-CUS - OLD DATA DELETE RESULT: \(result)")
//        }
//        catch
//        {
//            fatalError("Failed to delete CurrentUser: \(error)")
//        }
        // Try to retrieve the Current User data from Core Data
        var currentUserArray = [CurrentUser]()
        let currentUserFetch: NSFetchRequest<CurrentUser> = CurrentUser.fetchRequest()
        do
        {
            currentUserArray = try moc.fetch(currentUserFetch)
            print("CD-CUS - currentUserArray: \(currentUserArray)")
        }
        catch
        {
            fatalError("Failed to fetch CurrentUser: \(error)")
        }
        // If the user needs to be deleted, just leave the array empty
        if !deleteUser
        {
            // If the return has no content, no current User have been saved
            if currentUserArray.count == 0
            {
                print("CD-CUS - NEW")
                // Save the Current User data in Core Data
                let entity = NSEntityDescription.insertNewObject(forEntityName: "CurrentUser", into: moc) as! CurrentUser
                entity.setValue(user.userID, forKey: "userID")
                entity.setValue(user.facebookID, forKey: "facebookID")
                entity.setValue(user.type, forKey: "type")
                entity.setValue(user.status, forKey: "status")
                entity.setValue(user.datetime, forKey: "datetime")
                entity.setValue(user.connection, forKey: "connection")
                if let userName = user.name
                {
                    entity.setValue(userName, forKey: "name")
                }
                if let userImage = user.image
                {
                    entity.setValue(UIImagePNGRepresentation(userImage)! as NSData, forKey: "image")
                }
                if let userThumbnail = user.thumbnail
                {
                    entity.setValue(UIImagePNGRepresentation(userThumbnail)! as NSData, forKey: "thumbnail")
                }
            }
            else
            {
                print("CD-CUS - EXISTS")
                // Replace the Current User data to ensure that the latest data is used
                currentUserArray[0].userID = user.userID
                currentUserArray[0].facebookID = user.facebookID
                currentUserArray[0].type = user.type
                currentUserArray[0].status = user.status
                currentUserArray[0].connection = user.connection
                if let datetime = user.datetime
                {
                    currentUserArray[0].datetime = datetime as NSDate
                }
                else
                {
                    currentUserArray[0].datetime = NSDate(timeIntervalSinceNow: 0)
                }
                if let userName = user.name
                {
                    currentUserArray[0].name = userName
                }
                if let userImage = user.image
                {
                    currentUserArray[0].image = UIImagePNGRepresentation(userImage)! as NSData
                }
                if let userThumbnail = user.thumbnail
                {
                    currentUserArray[0].thumbnail = UIImagePNGRepresentation(userThumbnail)! as NSData
                }
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
    
    func currentUserRetrieve() -> User
    {
        // Access Core Data
        // Retrieve the Current User data from Core Data
        let moc = DataController().managedObjectContext
        moc.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        let currentUserFetch: NSFetchRequest<CurrentUser> = CurrentUser.fetchRequest()
        
        // Create an empty CurrentUser list in case the Core Data request fails
        var currentUserArray = [CurrentUser]()
        do
        {
            currentUserArray = try moc.fetch(currentUserFetch)
        }
        catch
        {
            fatalError("Failed to fetch CurrentUser: \(error)")
        }
        // Create a new Current User entity
        let currentUser = User()
        if currentUserArray.count > 0
        {
            // Use the first object - only one should be saved
            currentUser.userID = currentUserArray[0].userID
            currentUser.facebookID = currentUserArray[0].facebookID
            currentUser.type = currentUserArray[0].type
            currentUser.status = currentUserArray[0].status
            if let connection = currentUserArray[0].connection
            {
                currentUser.connection = connection as String
            }
            else
            {
                currentUser.connection = "na"
            }
            if let datetimeRaw = currentUserArray[0].datetime
            {
                currentUser.datetime = datetimeRaw as Date
            }
            else
            {
                currentUser.datetime = Date(timeIntervalSinceNow: 0)
            }
            if let userName = currentUserArray[0].name
            {
                currentUser.name = userName
            }
            if let userImage = currentUserArray[0].image
            {
                currentUser.image = UIImage(data: userImage as Data)
            }
            if let userThumbnail = currentUserArray[0].thumbnail
            {
                currentUser.thumbnail = UIImage(data: userThumbnail as Data)
            }
        }
        return currentUser
    }
    
    
    // MARK: USER
    func userSave(user: User, deleteUser: Bool)
    {
        // Try to retrieve the User data from Core Data
        var userArray = [UserCD]()
        let moc = DataController().managedObjectContext
        moc.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        let userFetch: NSFetchRequest<UserCD> = UserCD.fetchRequest()
        // Create an empty User list in case the Core Data request fails
        do
        {
            userArray = try moc.fetch(userFetch)
        }
        catch
        {
            fatalError("Failed to fetch User: \(error)")
        }
        // If the user needs to be deleted, just leave the array empty
        if !deleteUser
        {
            // Check whether the user exists, otherwise add the user
            var userExists = false
            userLoop: for (uIndex, userCheck) in userArray.enumerated()
            {
                if let checkUserID = userCheck.userID
                {
                    if checkUserID == user.userID
                    {
                        // The user exists, so update the Core Data
                        userExists = true
                        // Replace the User data to ensure that the latest data is used
                        userArray[uIndex].userID = user.userID
                        userArray[uIndex].facebookID = user.facebookID
                        userArray[uIndex].type = user.type
                        userArray[uIndex].status = user.status
                        userArray[uIndex].connection = user.connection
                        if let datetimeRaw = user.datetime
                        {
                            userArray[uIndex].datetime = datetimeRaw as NSDate
                        }
                        else
                        {
                            userArray[uIndex].datetime = NSDate(timeIntervalSinceNow: 0)
                        }
                        if let userName = user.name
                        {
                            userArray[uIndex].name = userName
                        }
                        if let userImage = user.image
                        {
                            userArray[uIndex].image = UIImagePNGRepresentation(userImage)! as NSData
                        }
                        if let userThumbnail = user.thumbnail
                        {
                            userArray[uIndex].thumbnail = UIImagePNGRepresentation(userThumbnail)! as NSData
                        }
                        
                        break userLoop
                    }
                }
            }
            // If the user does not exist, add a new entity
            if !userExists
            {
                print("CD-US - NOT EXIST: \(user.userID)")
                let newUser = NSEntityDescription.insertNewObject(forEntityName: "UserCD", into: moc) as! UserCD
                newUser.setValue(user.userID, forKey: "userID")
                newUser.setValue(user.facebookID, forKey: "facebookID")
                newUser.setValue(user.type, forKey: "type")
                newUser.setValue(user.status, forKey: "status")
                newUser.setValue(user.datetime, forKey: "datetime")
                newUser.setValue(user.connection, forKey: "connection")
                if let userName = user.name
                {
                    newUser.setValue(userName, forKey: "name")
                }
                if let userImage = user.image
                {
                    newUser.setValue(UIImagePNGRepresentation(userImage)! as NSData, forKey: "image")
                }
                if let userThumbnail = user.thumbnail
                {
                    newUser.setValue(UIImagePNGRepresentation(userThumbnail)! as NSData, forKey: "thumbnail")
                }
                
                userArray.append(newUser)
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
    
    func usersRetrieveAll() -> [User]
    {
        // Access Core Data
        // Retrieve User data from Core Data
        let moc = DataController().managedObjectContext
        moc.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        let userFetch: NSFetchRequest<UserCD> = UserCD.fetchRequest()
        
        // Create an empty User list in case the Core Data request fails
        var userArray = [UserCD]()
        do
        {
            userArray = try moc.fetch(userFetch)
        }
        catch
        {
            fatalError("Failed to fetch CurrentUser: \(error)")
        }
        // Create a User list
        var users = [User]()
        for userObj in userArray
        {
            let user = User()
            user.userID = userObj.userID
            user.facebookID = userObj.facebookID
            user.type = userObj.type
            user.status = userObj.status
            user.datetime = userObj.datetime! as Date
            if let userConnection = userObj.connection
            {
                user.connection = userConnection
            }
            if let userName = userObj.name
            {
                user.name = userName
            }
            if let userImage = userObj.image
            {
                user.image = UIImage(data: userImage as Data)
            }
            if let userThumbnail = userObj.thumbnail
            {
                user.thumbnail = UIImage(data: userThumbnail as Data)
            }
            users.append(user)
        }
        return users
    }
    
    
    // MARK: USER SKILLS
    func skillSave(skill: Skill, deleteSkill: Bool)
    {
        // Try to retrieve the User data from Core Data
        var skillArray = [SkillCD]()
        let moc = DataController().managedObjectContext
        moc.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        let skillFetch: NSFetchRequest<SkillCD> = SkillCD.fetchRequest()
        // Create an empty Skill list in case the Core Data request fails
        do
        {
            skillArray = try moc.fetch(skillFetch)
        }
        catch
        {
            fatalError("CD-SS - Failed to fetch Skill: \(error)")
        }
        // If the user needs to be deleted, just leave the array empty
        if !deleteSkill
        {
            // Check whether the skill exists, otherwise add the skill
            var skillExists = false
            skillLoop: for (sIndex, skillCheck) in skillArray.enumerated()
            {
                if let checkSkillID = skillCheck.skillID
                {
                    if checkSkillID == skill.skillID
                    {
                        // The skill exists, so update the Core Data
                        skillExists = true
                        // Replace the Skill data to ensure that the latest data is used
                        skillArray[sIndex].skillID = skill.skillID
                        skillArray[sIndex].skill = skill.skill
                        skillArray[sIndex].userID = skill.userID
                        skillArray[sIndex].level = Int32(skill.level.rawValue)
                        skillArray[sIndex].order = Int32(skill.order)
                        
                        break skillLoop
                    }
                }
            }
            // If the user does not exist, add a new entity
            if !skillExists
            {
                print("CD-SS - NOT EXIST: \(skill.skillID)")
                let newSkill = NSEntityDescription.insertNewObject(forEntityName: "SkillCD", into: moc) as! SkillCD
                newSkill.setValue(skill.skillID, forKey: "skillID")
                newSkill.setValue(skill.skill, forKey: "skill")
                newSkill.setValue(skill.userID, forKey: "userID")
                newSkill.setValue(skill.level.rawValue, forKey: "level")
                newSkill.setValue(skill.order, forKey: "order")
                
                skillArray.append(newSkill)
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
    
    func skillRetrieveForUser(userID: String!) -> [Skill]
    {
        // Access Core Data
        // Retrieve the Skill data for the passed user from Core Data
        let moc = DataController().managedObjectContext
        moc.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        let skillFetch: NSFetchRequest<SkillCD> = SkillCD.fetchRequest()
        
        // Create an empty Skill list in case the Core Data request fails
        var skillArray = [SkillCD]()
        do
        {
            skillArray = try moc.fetch(skillFetch)
        }
        catch
        {
            fatalError("Failed to fetch CurrentUser: \(error)")
        }
        // Create a new Skill object
        var skills = [Skill]()
        for skillObj in skillArray
        {
            let skill = Skill()
            skill.skillID = skillObj.skillID
            skill.userID = skillObj.userID
            skill.skill = skillObj.skill
            skill.level = Constants().experience(Int(skillObj.level))
            skill.order = Int(skillObj.order)
            skills.append(skill)
        }
        return skills
    }
    
    
    // MARK: MAP SETTINGS
    func mapSettingSaveFromGlobalSettings()
    {
        print("CD: SAVE MAP SETTING TRAFFIC: \(Constants.Settings.menuMapTraffic)")
        print("CD: SAVE MAP SETTING SPOT: \(Constants.Settings.menuMapSpot)")
        print("CD: SAVE MAP SETTING HYDRO: \(Constants.Settings.menuMapHydro)")
        print("CD: SAVE MAP SETTING SHELTER: \(Constants.Settings.menuMapShelter)")
        print("CD: SAVE MAP SETTING TIME: \(Constants.Settings.menuMapTimeFilter)")
        // Try to retrieve the Map Settings data from Core Data
        var mapSettingArray = [MapSetting]()
        let moc = DataController().managedObjectContext
//        moc.mergePolicy = NSMergePolicy.overwrite
        moc.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        let mapSettingFetch: NSFetchRequest<MapSetting> = MapSetting.fetchRequest()
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
            entity.setValue(Int32(Constants.Settings.menuMapTraffic.rawValue), forKey: "menuMapTraffic")
            entity.setValue(Int32(Constants.Settings.menuMapSpot.rawValue), forKey: "menuMapSpot")
            entity.setValue(Int32(Constants.Settings.menuMapHydro.rawValue), forKey: "menuMapHydro")
            entity.setValue(Int32(Constants.Settings.menuMapShelter.rawValue), forKey: "menuMapShelter")
            entity.setValue(Int32(Constants.Settings.menuMapTimeFilter.rawValue), forKey: "menuMapTimeFilter")
        }
        else
        {
            // Replace the Map Setting data to ensure that the latest data is used
            mapSettingArray[0].menuMapTraffic = Int32(Constants.Settings.menuMapTraffic.rawValue)
            mapSettingArray[0].menuMapSpot = Int32(Constants.Settings.menuMapSpot.rawValue)
            mapSettingArray[0].menuMapHydro = Int32(Constants.Settings.menuMapHydro.rawValue)
            mapSettingArray[0].menuMapShelter = Int32(Constants.Settings.menuMapShelter.rawValue)
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
    
    func mapSettingRetrieve() -> [MapSetting]
    {
        // Try to retrieve the Map Setting setting from Core Data
        let moc = DataController().managedObjectContext
        moc.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
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
//        moc.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
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
//        moc.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
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
//        moc.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
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
