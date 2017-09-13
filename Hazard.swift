//
//  Hazard.swift
//  Harvey
//
//  Created by Sean Hart on 9/11/17.
//  Copyright © 2017 tangojlabs. All rights reserved.
//

import Foundation

class Hazard
{
    var hazardID: String?
    var userID: String!
    var datetime: Date!
    var lat: Double!
    var lng: Double!
    var type: Constants.HazardType!
    var status: String = "active"
    
    convenience init(userID: String!, datetime: Date!, lat: Double!, lng: Double!, type: Constants.HazardType!)
    {
        self.init()
        
        self.userID = userID
        self.datetime = datetime
        self.lat = lat
        self.lng = lng
        self.type = type
    }
}
