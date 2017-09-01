//
//  SpotTableViewCell.swift
//  Harvey
//
//  Created by Sean Hart on 8/31/17.
//  Copyright © 2017 tangojlabs. All rights reserved.
//

import UIKit

class SpotTableViewCell: UITableViewCell
{
    var cellContainer: UIView!
    var mediaActivityIndicator: UIActivityIndicatorView!
    var cellImageView: UIImageView!
    var datetimeLabel: UILabel!
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?)
    {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.backgroundColor = Constants.Colors.standardBackground
        
        cellContainer = UIView(frame: CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.width + 20))
        self.addSubview(cellContainer)
        
        cellImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: cellContainer.frame.width, height: cellContainer.frame.width))
        cellImageView.contentMode = UIViewContentMode.scaleAspectFit
        cellImageView.clipsToBounds = true
        cellContainer.addSubview(cellImageView)
        
        // Add a loading indicator until the Media has downloaded
        // Give it the same size and location as the imageView
        mediaActivityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: cellImageView.frame.width, height: cellImageView.frame.height))
        mediaActivityIndicator.color = UIColor.black
        cellImageView.addSubview(mediaActivityIndicator)
        
        // The Datetime Label should be in small font just below the Navigation Bar starting at the left of the screen (left aligned text)
        datetimeLabel = UILabel(frame: CGRect(x: 5, y: cellImageView.frame.height + 2, width: cellContainer.frame.width - 10, height: 15))
        datetimeLabel.font = UIFont(name: Constants.Strings.fontAlt, size: 14)
        datetimeLabel.textColor = Constants.Colors.colorGrayDark
        datetimeLabel.textAlignment = .left
        cellContainer.addSubview(datetimeLabel)
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
