//
//  UserTableViewController.swift
//  Harvey
//
//  Created by Sean Hart on 9/9/17.
//  Copyright © 2017 TangoJ Labs, LLC. All rights reserved.
//

import UIKit

class UserTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate, UIGestureRecognizerDelegate, AWSRequestDelegate
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
    
    var userTableView: UITableView!
    lazy var refreshControl: UIRefreshControl = UIRefreshControl()
    var tableGestureRecognizer: UITapGestureRecognizer!
    
    var users = Constants.Data.allUsers
    
    override func viewDidLoad()
    {
        super.viewDidLoad()

        prepVcLayout()
        self.automaticallyAdjustsScrollViewInsets = false
        
        // Add the view container to hold all other views (allows for shadows on all subviews)
        viewContainer = UIView(frame: CGRect(x: 0, y: vcOffsetY, width: self.view.bounds.width, height: vcHeight))
        viewContainer.backgroundColor = Constants.Colors.standardBackgroundGrayUltraLight
        self.view.addSubview(viewContainer)
        
        // A tableview will hold all users
        userTableView = UITableView(frame: CGRect(x: 0, y: 0, width: viewContainer.frame.width, height: viewContainer.frame.height))
        userTableView.dataSource = self
        userTableView.delegate = self
        userTableView.register(SpotTableViewCell.self, forCellReuseIdentifier: Constants.Strings.userTableViewCellReuseIdentifier)
        userTableView.separatorStyle = .none
        userTableView.backgroundColor = Constants.Colors.standardBackground
        userTableView.isScrollEnabled = true
        userTableView.bounces = true
        userTableView.alwaysBounceVertical = true
        userTableView.allowsSelection = false
        userTableView.showsVerticalScrollIndicator = false
//        userTableView.isUserInteractionEnabled = true
//        userTableView.allowsSelection = true
        userTableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        viewContainer.addSubview(userTableView)
        
        tableGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UserTableViewController.tableGesture(_:)))
        tableGestureRecognizer.delegate = self
        userTableView.addGestureRecognizer(tableGestureRecognizer)
        
        // Create a refresh control for the CollectionView and add a subview to move the refresh control where needed
        refreshControl = UIRefreshControl()
        refreshControl.attributedTitle = NSAttributedString(string: "")
        refreshControl.addTarget(self, action: #selector(UserTableViewController.refreshDataManually), for: UIControlEvents.valueChanged)
        userTableView.addSubview(refreshControl)
        userTableView.contentOffset = CGPoint(x: 0, y: -self.refreshControl.frame.size.height)
        
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
        userTableView.frame = CGRect(x: 0, y: 0, width: viewContainer.frame.width, height: viewContainer.frame.height)
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
    

    // MARK: TABLE VIEW DATA SOURCE
    
    func numberOfSections(in tableView: UITableView) -> Int
    {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return Constants.Data.allUsers.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return Constants.Dim.userTableCellHeight
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        print("UTVC - CREATING CELL: \(indexPath.row)")
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.Strings.userTableViewCellReuseIdentifier, for: indexPath) as! UserTableViewCell
        
        // Store the user for this cell for reference
        let cellUser = Constants.Data.allUsers[indexPath.row]
        
        // Remove all subviews
        for subview in cell.subviews
        {
            subview.removeFromSuperview()
        }
        
        // Start animating the activity indicator
        cell.activityIndicator.startAnimating()
        // Assign the user image to the image if available - if not, assign the thumbnail until the real image downloads
        if let image = cellUser.image
        {
            print("STVC - ADDING IMAGE FOR USER: \(cellUser.userID)")
            cell.userImageView.image = image
            
            // Stop animating the activity indicator
            cell.activityIndicator.stopAnimating()
        }
        else if let thumbnail = cellUser.thumbnail
        {
            print("STVC - ADDING THUMBNAIL FOR USER: \(cellUser.userID)")
            cell.userImageView.image = thumbnail
            
            // Stop animating the activity indicator
            cell.activityIndicator.stopAnimating()
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        print("UTVC - SELECTED CELL: \(indexPath.row)")
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
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]?
    {
        let userSelect = users[indexPath.row]
        
        // Determine which block setting and title should be used
        var blockTitle = "BLOCK"
        var alertTitle = "BLOCK USER"
        var alertMessage = "Are you sure you want to block \(String(describing: userSelect.name))?"
        var connectionUpdateValue = "block"
        if userSelect.connection == "block"
        {
            blockTitle = "Unblock"
            alertTitle = "Unblock User"
            alertMessage = "Are you sure you want to unblock \(String(describing: userSelect.name))?"
            connectionUpdateValue = "na"
        }
        let block = UITableViewRowAction(style: .normal, title: blockTitle)
        { action, index in
            print("UTVC-ACTION-BLOCK")
            // Ensure the user wants to flag the content "Are you sure you want to report this image as objectionable or inaccurate?"
            let alertController = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: UIAlertControllerStyle.alert)
            let yesAction = UIAlertAction(title: "Yes", style: UIAlertActionStyle.default)
            { (result : UIAlertAction) -> Void in
                
                // change the user social status, refresh the table, and send the block user status change put request
                if blockTitle == "BLOCK"
                {
                    Constants.Data.allUserBlockList.append(userSelect.userID)
                    for user in Constants.Data.allUsers
                    {
                        if user.userID == userSelect.userID
                        {
                            user.connection = "block"
                        }
                    }
                }
                else
                {
                    for (bIndex, blockedUserID) in Constants.Data.allUserBlockList.enumerated()
                    {
                        if blockedUserID == userSelect.userID
                        {
                            Constants.Data.allUserBlockList.remove(at: bIndex)
                        }
                    }
                    for user in Constants.Data.allUsers
                    {
                        if user.userID == userSelect.userID
                        {
                            user.connection = "na"
                        }
                    }
                }
                self.reloadDataManually()
                
                // Upload the change
                AWSPrepRequest(requestToCall: AWSPutUserConnection(targetUserID: userSelect.userID, connection: connectionUpdateValue), delegate: self as AWSRequestDelegate).prepRequest()
            }
            let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.default)
            { (result : UIAlertAction) -> Void in
                print("UTVC - BLOCK / UNBLOCK CANCELLED")
            }
            alertController.addAction(cancelAction)
            alertController.addAction(yesAction)
            self.present(alertController, animated: true, completion: nil)
        }
        block.backgroundColor = Constants.Colors.colorGrayDark
        
        return [block]
    }
    
    // MARK: SCROLL VIEW DELEGATE METHODS
    
    func scrollViewDidScroll(_ scrollView: UIScrollView)
    {
        
    }
    
    
    // MARK: GESTURE RECOGNIZERS
    
    func tableGesture(_ gesture: UITapGestureRecognizer)
    {
//        if gesture.state == UIGestureRecognizerState.ended
//        {
//            let tapLocation = gesture.location(in: self.userTableView)
//            print("UTVC - TAP LOCATION: \(tapLocation)")
//            if let tappedIndexPath = userTableView.indexPathForRow(at: tapLocation)
//            {
//                print("UTVC - TAPPED INDEX PATH: \(tappedIndexPath)")
//                if let tappedCell = self.userTableView.cellForRow(at: tappedIndexPath) as? UserTableViewCell
//                {
//                    let cellTapLocation = gesture.location(in: tappedCell)
//                    if tappedCell.userImageView.frame.contains(cellTapLocation)
//                    {
//                        
//                    }
//                }
//            }
//        }
    }
    
    
    // MARK: CUSTOM METHODS
    
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
    
    func refreshTable()
    {
        DispatchQueue.main.async(execute:
            {
                if self.userTableView != nil
                {
                    // Reload the TableView
                    self.userTableView.performSelector(onMainThread: #selector(UITableView.reloadData), with: nil, waitUntilDone: true)
                }
        })
    }
    
    // Reload the local list from the global list
    func reloadDataManually()
    {
        users = Constants.Data.allUsers
        refreshTable()
    }
    // Request fresh data from the server
    func refreshDataManually()
    {
        
        refreshTable()
    }
    
    
    // MARK: AWS DELEGATE METHODS
    
    func showLoginScreen()
    {
        print("UTVC - SHOW LOGIN SCREEN")
        
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
                case _ as AWSUpdateSpotContentData:
                    if success
                    {
                        
                    }
                    else
                    {
                        // Show the error message
                        let alertController = UtilityFunctions().createAlertOkView("AWSGetMediaImage - Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
                        self.present(alertController, animated: true, completion: nil)
                    }
                default:
                    print("STVC-DEFAULT: THERE WAS AN ISSUE WITH THE DATA RETURNED FROM AWS")
                    // Show the error message
                    let alertController = UtilityFunctions().createAlertOkView("DEFAULT - Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
                    self.present(alertController, animated: true, completion: nil)
                }
        })
    }
}
