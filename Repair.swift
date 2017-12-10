//
//  Repair.swift
//  Harvey
//
//  Created by Sean Hart on 9/16/17.
//  Copyright © 2017 TangoJ Labs, LLC. All rights reserved.
//

import UIKit

class Repair
{
    var repairID: String!
    var structureID: String!
    var repair: String!
    var datetime: Date!
    var stage: Constants.RepairStage!
    
    var title: String = ""
    var order: Int = 0 // For use when listing a structure's repair needs
    var icon: UIImage?
    var skillsNeeded = [String]()
    
    var repairImages = [RepairImage]() // Images of the damaged area - display on the preview view
    
    convenience init(repairID: String!, structureID: String!, repair: String!, datetime: Date!, stage: Constants.RepairStage!)
    {
        self.init()
        
        self.repairID = repairID
        self.structureID = structureID
        self.repair = repair
        self.datetime = datetime
        self.stage = stage
    }
}
