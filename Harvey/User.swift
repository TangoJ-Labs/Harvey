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
    var digitsID: String!
    var userID: String!
    var facebookID: String!
    var userName: String?
//    var userImageID: String?
    var userImage: UIImage?
    
    convenience init(digitsID: String!, userID: String!, facebookID: String!, userName: String?)
    {
        self.init()
        
        self.digitsID = digitsID
        self.userID = userID
        self.facebookID = facebookID
        self.userName = userName
    }
}
