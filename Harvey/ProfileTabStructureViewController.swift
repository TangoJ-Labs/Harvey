//
//  ProfileTabStructureViewController.swift
//  Harvey
//
//  Created by Sean Hart on 9/15/17.
//  Copyright © 2017 TangoJ Labs, LLC. All rights reserved.
//

import UIKit


class ProfileTabStructureViewController: UIViewController, UIGestureRecognizerDelegate, UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate, AWSRequestDelegate, CameraViewControllerDelegate
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
    var viewSpinner: UIActivityIndicatorView!
    
    var backgroundLabel: UILabel!
    var structureTableView: UITableView!
    var addStructureButton: UIView!
    var addStructureLabel: UILabel!
    var tableBorder: CALayer!
    
    var addButton: UIView!
    var addButtonLabel: UILabel!
    var addButtonTapGestureRecognizer: UITapGestureRecognizer!
    
    let addButtonHeight: CGFloat = 70
    
    var structureList = [Structure]()
    var userStructureCount = 0
    
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
        backgroundLabel.text = "You haven't added any homes needing repair.  Tap the button below to add one."
        
        // A tableview will hold all structures
        structureTableView = UITableView(frame: CGRect(x: 0, y: 0, width: viewContainer.frame.width, height: viewContainer.frame.height - addButtonHeight))
        structureTableView.dataSource = self
        structureTableView.delegate = self
        structureTableView.register(ProfileTabStructureTableViewCell.self, forCellReuseIdentifier: Constants.Strings.profileTabStructureTableViewCellReuseIdentifier)
        structureTableView.separatorStyle = .none
        structureTableView.backgroundColor = UIColor.clear //Constants.Colors.standardBackground
        structureTableView.isScrollEnabled = true
        structureTableView.bounces = true
        structureTableView.alwaysBounceVertical = true
        structureTableView.showsVerticalScrollIndicator = false
        structureTableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        viewContainer.addSubview(structureTableView)
        
        tableBorder = CALayer()
        tableBorder.frame = CGRect(x: 0, y: 0, width: structureTableView.frame.width, height: 1)
        tableBorder.backgroundColor = Constants.Colors.standardBackgroundGrayUltraLight.cgColor
        
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
        
        requestData()
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        prepVcLayout()
        prepFrames()
        
        reloadStructureTable()
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
    }
    
    
    // MARK: LAYOUT METHODS
    
    func statusBarHeightChange(_ notification: Notification)
    {
        prepVcLayout()
        prepFrames()
    }
    
    func prepFrames()
    {
        statusBarView.frame = CGRect(x: 0, y: 0, width: screenSize.width, height: statusBarHeight)
        viewContainer.frame = CGRect(x: 0, y: vcOffsetY, width: screenSize.width, height: vcHeight)
        viewSpinner.frame = CGRect(x: 0, y: 0, width: viewContainer.frame.width, height: viewContainer.frame.height)
        structureTableView.frame = CGRect(x: 0, y: 0, width: viewContainer.frame.width, height: viewContainer.frame.height - addButtonHeight)
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
        
        // Assign the created Nav Bar settings to the Tab Bar Controller
        self.navigationItem.titleView = ncTitle
        self.navigationItem.hidesBackButton = true
        self.navigationItem.setLeftBarButton(leftButtonItem, animated: false)
        
        // Device and Status Bar Settings
        UIApplication.shared.isStatusBarHidden = false
        UIApplication.shared.statusBarStyle = Constants.Settings.statusBarStyle
        statusBarHeight = UIApplication.shared.statusBarFrame.size.height
        navBarHeight = 44
        if let tabCon = self.tabBarController
        {
            tabBarHeight = tabCon.tabBar.frame.height
            print("PTSVC - STATUS BAR HEIGHT: \(statusBarHeight)")
            print("PTSVC - TAB BAR HEIGHT: \(tabBarHeight)")
            tabCon.navigationItem.titleView = ncTitle
            tabCon.navigationItem.hidesBackButton = true
            tabCon.navigationItem.setLeftBarButton(leftButtonItem, animated: false)
            
            print("PTSVC - TAB CON: \(tabCon)")
            if let navCon = tabCon.navigationController
            {
                print("PTSVC - NAV CON: \(navCon)")
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
        print("PTSVC - CHECK DIMS: \(screenSize), \(vcHeight), \(statusBarHeight), \(navBarHeight), \(tabBarHeight)")
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
        // Explain that a photo is needed to create the Structure - allow the user to cancel
        let alertController = UIAlertController(title: "Photo Required", message: "A house profile photo is required - Please take a photo of the outside of the house.  Other users will see this photo when viewing information regarding this house.", preferredStyle: UIAlertControllerStyle.alert)
        let laterAction = UIAlertAction(title: "Later", style: UIAlertActionStyle.default)
        { (result : UIAlertAction) -> Void in
            print("PTSVC - CAMERA POPUP - LATER")
            
        }
        alertController.addAction(laterAction)
        let okAction = UIAlertAction(title: "Ok", style: UIAlertActionStyle.default)
        { (result : UIAlertAction) -> Void in
            print("PTSVC - CAMERA POPUP - OK")
            // Load the camera view and only allow one photo to be taken
            if let navCon = self.navigationController
            {
                let cameraVC = CameraSingleImageViewController()
                cameraVC.cameraDelegate = self
                cameraVC.newStructure = true
                navCon.pushViewController(cameraVC, animated: true)
            }
        }
        alertController.addAction(okAction)
        alertController.show()
    }
    
    // MARK: TABLE VIEW DATA SOURCE
    
    func numberOfSections(in tableView: UITableView) -> Int
    {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        let rowCount = structureList.count
        // Only add the table border if it contains data
        if rowCount > 0
        {
            structureTableView.layer.addSublayer(tableBorder)
        }
        else
        {
            tableBorder.removeFromSuperlayer()
        }
        return rowCount
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return screenSize.width //Constants.Dim.structureCellHeight
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        print("PTSVC - CREATING CELL: \(indexPath.row), FOR STRUCTURE: \(structureList[indexPath.row].structureID)")
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.Strings.profileTabStructureTableViewCellReuseIdentifier, for: indexPath) as! ProfileTabStructureTableViewCell
        
        // Remove all subviews
        for subview in cell.subviews
        {
            subview.removeFromSuperview()
        }
        
        cell.cellContainer = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: tableView.frame.width))
        cell.addSubview(cell.cellContainer)
        
        cell.structureImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: cell.cellContainer.frame.width, height: cell.cellContainer.frame.width))
        cell.structureImageView.contentMode = UIViewContentMode.scaleAspectFill
        cell.structureImageView.clipsToBounds = true
//        cellContainer.addSubview(structureImageView)
        
        cell.imageSpinner = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: cell.structureImageView.frame.width, height: cell.structureImageView.frame.height))
        cell.imageSpinner.color = Constants.Colors.colorGrayDark
        cell.cellContainer.addSubview(cell.imageSpinner)
        
        cell.border1.frame = CGRect(x: 0, y: cell.cellContainer.frame.height - 1, width: cell.cellContainer.frame.width, height: 1)
        cell.border1.backgroundColor = Constants.Colors.standardBackgroundGrayUltraLight.cgColor
        cell.cellContainer.layer.addSublayer(cell.border1)
        
//        cell.cellContainer = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: tableView.frame.width))
////        cell.cellContainer = UIView(frame: CGRect(x: 0, y: 0, width: cell.frame.width, height: cell.frame.height))
//        cell.structureImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: cell.cellContainer.frame.width, height: cell.cellContainer.frame.width))
//        cell.imageSpinner = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: cell.structureImageView.frame.width, height: cell.structureImageView.frame.height))
//        cell.border1.frame = CGRect(x: 0, y: cell.cellContainer.frame.height - 1, width: cell.cellContainer.frame.width, height: 1)
        
        cell.imageSpinner.startAnimating()
        if let image = structureList[indexPath.row].image
        {
            cell.cellContainer.addSubview(cell.structureImageView)
            cell.structureImageView.image = image
            cell.imageSpinner.stopAnimating()
        }
        else
        {
            // Download the image if the stringID is available
            if let mediaID = structureList[indexPath.row].imageID
            {
                print("PTSVC - DOWNLOAD IMAGE FOR STRUCTURE: \(structureList[indexPath.row].structureID)")
                AWSPrepRequest(requestToCall: AWSDownloadMediaImage(imageID: mediaID), delegate: self as AWSRequestDelegate).prepRequest()
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath)
    {
        print("PTSVC - WILL DISPLAY CELL: \(indexPath.row)")
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        print("PTSVC - SELECTED CELL: \(indexPath.row)")
        
        // Unhighlight the cell
        tableView.deselectRow(at: indexPath, animated: true)
        
        // Load the Repair table view controller with repair data for this Structure
        let repairVC = ProfileRepairViewController(structure: self.structureList[indexPath.row])
        if let navController = self.navigationController
        {
            navController.pushViewController(repairVC, animated: true)
        }
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
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath)
    {
        print("PTSVC - EDIT STYLE FOR ROW: \(indexPath.row)")
    }
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool
    {
        return true
    }
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]?
    {
        print("PTSVC - EDIT ACTIONS FOR ROW: \(indexPath.row)")
        let replaceImageAction = UITableViewRowAction(style: .normal, title: "Replace\nImage")
        { action, index in
            print("PTSVC - REPLACE IMAGE FOR STRUCTURE AT ROW: \(indexPath.row)")
            // Load the camera view and only allow one photo to be taken
            if let navCon = self.navigationController
            {
                let cameraVC = CameraSingleImageViewController()
                cameraVC.cameraDelegate = self
                cameraVC.newStructure = false
                cameraVC.structure = self.structureList[indexPath.row]
                navCon.pushViewController(cameraVC, animated: true)
            }
        }
        replaceImageAction.backgroundColor = Constants.Colors.colorBlue
        
        let deleteAction = UITableViewRowAction(style: .normal, title: "Delete")
        { action, index in
            // Show the popup message confirming the deletion request
            let alertController = UIAlertController(title: "Confirm Delete", message: "Are you sure you want to delete this house profile?", preferredStyle: UIAlertControllerStyle.alert)
            let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.default)
            { (result : UIAlertAction) -> Void in
                print("PTSVC - POPUP DELETE CANCEL")
                
            }
            let deleteAction = UIAlertAction(title: "Delete", style: UIAlertActionStyle.default)
            { (result : UIAlertAction) -> Void in
                print("PTSVC - POPUP DELETE CONFIRM")
                print("PTSVC - DELETE STRUCTURE AT ROW: \(indexPath.row)")
                // Indicate this structure as deleted in the database
                AWSPrepRequest(requestToCall: AWSStructureDelete(structure: self.structureList[indexPath.row]), delegate: self as AWSRequestDelegate).prepRequest()
            }
            alertController.addAction(cancelAction)
            alertController.addAction(deleteAction)
            alertController.show()
        }
        deleteAction.backgroundColor = Constants.Colors.colorGrayDark
        return [replaceImageAction,deleteAction]
    }
    
    
    // MARK: SCROLL VIEW DELEGATE METHODS
    
    func scrollViewDidScroll(_ scrollView: UIScrollView)
    {
        
    }
    
    
    // MARK: DELEGATE METHODS
    
    func returnFromCamera(updatedRow: Int?)
    {
        print("PTSVC - RETURN FROM CAMERA")
        // The new Structure and StructureUser data was added to the global arrays - reload the data and table to show
        reloadStructureTable()
    }
    
    
    // MARK: CUSTOM METHODS
    
    func refreshStructureTable()
    {
        DispatchQueue.main.async(execute:
            {
                if self.structureTableView != nil
                {
                    print("PTSVC - REFRESH SKILL TABLE")
                    
                    // Reload the TableView
                    self.structureTableView.reloadData()
                }
        })
    }
    func reloadStructureTable()
    {
        self.structureList = Constants.Data.structures
        
        // Order the StructureList
        let structureListSort = self.structureList.sorted {
            $0.datetime > $1.datetime
        }
        self.structureList = structureListSort
        
        // Recount the user structures
        // Reset the counter for structures that the current user controls
        self.userStructureCount = 0
        // Request the structure data for all structures associated with this user
        for structureUser in Constants.Data.structureUsers
        {
            if structureUser.userID == Constants.Data.currentUser.userID
            {
                // Record the number of structures that should be returned - to know when all of them have returned a response
                self.userStructureCount += 1
            }
        }
        
        // If the list of shown structures is at least as large as the count of how many structures the current user controls,
        // then hide the spinner and display the background text if needed
        if self.structureList.count >= self.userStructureCount
        {
            self.viewSpinner.stopAnimating()
            if self.userStructureCount == 0
            {
                self.structureTableView.addSubview(self.backgroundLabel)
            }
            else
            {
                self.backgroundLabel.removeFromSuperview()
            }
        }
        
        refreshStructureTable()
    }
    
    func requestData()
    {
        print("PTSVC - REQUEST DATA")
        // Request all structureIDs associated with the current user
        let awsStructureUserQuery = AWSStructureUserQuery()
        awsStructureUserQuery.userID = Constants.Data.currentUser.userID
        AWSPrepRequest(requestToCall: awsStructureUserQuery, delegate: self as AWSRequestDelegate).prepRequest()
    }
    
    
    // MARK: AWS DELEGATE METHODS
    
    func showLoginScreen()
    {
        print("PTSVC - SHOW LOGIN SCREEN")
        
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
                case let awsCreateRandomID as AWSCreateRandomID:
                    if success
                    {
                        print("PTSVC - AWS GET RANDOM ID: \(awsCreateRandomID)")
                        if let randomID = awsCreateRandomID.randomID
                        {
                            print("PRSTVC - RANDOM ID: \(randomID)")
                        }
                    }
                    else
                    {
                        print("PTSVC - AWS GET RANDOM ID - FAILURE")
                        // Show the error message
                        let alert = UtilityFunctions().createAlertOkView("Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
                        alert.show()
                    }
                case _ as AWSStructureUserQuery:
                    if success
                    {
                        print("PTSVC - AWS STRUCTURE-USER QUERY - SUCCESS")
                        // Reset the counter for structures that the current user controls
                        self.userStructureCount = 0
                        // Request the structure data for all structures associated with this user
                        for structureUser in Constants.Data.structureUsers
                        {
                            if structureUser.userID == Constants.Data.currentUser.userID
                            {
                                // Record the number of structures that should be returned - to know when all of them have returned a response
                                self.userStructureCount += 1
                                AWSPrepRequest(requestToCall: AWSStructureQuery(structureID: structureUser.structureID), delegate: self as AWSRequestDelegate).prepRequest()
                            }
                        }
                        // Reload the table in case the list is 0
                        self.reloadStructureTable()
                    }
                    else
                    {
                        print("PTSVC - AWS STRUCTURE-USER QUERY - FAILURE")
                        // Show the error message
                        let alert = UtilityFunctions().createAlertOkView("Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
                        alert.show()
                    }
                case _ as AWSStructureQuery:
                    if success
                    {
                        print("PTSVC - AWS STRUCTURE QUERY - SUCCESS")
                        self.reloadStructureTable()
                    }
                    else
                    {
                        print("PTSVC - AWS STRUCTURE QUERY - FAILURE")
                        // Show the error message
                        let alert = UtilityFunctions().createAlertOkView("Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
                        alert.show()
                    }
                case _ as AWSStructureDelete:
                    if success
                    {
                        print("PTSVC - AWS STRUCTURE DELETE - SUCCESS")
                        // Update the user structure count
                        print("PTSVC - DELETE - USER STRUCTURE COUNT: \(self.userStructureCount)")
                        self.userStructureCount -= 1
                        print("PTSVC - DELETE - USER STRUCTURE COUNT: \(self.userStructureCount)")
                        self.reloadStructureTable()
                    }
                    else
                    {
                        print("PTSVC - AWS STRUCTURE DELETE - FAILURE")
                        // Show the error message
                        let alert = UtilityFunctions().createAlertOkView("Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
                        alert.show()
                    }
                case let awsDownloadMediaImage as AWSDownloadMediaImage:
                    if success
                    {
                        print("PTSVC - AWSDownloadMediaImage - SUCCESS")
                        if let structureImage = awsDownloadMediaImage.contentImage
                        {
                            // Find the structure Object in the local array and add the downloaded image to the object variable
                            findStructureLoop: for structureObject in self.structureList
                            {
                                if structureObject.imageID == awsDownloadMediaImage.imageID
                                {
                                    print("PTSVC - AWSDownloadMediaImage - ADDED IMAGE TO LOCAL LIST")
                                    structureObject.image = structureImage
                                    break findStructureLoop
                                }
                            }
                            
                            // Find the structure Object in the global array and add the downloaded image to the object variable
                            findStructureLoop: for structureObject in Constants.Data.structures
                            {
                                if structureObject.imageID == awsDownloadMediaImage.imageID
                                {
                                    print("PTSVC - AWSDownloadMediaImage - ADDED IMAGE TO GLOBAL LIST")
                                    structureObject.image = structureImage
                                    break findStructureLoop
                                }
                            }
                            // Reload the TableView
                            self.reloadStructureTable()
                        }
                    }
                    else
                    {
                        // Show the error message
                        let alertController = UtilityFunctions().createAlertOkView("Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
                        self.present(alertController, animated: true, completion: nil)
                    }
                default:
                    print("PTSVC-DEFAULT: THERE WAS AN ISSUE WITH THE DATA RETURNED FROM AWS")
                    
                    // Show the error message
                    let alert = UtilityFunctions().createAlertOkView("Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
                    alert.show()
                }
        })
    }
}
