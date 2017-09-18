//
//  ProfileSkillTableViewCell.swift
//  Harvey
//
//  Created by Sean Hart on 9/15/17.
//  Copyright © 2017 tangojlabs. All rights reserved.
//

import UIKit

class ProfileSkillTableViewCell: UITableViewCell
{
    var cellContainer: UIView!
    var skillImageView: UIImageView!
    var skillTitle: UILabel!
    var checkContainer: UIView!
    var checkText: UILabel!
    var border1 = CALayer()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?)
    {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.backgroundColor = Constants.Colors.standardBackground
        
        print("STVC - CELL FRAME: \(self.frame.size)")
        print("STVC - CELL BOUNDS: \(self.bounds.size)")
        
        cellContainer = UIView(frame: CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height))
        self.addSubview(cellContainer)
        
        skillImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: cellContainer.frame.height, height: cellContainer.frame.height))
        skillImageView.contentMode = UIViewContentMode.scaleAspectFit
        skillImageView.clipsToBounds = true
        cellContainer.addSubview(skillImageView)
        
        skillTitle = UILabel(frame: CGRect(x: cellContainer.frame.height + 10, y: 0, width: cellContainer.frame.width - cellContainer.frame.height - 70 - 20, height: cellContainer.frame.height))
        skillTitle.font = UIFont(name: Constants.Strings.fontAlt, size: 14)
        skillTitle.textColor = Constants.Colors.colorTextDark
        skillTitle.textAlignment = .left
        skillTitle.numberOfLines = 1
        cellContainer.addSubview(skillTitle)
        
        checkContainer = UIView(frame: CGRect(x: cellContainer.frame.width - 70, y: 0, width: 70, height: cellContainer.frame.height))
        cellContainer.addSubview(checkContainer)
        
        checkText = UILabel(frame: CGRect(x: 0, y: 0, width: checkContainer.frame.width, height: checkContainer.frame.height))
        checkText.font = UIFont(name: Constants.Strings.fontAlt, size: 12)
        checkText.textColor = Constants.Colors.colorTextDark
        checkText.textAlignment = .center
        checkText.numberOfLines = 2
        checkText.lineBreakMode = NSLineBreakMode.byWordWrapping
        checkContainer.addSubview(checkText)
        
        border1.frame = CGRect(x: 0, y: Constants.Dim.skillCellHeight - 1, width: cellContainer.frame.width, height: 1)
        border1.backgroundColor = Constants.Colors.standardBackgroundGrayUltraLight.cgColor
        cellContainer.layer.addSublayer(border1)
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func awakeFromNib()
    {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func prepareForReuse()
    {
//        cellContainer = UIView()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool)
    {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
}
