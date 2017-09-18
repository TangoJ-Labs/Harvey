//
//  ProfileViewController.swift
//  Harvey
//
//  Created by Sean Hart on 9/12/17.
//  Copyright © 2017 tangojlabs. All rights reserved.
//

import FBSDKLoginKit
import UIKit

class ProfileViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate, FBSDKLoginButtonDelegate, SpotTableViewControllerDelegate, AWSRequestDelegate, RequestDelegate
{
    var user: User = Constants.Data.currentUser
    
    // Save device settings to adjust view if needed
    var screenSize: CGRect!
    var statusBarHeight: CGFloat!
    var navBarHeight: CGFloat!
    var viewFrameY: CGFloat!
    var vcHeight: CGFloat!
    var vcOffsetY: CGFloat!
    
    var ncTitleText: UILabel!
    
    // The views to hold major components of the view controller
    var statusBarView: UIView!
    var viewContainer: UIView!
    
    var currentUserContainer: UIView!
    var userImage: UIImageView!
    var userName: UILabel!
    var fbLoginButton: FBSDKLoginButton!
    
    var activityTableView: UITableView!
    
    let cellHeight: CGFloat = 50
    
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
        
        // Create a container to hold and center the content
        currentUserContainer = UIView(frame: CGRect(x: 0, y: (viewContainer.frame.height / 4) - 100, width: viewContainer.frame.width, height: 200))
        currentUserContainer.backgroundColor = Constants.Colors.standardBackground
        viewContainer.addSubview(currentUserContainer)
        
        // Add the user image and name
        userImage = UIImageView(frame: CGRect(x: (currentUserContainer.frame.width / 2) - 50, y: 10, width: 100, height: 100))
        userImage.layer.cornerRadius = userImage.frame.height / 2
        userImage.contentMode = UIViewContentMode.scaleAspectFill
        userImage.clipsToBounds = true
        currentUserContainer.addSubview(userImage)
        
        userName = UILabel(frame: CGRect(x: 5, y: 110, width: currentUserContainer.frame.width - 10, height: 20))
        userName.backgroundColor = UIColor.clear
        userName.textAlignment = .center
        userName.font = UIFont(name: "HelveticaNeue-UltraLight", size: 18)
        currentUserContainer.addSubview(userName)
        
        fbLoginButton = FBSDKLoginButton()
        fbLoginButton.center = CGPoint(x: currentUserContainer.frame.width / 2, y: 170)
        fbLoginButton.readPermissions = ["public_profile", "email"]
        fbLoginButton.delegate = self
        currentUserContainer.addSubview(fbLoginButton)
        
        // Create a table to show selection options for viewing user activity history
        activityTableView = UITableView(frame: CGRect(x: 0, y: viewContainer.frame.height * (3/4) - 100, width: viewContainer.frame.width, height: 200))
        activityTableView.dataSource = self
        activityTableView.delegate = self
        activityTableView.register(UITableViewCell.self, forCellReuseIdentifier: "activityCell")
        activityTableView.separatorStyle = .none
        activityTableView.backgroundColor = Constants.Colors.standardBackground
        activityTableView.isScrollEnabled = false
        activityTableView.bounces = false
        activityTableView.alwaysBounceVertical = false
        activityTableView.showsVerticalScrollIndicator = false
        activityTableView.isUserInteractionEnabled = true
        activityTableView.allowsSelection = true
        activityTableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        viewContainer.addSubview(activityTableView)
        
        let border1 = CALayer()
        border1.frame = CGRect(x: 0, y: 0, width: viewContainer.frame.width, height: 1)
        border1.backgroundColor = Constants.Colors.standardBackgroundGrayUltraLight.cgColor
        activityTableView.layer.addSublayer(border1)
        
        // Prepare the data and features
        setDefaultUserFeatures()
        refreshUserFeatures()
        
        NotificationCenter.default.addObserver(self, selector: #selector(ProfileViewController.statusBarHeightChange(_:)), name: Notification.Name("UIApplicationWillChangeStatusBarFrameNotification"), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        self.refreshUserFeatures()
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
    }
    
    func prepVcLayout()
    {
        // Device and Status Bar Settings
        UIApplication.shared.isStatusBarHidden = false
        UIApplication.shared.statusBarStyle = Constants.Settings.statusBarStyle
        statusBarHeight = UIApplication.shared.statusBarFrame.size.height
        navBarHeight = self.navigationController?.navigationBar.frame.height
        viewFrameY = self.view.frame.minY
        screenSize = UIScreen.main.bounds
        
        self.automaticallyAdjustsScrollViewInsets = false
        
        vcHeight = screenSize.height - statusBarHeight - navBarHeight
        vcOffsetY = statusBarHeight + navBarHeight
        if statusBarHeight == 40
        {
            vcHeight = screenSize.height - 76
            vcOffsetY = 56
        }
        
        // Navigation Bar settings
        if let navController = self.navigationController
        {
            navController.isNavigationBarHidden = false
            navBarHeight = navController.navigationBar.frame.height
            navController.navigationBar.barTintColor = Constants.Colors.colorOrangeOpaque
        }
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
        
        let ncTitle = UIView(frame: CGRect(x: screenSize.width / 2 - 100, y: 10, width: 200, height: 40))
        ncTitleText = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 40))
        ncTitleText.text = "My Profile"
        if let name = Constants.Data.currentUser.name
        {
            ncTitleText.text = name
        }
        
        ncTitleText.textColor = Constants.Colors.colorTextNavBar
        ncTitleText.font = UIFont(name: Constants.Strings.fontAlt, size: 22)
        ncTitleText.textAlignment = .center
        ncTitle.addSubview(ncTitleText)
        
        // Assign the created Nav Bar settings to the Tab Bar Controller
        self.navigationItem.titleView = ncTitle
        self.navigationItem.hidesBackButton = true
        self.navigationItem.setLeftBarButton(leftButtonItem, animated: false)
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
        return 4
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return cellHeight
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        print("PVC - CREATING CELL: \(indexPath.row)")
        let cell = tableView.dequeueReusableCell(withIdentifier: "activityCell", for: indexPath)
        
        // Remove all subviews
        for subview in cell.subviews
        {
            subview.removeFromSuperview()
        }
        
        let cellContainer = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: cellHeight))
        cell.addSubview(cellContainer)
        
        let cellImageView = UIImageView(frame: CGRect(x: (cellContainer.frame.width / 2) - 20, y: 5, width: 40, height: 40))
        cellImageView.contentMode = UIViewContentMode.scaleAspectFit
        cellImageView.clipsToBounds = true
        cellContainer.addSubview(cellImageView)
        
        let cellArrow = UILabel(frame: CGRect(x: cellContainer.frame.width - 50, y: 5, width: 40, height: 40))
        cellArrow.backgroundColor = UIColor.clear
        cellArrow.textAlignment = .center
        cellArrow.font = UIFont(name: "HelveticaNeue-UltraLight", size: 18)
        cellArrow.text = "\u{25BA}" //"\u{2192}"
        cellContainer.addSubview(cellArrow)
        
        let border1 = CALayer()
        border1.frame = CGRect(x: 0, y: cellHeight - 1, width: cellContainer.frame.width, height: 1)
        border1.backgroundColor = Constants.Colors.standardBackgroundGrayUltraLight.cgColor
        cellContainer.layer.addSublayer(border1)
        
        if indexPath.row == 0
        {
            cellImageView.image = UIImage(named: Constants.Strings.iconSettings)
        }
        else if indexPath.row == 1
        {
            cellImageView.image = UIImage(named: Constants.Strings.iconCamera)
        }
        else if indexPath.row == 2
        {
            cellImageView.image = UIImage(named: Constants.Strings.markerIconCamera)
        }
        else if indexPath.row == 3
        {
            cellImageView.image = UIImage(named: Constants.Strings.iconHazard)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        print("PVC - SELECTED CELL: \(indexPath.row)")
        
        // Create a back button and title for the Nav Bar
        let backButtonItem = UIBarButtonItem(title: "\u{2190}",
                                             style: UIBarButtonItemStyle.plain,
                                             target: self,
                                             action: #selector(MapViewController.popViewController(_:)))
        backButtonItem.tintColor = Constants.Colors.colorTextNavBar
        
        // Create a title for the view that shows the coordinates of the tapped spot
        let ncTitle = UIView(frame: CGRect(x: screenSize.width / 2 - 75, y: 10, width: 150, height: 40))
        let ncTitleText = UILabel(frame: CGRect(x: 0, y: 0, width: 150, height: 40))
        ncTitleText.textColor = Constants.Colors.colorTextNavBar
        ncTitleText.font = UIFont(name: Constants.Strings.fontAlt, size: 14)
        ncTitleText.textAlignment = .center
        ncTitle.addSubview(ncTitleText)
        
        if indexPath.row == 0
        {
            print("PVC - LAUNCH PROFILE SETTINGS VC")
            
            let tab1VC = ProfileTabVolunteerViewController()
            tab1VC.tabBarItem = UITabBarItem(title: "Volunteer", image: nil, selectedImage: nil)
            
            
//            let leftButtonItem = UIBarButtonItem(title: "\u{2190}",
//                                                 style: UIBarButtonItemStyle.plain,
//                                                 target: self,
//                                                 action: #selector(UserViewController.popViewController(_:)))
//            leftButtonItem.tintColor = Constants.Colors.colorTextNavBar
//            
//            let rightButtonItem = UIBarButtonItem(title: "",
//                                                  style: UIBarButtonItemStyle.plain,
//                                                  target: self,
//                                                  action: #selector(UserViewController.blankFunc(_:)))
//            rightButtonItem.tintColor = Constants.Colors.colorTextNavBar
//            
//            let ncTitle = UIView(frame: CGRect(x: screenSize.width / 2 - 100, y: 10, width: 200, height: 40))
//            ncTitleText = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 40))
//            ncTitleText.text = "My Volunteer Profile"
//            if let name = Constants.Data.currentUser.name
//            {
//                ncTitleText.text = name
//            }
//            
//            ncTitleText.textColor = Constants.Colors.colorTextNavBar
//            ncTitleText.font = UIFont(name: Constants.Strings.fontAlt, size: 22)
//            ncTitleText.textAlignment = .center
//            ncTitle.addSubview(ncTitleText)
//            
//            // Assign the created Nav Bar settings to the Tab Bar Controller
//            self.navigationItem.titleView = ncTitle
//            self.navigationItem.hidesBackButton = true
//            self.navigationItem.setLeftBarButton(leftButtonItem, animated: false)
            
            
            
            let tab2VC = ProfileTabHouseViewController()
            tab2VC.tabBarItem = UITabBarItem(title: "My House", image: nil, selectedImage: nil)
            
            
            // Navigation Bar settings
            let profileTabBarController = UITabBarController()
//            if let navCon = profileTabBarController.navigationController
//            {
//                navCon.isNavigationBarHidden = false
//                navCon.navigationBar.barTintColor = Constants.Colors.colorOrangeOpaque
//            }
            let controllers = [tab1VC,tab2VC]
            profileTabBarController.viewControllers = controllers
            self.navigationController!.pushViewController(profileTabBarController, animated: true)
        }
        else if indexPath.row == 1
        {
            var mySpots = [Spot]()
            for spot in Constants.Data.allSpot
            {
                if spot.userID == Constants.Data.currentUser.userID
                {
                    print("PVC - PREP ACTIVITIES - SPOT: \(spot.spotID)")
                    mySpots.append(spot)
                }
            }
            
            // Instantiate the Spot View Controller
            ncTitleText.text = "My Photos"
            
            let spotTableVC = SpotTableViewController(spots: mySpots, allowDelete: true)
            spotTableVC.spotTableDelegate = self
            spotTableVC.navigationItem.setLeftBarButton(backButtonItem, animated: true)
            spotTableVC.navigationItem.titleView = ncTitle
            
            if let navController = self.navigationController
            {
                navController.pushViewController(spotTableVC, animated: true)
            }
        }
        else if indexPath.row == 2
        {
            var mySpotRequests = [SpotRequest]()
            for sRequest in Constants.Data.allSpotRequest
            {
                print("PVC - PREP ACTIVITIES - SPOT REQUEST: \(String(describing: sRequest.requestID))")
                if sRequest.userID == Constants.Data.currentUser.userID
                {
                    mySpotRequests.append(sRequest)
                }
            }
            
            // Instantiate the Activity View Controller
            ncTitleText.text = "My Photo Requests"
            
            let spotRequestTableVC = ActivityViewController(spotRequests: mySpotRequests)
            spotRequestTableVC.navigationItem.setLeftBarButton(backButtonItem, animated: true)
            spotRequestTableVC.navigationItem.titleView = ncTitle
            
            if let navController = self.navigationController
            {
                navController.pushViewController(spotRequestTableVC, animated: true)
            }
        }
        else if indexPath.row == 3
        {
            var myHazards = [Hazard]()
            for hazard in Constants.Data.allHazard
            {
                print("PVC - PREP ACTIVITIES - HAZARD: \(String(describing: hazard.hazardID))")
                if hazard.userID == Constants.Data.currentUser.userID
                {
                    myHazards.append(hazard)
                }
            }
            
            // Instantiate the Activity View Controller
            ncTitleText.text = "My Hazard Reports"
            
            let activityTableVC = ActivityViewController(hazards: myHazards)
            activityTableVC.navigationItem.setLeftBarButton(backButtonItem, animated: true)
            activityTableVC.navigationItem.titleView = ncTitle
            
            if let navController = self.navigationController
            {
                navController.pushViewController(activityTableVC, animated: true)
            }
        }
        
        // Unhighlight the cell
        tableView.deselectRow(at: indexPath, animated: false)
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
    
    
    // MARK: FBSDK METHODS
    
    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!)
    {
        if ((error) != nil)
        {
            print("LVC - FBSDK ERROR: \(error)")
        }
        else if result.isCancelled
        {
            print("LVC - FBSDK IS CANCELLED: \(result.description)")
        }
        else
        {
            print("LVC - FBSDK COMPLETE w/ token: \(result.token)")
            
            // Log the user into Harvey
            AWSPrepRequest(requestToCall: AWSLoginUser(secondaryAwsRequestObject: nil), delegate: self as AWSRequestDelegate).prepRequest()
        }
    }
    
    func loginButtonWillLogin(_ loginButton: FBSDKLoginButton!) -> Bool
    {
        print("LVC - FBSDK WILL LOG IN: \(loginButton)")
        return true
    }
    
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!)
    {
        print("PVC - FBSDK DID LOG OUT: \(loginButton)")
        
        UtilityFunctions().logOutFBAndClearData()
        
        // Load the LoginVC
        let loginVC = LoginViewController()
        self.navigationController!.pushViewController(loginVC, animated: true)
    }
    
    
    // MARK: DATA METHODS
    
    func reloadData()
    {
    }
    
    func refreshUserFeatures()
    {
        print("PVC - REFRESH USER FEATURES")
        // If the user info is available, load the user info features
        if let uName = user.name
        {
            self.user.name = uName
            userName.text = uName
            ncTitleText.text = uName
        }
        if let uImage = user.image
        {
            self.user.image = uImage
            userImage.image = uImage
            
            // If the user image is still the thumbnail, request the large one again
            if uImage.size.width < 70
            {
                RequestPrep(requestToCall: FBDownloadUserImage(facebookID: Constants.Data.currentUser.facebookID, largeImage: true), delegate: self as RequestDelegate).prepRequest()
            }
        }
        else
        {
            // THIS MIGHT NOT EVER BE CALLED (image filled with thumbnail at minimum?)
            // Just use the thumbnail for now
            if let uThumbnail = user.thumbnail
            {
                userImage.image = uThumbnail
            }
            
            // Request the large image
            RequestPrep(requestToCall: FBDownloadUserImage(facebookID: user.facebookID, largeImage: true), delegate: self as RequestDelegate).prepRequest()
        }
    }
    func setDefaultUserFeatures()
    {
        userImage.image = UIImage(named: "PROFILE_DEFAULT.png")
        userName.text = "Please log in."
    }
    
    
    // MARK: AWS DELEGATE METHODS
    
    func showLoginScreen()
    {
        print("PVC - SHOW LOGIN SCREEN")
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
                case let awsLoginUser as AWSLoginUser:
                    if success
                    {
                        // Check whether the user has accepted the agreement
                        if let user = awsLoginUser.user
                        {
                            print("PVC-AWSLoginUser: \(String(describing: user.name))")
                        }
                    }
                    else
                    {
                        if awsLoginUser.banned
                        {
                            // Show the error message
                            let alert = UtilityFunctions().createAlertOkView("Banned", message: "I'm sorry, you have been banned from Harveytown.  Please contact admin@tangojlabs.com if you think this is an error.")
                            alert.show()
                            
                            UtilityFunctions().logOutFBAndClearData()
                            
                            // Load the LoginVC
                            let loginVC = LoginViewController()
                            self.navigationController!.pushViewController(loginVC, animated: true)
                        }
                        else
                        {
                            print("ERROR: AWSLoginUser")
                            // Show the error message
                            let alert = UtilityFunctions().createAlertOkView("Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
                            alert.show()
                        }
                    }
                case _ as AWSPutUserConnection:
                    if success
                    {
                        self.popViewController()
                    }
                    else
                    {
                        print("PVC - AWS ERROR: AWSPutUserConnection")
                        // Show the error message
                        let alert = UtilityFunctions().createAlertOkView("Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
                        alert.show()
                    }
                default:
                    print("PVC-DEFAULT: THERE WAS AN ISSUE WITH THE DATA RETURNED FROM AWS")
                    
                    // Show the error message
                    let alert = UtilityFunctions().createAlertOkView("Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
                    alert.show()
                }
        })
    }
    
    func processRequestReturn(_ requestCalled: RequestObject, success: Bool)
    {
        // Process the return data based on the method used
        switch requestCalled
        {
        case _ as FBDownloadUserImage:
            if success
            {
                print("PVC - DOWNLOADED USER IMAGE")
                self.refreshUserFeatures()
            }
            else
            {
                // Show the error message
                let alert = UtilityFunctions().createAlertOkView("Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
                alert.show()
            }
        default:
            // Show the error message
            let alert = UtilityFunctions().createAlertOkView("Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
            alert.show()
        }
    }
}
