//
//  ProfileDamageTableViewCell.swift
//  Harvey
//
//  Created by Sean Hart on 9/16/17.
//  Copyright © 2017 tangojlabs. All rights reserved.
//

import UIKit

class ProfileDamageTableViewCell: UITableViewCell
{
    var cellContainer: UIView!
    var damageImageView: UIImageView!
    var damageTitle: UILabel!
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
        
        damageImageView = UIImageView(frame: CGRect(x: 10, y: 0, width: 50, height: cellContainer.frame.height))
        damageImageView.contentMode = UIViewContentMode.scaleAspectFit
        damageImageView.clipsToBounds = true
        cellContainer.addSubview(damageImageView)
        
        damageTitle = UILabel(frame: CGRect(x: 70, y: 0, width: 150, height: cellContainer.frame.height))
        damageTitle.font = UIFont(name: Constants.Strings.fontAlt, size: 20)
        damageTitle.textColor = Constants.Colors.colorTextDark
        damageTitle.textAlignment = .center
        damageTitle.numberOfLines = 1
        cellContainer.addSubview(damageTitle)
        
        checkContainer = UIView(frame: CGRect(x: cellContainer.frame.width - 70, y: 0, width: 70, height: cellContainer.frame.height))
        cellContainer.addSubview(checkContainer)
        
        checkText = UILabel(frame: CGRect(x: 0, y: 0, width: checkContainer.frame.width, height: checkContainer.frame.height))
        checkText.font = UIFont(name: Constants.Strings.fontAlt, size: 12)
        checkText.textColor = UIColor.black //Constants.Colors.colorTextDark
        checkText.textAlignment = .center
        checkText.numberOfLines = 2
        checkText.lineBreakMode = NSLineBreakMode.byWordWrapping
        checkContainer.addSubview(checkText)
        
        border1.frame = CGRect(x: 0, y: Constants.Dim.damageCellHeight - 1, width: cellContainer.frame.width, height: 1)
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
