//
//  StructureViewController.swift
//  Harvey
//
//  Created by Sean Hart on 10/10/17.
//  Copyright © 2017 TangoJ Labs, LLC. All rights reserved.
//

import UIKit


class StructureViewController: UIViewController, UIGestureRecognizerDelegate, UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate, AWSRequestDelegate, RequestDelegate, HoleViewDelegate
{
    var structure: Structure!
    var primaryUser: User?
    
    convenience init(structure: Structure!)
    {
        self.init(nibName:nil, bundle:nil)
        
        self.structure = structure
    }
    
    // Save device settings to adjust view if needed
    var screenSize: CGRect!
    var statusBarHeight: CGFloat!
    var navBarHeight: CGFloat!
    var vcHeight: CGFloat!
    var vcOffsetY: CGFloat!
    
    var ncTitleText: UILabel!
    
    // The views to hold major components of the view controller
    var statusBarView: UIView!
    var viewContainer: UIView!
    
    var structureImageView: UIImageView!
    var structureImageSpinner: UIActivityIndicatorView!
    var repairTableView: UITableView!
    var repairTableViewBackgroundLabel: UILabel!
    var repairTableTapGestureRecognizer: UITapGestureRecognizer!
    var contactButton: UIView!
    var contactButtonImage: UIImageView!
    var contactButtonTapGestureRecognizer: UITapGestureRecognizer!
    
    var repairTableViewY: CGFloat = 200
    
    // Create a local repair list to only show those needed or in progress
    var activeRepairs = [Repair]()
    
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
        
        structureImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: viewContainer.frame.width, height: viewContainer.frame.width))
//        structureImageView.isUserInteractionEnabled = true // Needed to allow the contact button to work?
        structureImageView.contentMode = UIViewContentMode.scaleAspectFill
        structureImageView.clipsToBounds = true
        viewContainer.addSubview(structureImageView)
        
        structureImageSpinner = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: viewContainer.frame.width, height: viewContainer.frame.height))
        structureImageSpinner.color = Constants.Colors.colorGrayDark
        viewContainer.addSubview(structureImageSpinner)
        structureImageSpinner.startAnimating()
        
        repairTableViewY = viewContainer.frame.width
        // A tableview will hold all repairs
        repairTableView = UITableView(frame: CGRect(x: 0, y: repairTableViewY, width: viewContainer.frame.width, height: viewContainer.frame.height - repairTableViewY))
        repairTableView.dataSource = self
        repairTableView.delegate = self
        repairTableView.register(StructureTableViewCell.self, forCellReuseIdentifier: Constants.Strings.structureTableViewCellReuseIdentifier)
        repairTableView.separatorStyle = .none
        repairTableView.backgroundColor = UIColor.clear //Constants.Colors.standardBackground
        repairTableView.isScrollEnabled = true
        repairTableView.bounces = true
        repairTableView.alwaysBounceVertical = true
        repairTableView.showsVerticalScrollIndicator = false
        repairTableView.allowsSelection = false
        repairTableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        viewContainer.addSubview(repairTableView)
        
        repairTableViewBackgroundLabel = UILabel(frame: CGRect(x: 0, y: 0, width: repairTableView.frame.width, height: repairTableView.frame.height))
        repairTableViewBackgroundLabel.textColor = Constants.Colors.colorTextDark
        repairTableViewBackgroundLabel.numberOfLines = 3
        repairTableViewBackgroundLabel.lineBreakMode = NSLineBreakMode.byWordWrapping
        repairTableViewBackgroundLabel.textAlignment = .center
        repairTableViewBackgroundLabel.font = UIFont(name: "HelveticaNeue-UltraLight", size: 20)
        repairTableViewBackgroundLabel.text = "This house doesn't have any repairs requested at this time.  Try checking back here later."
        repairTableView.addSubview(repairTableViewBackgroundLabel)
        
        repairTableTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(StructureViewController.tableTap(_:)))
        repairTableTapGestureRecognizer.delegate = self
        repairTableView.addGestureRecognizer(repairTableTapGestureRecognizer)
        
        contactButton = UIView(frame: CGRect(x: viewContainer.frame.width - 70, y: 10, width: 60, height: 60))
        contactButton.backgroundColor = Constants.Colors.standardBackground
        contactButton.layer.cornerRadius = 30
        contactButton.layer.shadowOffset = CGSize(width: 0, height: 0.6)
        contactButton.layer.shadowOpacity = 0.5
        contactButton.layer.shadowRadius = 1.0
        viewContainer.addSubview(contactButton)
        
        contactButtonImage = UIImageView(frame: CGRect(x: 5, y: 5, width: contactButton.frame.width - 10, height: contactButton.frame.height - 10))
        contactButtonImage.layer.cornerRadius = (contactButton.frame.width - 10) / 2
        contactButtonImage.contentMode = UIViewContentMode.scaleAspectFill
        contactButtonImage.clipsToBounds = true
        contactButton.addSubview(contactButtonImage)
        
        contactButtonTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(StructureViewController.contactButtonTap(_:)))
        contactButtonTapGestureRecognizer.delegate = self
        contactButton.addGestureRecognizer(contactButtonTapGestureRecognizer)
        
        let border1 = CALayer()
        border1.frame = CGRect(x: 0, y: 0, width: repairTableView.frame.width, height: 1)
        border1.backgroundColor = Constants.Colors.standardBackgroundGrayUltraLight.cgColor
        repairTableView.layer.addSublayer(border1)
        
        NotificationCenter.default.addObserver(self, selector: #selector(StructureViewController.statusBarHeightChange(_:)), name: Notification.Name("UIApplicationWillChangeStatusBarFrameNotification"), object: nil)
        
        requestData()
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        prepVcLayout()
        prepFrames()
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
        structureImageView.frame = CGRect(x: 0, y: 0, width: viewContainer.frame.width, height: viewContainer.frame.width)
        structureImageSpinner.frame = CGRect(x: 0, y: 0, width: viewContainer.frame.width, height: viewContainer.frame.height)
        repairTableView.frame = CGRect(x: 0, y: repairTableViewY, width: viewContainer.frame.width, height: viewContainer.frame.height - repairTableViewY)
        repairTableViewBackgroundLabel.frame = CGRect(x: 0, y: 0, width: repairTableView.frame.width, height: repairTableView.frame.height)
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
        ncTitleText.text = "Repairs Needed"
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
        
        self.automaticallyAdjustsScrollViewInsets = false
        
        vcHeight = screenSize.height - statusBarHeight - navBarHeight
        vcOffsetY = CGFloat(statusBarHeight) + CGFloat(navBarHeight)
        if statusBarHeight == 40
        {
            vcOffsetY = navBarHeight + 20
        }
        print("SVC - CHECK DIMS: \(screenSize), \(vcHeight), \(statusBarHeight), \(navBarHeight)")
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
    
    func tableTap(_ gesture: UITapGestureRecognizer)
    {
        let tapLocation = gesture.location(in: self.repairTableView)
        print("SVC - TABLE TAP LOCATION: \(tapLocation)")
        let tapIndexPath = self.repairTableView.indexPathForRow(at: tapLocation)
        if let indexPath = tapIndexPath
        {
            let tapCell = self.repairTableView.cellForRow(at: indexPath) as! StructureTableViewCell
            let pointWithinCell = gesture.location(in: tapCell)
            print("SVC - TABLE TAP INDEX PATH: \(indexPath)")
            print("SVC - TABLE TAP CELL: \(tapCell)")
            print("SVC - POINT WITHIN CELL: \(pointWithinCell)")
            
            if tapCell.addImageView.frame.contains(pointWithinCell)
            {
                print("SVC - ADD REPAIR IMAGE")
                // Load the repair view (multiple photos allowed)
                if let navCon = self.navigationController
                {
                    let repairImageVC = RepairImageViewController()
                    repairImageVC.allowEdit = false
                    repairImageVC.repair = activeRepairs[indexPath.row]
                    navCon.pushViewController(repairImageVC, animated: true)
                }
            }
        }
    }
    
    func contactButtonTap(_ gesture: UITapGestureRecognizer)
    {
        print("SVC - CONTACT BUTTON TAP FOR STRUCTURE: \(structure.structureID)")
        // Find the structureUser entry
        structureUserCheckLoop: for structureUserCheck in Constants.Data.structureUsers
        {
            print("SVC - CONTACT BUTTON - CHECK STRUCTURE USER FOR STRUCT: \(structureUserCheck.structureID), USER: \(structureUserCheck.userID)")
            // Check using the structureID
            if structureUserCheck.structureID == structure.structureID
            {
                // Find the facebookID for the user
                userLoop: for user in Constants.Data.allUsers
                {
                    if user.userID == structureUserCheck.userID
                    {
//                        let fbMessengerUrlString = String(format: "fb-messenger://user-thread/%d", user.facebookID!)
//                        let fbMessengerUrlString = "http://m.me/\(user.facebookID!)"
                        let fbMessengerUrlString = "https://www.facebook.com/app_scoped_user_id/\(user.facebookID!)"
                        let fbMessengerUrl = URL(string: fbMessengerUrlString)
                        print("SVC - CONTACT BUTTON - FB URL STRING: \(fbMessengerUrlString), URL: \(fbMessengerUrl!)")
                        if UIApplication.shared.canOpenURL(fbMessengerUrl!)
                        {
                            print("SVC - CONTACT BUTTON - CAN OPEN URL")
                            if #available(iOS 10.0, *)
                            {
                                print("SVC - CONTACT BUTTON - OPEN URL - 10.0")
                                UIApplication.shared.open(fbMessengerUrl!, options: [:], completionHandler:  { (success) in
                                    print("SVC - CONTACT BUTTON - OPEN URL RESPONSE: \(success)")
                                })
                            }
                            else
                            {
                                print("SVC - CONTACT BUTTON - OPEN URL")
                                UIApplication.shared.openURL(fbMessengerUrl!)
                            }
                        }
                        
                        break userLoop
                    }
                }
                
                break structureUserCheckLoop
            }
        }
    }
    
    
    // MARK: TABLE VIEW DATA SOURCE
    
    func numberOfSections(in tableView: UITableView) -> Int
    {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return activeRepairs.count
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return Constants.Dim.repairCellHeight
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        print("SVC - CREATING CELL: \(indexPath.row)")
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.Strings.structureTableViewCellReuseIdentifier, for: indexPath) as! StructureTableViewCell
        
        // Remove all subviews
        for subview in cell.subviews
        {
            subview.removeFromSuperview()
        }
        
        let iconSize: CGFloat = 60
        
        cell.cellContainer = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: Constants.Dim.repairCellHeight))
        cell.addSubview(cell.cellContainer)
        
        cell.iconImageView = UIImageView(frame: CGRect(x: 0, y: (cell.cellContainer.frame.height - iconSize) / 2, width: iconSize, height: iconSize))
        cell.iconImageView.backgroundColor = UIColor.gray
        cell.iconImageView.contentMode = UIViewContentMode.scaleAspectFit
        cell.iconImageView.clipsToBounds = true
        cell.cellContainer.addSubview(cell.iconImageView)
        
        cell.imageSpinner = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: iconSize, height: iconSize))
        cell.imageSpinner.color = Constants.Colors.colorGrayDark
        cell.iconImageView.addSubview(cell.imageSpinner)
        cell.imageSpinner.startAnimating()
        if let icon = activeRepairs[indexPath.row].icon
        {
            cell.iconImageView.image = icon
            cell.imageSpinner.stopAnimating()
        }
        
        cell.repairTitle = UILabel(frame: CGRect(x: iconSize + 10, y: 0, width: cell.cellContainer.frame.width - iconSize - 150, height: cell.cellContainer.frame.height))
//        cell.repairTitle.backgroundColor = UIColor.red
        cell.repairTitle.font = UIFont(name: Constants.Strings.fontAltLight, size: 20)
        cell.repairTitle.textColor = Constants.Colors.colorTextDark
        cell.repairTitle.textAlignment = .left
        cell.repairTitle.text = activeRepairs[indexPath.row].repair
        cell.repairTitle.numberOfLines = 2
        cell.repairTitle.lineBreakMode = NSLineBreakMode.byWordWrapping
        cell.cellContainer.addSubview(cell.repairTitle)
        
        cell.repairStage = UILabel(frame: CGRect(x: cell.cellContainer.frame.width - 130, y: 0, width: 80, height: cell.cellContainer.frame.height))
        cell.repairStage.font = UIFont(name: Constants.Strings.fontAltLight, size: 16)
        cell.repairStage.textColor = Constants.Colors.colorTextDark
        cell.repairStage.textAlignment = .center
        cell.repairStage.numberOfLines = 2
        cell.repairStage.lineBreakMode = NSLineBreakMode.byWordWrapping
        cell.repairStage.backgroundColor = Constants().repairStageColor(activeRepairs[indexPath.row].stage.rawValue)
        cell.repairStage.text = Constants().repairStageTitle(activeRepairs[indexPath.row].stage.rawValue)
        cell.cellContainer.addSubview(cell.repairStage)
        
        cell.addImageView = UIImageView(frame: CGRect(x: cell.cellContainer.frame.width - 50, y: 0, width: 50, height: cell.cellContainer.frame.height))
        cell.addImageView.contentMode = UIViewContentMode.scaleAspectFit
        cell.addImageView.clipsToBounds = true
        cell.addImageView.image = UIImage(named: "icon_camera.png")
        cell.cellContainer.addSubview(cell.addImageView)
        
        cell.border1.frame = CGRect(x: 0, y: Constants.Dim.repairCellHeight - 1, width: cell.cellContainer.frame.width, height: 1)
        cell.border1.backgroundColor = Constants.Colors.standardBackgroundGrayUltraLight.cgColor
        cell.cellContainer.layer.addSublayer(cell.border1)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath)
    {
        print("SVC - WILL DISPLAY CELL: \(indexPath.row)")
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
    
    
    // MARK: DELEGATE METHODS
    
    
    // MARK: CUSTOM METHODS
    
    func refreshTable()
    {
        DispatchQueue.main.async(execute:
            {
                if self.repairTableView != nil
                {
                    print("SVC - REFRESH SKILL TABLE")
                    
                    // Reload the TableView
                    self.repairTableView.reloadData()
                }
        })
    }
    func reloadTable()
    {
        // Order the StructureList
        let repairListSort = self.structure.repairs.sorted {
            $0.order < $1.order
        }
        self.structure.repairs = repairListSort
        // Now filter the repairs for only those needed or in progress
        for repair in self.structure.repairs
        {
            if repair.stage == Constants.RepairStage.waiting || repair.stage == Constants.RepairStage.repairing
            {
                self.activeRepairs.append(repair)
            }
        }
        
        // Add / remove the background text depending on whether content is showing
        if self.activeRepairs.count == 0
        {
            repairTableView.addSubview(repairTableViewBackgroundLabel)
        }
        else
        {
            repairTableViewBackgroundLabel.removeFromSuperview()
            
            // Only show the tutorial view when the repairs are visible - otherwise it won't make sense
            // Recall the Tutorial Views data in Core Data.  If it is empty for the current ViewController's tutorial, it has not been seen by the curren user.
//            let tutorialView = CoreDataFunctions().tutorialViewRetrieve()
//            print("MVC: TUTORIAL VIEW STRUCTURE: \(String(describing: tutorialView.))")
//            if tutorialView.tutorialMapViewDatetime == nil
            if 2 == 2
            {
                print("SVC-CHECK 1")
                let holeView = HoleView(holeViewPosition: 1, frame: viewContainer.bounds, circleOffsetX: 75, circleOffsetY: repairTableViewY + 70, circleRadius: 70, textOffsetX: (viewContainer.bounds.width / 2) - 130, textOffsetY: 120, textWidth: 260, textFontSize: 24, text: "See which repairs require skills that you have.")
                holeView.holeViewDelegate = self
                viewContainer.addSubview(holeView)
            }
        }
        
        self.structureImageSpinner.stopAnimating()
        
        refreshTable()
    }
    func requestData()
    {
        print("SVC - REQUEST DATA")
        // Display the Structure image, or download if needed
        if let sImage = self.structure.image
        {
            structureImageView.image = sImage
        }
        else
        {
            // Download the image
            if let sImageID = self.structure.imageID
            {
                AWSPrepRequest(requestToCall: AWSDownloadMediaImage(imageID: sImageID), delegate: self as AWSRequestDelegate).prepRequest()
            }
        }
        
        print("SVC - REPAIR COUNT: \(self.structure.repairs.count)")
        // Request all repairs associated with this structure, if the list is empty
        if self.structure.repairs.count == 0
        {
            print("SVC - REQUESTING REPAIR DATA")
            AWSPrepRequest(requestToCall: AWSRepairQuery(structureID: self.structure.structureID), delegate: self as AWSRequestDelegate).prepRequest()
        }
        
        // Find the primary user for this structure and assign the object to the local entity - add the fb image to the contact button
        structureUserCheckLoop: for structureUserCheck in Constants.Data.structureUsers
        {
            // Check using the structureID
            if structureUserCheck.structureID == structure.structureID
            {
                // Find the facebookID for the user
                userLoop: for user in Constants.Data.allUsers
                {
                    if user.userID == structureUserCheck.userID
                    {
                        print("SVC - FOUND PRIMARY USER: \(user.userID)")
                        self.primaryUser = user
                        if let image = user.image
                        {
                            self.contactButtonImage.image = image
                        }
                        else
                        {
                            // Download the user image
                            RequestPrep(requestToCall: FBDownloadUserImage(facebookID: user.facebookID, largeImage: false), delegate: self as RequestDelegate).prepRequest()
                        }
                        
                        break userLoop
                    }
                }
                
                break structureUserCheckLoop
            }
        }
    }
    
    
    // MARK: AWS DELEGATE METHODS
    
    func showLoginScreen()
    {
        print("SVC - SHOW LOGIN SCREEN")
        
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
                case let awsDownloadMediaImage as AWSDownloadMediaImage:
                    if success
                    {
                        print("SVC - AWSDownloadMediaImage - SUCCESS")
                        if let structureImage = awsDownloadMediaImage.contentImage
                        {
                            // Add the image to the local structure object and display in the view
                            self.structure.image = structureImage
                            self.structureImageView.image = structureImage
                            
                            // Find the structure Object in the global array and add the downloaded image to the object variable
                            findStructureLoop: for structureObject in Constants.Data.structures
                            {
                                if structureObject.imageID == awsDownloadMediaImage.imageID
                                {
                                    print("SVC - AWSDownloadMediaImage - ADDED IMAGE TO GLOBAL LIST")
                                    structureObject.image = structureImage
                                    break findStructureLoop
                                }
                            }
                            // Reload the TableView
                            self.reloadTable()
                        }
                    }
                    else
                    {
                        print("SVC - AWS DOWNLOAD IMAGE - FAILURE")
                        // Show the error message
                        let alertController = UtilityFunctions().createAlertOkView("Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
                        self.present(alertController, animated: true, completion: nil)
                    }
                case let awsRepairQuery as AWSRepairQuery:
                    if success
                    {
                        self.structure.repairs = awsRepairQuery.repairs
                        
                        print("SVC - AWS REPAIR QUERY - SUCCESS")
                        self.reloadTable()
                        
//                        // Download the latest images for the repairs
//                        for repair in self.structure.repairs
//                        {
//                            for rImage in repair.repairImages
//                            {
//                                // Download the repair image(s)
//                                let awsObject = AWSDownloadMediaImage(imageID: rImage.imageID)
//                                awsObject.imageParentID = repair.repairID
//                                AWSPrepRequest(requestToCall: awsObject, delegate: self as AWSRequestDelegate).prepRequest()
//                            }
//                        }
                    }
                    else
                    {
                        print("SVC - AWS REPAIR QUERY - FAILURE")
                        // Show the error message
                        let alert = UtilityFunctions().createAlertOkView("Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
                        alert.show()
                    }
                default:
                    print("SVC-DEFAULT: THERE WAS AN ISSUE WITH THE DATA RETURNED FROM AWS")
                    
                    // Show the error message
                    let alert = UtilityFunctions().createAlertOkView("Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
                    alert.show()
                }
        })
    }
    
    // Process responses from non-AWS requests
    func processRequestReturn(_ requestCalled: RequestObject, success: Bool)
    {
        // Process the return data based on the method used
        switch requestCalled
        {
        case _ as FBDownloadUserImage:
            if success
            {
                print("SVC-FBDownloadUserImage SUCCESS")
                // Reload all needed data and features
                self.requestData()
            }
            else
            {
                print("SVC-FBDownloadUserImage FAILURE")
            }
        default:
            print("SVC-processRequestReturn DEFAULT")
        }
    }
    
    
    // MARK: HOLE VIEW DELEGATE
    func holeViewRemoved(removingViewAtPosition: Int)
    {
        // Give a short tutorial for new users
        switch removingViewAtPosition
        {
        case 1:
            // Show users how to add photo requests (SpotRequests)
            print("MVC-CHECK TUTORIAL 1")
            let holeView = HoleView(holeViewPosition: 2, frame: viewContainer.bounds, circleOffsetX: viewContainer.frame.width - 90, circleOffsetY: repairTableViewY + 60, circleRadius: 60, textOffsetX: (viewContainer.bounds.width / 2) - 130, textOffsetY: 120, textWidth: 260, textFontSize: 24, text: "Check the repair status.")
            holeView.holeViewDelegate = self
            viewContainer.addSubview(holeView)
            
        case 2:
            // Show users how to add photo requests (SpotRequests)
            print("MVC-CHECK TUTORIAL 2")
            let holeView = HoleView(holeViewPosition: 3, frame: viewContainer.bounds, circleOffsetX: viewContainer.frame.width - 25, circleOffsetY: repairTableViewY + 35, circleRadius: 35, textOffsetX: (viewContainer.bounds.width / 2) - 130, textOffsetY: 120, textWidth: 260, textFontSize: 24, text: "View photos of the damage.")
            holeView.holeViewDelegate = self
            viewContainer.addSubview(holeView)
            
        case 3:
            // Show users how to add photos to fulfill requests
            print("MVC-CHECK TUTORIAL 3")
            let holeView = HoleView(holeViewPosition: 4, frame: viewContainer.bounds, circleOffsetX: viewContainer.frame.width - 60, circleOffsetY: 20, circleRadius: 60, textOffsetX: (viewContainer.bounds.width / 2) - 130, textOffsetY: 120, textWidth: 260, textFontSize: 24, text: "Contact the homeowner through their Facebook page to schedule a time to help with repairs.")
            holeView.holeViewDelegate = self
            viewContainer.addSubview(holeView)
            
        default:
            // The tutorial has ended - Record the Tutorial View in Core Data
            print("MVC-CHECK TUTORIAL 4")
//            let moc = DataController().managedObjectContext
//            let tutorialView = NSEntityDescription.insertNewObject(forEntityName: "TutorialView", into: moc) as! TutorialView
//            tutorialView.setValue(NSDate(), forKey: "tutorialMapViewDatetime")
//            CoreDataFunctions().tutorialViewSave(tutorialView: tutorialView)
        }
    }
}
