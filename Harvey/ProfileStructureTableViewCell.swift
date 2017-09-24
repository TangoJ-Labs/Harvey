//
//  ProfileStructureTableViewCell.swift
//  Harvey
//
//  Created by Sean Hart on 9/16/17.
//  Copyright © 2017 TangoJ Labs, LLC. All rights reserved.
//

import UIKit

class ProfileStructureTableViewCell: UITableViewCell
{
    var cellContainer: UIView!
    var structureImageView: UIImageView!
    var imageSpinner: UIActivityIndicatorView!
    var border1 = CALayer()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?)
    {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.backgroundColor = Constants.Colors.standardBackground
        
        print("STVC - CELL FRAME: \(self.frame.size)")
        print("STVC - CELL BOUNDS: \(self.bounds.size)")
        
        cellContainer = UIView(frame: CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height))
        self.addSubview(cellContainer)
        
        structureImageView = UIImageView(frame: CGRect(x: 10, y: 0, width: cellContainer.frame.width - 20, height: cellContainer.frame.height))
        structureImageView.contentMode = UIViewContentMode.scaleAspectFit
        structureImageView.clipsToBounds = true
        cellContainer.addSubview(structureImageView)
        
        imageSpinner = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: structureImageView.frame.width, height: structureImageView.frame.height))
        imageSpinner.color = Constants.Colors.colorGrayDark
        structureImageView.addSubview(imageSpinner)
        
        border1.frame = CGRect(x: 0, y: Constants.Dim.structureCellHeight - 1, width: cellContainer.frame.width, height: 1)
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
