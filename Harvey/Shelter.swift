//
//  Shelter.swift
//  Harvey
//
//  Created by Sean Hart on 9/3/17.
//  Copyright © 2017 TangoJ Labs, LLC. All rights reserved.
//

import Foundation

class Shelter
{
    var shelterID: String!
    var datetime: Date!
    var name: String!
    var address: String!
    var city: String!
    var lat: Double!
    var lng: Double!
    var phone: String?
    var website: String?
    var info: String?
    var type: String = "Shelter"
    var condition: String = "Unknown"
    var status: String = "active"
    
    convenience init(shelterID: String!, datetime: Date!, name: String!, address: String!, city: String!, lat: Double!, lng: Double!)
    {
        self.init()
        
        self.shelterID = shelterID
        self.datetime = datetime
        self.name = name
        self.address = address
        self.city = city
        self.lat = lat
        self.lng = lng
    }
}
