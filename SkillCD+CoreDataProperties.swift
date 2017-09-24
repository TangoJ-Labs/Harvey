//
//  SkillCD+CoreDataProperties.swift
//  Harvey
//
//  Created by Sean Hart on 9/17/17.
//  Copyright © 2017 TangoJ Labs, LLC. All rights reserved.
//

import Foundation
import CoreData


extension SkillCD {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SkillCD> {
        return NSFetchRequest<SkillCD>(entityName: "SkillCD")
    }

    @NSManaged public var level: Int32
    @NSManaged public var order: Int32
    @NSManaged public var skill: String?
    @NSManaged public var userID: String?
    @NSManaged public var skillID: String?

}
