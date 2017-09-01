//
//  Spot.swift
//  Harvey
//
//  Created by Sean Hart on 8/30/17.
//  Copyright © 2017 tangojlabs. All rights reserved.
//

import Foundation

class Spot
{
    var spotID: String!
    var userID: String!
    var datetime: Date!
    var lat: Double!
    var lng: Double!
    var status: String = "active"
    
    let radius: Double = 50 // in meters - see spotRadius in Constants
    
    var spotContent = [SpotContent]()
    
    convenience init(spotID: String!, userID: String!, datetime: Date!, lat: Double!, lng: Double!)
    {
        self.init()
        
        self.spotID = spotID
        self.userID = userID
        self.datetime = datetime
        self.lat = lat
        self.lng = lng
    }
}
