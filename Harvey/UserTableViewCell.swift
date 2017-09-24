//
//  UserTableViewCell.swift
//  Harvey
//
//  Created by Sean Hart on 9/9/17.
//  Copyright © 2017 TangoJ Labs, LLC. All rights reserved.
//

import UIKit

class UserTableViewCell: UITableViewCell
{

    var cellContainer: UIView!
    var userImageView: UIImageView!
    var activityIndicator: UIActivityIndicatorView!
    var userNameLabel: UILabel!
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?)
    {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.backgroundColor = Constants.Colors.standardBackground
        
        print("UTVC - CELL FRAME: \(self.frame.size)")
        print("UTVC - CELL BOUNDS: \(self.bounds.size)")
        
        cellContainer = UIView(frame: CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.width))
        cellContainer.backgroundColor = UIColor.red
        self.addSubview(cellContainer)
        
        userImageView = UIImageView(frame: CGRect(x: 10, y: 10, width: 30, height: 30))
        userImageView.layer.cornerRadius = 15
        userImageView.contentMode = UIViewContentMode.scaleAspectFill
        userImageView.clipsToBounds = true
        cellContainer.addSubview(userImageView)
        
        // Add a loading indicator until the Image has downloaded
        // Give it the same size and location as the imageView
        activityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: userImageView.frame.width, height: userImageView.frame.height))
        activityIndicator.color = UIColor.black
        userImageView.addSubview(activityIndicator)
        
        userNameLabel = UILabel(frame: CGRect(x: userImageView.frame.width + 20, y: (cellContainer.frame.height / 2) - 15, width: cellContainer.frame.width - (userImageView.frame.width + 30), height: 30))
        userNameLabel.font = UIFont(name: Constants.Strings.fontAlt, size: 20)
        userNameLabel.textColor = Constants.Colors.colorTextDark
        userNameLabel.textAlignment = .left
        userNameLabel.numberOfLines = 1
        cellContainer.addSubview(userNameLabel)
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
