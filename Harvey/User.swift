//
//  User.swift
//  Harvey
//
//  Created by Sean Hart on 8/29/17.
//  Copyright © 2017 tangojlabs. All rights reserved.
//

import UIKit

class User
{
    var userID: String!
    var facebookID: String!
    var type: String!
    var status: String!
    var datetime: Date!
    var name: String?
    var thumbnail: UIImage?
    var image: UIImage?
    var connection: String = "na"
    
    convenience init(userID: String!, facebookID: String!, type: String!, status: String!, datetime: Date!)
    {
        self.init()
        
        self.userID = userID
        self.facebookID = facebookID
        self.type = type
        self.status = status
        self.datetime = datetime
    }
}
