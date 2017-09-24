//
//  LogUserflow+CoreDataProperties.swift
//  Harvey
//
//  Created by Sean Hart on 9/2/17.
//  Copyright © 2017 TangoJ Labs, LLC. All rights reserved.
//

import Foundation
import CoreData


extension LogUserflow {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<LogUserflow> {
        return NSFetchRequest<LogUserflow>(entityName: "LogUserflow")
    }

    @NSManaged public var action: String?
    @NSManaged public var timestamp: Double
    @NSManaged public var viewController: String?

}
