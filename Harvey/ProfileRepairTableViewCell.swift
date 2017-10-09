//
//  ProfileRepairTableViewCell.swift
//  Harvey
//
//  Created by Sean Hart on 10/2/17.
//  Copyright © 2017 TangoJ Labs, LLC. All rights reserved.
//

import UIKit

class ProfileRepairTableViewCell: UITableViewCell
{
    var cellContainer: UIView!
    var iconImageView: UIImageView!
    var imageSpinner: UIActivityIndicatorView!
    var repairTitle: UILabel!
    var repairStage: UILabel!
    var addImageView: UIImageView!
    var border1 = CALayer()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?)
    {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.backgroundColor = Constants.Colors.standardBackground
        
        print("STVC - CELL FRAME: \(self.frame.size)")
        print("STVC - CELL BOUNDS: \(self.bounds.size)")
        
//        cellContainer = UIView(frame: CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height))
//        self.addSubview(cellContainer)
//
//        repairImageView = UIImageView(frame: CGRect(x: 10, y: 0, width: cellContainer.frame.height, height: cellContainer.frame.height))
//        repairImageView.contentMode = UIViewContentMode.scaleAspectFit
//        repairImageView.clipsToBounds = true
//        cellContainer.addSubview(repairImageView)
//
//        imageSpinner = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: repairImageView.frame.width, height: repairImageView.frame.height))
//        imageSpinner.color = Constants.Colors.colorGrayDark
//        repairImageView.addSubview(imageSpinner)
//
//        repairTitle = UILabel(frame: CGRect(x: cellContainer.frame.height + 20, y: 0, width: cellContainer.frame.width - cellContainer.frame.height - 30, height: cellContainer.frame.height))
//
//        border1.frame = CGRect(x: 0, y: Constants.Dim.structureCellHeight - 1, width: cellContainer.frame.width, height: 1)
//        border1.backgroundColor = Constants.Colors.standardBackgroundGrayUltraLight.cgColor
//        cellContainer.layer.addSublayer(border1)
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
