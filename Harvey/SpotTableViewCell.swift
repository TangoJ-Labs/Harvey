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
    var shareButton: UIImageView!
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?)
    {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.backgroundColor = Constants.Colors.standardBackground
        
        cellContainer = UIView(frame: CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.width))
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
        datetimeLabel = UILabel(frame: CGRect(x: cellImageView.frame.width - 15, y: cellImageView.frame.height - 35, width: 10, height: 30))
        datetimeLabel.backgroundColor = Constants.Colors.standardBackgroundTransparent
        datetimeLabel.font = UIFont(name: Constants.Strings.fontAlt, size: 20)
        datetimeLabel.textColor = Constants.Colors.colorGrayDark
        datetimeLabel.textAlignment = .center
        cellContainer.addSubview(datetimeLabel)
        
        shareButton = UIImageView(frame: CGRect(x: cellContainer.frame.width - 55, y: 5, width: 50, height: 50))
        shareButton.backgroundColor = Constants.Colors.standardBackgroundGrayTransparent
        shareButton.image = UIImage(named: Constants.Strings.iconShareArrow)
        shareButton.contentMode = UIViewContentMode.scaleAspectFit
        shareButton.clipsToBounds = true
        cellContainer.addSubview(shareButton)
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
