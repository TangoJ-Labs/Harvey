//
//  ActivityTableViewCell.swift
//  Harvey
//
//  Created by Sean Hart on 9/13/17.
//  Copyright © 2017 tangojlabs. All rights reserved.
//

import GoogleMaps
import UIKit

class ActivityTableViewCell: UITableViewCell
{
    var cellContainer: UIView!
    var mapView: GMSMapView!
//    var datetimeLabel: UILabel!
    var deleteButtonView: UIView!
    var deleteButtonImage: UILabel!
    
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
