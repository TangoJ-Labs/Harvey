//
//  MapSetting+CoreDataProperties.swift
//  Harvey
//
//  Created by Sean Hart on 9/4/17.
//  Copyright © 2017 tangojlabs. All rights reserved.
//

import Foundation
import CoreData


extension MapSetting {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<MapSetting> {
        return NSFetchRequest<MapSetting>(entityName: "MapSetting")
    }

    @NSManaged public var menuMapHydro: Int32
    @NSManaged public var menuMapShelter: Int32
    @NSManaged public var menuMapSpot: Int32
    @NSManaged public var menuMapTimeFilter: Int32
    @NSManaged public var menuMapTraffic: Int32

}
