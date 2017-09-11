//
//  Reading.swift
//  Harvey
//
//  Created by Sean Hart on 8/30/17.
//  Copyright © 2017 tangojlabs. All rights reserved.
//

import Foundation

class Hydro
{
    var readingID: String!
    var datetime: Date!
    var gaugeID: String!
    var title: String!
    var lat: Double!
    var lng: Double!
    var obs: String?
    var obs2: String?
    var obsCat: String?
    var obsTime: String?
    var projHigh: String?
    var projHigh2: String?
    var projHighCat: String?
    var projHighTime: String?
    var projLast: String?
    var projLast2: String?
    var projLastCat: String?
    var projLastTime: String?
    var projRec: String?
    var projRec2: String?
    var projRecCat: String?
    var projRecTime: String?
    
    convenience init(readingID: String!, datetime: Date!, gaugeID: String!, title: String!, lat: Double!, lng: Double!)
    {
        self.init()
        
        self.readingID = readingID
        self.datetime = datetime
        self.gaugeID = gaugeID
        self.title = title
        self.lat = lat
        self.lng = lng
    }
}

