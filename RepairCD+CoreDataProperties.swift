//
//  RepairCD+CoreDataProperties.swift
//  Harvey
//
//  Created by Sean Hart on 9/20/17.
//  Copyright © 2017 TangoJ Labs, LLC. All rights reserved.
//

import Foundation
import CoreData


extension RepairCD {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<RepairCD> {
        return NSFetchRequest<RepairCD>(entityName: "RepairCD")
    }

    @NSManaged public var order: Int32
    @NSManaged public var repair: String?
    @NSManaged public var repairID: String?
    @NSManaged public var structureID: String?
    @NSManaged public var datetime: NSDate?
    @NSManaged public var stage: Int32

}
