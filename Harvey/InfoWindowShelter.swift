//
//  InfoWindowShelter.swift
//  Harvey
//
//  Created by Sean Hart on 9/4/17.
//  Copyright © 2017 TangoJ Labs, LLC. All rights reserved.
//

import UIKit

class InfoWindowShelter: UIView
{
    var labelTitle: UILabel!
    var label1A: UILabel!
    var label1B: UILabel!
    var label2A: UILabel!
    var label2B: UILabel!
    var textView1: UITextView!
    var labelFooter: UILabel!
    
    override init (frame : CGRect)
    {
        super.init(frame : frame)
//        print("IWH - INIT")
        
        // Add info window fields to show data
        labelTitle = UILabel(frame: CGRect(x: 10, y: 5, width: self.frame.width - 20, height: 60))
        labelTitle.backgroundColor = Constants.Colors.standardBackground
        labelTitle.textAlignment = .center
        labelTitle.numberOfLines = 2
        labelTitle.lineBreakMode = NSLineBreakMode.byWordWrapping
        labelTitle.font = UIFont(name: Constants.Strings.fontAlt, size: 18)
        labelTitle.textColor = Constants.Colors.colorTextDark
        self.addSubview(labelTitle)
        
        label1A = UILabel(frame: CGRect(x: 10, y: 80, width: self.frame.width - 20, height: 20))
        label1A.backgroundColor = UIColor.clear
        label1A.textAlignment = .center
        label1A.font = UIFont(name: Constants.Strings.fontAlt, size: 16)
        label1A.textColor = Constants.Colors.colorTextDark
        self.addSubview(label1A)
        
        label1B = UILabel(frame: CGRect(x: 10, y: 105, width: self.frame.width - 20, height: 20))
        label1B.backgroundColor = UIColor.clear
        label1B.textAlignment = .center
        label1B.font = UIFont(name: Constants.Strings.fontAlt, size: 16)
        label1B.textColor = Constants.Colors.colorTextDark
        self.addSubview(label1B)
        
        label2A = UILabel(frame: CGRect(x: 10, y: 150, width: self.frame.width - 20, height: 20))
        label2A.backgroundColor = UIColor.clear
        label2A.textAlignment = .center
        label2A.font = UIFont(name: Constants.Strings.fontAlt, size: 16)
        label2A.textColor = Constants.Colors.colorTextDark
        self.addSubview(label2A)
        
        label2B = UILabel(frame: CGRect(x: 10, y: 175, width: self.frame.width - 20, height: 20))
        label2B.backgroundColor = UIColor.clear
        label2B.textAlignment = .center
        label2B.font = UIFont(name: Constants.Strings.fontAlt, size: 16)
        label2B.textColor = Constants.Colors.colorTextDark
        self.addSubview(label2B)
        
        textView1 = UITextView(frame: CGRect(x: 10, y: 215, width: self.frame.width - 20, height: 50))
        textView1.isEditable = false
        textView1.isScrollEnabled = true
        textView1.font = UIFont(name: Constants.Strings.fontAlt, size: 16)
        textView1.textAlignment = .center
        textView1.textColor = Constants.Colors.colorTextDark
        self.addSubview(textView1)
        
        labelFooter = UILabel(frame: CGRect(x: 10, y: self.frame.height - 20, width: self.frame.width - 20, height: 15))
        labelFooter.backgroundColor = UIColor.clear
        labelFooter.textAlignment = .center
        labelFooter.font = UIFont(name: Constants.Strings.fontAlt, size: 12)
        labelFooter.textColor = Constants.Colors.colorTextDark
        self.addSubview(labelFooter)
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
    }
}
