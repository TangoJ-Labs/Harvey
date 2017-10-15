//
//  ProfileRepairViewController.swift
//  Harvey
//
//  Created by Sean Hart on 10/2/17.
//  Copyright © 2017 TangoJ Labs, LLC. All rights reserved.
//

import UIKit


class ProfileRepairViewController: UIViewController, UIGestureRecognizerDelegate, UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate, CameraViewControllerDelegate, AWSRequestDelegate
{
    var structure: Structure!
//    var repairList = [Repair]()
    
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
    var viewSpinner: UIActivityIndicatorView!
    
    var backgroundLabel: UILabel!
    var repairTableView: UITableView!
    var repairTableTapGestureRecognizer: UITapGestureRecognizer!
    
//    var structureInfoContainer: UIView!
//    var structureImageView: UIImageView!
//    var structureImageViewTapGestureRecognizer: UITapGestureRecognizer!
//    var structureDeleteButton: UILabel!
//    var structureDeleteButtonTapGestureRecognizer: UITapGestureRecognizer!
    
    let structureInfoContainerHeight: CGFloat = 0 //70
    
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
        
        // A tableview will hold all repairs
        repairTableView = UITableView(frame: CGRect(x: 0, y: 0, width: viewContainer.frame.width, height: viewContainer.frame.height - structureInfoContainerHeight))
        repairTableView.dataSource = self
        repairTableView.delegate = self
        repairTableView.register(ProfileRepairTableViewCell.self, forCellReuseIdentifier: Constants.Strings.profileRepairTableViewCellReuseIdentifier)
        repairTableView.separatorStyle = .none
        repairTableView.backgroundColor = UIColor.clear //Constants.Colors.standardBackground
        repairTableView.isScrollEnabled = true
        repairTableView.bounces = true
        repairTableView.alwaysBounceVertical = true
        repairTableView.showsVerticalScrollIndicator = false
        repairTableView.allowsSelection = false
        repairTableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        viewContainer.addSubview(repairTableView)
        
        repairTableTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ProfileRepairViewController.tableTap(_:)))
        repairTableTapGestureRecognizer.delegate = self
        repairTableView.addGestureRecognizer(repairTableTapGestureRecognizer)
        
        let border1 = CALayer()
        border1.frame = CGRect(x: 0, y: 0, width: repairTableView.frame.width, height: 1)
        border1.backgroundColor = Constants.Colors.standardBackgroundGrayUltraLight.cgColor
        repairTableView.layer.addSublayer(border1)
        
        NotificationCenter.default.addObserver(self, selector: #selector(ProfileRepairViewController.statusBarHeightChange(_:)), name: Notification.Name("UIApplicationWillChangeStatusBarFrameNotification"), object: nil)
        
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
        viewSpinner.frame = CGRect(x: 0, y: 0, width: viewContainer.frame.width, height: viewContainer.frame.height)
        repairTableView.frame = CGRect(x: 0, y: 0, width: viewContainer.frame.width, height: viewContainer.frame.height - structureInfoContainerHeight)
//        structureImageView.frame = CGRect(x: 0, y: 0, width: structureInfoContainer.frame.width / 2, height: structureInfoContainer.frame.height)
//        structureDeleteButton.frame = CGRect(x: 0, y: 0, width: structureInfoContainer.frame.width / 2, height: structureInfoContainer.frame.height)
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
        ncTitleText.text = "Repairs"
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
        print("PTSTVC - CHECK DIMS: \(screenSize), \(vcHeight), \(statusBarHeight), \(navBarHeight)")
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
    
    func structureImageViewTap(_ gesture: UITapGestureRecognizer)
    {
        print("PRVC - STRUCTURE IMAGE VIEW TAP")
        // Ask whether the user wants to replace the structure image
        let alertController = UIAlertController(title: "House Image", message: "Do you want to replace this house image?", preferredStyle: UIAlertControllerStyle.alert)
        let laterAction = UIAlertAction(title: "No", style: UIAlertActionStyle.default)
        { (result : UIAlertAction) -> Void in
            print("PRVC - STRUCTURE IMAGE - NO")
        }
        alertController.addAction(laterAction)
        let okAction = UIAlertAction(title: "Replace", style: UIAlertActionStyle.default)
        { (result : UIAlertAction) -> Void in
            print("PRVC - STRUCTURE IMAGE - REPLACE")
            // Load the repair view (multiple photos allowed)
            if let navCon = self.navigationController
            {
                // Load the CameraVC
                let cameraVC = CameraSingleImageViewController()
                cameraVC.cameraDelegate = self
                navCon.pushViewController(cameraVC, animated: true)
            }
        }
        alertController.addAction(okAction)
        alertController.show()
    }
    func structureDeleteButtonTap(_ gesture: UITapGestureRecognizer)
    {
        print("PRVC - STRUCTURE DELETE TAP")
        // Ask whether the user wants to replace the structure image
        let alertController = UIAlertController(title: "House Delete", message: "Are you sure you want to delete this house?", preferredStyle: UIAlertControllerStyle.alert)
        let laterAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.default)
        { (result : UIAlertAction) -> Void in
            print("PRVC - STRUCTURE DELETE - CANCEL")
        }
        alertController.addAction(laterAction)
        let okAction = UIAlertAction(title: "Delete", style: UIAlertActionStyle.default)
        { (result : UIAlertAction) -> Void in
            print("PRVC - STRUCTURE IMAGE - DELETE")
            
        }
        alertController.addAction(okAction)
        alertController.show()
    }
    func tableTap(_ gesture: UITapGestureRecognizer)
    {
        let tapLocation = gesture.location(in: self.repairTableView)
        print("PRVC - TABLE TAP LOCATION: \(tapLocation)")
        let tapIndexPath = self.repairTableView.indexPathForRow(at: tapLocation)
        if let indexPath = tapIndexPath
        {
            let tapCell = self.repairTableView.cellForRow(at: indexPath) as! ProfileRepairTableViewCell
            let pointWithinCell = gesture.location(in: tapCell)
            print("PRVC - TABLE TAP INDEX PATH: \(indexPath)")
            print("PRVC - TABLE TAP CELL: \(tapCell)")
            print("PRVC - POINT WITHIN CELL: \(pointWithinCell)")
            
            if tapCell.addImageView.frame.contains(pointWithinCell)
            {
                print("PRVC - ADD REPAIR IMAGE")
                // Load the repair view (multiple photos allowed)
                if let navCon = self.navigationController
                {
                    let repairImageVC = RepairImageViewController()
                    repairImageVC.allowEdit = true
                    repairImageVC.repair = structure.repairs[indexPath.row]
                    navCon.pushViewController(repairImageVC, animated: true)
                }
            }
            else
            {
                print("PRVC - TOGGLE REPAIR STAGE")
                // If no images exist for this repair, require images to be added before advancing the stage
                if structure.repairs[indexPath.row].repairImages.count == 0
                {
                    // Explain that taking new Repair photos will replace all previous photos
                    let alertController = UIAlertController(title: "Photos Required", message: "Please save at least one photo of the area needing repair.", preferredStyle: UIAlertControllerStyle.alert)
                    let laterAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.default)
                    { (result : UIAlertAction) -> Void in
                        print("PRVC - CAMERA POPUP - CANCEL")
                    }
                    alertController.addAction(laterAction)
                    let okAction = UIAlertAction(title: "Camera", style: UIAlertActionStyle.default)
                    { (result : UIAlertAction) -> Void in
                        print("PRVC - CAMERA POPUP - CAMERA")
                        // Load the repair view (multiple photos allowed)
                        if let navCon = self.navigationController
                        {
                            // Load the CameraVC
                            let cameraVC = CameraMultiImageViewController()
                            cameraVC.cameraDelegate = self
                            cameraVC.forRepair = true
                            cameraVC.repair = self.structure.repairs[indexPath.row]
                            navCon.pushViewController(cameraVC, animated: true)
                        }
                    }
                    alertController.addAction(okAction)
                    alertController.show()
                }
                else
                {
                    // Toggle the stage of this repair
                    toggleRepairStageFor(row: indexPath.row)
                }
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
        return structure.repairs.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return Constants.Dim.repairCellHeight
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        print("PRTVC - CREATING CELL: \(indexPath.row)")
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.Strings.profileRepairTableViewCellReuseIdentifier, for: indexPath) as! ProfileRepairTableViewCell
        
        // Remove all subviews
        for subview in cell.subviews
        {
            subview.removeFromSuperview()
        }
        
        let iconSize: CGFloat = 60
        
        cell.cellContainer = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: Constants.Dim.repairCellHeight))
        cell.addSubview(cell.cellContainer)
        
        cell.iconImageView = UIImageView(frame: CGRect(x: 0, y: (cell.cellContainer.frame.height - iconSize) / 2, width: iconSize, height: iconSize))
//        cell.iconImageView.backgroundColor = UIColor.gray
        cell.iconImageView.contentMode = UIViewContentMode.scaleAspectFit
        cell.iconImageView.clipsToBounds = true
        cell.cellContainer.addSubview(cell.iconImageView)
        
        cell.imageSpinner = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: iconSize, height: iconSize))
        cell.imageSpinner.color = Constants.Colors.colorGrayDark
        cell.iconImageView.addSubview(cell.imageSpinner)
        cell.imageSpinner.startAnimating()
        print("PRTVC - CELL ICON: \(structure.repairs[indexPath.row].icon)")
//        print("PRTVC - WINDOW ICON: \(UIImage(named: "window.png"))")
//        print("PRTVC - PROFILE ICON: \(UIImage(named: "PROFILE_DEFAULT.png"))")
//        cell.iconImageView.image = UIImage(named: "window.png")
        if let icon = structure.repairs[indexPath.row].icon
        {
            cell.iconImageView.image = icon
            cell.imageSpinner.stopAnimating()
        }
        
        cell.repairTitle = UILabel(frame: CGRect(x: iconSize + 10, y: 0, width: cell.cellContainer.frame.width - iconSize - 150, height: cell.cellContainer.frame.height))
//        cell.repairTitle.backgroundColor = UIColor.red
        cell.repairTitle.font = UIFont(name: Constants.Strings.fontAltLight, size: 20)
        cell.repairTitle.textColor = Constants.Colors.colorTextDark
        cell.repairTitle.textAlignment = .left
        cell.repairTitle.text = structure.repairs[indexPath.row].repair
        cell.repairTitle.numberOfLines = 2
        cell.repairTitle.lineBreakMode = NSLineBreakMode.byWordWrapping
        cell.cellContainer.addSubview(cell.repairTitle)
        
        cell.repairStage = UILabel(frame: CGRect(x: cell.cellContainer.frame.width - 130, y: 0, width: 80, height: cell.cellContainer.frame.height))
        cell.repairStage.font = UIFont(name: Constants.Strings.fontAltLight, size: 16)
        cell.repairStage.textColor = Constants.Colors.colorTextDark
        cell.repairStage.textAlignment = .center
        cell.repairStage.numberOfLines = 2
        cell.repairStage.lineBreakMode = NSLineBreakMode.byWordWrapping
        cell.repairStage.backgroundColor = Constants().repairStageColor(structure.repairs[indexPath.row].stage.rawValue)
        cell.repairStage.text = Constants().repairStageTitle(structure.repairs[indexPath.row].stage.rawValue)
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
        print("PRTVC - WILL DISPLAY CELL: \(indexPath.row)")
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
    
    func returnFromCamera(updatedRow: Int?)
    {
        print("PRTVC - RETURN FROM CAMERA")
        // If the camera was used from this view, it was called when attempting to advance a repair stage - advance that stage upon return
        if let row = updatedRow
        {
            print("PRTVC - RETURN FROM CAMERA - TOGGLE ROW: \(row)")
            toggleRepairStageFor(row: row)
        }
        
        // The new data was added to the global arrays - reload the data and table to show
        reloadTable()
    }
    
    
    // MARK: CUSTOM METHODS
    
    func refreshTable()
    {
        DispatchQueue.main.async(execute:
            {
                if self.repairTableView != nil
                {
                    print("PRTVC - REFRESH REPAIR TABLE")
                    
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
        self.viewSpinner.stopAnimating()
        
        refreshTable()
    }
    func requestData()
    {
        print("PRTVC - REQUEST DATA")
        // Request all structureIDs associated with the current user
        AWSPrepRequest(requestToCall: AWSRepairQuery(structureID: self.structure.structureID), delegate: self as AWSRequestDelegate).prepRequest()
    }
    func toggleRepairStageFor(row: Int)
    {
        print("PRTVC - TOGGLE ROW: \(row)")
        // Toggle the stage of this repair
        let newStage = Constants().repairStageToggle(structure.repairs[row].stage) //Constants.RepairStage.na
        structure.repairs[row].stage = newStage
        reloadTable()
        
        // Change the setting in the global array and upload the changes
        structureLoop: for structure in Constants.Data.structures
        {
            if structure.structureID == self.structure.structureID
            {
                repairLoop: for repair in structure.repairs
                {
                    if repair.repairID == structure.repairs[row].repairID
                    {
                        repair.stage = newStage
                        
                        // Save the updated / new repair stage to Core Data
                        CoreDataFunctions().repairSave(repair: structure.repairs[row])
                        break repairLoop
                    }
                }
                break structureLoop
            }
        }
        // Upload the changes
        AWSPrepRequest(requestToCall: AWSRepairPut(repair: structure.repairs[row]), delegate: self as AWSRequestDelegate).prepRequest()
    }
    
    
    // MARK: AWS DELEGATE METHODS
    
    func showLoginScreen()
    {
        print("PRTVC - SHOW LOGIN SCREEN")
        
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
                case let awsRepairQuery as AWSRepairQuery:
                    if success
                    {
                        self.structure.repairs = awsRepairQuery.repairs
                        
                        print("PRTVC - AWS REPAIR QUERY - SUCCESS")
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
                        print("PRTVC - AWS REPAIR QUERY - FAILURE")
                        // Show the error message
                        let alert = UtilityFunctions().createAlertOkView("Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
                        alert.show()
                    }
                case _ as AWSRepairPut:
                    if success
                    {
                        print("PRTVC - AWS REPAIR PUT - SUCCESS")
                    }
                    else
                    {
                        print("PRTVC - AWS REPAIR PUT - FAILURE")
                        // Show the error message
                        let alert = UtilityFunctions().createAlertOkView("Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
                        alert.show()
                    }
//                case let awsDownloadMediaImage as AWSDownloadMediaImage:
//                    if success
//                    {
//                        if let repairImage = awsDownloadMediaImage.contentImage
//                        {
//                            // Find the repair Object in the local array and add the downloaded image to the object variable
//                            findRepairLoop: for repairObject in self.structure.repairs
//                            {
//                                if repairObject.repairID == awsDownloadMediaImage.imageParentID
//                                {
//                                    repairObject.repairImages.append(repairImage)
//                                    break findRepairLoop
//                                }
//                            }
//
//                            // Find the repair Object in the global array and add the downloaded image to the object variable
//                            findStructureLoop: for structureObject in Constants.Data.structures
//                            {
//                                findRepairLoop: for repairObject in structureObject.repairs
//                                {
//                                    if repairObject.repairID == awsDownloadMediaImage.imageParentID
//                                    {
//                                        repairObject.repairImages.append(repairImage)
//                                        break findRepairLoop
//                                    }
//                                }
//                                break findStructureLoop
//                            }
//                            // Reload the TableView
//                            self.refreshTable()
//                        }
//                    }
//                    else
//                    {
//                        // Show the error message
//                        let alertController = UtilityFunctions().createAlertOkView("Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
//                        self.present(alertController, animated: true, completion: nil)
//                    }
                default:
                    print("PRTVC-DEFAULT: THERE WAS AN ISSUE WITH THE DATA RETURNED FROM AWS")
                    
                    // Show the error message
                    let alert = UtilityFunctions().createAlertOkView("Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
                    alert.show()
                }
        })
    }
}
