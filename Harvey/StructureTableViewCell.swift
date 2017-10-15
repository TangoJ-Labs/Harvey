//
//  StructureViewCell.swift
//  Harvey
//
//  Created by Sean Hart on 10/10/17.
//  Copyright © 2017 TangoJ Labs, LLC. All rights reserved.
//

import UIKit

class StructureTableViewCell: UITableViewCell
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
