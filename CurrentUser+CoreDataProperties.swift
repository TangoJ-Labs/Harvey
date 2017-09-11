//
//  CurrentUser+CoreDataProperties.swift
//  Harvey
//
//  Created by Sean Hart on 9/9/17.
//  Copyright © 2017 tangojlabs. All rights reserved.
//

import Foundation
import CoreData


extension CurrentUser {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CurrentUser> {
        return NSFetchRequest<CurrentUser>(entityName: "CurrentUser")
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
