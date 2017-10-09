//
//  ProfileRepairImageTableViewCell.swift
//  Harvey
//
//  Created by Sean Hart on 10/7/17.
//  Copyright © 2017 TangoJ Labs, LLC. All rights reserved.
//

import UIKit

class RepairImageTableViewCell: UITableViewCell
{
    var cellContainer: UIView!
    var repairImageView: UIImageView!
    var imageSpinner: UIActivityIndicatorView!
    var border1 = CALayer()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?)
    {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
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
