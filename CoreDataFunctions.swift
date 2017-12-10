//
//  CoreDataFunctions.swift
//  Harvey
//
//  Created by Sean Hart on 9/2/17.
//  Copyright © 2017 TangoJ Labs, LLC. All rights reserved.
//

import CoreData
import UIKit


class CoreDataFunctions: AWSRequestDelegate
{
    
    // MARK: TUTORIAL VIEWS
    func tutorialViewSave(tutorialView: TutorialView)
    {
//        print("CD-TVS: CHECK A: \(String(describing: tutorialView.tutorialMapViewDatetime))")
//        print("CD-TVS: CHECK B: \(String(describing: tutorialView.tutorialProfileViewDatetime))")
//        print("CD-TVS: CHECK C: \(String(describing: tutorialView.tutorialStructureViewDatetime))")
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
            if let tutorialProfileViewDatetime = tutorialView.tutorialProfileViewDatetime
            {
                entity.setValue(tutorialProfileViewDatetime, forKey: "tutorialProfileViewDatetime")
            }
            if let tutorialStructureViewDatetime = tutorialView.tutorialStructureViewDatetime
            {
                entity.setValue(tutorialStructureViewDatetime, forKey: "tutorialStructureViewDatetime")
            }
        }
        else
        {
            // Replace the Tutorial Views data to ensure that the latest data is used
            if let tutorialMapViewDatetime = tutorialView.tutorialMapViewDatetime
            {
                tutorialViewArray[0].tutorialMapViewDatetime = tutorialMapViewDatetime
            }
            if let tutorialProfileViewDatetime = tutorialView.tutorialProfileViewDatetime
            {
                tutorialViewArray[0].tutorialProfileViewDatetime = tutorialProfileViewDatetime
            }
            if let tutorialStructureViewDatetime = tutorialView.tutorialStructureViewDatetime
            {
                tutorialViewArray[0].tutorialStructureViewDatetime = tutorialStructureViewDatetime
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
            if let tutorialProfileViewDatetime = tutorialViewsArray[tutorialViewArrayIndexUse].tutorialProfileViewDatetime
            {
                tutorialView.setValue(tutorialProfileViewDatetime, forKey: "tutorialProfileViewDatetime")
            }
            if let tutorialStructureViewDatetime = tutorialViewsArray[tutorialViewArrayIndexUse].tutorialStructureViewDatetime
            {
                tutorialView.setValue(tutorialStructureViewDatetime, forKey: "tutorialStructureViewDatetime")
            }
        }
//        print("CD-TVR: CHECK A: \(String(describing: tutorialView.tutorialMapViewDatetime))")
//        print("CD-TVR: CHECK B: \(String(describing: tutorialView.tutorialProfileViewDatetime))")
//        print("CD-TVR: CHECK C: \(String(describing: tutorialView.tutorialStructureViewDatetime))")
        return tutorialView
    }
    
    
    // MARK: CURRENT USER
    func currentUserSave(user: User)
    {
//        print("CD-CUS - USER NAME: \(String(describing: user.name))")
        let moc = DataController().managedObjectContext
        moc.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        // Try to retrieve the Current User data from Core Data
        var currentUserArray = [CurrentUser]()
        let currentUserFetch: NSFetchRequest<CurrentUser> = CurrentUser.fetchRequest()
        do
        {
            currentUserArray = try moc.fetch(currentUserFetch)
//            print("CD-CUS - currentUserArray: \(currentUserArray)")
        }
        catch
        {
            fatalError("Failed to fetch CurrentUser: \(error)")
        }
        // If the return has no content, no current User have been saved
        if currentUserArray.count == 0
        {
//            print("CD-CUS - NEW")
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
//            print("CD-CUS - EXISTS")
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
    
    func currentUserRetrieve(deleteAll: Bool) -> User
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
        // If the data should not be deleted, return the data, otherwise clear the data array and save
        if !deleteAll
        {
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
        }
        else
        {
            currentUserArray = [CurrentUser]()
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
        return currentUser
    }
    
    
    // MARK: USER
    func userSave(user: User)
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
//            print("CD-US - NOT EXIST: \(user.userID)")
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
    func skillSave(skill: Skill)
    {
        // Try to retrieve the Skill data from Core Data
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
            fatalError("CD-SSK - Failed to fetch entity: \(error)")
        }
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
        // If the skill does not exist, add a new entity
        if !skillExists
        {
//            print("CD-SSK - NOT EXIST: \(skill.skillID)")
            let newSkill = NSEntityDescription.insertNewObject(forEntityName: "SkillCD", into: moc) as! SkillCD
            newSkill.setValue(skill.skillID, forKey: "skillID")
            newSkill.setValue(skill.skill, forKey: "skill")
            newSkill.setValue(skill.userID, forKey: "userID")
            newSkill.setValue(skill.level.rawValue, forKey: "level")
            newSkill.setValue(skill.order, forKey: "order")
            
            skillArray.append(newSkill)
        }
        // Save the Entity
        do
        {
            try moc.save()
        }
        catch
        {
            fatalError("CD-SSK - Failure to save context: \(error)")
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
            fatalError("CD-SKR - Failed to fetch entity: \(error)")
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
    
    // MARK: STRUCTURE REPAIRS
    func repairSave(repair: Repair)
    {
        // Try to retrieve the Repair data from Core Data
        var repairArray = [RepairCD]()
        let moc = DataController().managedObjectContext
        moc.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        let repairFetch: NSFetchRequest<RepairCD> = RepairCD.fetchRequest()
        // Create an empty Repair list in case the Core Data request fails
        do
        {
            repairArray = try moc.fetch(repairFetch)
        }
        catch
        {
            fatalError("CD-RS - Failed to fetch entity: \(error)")
        }
        // Check whether the repair exists, otherwise add the repair
        var repairExists = false
        repairLoop: for (rIndex, repairCheck) in repairArray.enumerated()
        {
            if let checkRepairID = repairCheck.repairID
            {
                if checkRepairID == repair.repairID
                {
                    // The repair exists, so update the Core Data
                    repairExists = true
                    // Replace the Repair data to ensure that the latest data is used
                    repairArray[rIndex].repairID = repair.repairID
                    repairArray[rIndex].structureID = repair.structureID
                    repairArray[rIndex].repair = repair.repair
                    repairArray[rIndex].datetime = repair.datetime! as NSDate
                    repairArray[rIndex].stage = Int32(repair.stage.rawValue)
                    repairArray[rIndex].order = Int32(repair.order)
                    
                    break repairLoop
                }
            }
        }
        // If the repair does not exist, add a new entity
        if !repairExists
        {
//            print("CD-RS - NOT EXIST: \(repair.repairID)")
            let newRepair = NSEntityDescription.insertNewObject(forEntityName: "RepairCD", into: moc) as! RepairCD
            newRepair.setValue(repair.repairID, forKey: "repairID")
            newRepair.setValue(repair.structureID, forKey: "structureID")
            newRepair.setValue(repair.repair, forKey: "repair")
            newRepair.setValue(repair.datetime, forKey: "datetime")
            newRepair.setValue(repair.stage.rawValue, forKey: "stage")
            newRepair.setValue(repair.order, forKey: "order")
            
            repairArray.append(newRepair)
        }
        // Save the Entity
        do
        {
            try moc.save()
        }
        catch
        {
            fatalError("CD-RS - Failure to save context: \(error)")
        }
    }
    
    func repairRetrieveForStructure(structureID: String!) -> [Repair]
    {
        // Access Core Data
        // Retrieve the Repair data for the passed structure from Core Data
        let moc = DataController().managedObjectContext
        moc.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        let repairFetch: NSFetchRequest<RepairCD> = RepairCD.fetchRequest()
        
        // Create an empty Repair list in case the Core Data request fails
        var repairArray = [RepairCD]()
        do
        {
            repairArray = try moc.fetch(repairFetch)
        }
        catch
        {
            fatalError("CD-RR - Failed to fetch entity: \(error)")
        }
        // Create a new Repair object
        var repairs = [Repair]()
        for repairObj in repairArray
        {
            let repair = Repair()
            repair.repairID = repairObj.repairID
            repair.structureID = repairObj.structureID
            repair.repair = repairObj.repair
            repair.datetime = repairObj.datetime! as Date
            repair.stage = Constants().repairStage(Int(repairObj.stage))
            repair.order = Int(repairObj.order)
            repairs.append(repair)
        }
        return repairs
    }
    
    // MARK: STRUCTURE
    func structureSave(structure: Structure)
    {
        // Try to retrieve the Structure data from Core Data
        var structureArray = [StructureCD]()
        let moc = DataController().managedObjectContext
        moc.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        let structureFetch: NSFetchRequest<StructureCD> = StructureCD.fetchRequest()
        // Create an empty Structure list in case the Core Data request fails
        do
        {
            structureArray = try moc.fetch(structureFetch)
        }
        catch
        {
            fatalError("CD-STS - Failed to fetch entity: \(error)")
        }
        // Check whether the structure exists, otherwise add the entity
        var structureExists = false
        structureLoop: for (sIndex, structureCheck) in structureArray.enumerated()
        {
            if let checkStructureID = structureCheck.structureID
            {
                if checkStructureID == structure.structureID
                {
                    // The structure exists, so update the Core Data
                    structureExists = true
                    // Replace the Structure data to ensure that the latest data is used
//                    print("CD-STS - EXISTS: \(structure.structureID)")
                    structureArray[sIndex].structureID = structure.structureID
                    structureArray[sIndex].lat = structure.lat
                    structureArray[sIndex].lng = structure.lng
                    structureArray[sIndex].datetime = structure.datetime as! NSDate
                    structureArray[sIndex].type = Int32(structure.type.rawValue)
                    structureArray[sIndex].stage = Int32(structure.stage.rawValue)
                    if let structureImageID = structure.imageID
                    {
                        structureArray[sIndex].imageID = structureImageID
                    }
                    if let structureImage = structure.image
                    {
                        structureArray[sIndex].image = UIImagePNGRepresentation(structureImage)! as NSData
                    }
                    
                    break structureLoop
                }
            }
        }
        // If the structure does not exist, add a new entity
        if !structureExists
        {
//            print("CD-STS - EXISTS (NO): \(structure.structureID)")
            let newStructure = NSEntityDescription.insertNewObject(forEntityName: "StructureCD", into: moc) as! StructureCD
            newStructure.setValue(structure.structureID, forKey: "structureID")
            newStructure.setValue(structure.lat, forKey: "lat")
            newStructure.setValue(structure.lng, forKey: "lng")
            newStructure.setValue(structure.datetime, forKey: "datetime")
            newStructure.setValue(structure.type.rawValue, forKey: "type")
            newStructure.setValue(structure.stage.rawValue, forKey: "stage")
            if let structureImageID = structure.imageID
            {
                newStructure.setValue(structureImageID, forKey: "imageID")
            }
            if let structureImage = structure.image
            {
                newStructure.setValue(UIImagePNGRepresentation(structureImage)! as NSData, forKey: "image")
            }
            
            structureArray.append(newStructure)
        }
        // Save the Entity
        do
        {
            try moc.save()
        }
        catch
        {
            fatalError("CD-STS - Failure to save context: \(error)")
        }
    }
    
    func structureDelete(structureID: String)
    {
        // Try to retrieve the Structure data from Core Data
        var structureArray = [StructureCD]()
        let moc = DataController().managedObjectContext
        moc.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        let structureFetch: NSFetchRequest<StructureCD> = StructureCD.fetchRequest()
        // Create an empty Structure list in case the Core Data request fails
        do
        {
            structureArray = try moc.fetch(structureFetch)
        }
        catch
        {
            fatalError("CD-STD - Failed to fetch entity: \(error)")
        }
        // Find the structure in the array and delete the entity
        structureLoop: for (sIndex, structureCheck) in structureArray.enumerated()
        {
            if let checkStructureID = structureCheck.structureID
            {
                if checkStructureID == structureID
                {
                    structureArray.remove(at: sIndex)
                    break structureLoop
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
            fatalError("CD-STD - Failure to save context: \(error)")
        }
    }
    
    func structureRetrieveAll() -> [Structure]
    {
        // Access Core Data
        // Retrieve all Structure entities from Core Data
        let moc = DataController().managedObjectContext
        moc.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        let structureFetch: NSFetchRequest<StructureCD> = StructureCD.fetchRequest()
        
        // Create an empty Structure list in case the Core Data request fails
        var structureArray = [StructureCD]()
        do
        {
            structureArray = try moc.fetch(structureFetch)
        }
        catch
        {
            fatalError("CD-STR - Failed to fetch entity: \(error)")
        }
        // Create a new Structure object
        var structures = [Structure]()
        for structureObj in structureArray
        {
            let structure = Structure()
            structure.structureID = structureObj.structureID
            structure.lat = structureObj.lat
            structure.lng = structureObj.lng
            structure.datetime = structureObj.datetime! as Date
            structure.type = Constants().structureType(Int(structureObj.type))
            structure.stage = Constants().structureStage(Int(structureObj.stage))
            structure.repairs = repairRetrieveForStructure(structureID: structureObj.structureID)
            if let structureImageID = structureObj.imageID
            {
                structure.imageID = structureImageID
            }
            if let structureImage = structureObj.image
            {
                structure.image = UIImage(data: structureImage as Data)
            }
            structures.append(structure)
        }
        return structures
    }
    
    
    // MARK: STRUCTURE-USER
    func structureUserSave(structureUser: StructureUser)
    {
        // Try to retrieve the StructureUser data from Core Data
        var structureUserArray = [StructureUserCD]()
        let moc = DataController().managedObjectContext
        moc.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        let structureUserFetch: NSFetchRequest<StructureUserCD> = StructureUserCD.fetchRequest()
        // Create an empty Structure list in case the Core Data request fails
        do
        {
            structureUserArray = try moc.fetch(structureUserFetch)
        }
        catch
        {
            fatalError("CD-STUS - Failed to fetch entity: \(error)")
        }
        // Check whether the structureUser exists, otherwise add the entity
        var structureUserExists = false
        structureUserLoop: for (suIndex, structureUserCheck) in structureUserArray.enumerated()
        {
            if let checkStructureID = structureUserCheck.structureID
            {
                if checkStructureID == structureUser.structureID
                {
                    // The structureUser exists, so update the Core Data
                    structureUserExists = true
                    // Replace the StructureUser data to ensure that the latest data is used
                    structureUserArray[suIndex].structureID = structureUser.structureID
                    structureUserArray[suIndex].userID = structureUser.userID
                    
                    break structureUserLoop
                }
            }
        }
        // If the structure does not exist, add a new entity
        if !structureUserExists
        {
//            print("CD-STUS - NOT EXIST: \(structureUser.structureID)")
            let newStructureUser = NSEntityDescription.insertNewObject(forEntityName: "StructureUserCD", into: moc) as! StructureUserCD
            newStructureUser.setValue(structureUser.structureID, forKey: "structureID")
            newStructureUser.setValue(structureUser.userID, forKey: "userID")
            structureUserArray.append(newStructureUser)
        }
        // Save the Entity
        do
        {
            try moc.save()
        }
        catch
        {
            fatalError("CD-STUS - Failure to save context: \(error)")
        }
    }
    
    func structureUserDelete(structureID: String)
    {
        // Try to retrieve the Structure data from Core Data
        var structureUserArray = [StructureUserCD]()
        let moc = DataController().managedObjectContext
        moc.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        let structureUserFetch: NSFetchRequest<StructureUserCD> = StructureUserCD.fetchRequest()
        // Create an empty StructureUser list in case the Core Data request fails
        do
        {
            structureUserArray = try moc.fetch(structureUserFetch)
        }
        catch
        {
            fatalError("CD-STUD - Failed to fetch entity: \(error)")
        }
        // Find the StructureUser in the array and delete the entity
        structureUserLoop: for (sIndex, structureUserCheck) in structureUserArray.enumerated()
        {
            if let checkStructureID = structureUserCheck.structureID
            {
                if checkStructureID == structureID
                {
                    structureUserArray.remove(at: sIndex)
                    break structureUserLoop
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
            fatalError("CD-STUD - Failure to save context: \(error)")
        }
    }
    
    func structureUserRetrieveAll() -> [StructureUser]
    {
        // Access Core Data
        // Retrieve all StructureUser entities from Core Data
        let moc = DataController().managedObjectContext
        moc.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        let structureUserFetch: NSFetchRequest<StructureUserCD> = StructureUserCD.fetchRequest()
        
        // Create an empty StructureUser list in case the Core Data request fails
        var structureUserArray = [StructureUserCD]()
        do
        {
            structureUserArray = try moc.fetch(structureUserFetch)
        }
        catch
        {
            fatalError("CD-STUR - Failed to fetch entity: \(error)")
        }
        // Create new StructureUser objects
        var structureUsers = [StructureUser]()
        for structureUserObj in structureUserArray
        {
            let structureUser = StructureUser()
            structureUser.structureID = structureUserObj.structureID
            structureUser.userID = structureUserObj.userID
            structureUsers.append(structureUser)
        }
        return structureUsers
    }
    
    
    // MARK: MAP SETTINGS
    func mapSettingSaveFromGlobalSettings()
    {
//        print("CD: SAVE MAP SETTING TRAFFIC: \(Constants.Settings.menuMapTraffic)")
//        print("CD: SAVE MAP SETTING SPOT: \(Constants.Settings.menuMapSpot)")
//        print("CD: SAVE MAP SETTING HYDRO: \(Constants.Settings.menuMapHydro)")
//        print("CD: SAVE MAP SETTING SHELTER: \(Constants.Settings.menuMapShelter)")
//        print("CD: SAVE MAP SETTING TIME: \(Constants.Settings.menuMapTimeFilter)")
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
//        // Retrieve the notification data from Core Data
//        let moc = DataController().managedObjectContext
//        moc.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
//        let logErrorFetch: NSFetchRequest<LogError> = LogError.fetchRequest()
//        
//        // Create an empty notifications list in case the Core Data request fails
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
//        // Retrieve the notification data from Core Data
//        let moc = DataController().managedObjectContext
//        let logUserflowFetch: NSFetchRequest<LogUserflow> = LogUserflow.fetchRequest()
//        
//        // Create an empty notifications list in case the Core Data request fails
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
