//
//  AboutViewController.swift
//  Harvey
//
//  Created by Sean Hart on 9/1/17.
//  Copyright © 2017 tangojlabs. All rights reserved.
//

import UIKit

class AboutViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate
{
    // Save device settings to adjust view if needed
    var screenSize: CGRect!
    var statusBarHeight: CGFloat!
    var navBarHeight: CGFloat!
    var viewFrameY: CGFloat!
    
    // Add the view components
    var viewContainer: UIView!
    var headerContainer: UIView!
    var headerLabel: UILabel!
    var headerLabel2: UILabel!
    var attrTableView: UITableView!
    
    // Properties to hold local information
    var viewContainerHeight: CGFloat!
    
    // Text
    let headerText: String = "Created by TangoJ Labs, LLC/n/nData provided by:"
    
    
    override func viewDidLoad()
    {
        super.viewDidLoad()

        // Device and Status Bar Settings
        UIApplication.shared.isStatusBarHidden = false
        UIApplication.shared.statusBarStyle = Constants.Settings.statusBarStyle
        statusBarHeight = UIApplication.shared.statusBarFrame.size.height
        navBarHeight = self.navigationController?.navigationBar.frame.height
        viewFrameY = self.view.frame.minY
        screenSize = UIScreen.main.bounds
        
        self.automaticallyAdjustsScrollViewInsets = false
        
        // Add the view container to hold all other views (allows for shadows on all subviews)
        let viewContainerOffset = statusBarHeight + navBarHeight - viewFrameY
        self.viewContainerHeight = self.view.bounds.height - viewContainerOffset
        viewContainer = UIView(frame: CGRect(x: 0, y: viewContainerOffset, width: self.view.bounds.width, height: self.viewContainerHeight))
        viewContainer.backgroundColor = Constants.Colors.standardBackground
        self.view.addSubview(viewContainer)
        
        headerContainer = UIView(frame: CGRect(x: 0, y: 0, width: viewContainer.frame.width, height: 80))
        headerContainer.backgroundColor = Constants.Colors.standardBackground
        headerContainer.layer.shadowOffset = CGSize(width: 0.5, height: 2)
        headerContainer.layer.shadowOpacity = 0.5
        headerContainer.layer.shadowRadius = 1.0
        viewContainer.addSubview(headerContainer)
        
        headerLabel = UILabel(frame: CGRect(x: 10, y: 10, width: headerContainer.frame.width - 20, height: 30))
        headerLabel.font = UIFont(name: Constants.Strings.fontAltLight, size: 20)
        headerLabel.textColor = Constants.Colors.colorTextDark
        headerLabel.textAlignment = .center
        headerLabel.text = "Created by TangoJ Labs, LLC"
        headerContainer.addSubview(headerLabel)
        
        headerLabel2 = UILabel(frame: CGRect(x: 10, y: 50, width: headerContainer.frame.width - 20, height: 20))
        headerLabel2.font = UIFont(name: Constants.Strings.fontAltLight, size: 14)
        headerLabel2.textColor = Constants.Colors.colorTextDark
        headerLabel2.textAlignment = .center
        headerLabel2.text = "Data provided by:"
        headerContainer.addSubview(headerLabel2)
        
        // A tableview will hold all attributions
        attrTableView = UITableView(frame: CGRect(x: 0, y: headerContainer.frame.height, width: viewContainer.frame.width, height: viewContainer.frame.height - headerContainer.frame.height))
        attrTableView.dataSource = self
        attrTableView.delegate = self
        attrTableView.register(UITableViewCell.self, forCellReuseIdentifier: "about_cell")
        attrTableView.separatorStyle = .none
//        attrTableView.backgroundColor = Constants.Colors.colorOrange
        attrTableView.isScrollEnabled = true
        attrTableView.bounces = true
        attrTableView.alwaysBounceVertical = true
        attrTableView.showsVerticalScrollIndicator = false
//        attrTableView.isUserInteractionEnabled = true
//        attrTableView.allowsSelection = true
        attrTableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        viewContainer.addSubview(attrTableView)
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    // MARK: TABLE VIEW DATA SOURCE
    
    func numberOfSections(in tableView: UITableView) -> Int
    {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        let cellCount = 2
        
        return cellCount
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        var cellHeight: CGFloat = 120
        
        return cellHeight
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        var cell: UITableViewCell = attrTableView.dequeueReusableCell(withIdentifier: "about_cell") as! UITableViewCell
        
        var cellHeight: CGFloat = 120
        var cellText: String = ""
        
        if indexPath.row > 0
        {
            let border1 = CALayer()
            border1.frame = CGRect(x: 0, y: 0, width: cell.frame.width, height: 1)
            border1.backgroundColor = Constants.Colors.standardBackgroundGrayUltraLight.cgColor
            cell.layer.addSublayer(border1)
        }
        
        switch indexPath.row
        {
        case 0:
            cellText = "NOAA:\n\nHydrological Stream Data provided by the National Oceanic and Atmospheric Administration's National Weather Service - see water.weather.gov for more information"
        case 1:
            cellText = "SHELTER / RESOURCES:\n\nHouston shelter information provided by..."
        default:
            print("AVC-DEFAULT: CELL NOT CONSIDERED")
        }
        
        let cellTextView = UITextView(frame: CGRect(x: 5, y: 5, width: viewContainer.frame.width - 10, height: cellHeight - 10))
//        cellTextView.backgroundColor = Constants.Colors.colorBlue
        cellTextView.font = UIFont(name: Constants.Strings.fontAltLight, size: 14)
        cellTextView.textAlignment = .center
        cellTextView.isScrollEnabled = false
        cellTextView.isEditable = false
        cellTextView.isSelectable = false
        cellTextView.isUserInteractionEnabled = false
        cellTextView.text = cellText
        cell.addSubview(cellTextView)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath)
    {
    }
    
    func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath)
    {
    }
    
    func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath)
    {
    }
    
    
    // MARK: SCROLL VIEW DELEGATE METHODS
    
    func scrollViewDidScroll(_ scrollView: UIScrollView)
    {
        
    }
}
