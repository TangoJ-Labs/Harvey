//
//  SOS.swift
//  Harvey
//
//  Created by Sean Hart on 9/11/17.
//  Copyright © 2017 TangoJ Labs, LLC. All rights reserved.
//

import Foundation

class SOS
{
    var sosID: String?
    var userID: String!
    var datetime: Date!
    var lat: Double!
    var lng: Double!
    var status: String = "active"
    var type: String = "rescue"
    
    convenience init(userID: String!, datetime: Date!, lat: Double!, lng: Double!)
    {
        self.init()
        
        self.userID = userID
        self.datetime = datetime
        self.lat = lat
        self.lng = lng
    }
}
