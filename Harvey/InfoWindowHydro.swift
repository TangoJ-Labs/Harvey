//
//  InfoWindowHydro.swift
//  Harvey
//
//  Created by Sean Hart on 9/4/17.
//  Copyright © 2017 TangoJ Labs, LLC. All rights reserved.
//

import UIKit

class InfoWindowHydro: UIView
{
//    var infoWindowExit: UIView!
//    var infoWindowExitLabel: UILabel!
//    var infoWindowExitTapGesture: UITapGestureRecognizer!
    
    var infoWindowTitle: UILabel!
    var infoWindowObs: UILabel!
    var infoWindowObsTime: UILabel!
    var infoWindowProjHigh: UILabel!
    var infoWindowProjHighTime: UILabel!
    var infoWindowLastUpdate: UILabel!
    
    override init (frame : CGRect)
    {
        super.init(frame : frame)
        print("IWH - INIT")
        
        // Add info window fields to show data
        infoWindowTitle = UILabel(frame: CGRect(x: 10, y: 5, width: self.frame.width - 20, height: 60))
        infoWindowTitle.backgroundColor = Constants.Colors.standardBackground
        infoWindowTitle.textAlignment = .center
        infoWindowTitle.numberOfLines = 2
        infoWindowTitle.lineBreakMode = NSLineBreakMode.byWordWrapping
        infoWindowTitle.font = UIFont(name: "HelveticaNeue-Light", size: 18)
        infoWindowTitle.textColor = Constants.Colors.colorTextDark
        self.addSubview(infoWindowTitle)
        
        infoWindowObs = UILabel(frame: CGRect(x: 10, y: 80, width: self.frame.width - 20, height: 20))
        infoWindowObs.backgroundColor = UIColor.clear
        infoWindowObs.textAlignment = .center
        infoWindowObs.font = UIFont(name: "HelveticaNeue-Light", size: 16)
        infoWindowObs.textColor = Constants.Colors.colorTextDark
        self.addSubview(infoWindowObs)
        
        infoWindowObsTime = UILabel(frame: CGRect(x: 10, y: 105, width: self.frame.width - 20, height: 20))
        infoWindowObsTime.backgroundColor = UIColor.clear
        infoWindowObsTime.textAlignment = .center
        infoWindowObsTime.font = UIFont(name: "HelveticaNeue-Light", size: 16)
        infoWindowObsTime.textColor = Constants.Colors.colorTextDark
        self.addSubview(infoWindowObsTime)
        
        infoWindowProjHigh = UILabel(frame: CGRect(x: 10, y: 150, width: self.frame.width - 20, height: 20))
        infoWindowProjHigh.backgroundColor = UIColor.clear
        infoWindowProjHigh.textAlignment = .center
        infoWindowProjHigh.font = UIFont(name: "HelveticaNeue-Light", size: 16)
        infoWindowProjHigh.textColor = Constants.Colors.colorTextDark
        self.addSubview(infoWindowProjHigh)
        
        infoWindowProjHighTime = UILabel(frame: CGRect(x: 10, y: 175, width: self.frame.width - 20, height: 20))
        infoWindowProjHighTime.backgroundColor = UIColor.clear
        infoWindowProjHighTime.textAlignment = .center
        infoWindowProjHighTime.font = UIFont(name: "HelveticaNeue-Light", size: 16)
        infoWindowProjHighTime.textColor = Constants.Colors.colorTextDark
        self.addSubview(infoWindowProjHighTime)
        
        infoWindowLastUpdate = UILabel(frame: CGRect(x: 10, y: self.frame.height - 20, width: self.frame.width - 20, height: 15))
        infoWindowLastUpdate.backgroundColor = UIColor.clear
        infoWindowLastUpdate.textAlignment = .center
        infoWindowLastUpdate.font = UIFont(name: "HelveticaNeue-Light", size: 12)
        infoWindowLastUpdate.textColor = Constants.Colors.colorTextDark
        self.addSubview(infoWindowLastUpdate)
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
    }
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    
//        infoWindowExit = UIView(frame: CGRect(x: infoWindow.frame.width - 50, y: 10, width: 40, height: 40))
//        infoWindowExit.layer.cornerRadius = 20
//        infoWindow.addSubview(infoWindowExit)
//
//        infoWindowExitLabel = UILabel(frame: CGRect(x: 5, y: 5, width: 30, height: 30))
//        infoWindowExitLabel.backgroundColor = UIColor.clear
//        infoWindowExitLabel.text = "\u{274c}"
//        infoWindowExitLabel.textAlignment = .center
//        infoWindowExitLabel.font = UIFont(name: "HelveticaNeue-UltraLight", size: 18)
//        infoWindowExit.addSubview(infoWindowExitLabel)
//
//        infoWindowExitTapGesture = UITapGestureRecognizer(target: self, action: #selector(MapViewController.infoWindowExitTap(_:)))
//        infoWindowExitTapGesture.numberOfTapsRequired = 1  // add single tap
//        infoWindowExit.addGestureRecognizer(infoWindowExitTapGesture)
}
