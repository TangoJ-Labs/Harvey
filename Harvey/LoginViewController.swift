//
//  LoginViewController.swift
//  Harvey
//
//  Created by Sean Hart on 8/29/17.
//  Copyright © 2017 tangojlabs. All rights reserved.
//

import FBSDKLoginKit
import ImageIO
import MobileCoreServices
import UIKit


class LoginViewController: UIViewController, FBSDKLoginButtonDelegate, AWSRequestDelegate, RequestDelegate
{
    // Save device settings to adjust view if needed
    var screenSize: CGRect!
    var statusBarHeight: CGFloat!
    var navBarHeight: CGFloat!
    var viewFrameY: CGFloat!
    var vcHeight: CGFloat!
    var vcOffsetY: CGFloat!
    
    // The views to hold major components of the view controller
    var statusBarView: UIView!
    var viewContainer: UIView!
    
    var contentContainer: UIView!
//    var exitButton: UIView!
//    var exitLabel: UILabel!
//    var exitButtonTapGesture: UITapGestureRecognizer!
    var userImage: UIImageView!
    var userName: UILabel!
    
    var loginBox: UIView!
    var fbLoginButton: FBSDKLoginButton!
    var loginActivityIndicator: UIActivityIndicatorView!
    var loginProcessLabel: UILabel!
    
    var clearLogin: Bool = false
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.edgesForExtendedLayout = UIRectEdge.all
        
        prepVcLayout()
        
        // Set the navBar settings - Create bar buttons and title for the Nav Bar
        // Only show the back bar button if the user is logged in (then viewing from parent view)
//        var backButtonIcon = ""
//        if Constants.Data.currentUser.facebookID != nil
//        {
//            backButtonIcon = "\u{2190}"
//        }
        let leftButtonItem = UIBarButtonItem(title: "",
                                              style: UIBarButtonItemStyle.plain,
                                              target: self,
                                              action: #selector(LoginViewController.blankFunc(_:)))
        leftButtonItem.tintColor = Constants.Colors.colorTextNavBar
        
        let rightButtonItem = UIBarButtonItem(title: "",
                                              style: UIBarButtonItemStyle.plain,
                                              target: self,
                                              action: #selector(LoginViewController.blankFunc(_:)))
        rightButtonItem.tintColor = Constants.Colors.colorTextNavBar
        
        let ncTitle = UIView(frame: CGRect(x: screenSize.width / 2 - 100, y: 10, width: 200, height: 40))
        let ncTitleText = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 40))
        ncTitleText.text = "LOG IN"
        
        ncTitleText.textColor = Constants.Colors.colorTextNavBar
        ncTitleText.font = UIFont(name: Constants.Strings.fontAlt, size: 22)
        ncTitleText.textAlignment = .center
        ncTitle.addSubview(ncTitleText)
        
        // Assign the created Nav Bar settings to the Tab Bar Controller
        self.navigationItem.titleView = ncTitle
        self.navigationItem.hidesBackButton = true
        self.navigationItem.setLeftBarButton(leftButtonItem, animated: false)
        
        // Check to see if the facebook user id is already in the FBSDK - if so, the user recalled the view, so show the exit button
        if (FBSDKAccessToken.current()) != nil
        {
            self.navigationItem.setRightBarButton(rightButtonItem, animated: true)
        }
        
        // Add the Status Bar, Top Bar and Search Bar last so that they are placed above (z-index) all other views
        statusBarView = UIView(frame: CGRect(x: 0, y: 0, width: screenSize.width, height: statusBarHeight))
        statusBarView.backgroundColor = Constants.Colors.colorStatusBar
        self.view.addSubview(statusBarView)
        
        // Add the view container to hold all other views (allows for shadows on all subviews)
//        viewContainer = UIView(frame: CGRect(x: screenSize.width / 4, y: vcHeight / 4, width: screenSize.width / 2, height: vcHeight / 2))
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
        setDefaultUserFeatures()
        refreshUserFeatures()
        
//        // Check to see if the facebook user id is already in the FBSDK - if so, the user recalled the view, so show the exit button
//        if let facebookToken = FBSDKAccessToken.current()
//        {
//            // Add the Exit Camera Button and overlaid Tap View for more tap coverage
//            exitButton = UIView(frame: CGRect(x: viewContainer.frame.width - 60, y: 40, width: 40, height: 40))
//            exitButton.layer.cornerRadius = 20
//            exitButton.backgroundColor = UIColor.white.withAlphaComponent(0.3)
//            viewContainer.addSubview(exitButton)
//            
//            exitLabel = UILabel(frame: CGRect(x: 5, y: 5, width: 30, height: 30))
//            exitLabel.backgroundColor = UIColor.clear
//            exitLabel.text = "\u{274c}"
//            exitLabel.textAlignment = .center
//            exitLabel.font = UIFont(name: "HelveticaNeue-UltraLight", size: 18)
//            exitButton.addSubview(exitLabel)
//            
//            exitButtonTapGesture = UITapGestureRecognizer(target: self, action: #selector(LoginViewController.exitButtonTap(_:)))
//            exitButtonTapGesture.numberOfTapsRequired = 1  // add single tap
//            exitButton.addGestureRecognizer(exitButtonTapGesture)
//        }
        
        loginBox = UIView(frame: CGRect(x: (contentContainer.frame.width / 2) - 140, y: 190, width: 280, height: 100))
//        loginBox.layer.cornerRadius = 5
//        loginBox.backgroundColor = Constants.Colors.colorFacebookDarkBlue
        contentContainer.addSubview(loginBox)
        
        fbLoginButton = FBSDKLoginButton()
        fbLoginButton.center = CGPoint(x: loginBox.frame.width / 2, y: 10)
        fbLoginButton.readPermissions = ["public_profile", "email"]
        fbLoginButton.delegate = self
        loginBox.addSubview(fbLoginButton)
        
        loginProcessLabel = UILabel(frame: CGRect(x: 0, y: loginBox.frame.height - 50, width: loginBox.frame.width, height: 20))
        loginProcessLabel.font = UIFont(name: Constants.Strings.fontAlt, size: 12)
        loginProcessLabel.text = "Logging you in..."
        loginProcessLabel.textColor = UIColor.black
        loginProcessLabel.textAlignment = .center
        
        // Add a loading indicator for the pause showing the "Log out" button after the FBSDK is logged in and before the Account VC loads
        loginActivityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: loginBox.frame.height - 30, width: loginBox.frame.width, height: 30))
        loginActivityIndicator.color = UIColor.black
        loginBox.addSubview(loginActivityIndicator)
        
        NotificationCenter.default.addObserver(self, selector: #selector(MapViewController.statusBarHeightChange(_:)), name: Notification.Name("UIApplicationWillChangeStatusBarFrameNotification"), object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
//        print("LVC - VIEW DID APPEAR")
        if clearLogin
        {
            setDefaultUserFeatures()
        }
        else
        {
            refreshUserFeatures()
        }
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        refreshUserFeatures()
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func refreshUserFeatures()
    {
        // If the user info is available, load the user info features
        if let uName = Constants.Data.currentUser.name
        {
            print("LVC-CURRENT USER: \(uName)")
            userName.text = uName
        }
        if let uImage = Constants.Data.currentUser.image
        {
            print("LVC-CURRENT USER: \(uImage.size)")
            userImage.image = uImage
            
            // If the user image is still the thumbnail, request the large one again
            if uImage.size.width < 70
            {
                RequestPrep(requestToCall: FBDownloadUserImage(facebookID: Constants.Data.currentUser.facebookID, largeImage: true), delegate: self as RequestDelegate).prepRequest()
            }
        }
    }
    func setDefaultUserFeatures()
    {
        userImage.image = UIImage(named: "PROFILE_DEFAULT.png")
        userName.text = "Please log in."
    }
    
    
    // MARK: TAP GESTURES
    func exitButtonTap(_ gesture: UITapGestureRecognizer)
    {
        // If the exit button is showing, the view was loaded from another view, so pop the VC
        popViewController()
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
    func loadMapVC(_ sender: UIBarButtonItem)
    {
        // Load the MapVC - the sender was the back button, so the user should have already agreed to the policies (no need to show)
        let mapVC = MapViewController()
        mapVC.showAgreement = false
        self.navigationController!.pushViewController(mapVC, animated: true)
    }
    func loadMapVC(showAgreement: Bool)
    {
        // Load the MapVC
        let mapVC = MapViewController()
        mapVC.showAgreement = showAgreement
        self.navigationController!.pushViewController(mapVC, animated: true)
    }
    func loadAgreementVC()
    {
        // Load the AgreementVC
        let agreementVC = AgreementViewController()
        self.navigationController!.pushViewController(agreementVC, animated: true)
    }
    func blankFunc(_ sender: UIBarButtonItem)
    {
    }
    
    
    func statusBarHeightChange(_ notification: Notification)
    {
        prepVcLayout()
        
        statusBarView.frame = CGRect(x: 0, y: 0, width: screenSize.width, height: statusBarHeight)
        viewContainer.frame = CGRect(x: 0, y: vcOffsetY, width: screenSize.width, height: vcHeight)
        contentContainer.frame = CGRect(x: 0, y: (viewContainer.frame.height / 2) - 120, width: viewContainer.frame.width, height: 240)
    }
    
    func prepVcLayout()
    {
        // Record the status bar settings to adjust the view if needed
        UIApplication.shared.isStatusBarHidden = false
        UIApplication.shared.statusBarStyle = Constants.Settings.statusBarStyle
        statusBarHeight = UIApplication.shared.statusBarFrame.size.height
        
        // Navigation Bar settings
        navBarHeight = 44.0
        if let navController = self.navigationController
        {
            navController.isNavigationBarHidden = false
            navBarHeight = navController.navigationBar.frame.height
            navController.navigationBar.barTintColor = Constants.Colors.colorOrangeOpaque
        }
        viewFrameY = self.view.frame.minY
        screenSize = UIScreen.main.bounds
        
        vcHeight = screenSize.height - statusBarHeight - navBarHeight
        vcOffsetY = statusBarHeight + navBarHeight
        if statusBarHeight == 40
        {
            vcHeight = screenSize.height - 76
            vcOffsetY = 56
        }
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
            // Show the logging in indicator and label
            loginActivityIndicator.startAnimating()
            loginBox.addSubview(loginProcessLabel)
            
            // Log the user into Harvey
            AWSPrepRequest(requestToCall: AWSLoginUser(secondaryAwsRequestObject: nil), delegate: self as AWSRequestDelegate).prepRequest()
        }
    }
    
    func loginButtonWillLogin(_ loginButton: FBSDKLoginButton!) -> Bool
    {
//        print("LVC - FBSDK WILL LOG IN: \(loginButton)")
        return true
    }
    
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!)
    {
//        print("LVC - FBSDK DID LOG OUT: \(loginButton)")
        
        // Reset the user features
        setDefaultUserFeatures()
        
        Constants.credentialsProvider.clearCredentials()
        Constants.credentialsProvider.clearKeychain()
        
        // Remove the back button so that the user is required to log in to continue
        let leftButtonItem = UIBarButtonItem(title: "",
                                              style: UIBarButtonItemStyle.plain,
                                              target: self,
                                              action: #selector(LoginViewController.blankFunc(_:)))
        leftButtonItem.tintColor = Constants.Colors.colorTextNavBar
        self.navigationItem.setLeftBarButton(leftButtonItem, animated: true)
        
//        // Remove the exitButton so that the user is required to login to continue
//        exitButton.removeFromSuperview()
        
        // Hide the logging in indicator and label
        loginActivityIndicator.stopAnimating()
        loginProcessLabel.removeFromSuperview()
    }
    
    
    // MARK: AWS DELEGATE METHODS
    
    func showLoginScreen()
    {
        print("LVC - SHOW LOGIN SCREEN")
        // Already there - log out the user from FB to start over
//        self.fbLoginButton.
        
        let loginManager = FBSDKLoginManager()
        loginManager.logOut()
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
                            print("LVC-AWSLoginUser: \(String(describing: user.name))")
                            if user.status != "eula_privacy_none"
                            {
                                self.loadMapVC(showAgreement: false)
                            }
                            else
                            {
                                self.loadMapVC(showAgreement: true)
                            }
                        }
                    }
                    else
                    {
                        if awsLoginUser.banned
                        {
                            // Show the error message
                            let alert = UtilityFunctions().createAlertOkView("Banned", message: "I'm sorry, you have been banned from Harveytown.  Please contact admin@tangojlabs.com if you think this is an error.")
                            alert.show()
                            
                            // Log out the user
                            let loginManager = FBSDKLoginManager()
                            loginManager.logOut()
                            
                            // Reset the user features
                            self.setDefaultUserFeatures()
                            
                            // Hide the logging in indicator and label
                            self.loginActivityIndicator.stopAnimating()
                            self.loginProcessLabel.removeFromSuperview()
                        }
                        else
                        {
                            print("ERROR: AWSLoginUser")
                            // Show the error message
                            let alert = UtilityFunctions().createAlertOkView("Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
                            alert.show()
                        }
                    }
                default:
                    print("LVC-DEFAULT: THERE WAS AN ISSUE WITH THE DATA RETURNED FROM AWS")
                    
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
                print("LVC - DOWNLOADED USER IMAGE")
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
