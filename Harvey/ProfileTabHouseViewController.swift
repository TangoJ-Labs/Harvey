//
//  ProfileTabHouseViewController.swift
//  Harvey
//
//  Created by Sean Hart on 9/15/17.
//  Copyright © 2017 tangojlabs. All rights reserved.
//

import UIKit


class ProfileTabHouseViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate
{
    // Save device settings to adjust view if needed
    var screenSize: CGRect!
    var statusBarHeight: CGFloat!
    var tabBarHeight: CGFloat!
    var navBarHeight: CGFloat!
    var vcHeight: CGFloat!
    var vcOffsetY: CGFloat!
    
    var ncTitleText: UILabel!
    
    // The views to hold major components of the view controller
    var statusBarView: UIView!
    var viewContainer: UIView!
    var summaryContainer: UIView!
    
    var damageTableView: UITableView!
    
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        prepVcLayout()
        
        // Add the Status Bar, Top Bar and Search Bar last so that they are placed above (z-index) all other views
        statusBarView = UIView(frame: CGRect(x: 0, y: 0, width: screenSize.width, height: statusBarHeight))
        statusBarView.backgroundColor = Constants.Colors.colorStatusBar
        self.view.addSubview(statusBarView)
        
        // Add the view container to hold all other views (allows for shadows on all subviews)
        viewContainer = UIView(frame: CGRect(x: 0, y: vcOffsetY, width: screenSize.width, height: vcHeight))
        viewContainer.backgroundColor = Constants.Colors.standardBackground
        self.view.addSubview(viewContainer)
        
        summaryContainer = UIView(frame: CGRect(x: 0, y: 0, width: viewContainer.frame.width, height: viewContainer.frame.height / 2))
        summaryContainer.backgroundColor = Constants.Colors.standardBackground
        viewContainer.addSubview(summaryContainer)
        
        // A tableview will hold all comments
        damageTableView = UITableView(frame: CGRect(x: 0, y: viewContainer.frame.height - (viewContainer.frame.height / 2), width: viewContainer.frame.width, height: viewContainer.frame.height / 2))
        damageTableView.dataSource = self
        damageTableView.delegate = self
        damageTableView.register(ProfileDamageTableViewCell.self, forCellReuseIdentifier: Constants.Strings.profileDamageTableViewCellReuseIdentifier)
        damageTableView.separatorStyle = .none
        damageTableView.backgroundColor = UIColor.clear //Constants.Colors.standardBackground
        damageTableView.isScrollEnabled = true
        damageTableView.bounces = true
        damageTableView.alwaysBounceVertical = true
        damageTableView.showsVerticalScrollIndicator = false
        damageTableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        viewContainer.addSubview(damageTableView)
        
        let border1 = CALayer()
        border1.frame = CGRect(x: 0, y: 0, width: damageTableView.frame.width, height: 1)
        border1.backgroundColor = Constants.Colors.standardBackgroundGrayUltraLight.cgColor
        damageTableView.layer.addSublayer(border1)
        
        NotificationCenter.default.addObserver(self, selector: #selector(MapViewController.statusBarHeightChange(_:)), name: Notification.Name("UIApplicationWillChangeStatusBarFrameNotification"), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        prepVcLayout()
        statusBarView.frame = CGRect(x: 0, y: 0, width: screenSize.width, height: statusBarHeight)
        viewContainer.frame = CGRect(x: 0, y: vcOffsetY, width: screenSize.width, height: vcHeight)
        summaryContainer.frame = CGRect(x: 0, y: 0, width: viewContainer.frame.width, height: viewContainer.frame.height / 2)
        damageTableView.frame = CGRect(x: 0, y: viewContainer.frame.height - (viewContainer.frame.height / 2), width: viewContainer.frame.width, height: viewContainer.frame.height / 2)
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
    }
    
    
    // MARK: LAYOUT METHODS
    
    func statusBarHeightChange(_ notification: Notification)
    {
        prepVcLayout()
        statusBarView.frame = CGRect(x: 0, y: 0, width: screenSize.width, height: statusBarHeight)
        viewContainer.frame = CGRect(x: 0, y: vcOffsetY, width: screenSize.width, height: vcHeight)
        summaryContainer.frame = CGRect(x: 0, y: 0, width: viewContainer.frame.width, height: viewContainer.frame.height / 2)
        damageTableView.frame = CGRect(x: 0, y: viewContainer.frame.height - (viewContainer.frame.height / 2), width: viewContainer.frame.width, height: viewContainer.frame.height / 2)
    }
    
    func prepVcLayout()
    {
        screenSize = UIScreen.main.bounds
        
        // Navigation Bar settings
        let leftButtonItem = UIBarButtonItem(title: "\u{2190}",
                                             style: UIBarButtonItemStyle.plain,
                                             target: self,
                                             action: #selector(UserViewController.popViewController(_:)))
        leftButtonItem.tintColor = Constants.Colors.colorTextNavBar
        
        let rightButtonItem = UIBarButtonItem(title: "",
                                              style: UIBarButtonItemStyle.plain,
                                              target: self,
                                              action: #selector(UserViewController.blankFunc(_:)))
        rightButtonItem.tintColor = Constants.Colors.colorTextNavBar
        
        let ncTitle = UIView(frame: CGRect(x: screenSize.width / 2 - 100, y: 20, width: 200, height: 20))
        ncTitleText = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 20))
        ncTitleText.text = "My House"
        ncTitleText.textColor = Constants.Colors.colorTextNavBar
        ncTitleText.font = UIFont(name: Constants.Strings.fontAlt, size: 16)
        ncTitleText.textAlignment = .center
        ncTitle.addSubview(ncTitleText)
        
        // Device and Status Bar Settings
        UIApplication.shared.isStatusBarHidden = false
        UIApplication.shared.statusBarStyle = Constants.Settings.statusBarStyle
        statusBarHeight = UIApplication.shared.statusBarFrame.size.height
        navBarHeight = 44
        if let tabCon = self.tabBarController
        {
            tabBarHeight = tabCon.tabBar.frame.height
            print("PTHVC - STATUS BAR HEIGHT: \(statusBarHeight)")
            print("PTHVC - TAB BAR HEIGHT: \(tabBarHeight)")
            tabCon.navigationItem.titleView = ncTitle
            tabCon.navigationItem.hidesBackButton = true
            tabCon.navigationItem.setLeftBarButton(leftButtonItem, animated: false)
            
            print("PTHVC - TAB CON: \(tabCon)")
            if let navCon = tabCon.navigationController
            {
                print("PTHVC - NAV CON: \(navCon)")
                navBarHeight = navCon.navigationBar.frame.height
                navCon.isNavigationBarHidden = false
                navCon.navigationBar.barTintColor = Constants.Colors.colorOrangeOpaque
            }
        }
        
        self.automaticallyAdjustsScrollViewInsets = false
        
        vcHeight = screenSize.height - statusBarHeight - navBarHeight - tabBarHeight
        vcOffsetY = CGFloat(statusBarHeight) + CGFloat(navBarHeight) //+ CGFloat(tabBarHeight)
        if statusBarHeight == 40
        {
            vcOffsetY = navBarHeight + 20
        }
        print("PTHVC - CHECK DIMS: \(screenSize), \(vcHeight), \(statusBarHeight), \(navBarHeight), \(tabBarHeight)")
    }
    
    
    // MARK: NAVIGATION / BAR BUTTON METHODS
    
    // Dismiss the latest View Controller presented from this VC
    // This version is used when the top VC is popped from a Nav Bar button
    func popViewController(_ sender: UIBarButtonItem)
    {
        self.navigationController!.popViewController(animated: true)
    }
    func popViewController()
    {
        self.navigationController!.popViewController(animated: true)
    }
    func blankFunc(_ sender: UIBarButtonItem)
    {
    }
    
    
    // MARK: TAP GESTURE RECOGNIZERS
    
    func blockButtonTap(_ gesture: UITapGestureRecognizer)
    {
        
    }
    
    // MARK: TABLE VIEW DATA SOURCE
    
    func numberOfSections(in tableView: UITableView) -> Int
    {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return 10
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return Constants.Dim.damageCellHeight
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        print("PTHVC - CREATING CELL: \(indexPath.row)")
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.Strings.profileDamageTableViewCellReuseIdentifier, for: indexPath) as! ProfileDamageTableViewCell
        
        cell.cellContainer = UIView(frame: CGRect(x: 0, y: 0, width: cell.frame.width, height: cell.frame.height))
        cell.damageImageView = UIImageView(frame: CGRect(x: 10, y: 0, width: 50, height: cell.cellContainer.frame.height))
        cell.damageTitle = UILabel(frame: CGRect(x: 70, y: 0, width: 150, height: cell.cellContainer.frame.height))
        cell.checkContainer = UIView(frame: CGRect(x: cell.cellContainer.frame.width - 70, y: 0, width: 70, height: cell.cellContainer.frame.height))
        cell.checkText = UILabel(frame: CGRect(x: 0, y: 0, width: cell.checkContainer.frame.width, height: cell.checkContainer.frame.height))
        cell.border1.frame = CGRect(x: 0, y: Constants.Dim.damageCellHeight - 1, width: cell.cellContainer.frame.width, height: 1)
        
        cell.checkContainer.backgroundColor = Constants.Colors.standardBackground
        
        
        cell.checkText.text = "Sheetrock"
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath)
    {
        print("PTVVC - WILL DISPLAY CELL: \(indexPath.row)")
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        print("PTVVC - SELECTED CELL: \(indexPath.row)")
        
        // Unhighlight the cell
        tableView.deselectRow(at: indexPath, animated: true)
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
