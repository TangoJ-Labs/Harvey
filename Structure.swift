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
    var userIDs: [String]! // Should have at least one userID (String)
    var lat: Double!
    var lng: Double!
    var datetime: Date!
    var type: Constants.Structure = Constants.Structure.other // Defaults to 'other'
    var stage: Constants.StructureStage = Constants.StructureStage.waiting // Defaults to 'waiting'
    
    var image: UIImage? // Image of the structure (just one) - for summary info
    
    convenience init(structureID: String!, userIDs: [String]!, lat: Double!, lng: Double!, datetime: Date!)
    {
        self.init()
        
        self.structureID = structureID
        self.userIDs = userIDs
        self.lat = lat
        self.lng = lng
        self.datetime = datetime
    }
}
