//
//  StructureUser.swift
//  Harvey
//
//  Created by Sean Hart on 9/30/17.
//  Copyright © 2017 TangoJ Labs, LLC. All rights reserved.
//

import Foundation

class StructureUser
{
    var structureID: String!
    var userID: String!
    var datetime: Date!
    
    convenience init(structureID: String!, userID: String!, datetime: Date!)
    {
        self.init()
        
        self.structureID = structureID
        self.userID = userID
        self.datetime = datetime
    }
}
