//
//  StructureCD+CoreDataProperties.swift
//  Harvey
//
//  Created by Sean Hart on 9/20/17.
//  Copyright © 2017 TangoJ Labs, LLC. All rights reserved.
//

import Foundation
import CoreData


extension StructureCD {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<StructureCD> {
        return NSFetchRequest<StructureCD>(entityName: "StructureCD")
    }

    @NSManaged public var structureID: String?
    @NSManaged public var userIDs: NSObject?
    @NSManaged public var lat: Double
    @NSManaged public var lng: Double
    @NSManaged public var datetime: NSDate?
    @NSManaged public var type: Int32
    @NSManaged public var stage: Int32
    @NSManaged public var image: NSData?

}
