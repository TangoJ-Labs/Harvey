//
//  UserViewController.swift
//  Harvey
//
//  Created by Sean Hart on 9/8/17.
//  Copyright © 2017 tangojlabs. All rights reserved.
//

import UIKit

class UserViewController: UIViewController, AWSRequestDelegate, RequestDelegate
{
    var user: User!
    
    convenience init(user: User!)
    {
        self.init(nibName:nil, bundle:nil)
        
        if let user = user
        {
            self.user = user
        }
    }
    
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
    
    var contentContainer: UIView!
    var userImage: UIImageView!
    var userName: UILabel!
    
    var blockButton: UIView!
    var blockButtonLabel: UILabel!
    var blockButtonTapGesture: UITapGestureRecognizer!
    
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
        contentContainer = UIView(frame: CGRect(x: 0, y: (viewContainer.frame.height / 2) - 120, width: viewContainer.frame.width, height: 240))
        contentContainer.backgroundColor = Constants.Colors.standardBackground
        viewContainer.addSubview(contentContainer)
        
        // Add the user image and name
        userImage = UIImageView(frame: CGRect(x: (contentContainer.frame.width / 2) - 50, y: 10, width: 100, height: 100))
        userImage.layer.cornerRadius = userImage.frame.height / 2
        userImage.contentMode = UIViewContentMode.scaleAspectFill
        userImage.clipsToBounds = true
        contentContainer.addSubview(userImage)
        
        userName = UILabel(frame: CGRect(x: 5, y: 120, width: contentContainer.frame.width - 10, height: 20))
        userName.backgroundColor = UIColor.clear
        userName.textAlignment = .center
        userName.font = UIFont(name: "HelveticaNeue-UltraLight", size: 18)
        contentContainer.addSubview(userName)
        
        // Create a button to block the user, if needed
        blockButton = UIView(frame: CGRect(x: 0, y: (viewContainer.frame.height / 2) + 150, width: viewContainer.frame.width, height: 50))
        blockButton.backgroundColor = Constants.Colors.colorGrayDark
        viewContainer.addSubview(blockButton)
        
        blockButtonLabel = UILabel(frame: CGRect(x: 10, y: 10, width: blockButton.frame.width - 20, height: 30))
        blockButtonLabel.backgroundColor = UIColor.clear
        blockButtonLabel.textColor = UIColor.white
        blockButtonLabel.textAlignment = .center
        blockButtonLabel.font = UIFont(name: "HelveticaNeue-UltraLight", size: 24)
        blockButtonLabel.text = "Block User"
        blockButton.addSubview(blockButtonLabel)
        
        blockButtonTapGesture = UITapGestureRecognizer(target: self, action: #selector(UserViewController.blockButtonTap(_:)))
        blockButtonTapGesture.numberOfTapsRequired = 1  // add single tap
        blockButton.addGestureRecognizer(blockButtonTapGesture)
        
        // Prepare the data and features
        setDefaultUserFeatures()
        refreshUserFeatures()
        
        // Request the large user image
        RequestPrep(requestToCall: FBDownloadUserImage(facebookID: user.facebookID, largeImage: true), delegate: self as RequestDelegate).prepRequest()
        
        NotificationCenter.default.addObserver(self, selector: #selector(MapViewController.statusBarHeightChange(_:)), name: Notification.Name("UIApplicationWillChangeStatusBarFrameNotification"), object: nil)
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
        if let name = user.name
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
        // Confirm that the current user wants to block the user
        var message = "Are you sure you want to block this user?"
        if let name = user.name
        {
            message = "Are you sure you want to block \(name)?"
        }
        let alertController = UIAlertController(title: "Block User", message: message, preferredStyle: UIAlertControllerStyle.alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel)
        { (result : UIAlertAction) -> Void in
            print("CANCEL BLOCK")
        }
        let confirmAction = UIAlertAction(title: "Block", style: UIAlertActionStyle.default)
        { (result : UIAlertAction) -> Void in
            print("BLOCK USER")
            // Change the user status to blocked
            AWSPrepRequest(requestToCall: AWSPutUserConnection(targetUserID: self.user.userID, connection: "blocked"), delegate: self as AWSRequestDelegate).prepRequest()
        }
        alertController.addAction(cancelAction)
        alertController.addAction(confirmAction)
        alertController.show()
    }
    
    
    
    // MARK: DATA METHODS
    
    func refreshUserFeatures()
    {
        userLoop: for user in Constants.Data.allUsers
        {
            if user.userID == self.user.userID
            {
                // If the user info is available, load the user info features
                if let uName = user.name
                {
                    self.user.name = uName
                    userName.text = uName
                    ncTitleText.text = uName
                    blockButtonLabel.text = "Block \(uName)"
                }
                if let uImage = user.image
                {
                    self.user.image = uImage
                    userImage.image = uImage
                }
                else
                {
                    // Just use the thumbnail for now
                    if let uThumbnail = user.thumbnail
                    {
                        userImage.image = uThumbnail
                    }
                }
                break userLoop
            }
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
        print("UVC - SHOW LOGIN SCREEN")
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
                case _ as AWSPutUserConnection:
                    if success
                    {
                        self.popViewController()
                    }
                    else
                    {
                        print("ERROR: AWSLoginUser")
                        // Show the error message
                        let alert = UtilityFunctions().createAlertOkView("Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
                        alert.show()
                    }
                default:
                    print("UVC-DEFAULT: THERE WAS AN ISSUE WITH THE DATA RETURNED FROM AWS")
                    
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
                print("UVC - DOWNLOADED USER IMAGE")
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
