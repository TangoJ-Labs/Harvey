//
//  UserCD+CoreDataProperties.swift
//  Harvey
//
//  Created by Sean Hart on 9/9/17.
//  Copyright © 2017 TangoJ Labs, LLC. All rights reserved.
//

import Foundation
import CoreData


extension UserCD {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserCD> {
        return NSFetchRequest<UserCD>(entityName: "UserCD")
    }

    @NSManaged public var connection: String?
    @NSManaged public var datetime: NSDate?
    @NSManaged public var facebookID: String?
    @NSManaged public var image: NSData?
    @NSManaged public var name: String?
    @NSManaged public var status: String?
    @NSManaged public var thumbnail: NSData?
    @NSManaged public var type: String?
    @NSManaged public var userID: String?

}
