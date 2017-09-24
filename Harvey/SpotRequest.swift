//
//  Request.swift
//  Harvey
//
//  Created by Sean Hart on 8/30/17.
//  Copyright © 2017 TangoJ Labs, LLC. All rights reserved.
//

import Foundation

class SpotRequest
{
    var requestID: String?
    var userID: String!
    var datetime: Date!
    var lat: Double!
    var lng: Double!
    var status: String = "active"
    
    convenience init(userID: String!, datetime: Date!, lat: Double!, lng: Double!)
    {
        self.init()
        
        self.userID = userID
        self.datetime = datetime
        self.lat = lat
        self.lng = lng
    }
}
