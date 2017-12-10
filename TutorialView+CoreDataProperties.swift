//
//  TutorialView+CoreDataProperties.swift
//  Harvey
//
//  Created by Sean Hart on 12/2/17.
//  Copyright © 2017 TangoJ Labs, LLC. All rights reserved.
//
//

import Foundation
import CoreData


extension TutorialView {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TutorialView> {
        return NSFetchRequest<TutorialView>(entityName: "TutorialView")
    }

    @NSManaged public var tutorialMapViewDatetime: NSDate?
    @NSManaged public var tutorialProfileViewDatetime: NSDate?
    @NSManaged public var tutorialStructureViewDatetime: NSDate?

}
