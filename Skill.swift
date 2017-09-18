//
//  Skill.swift
//  Harvey
//
//  Created by Sean Hart on 9/16/17.
//  Copyright © 2017 tangojlabs. All rights reserved.
//

import Foundation

class Skill
{
    var skillID: String!
    var skill: String!
    var userID: String!
    var level: Constants.Experience = Constants.Experience.none // Defaults to 'no experience'
    
    // For use when listing a user's skills
    var order: Int = 0
    
    convenience init(skillID: String!, skill: String!, userID: String!)
    {
        self.init()
        
        self.skillID = skillID
        self.skill = skill
        self.userID = userID
    }
}
