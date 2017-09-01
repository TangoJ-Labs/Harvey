//
//  SpotImages.swift
//  Harvey
//
//  Created by Sean Hart on 8/30/17.
//  Copyright © 2017 tangojlabs. All rights reserved.
//

import UIKit

class SpotContent
{
    var contentID: String!
    var spotID: String!
    var datetime: Date!
    var type: Constants.ContentType!
    var lat: Double!
    var lng: Double!
    var status: String = "active"
    
    var image: UIImage?
    
    convenience init(contentID: String!, spotID: String!, datetime: Date!, type: Constants.ContentType!, lat: Double!, lng: Double!)
    {
        self.init()
        
        self.contentID = contentID
        self.spotID = spotID
        self.datetime = datetime
        self.type = type
        self.lat = lat
        self.lng = lng
    }
}
