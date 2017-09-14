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
//    var footerContainer: UIView!
    var userImageActivityIndicator: UIActivityIndicatorView!
    var userImageView: UIImageView!
    var datetimeLabel: UILabel!
    var shareButtonView: UIView!
    var shareButtonImage: UIImageView!
    var flagButtonView: UIView!
    var flagButtonImage: UILabel!
    
    var deleteButtonView: UIView!
    var deleteButtonImage: UILabel!
    var deleteButtonActivityIndicator: UIActivityIndicatorView!
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?)
    {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.backgroundColor = Constants.Colors.standardBackground
        
//        print("STVC - CELL FRAME: \(self.frame.size)")
//        print("STVC - CELL BOUNDS: \(self.bounds.size)")
        
//        cellContainer = UIView(frame: CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.width))
//        cellContainer.backgroundColor = UIColor.red
//        self.addSubview(cellContainer)
//        
//        cellImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: cellContainer.frame.width, height: cellContainer.frame.width))
//        cellImageView.backgroundColor = UIColor.yellow
//        cellImageView.contentMode = UIViewContentMode.scaleAspectFit
//        cellImageView.clipsToBounds = true
//        cellContainer.addSubview(cellImageView)
//        
//        // Add a loading indicator until the Media has downloaded
//        // Give it the same size and location as the imageView
//        mediaActivityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: cellImageView.frame.width, height: cellImageView.frame.height))
//        mediaActivityIndicator.color = UIColor.black
//        cellImageView.addSubview(mediaActivityIndicator)
//        
//        datetimeLabel = UILabel(frame: CGRect(x: cellImageView.frame.width - 60, y: cellImageView.frame.height - 60, width: 50, height: 50))
//        datetimeLabel.backgroundColor = Constants.Colors.standardBackgroundGrayTransparent
//        datetimeLabel.font = UIFont(name: Constants.Strings.fontAlt, size: 18)
//        datetimeLabel.textColor = Constants.Colors.colorTextLight
//        datetimeLabel.textAlignment = .center
//        datetimeLabel.numberOfLines = 2
//        datetimeLabel.lineBreakMode = NSLineBreakMode.byWordWrapping
//        cellContainer.addSubview(datetimeLabel)
//        
//        shareButtonView = UIView(frame: CGRect(x: cellContainer.frame.width - 60, y: 10, width: 50, height: 50))
//        shareButtonView.backgroundColor = Constants.Colors.standardBackgroundGrayTransparent
//        cellContainer.addSubview(shareButtonView)
//        
//        shareButtonImage = UIImageView(frame: CGRect(x: 10, y: 10, width: 30, height: 30))
//        shareButtonImage.image = UIImage(named: Constants.Strings.iconShareArrow)
//        shareButtonImage.contentMode = UIViewContentMode.scaleAspectFit
//        shareButtonImage.clipsToBounds = true
//        shareButtonView.addSubview(shareButtonImage)
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
