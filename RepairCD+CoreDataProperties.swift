//
//  RepairCD+CoreDataProperties.swift
//  Harvey
//
//  Created by Sean Hart on 9/17/17.
//  Copyright © 2017 tangojlabs. All rights reserved.
//

import Foundation
import CoreData


extension RepairCD {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<RepairCD> {
        return NSFetchRequest<RepairCD>(entityName: "RepairCD")
    }

    @NSManaged public var order: Int32
    @NSManaged public var repair: String?
    @NSManaged public var userID: String?
    @NSManaged public var repairID: String?

}
