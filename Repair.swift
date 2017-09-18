//
//  Repair.swift
//  Harvey
//
//  Created by Sean Hart on 9/16/17.
//  Copyright © 2017 tangojlabs. All rights reserved.
//

import Foundation

class Repair
{
    var repair: String!
    var userID: String!
    
    // For use when listing a user's skills
    var order: Int = 0
    
    convenience init(repair: String!, userID: String!)
    {
        self.init()
        
        self.repair = repair
        self.userID = userID
    }
}
