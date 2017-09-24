//
//  ProfileTabStructureViewController.swift
//  Harvey
//
//  Created by Sean Hart on 9/15/17.
//  Copyright © 2017 TangoJ Labs, LLC. All rights reserved.
//

import UIKit


class ProfileTabStructureViewController: UIViewController, UIGestureRecognizerDelegate, UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate
{
    var structureList: [Structure]!
    
//    convenience init(structureList: [Structure])
//    {
//        self.init(nibName:nil, bundle:nil)
//        
//        // Order the Array
//        let structureList = structureList.sorted {
//            $0.datetime > $1.datetime
//        }
//        self.spotRequests = spotRequestsSort
//        
//        print("ATVC - SPOT REQUESTS COUNT: \(spotRequestsSort.count)")
//        if spotRequests.count > 0
//        {
//            contentExists = true
//        }
//        else
//        {
//            backgroundText = "You don't have any Photo Requests yet.  Go to the main map to add some!"
//        }
//    }
    
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
    var viewSpinner: UIActivityIndicatorView!
    
    var backgroundLabel: UILabel!
    var structureTableView: UITableView!
    var addStructureButton: UIView!
    var addStructureLabel: UILabel!
    
    var addButton: UIView!
    var addButtonLabel: UILabel!
    var addButtonTapGestureRecognizer: UITapGestureRecognizer!
    
    let addButtonHeight: CGFloat = 70
    
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
        
        viewSpinner = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: viewContainer.frame.width, height: viewContainer.frame.height))
        viewSpinner.color = Constants.Colors.colorGrayDark
        viewContainer.addSubview(viewSpinner)
        viewSpinner.startAnimating()
        
        backgroundLabel = UILabel(frame: CGRect(x: 30, y: 5, width: viewContainer.frame.width - 60, height: viewContainer.frame.height / 2))
        backgroundLabel.textColor = Constants.Colors.colorTextDark
//        backgroundLabel.text = backgroundText
        backgroundLabel.numberOfLines = 3
        backgroundLabel.lineBreakMode = NSLineBreakMode.byWordWrapping
        backgroundLabel.textAlignment = .center
        backgroundLabel.font = UIFont(name: "HelveticaNeue-UltraLight", size: 20)
        backgroundLabel.text = "You haven't added any houses needing repair.  Tap the button below to add one."
        viewContainer.addSubview(backgroundLabel)
        
        // A tableview will hold all structures
        structureTableView = UITableView(frame: CGRect(x: 0, y: 0, width: viewContainer.frame.width, height: viewContainer.frame.height - addButtonHeight))
        structureTableView.dataSource = self
        structureTableView.delegate = self
        structureTableView.register(ProfileStructureTableViewCell.self, forCellReuseIdentifier: Constants.Strings.profileStructureTableViewCellReuseIdentifier)
        structureTableView.separatorStyle = .none
        structureTableView.backgroundColor = UIColor.clear //Constants.Colors.standardBackground
        structureTableView.isScrollEnabled = true
        structureTableView.bounces = true
        structureTableView.alwaysBounceVertical = true
        structureTableView.showsVerticalScrollIndicator = false
        structureTableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        viewContainer.addSubview(structureTableView)
        
        let border1 = CALayer()
        border1.frame = CGRect(x: 0, y: 0, width: structureTableView.frame.width, height: 1)
        border1.backgroundColor = Constants.Colors.standardBackgroundGrayUltraLight.cgColor
        structureTableView.layer.addSublayer(border1)
        
        addButton = UIView(frame: CGRect(x: 0, y: viewContainer.frame.height - addButtonHeight, width: viewContainer.frame.width, height: addButtonHeight))
        addButton.backgroundColor = Constants.Colors.colorGrayDark
        addButton.layer.shadowOffset = CGSize(width: 0, height: 0.6)
        addButton.layer.shadowOpacity = 0.5
        addButton.layer.shadowRadius = 1.0
        viewContainer.addSubview(addButton)
        
        addButtonLabel = UILabel(frame: CGRect(x: 5, y: 5, width: addButton.frame.width - 10, height: addButton.frame.height - 10))
        addButtonLabel.textColor = Constants.Colors.colorTextLight
        addButtonLabel.text = "+"
        addButtonLabel.textAlignment = .center
        addButtonLabel.font = UIFont(name: "HelveticaNeue-UltraLight", size: 40)
        addButtonLabel.numberOfLines = 1
        addButtonLabel.lineBreakMode = NSLineBreakMode.byWordWrapping
        addButton.addSubview(addButtonLabel)
        
        addButtonTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ProfileTabStructureViewController.addButtonTap(_:)))
        addButtonTapGestureRecognizer.delegate = self
        addButton.addGestureRecognizer(addButtonTapGestureRecognizer)
        
        NotificationCenter.default.addObserver(self, selector: #selector(ProfileTabStructureViewController.statusBarHeightChange(_:)), name: Notification.Name("UIApplicationWillChangeStatusBarFrameNotification"), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        prepVcLayout()
        statusBarView.frame = CGRect(x: 0, y: 0, width: screenSize.width, height: statusBarHeight)
        viewContainer.frame = CGRect(x: 0, y: vcOffsetY, width: screenSize.width, height: vcHeight)
        viewSpinner.frame = CGRect(x: 0, y: 0, width: viewContainer.frame.width, height: viewContainer.frame.height)
        structureTableView.frame = CGRect(x: 0, y: viewContainer.frame.height - (viewContainer.frame.height / 2), width: viewContainer.frame.width, height: viewContainer.frame.height / 2)
        addButton.frame = CGRect(x: 0, y: viewContainer.frame.height - addButtonHeight, width: viewContainer.frame.width, height: addButtonHeight)
        addButtonLabel.frame = CGRect(x: 5, y: 5, width: addButton.frame.width - 10, height: addButton.frame.height - 10)
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
        viewSpinner.frame = CGRect(x: 0, y: 0, width: viewContainer.frame.width, height: viewContainer.frame.height)
        structureTableView.frame = CGRect(x: 0, y: viewContainer.frame.height - (viewContainer.frame.height / 2), width: viewContainer.frame.width, height: viewContainer.frame.height / 2)
        addButton.frame = CGRect(x: 0, y: viewContainer.frame.height - addButtonHeight, width: viewContainer.frame.width, height: addButtonHeight)
        addButtonLabel.frame = CGRect(x: 5, y: 5, width: addButton.frame.width - 10, height: addButton.frame.height - 10)
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
            print("PTSTVC - STATUS BAR HEIGHT: \(statusBarHeight)")
            print("PTSTVC - TAB BAR HEIGHT: \(tabBarHeight)")
            tabCon.navigationItem.titleView = ncTitle
            tabCon.navigationItem.hidesBackButton = true
            tabCon.navigationItem.setLeftBarButton(leftButtonItem, animated: false)
            
            print("PTSTVC - TAB CON: \(tabCon)")
            if let navCon = tabCon.navigationController
            {
                print("PTSTVC - NAV CON: \(navCon)")
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
        print("PTSTVC - CHECK DIMS: \(screenSize), \(vcHeight), \(statusBarHeight), \(navBarHeight), \(tabBarHeight)")
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
    
    func addButtonTap(_ gesture: UITapGestureRecognizer)
    {
        // Load the camera view and only allow one photo to be taken
        if let navCon = self.navigationController
        {
            let cameraVC = CameraSingleImageViewController()
            navCon.pushViewController(cameraVC, animated: true)
        }
    }
    
    // MARK: TABLE VIEW DATA SOURCE
    
    func numberOfSections(in tableView: UITableView) -> Int
    {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return structureList.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return Constants.Dim.structureCellHeight
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        print("PTSTVC - CREATING CELL: \(indexPath.row)")
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.Strings.profileStructureTableViewCellReuseIdentifier, for: indexPath) as! ProfileStructureTableViewCell
        
        cell.cellContainer = UIView(frame: CGRect(x: 0, y: 0, width: cell.frame.width, height: cell.frame.height))
        cell.structureImageView = UIImageView(frame: CGRect(x: 10, y: 0, width: 50, height: cell.cellContainer.frame.height))
        cell.imageSpinner = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: cell.structureImageView.frame.width, height: cell.structureImageView.frame.height))
        cell.border1.frame = CGRect(x: 0, y: Constants.Dim.structureCellHeight - 1, width: cell.cellContainer.frame.width, height: 1)
        
        cell.imageSpinner.startAnimating()
        if let image = structureList[indexPath.row].image
        {
            cell.structureImageView.image = image
            cell.imageSpinner.stopAnimating()
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath)
    {
        print("PTSTVC - WILL DISPLAY CELL: \(indexPath.row)")
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
    
    
    // MARK: CUSTOM METHODS
    
    func refreshStructureTable()
    {
        DispatchQueue.main.async(execute:
            {
                if self.structureTableView != nil
                {
                    print("PTSTVC - REFRESH SKILL TABLE")
                    
                    // Reload the TableView
                    self.structureTableView.reloadData()
                }
        })
    }
    func reloadStructureTable()
    {
//        self.structureList = Constants.Data.structures
        
//        // Order the StructureList
//        let structureListSort = self.structureList.sorted {
//            $0.name < $1.name
//        }
//        self.structureList = structureListSort
        
        refreshStructureTable()
    }
    
    func requestData()
    {
//        // Request the user's skill history
//        AWSPrepRequest(requestToCall: AWSGetSkills(userID: Constants.Data.currentUser.userID), delegate: self as AWSRequestDelegate).prepRequest()
    }
    
    
    // MARK: AWS DELEGATE METHODS
    
    func showLoginScreen()
    {
        print("PTSTVC - SHOW LOGIN SCREEN")
        
        // Load the LoginVC
        let loginVC = LoginViewController()
        self.navigationController!.pushViewController(loginVC, animated: true)
    }
    
    func processAwsReturn(_ objectType: AWSRequestObject, success: Bool)
    {
        DispatchQueue.main.async(execute:
            {
                // Process the return data based on the method used
                switch objectType
                {
//                case let awsGetRandomID as AWSGetRandomID:
//                    if success
//                    {
//                        print("PTSTVC - AWS GET RANDOM ID: \(awsGetRandomID.randomID)")
//                        if let randomID = awsGetRandomID.randomID
//                        {
//                            
//                        }
//                    }
//                    else
//                    {
//                        print("PTSTVC - AWS GET RANDOM ID - FAILURE")
//                        // Show the error message
//                        let alert = UtilityFunctions().createAlertOkView("Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
//                        alert.show()
//                    }
//                case _ as AWSGetStructure:
//                    if success
//                    {
//                        print("PTSTVC - AWS GET STRUCTURE - SUCCESS")
//                        self.reloadSkillTable()
//                        self.titleSpinner.stopAnimating()
//                        self.titleContainer.addSubview(self.titleText)
//                    }
//                    else
//                    {
//                        print("PTSTVC - AWS GET STRUCTURE - FAILURE")
//                        // Show the error message
//                        let alert = UtilityFunctions().createAlertOkView("Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
//                        alert.show()
//                    }
//                case _ as AWSPutStructure:
//                    if success
//                    {
//                        print("PTSTVC - AWS PUT STRUCTURE - SUCCESS")
//                    }
//                    else
//                    {
//                        print("PTSTVC - AWS PUT STRUCTURE - FAILURE")
//                        // Show the error message
//                        let alert = UtilityFunctions().createAlertOkView("Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
//                        alert.show()
//                    }
                default:
                    print("PTSTVC-DEFAULT: THERE WAS AN ISSUE WITH THE DATA RETURNED FROM AWS")
                    
                    // Show the error message
                    let alert = UtilityFunctions().createAlertOkView("Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
                    alert.show()
                }
        })
    }
}
