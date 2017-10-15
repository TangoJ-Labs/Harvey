//
//  Structure.swift
//  Harvey
//
//  Created by Sean Hart on 9/17/17.
//  Copyright © 2017 TangoJ Labs, LLC. All rights reserved.
//

import UIKit

class Structure
{
    var structureID: String!
    var lat: Double!
    var lng: Double!
    var datetime: Date!
    var type: Constants.StructureType = Constants.StructureType.other // Defaults to 'other'
    var stage: Constants.StructureStage = Constants.StructureStage.waiting // Defaults to 'waiting'
    
//    var userIDs: [String]? // Should have at least one userID (String) - this data comes from a separate table, both in db and in Core Data
    var imageID: String?
    var image: UIImage? // Image of the structure (just one) - for summary info
    var repairs = [Repair]()
    
    convenience init(structureID: String!, lat: Double!, lng: Double!, datetime: Date!)
    {
        self.init()
        
        self.structureID = structureID
        self.lat = lat
        self.lng = lng
        self.datetime = datetime
    }
}
