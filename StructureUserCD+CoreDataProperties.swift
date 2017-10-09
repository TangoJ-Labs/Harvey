//
//  StructureUserCD+CoreDataProperties.swift
//  Harvey
//
//  Created by Sean Hart on 9/30/17.
//  Copyright © 2017 TangoJ Labs, LLC. All rights reserved.
//
//

import Foundation
import CoreData


extension StructureUserCD {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<StructureUserCD> {
        return NSFetchRequest<StructureUserCD>(entityName: "StructureUserCD")
    }

    @NSManaged public var structureID: String?
    @NSManaged public var userID: String?

}
