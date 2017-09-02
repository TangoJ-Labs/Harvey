//
//  LogError+CoreDataProperties.swift
//  Harvey
//
//  Created by Sean Hart on 9/2/17.
//  Copyright © 2017 tangojlabs. All rights reserved.
//

import Foundation
import CoreData


extension LogError {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<LogError> {
        return NSFetchRequest<LogError>(entityName: "LogError")
    }

    @NSManaged public var errorString: String?
    @NSManaged public var function: String?
    @NSManaged public var timestamp: Double

}
