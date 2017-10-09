//
//  RepairImage.swift
//  Harvey
//
//  Created by Sean Hart on 10/6/17.
//  Copyright © 2017 TangoJ Labs, LLC. All rights reserved.
//

import UIKit

class RepairImage
{
    var repairID: String!
    var imageID: String!
    
    var datetime: Date!
    var status: String = "active"
    
    var image: UIImage?
    var imageFilePath: String?
    
    var imageDownloading: Bool = false
    var deletePending: Bool = false
    
    convenience init(imageID: String!, repairID: String!, datetime: Date!)
    {
        self.init()
        
        self.imageID = imageID
        self.repairID = repairID
        self.datetime = datetime
    }
}
