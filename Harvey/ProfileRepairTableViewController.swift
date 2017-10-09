//
//  ProfileRepairTableViewController.swift
//  Harvey
//
//  Created by Sean Hart on 10/2/17.
//  Copyright © 2017 TangoJ Labs, LLC. All rights reserved.
//

import UIKit


class ProfileRepairViewController: UIViewController, UIGestureRecognizerDelegate, UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate, AWSRequestDelegate
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
        
        addButton = UIView(frame: CGRect(x: 0, y: 0, width: viewContainer.frame.width, height: addButtonHeight))
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
        
        backgroundLabel = UILabel(frame: CGRect(x: 30, y: 5, width: viewContainer.frame.width - 60, height: viewContainer.frame.height / 2))
        backgroundLabel.textColor = Constants.Colors.colorTextDark
//        backgroundLabel.text = backgroundText
        backgroundLabel.numberOfLines = 3
        backgroundLabel.lineBreakMode = NSLineBreakMode.byWordWrapping
        backgroundLabel.textAlignment = .center
        backgroundLabel.font = UIFont(name: "HelveticaNeue-UltraLight", size: 20)
        backgroundLabel.text = "You haven't added any houses needing repair.  Tap the button below to add one."
        
        // A tableview will hold all repairs
        repairTableView = UITableView(frame: CGRect(x: 0, y: addButtonHeight, width: viewContainer.frame.width, height: viewContainer.frame.height - addButtonHeight))
        repairTableView.dataSource = self
        repairTableView.delegate = self
        repairTableView.register(ProfileRepairTableViewCell.self, forCellReuseIdentifier: Constants.Strings.profileRepairTableViewCellReuseIdentifier)
        repairTableView.separatorStyle = .none
        repairTableView.backgroundColor = UIColor.clear //Constants.Colors.standardBackground
        repairTableView.isScrollEnabled = true
        repairTableView.bounces = true
        repairTableView.alwaysBounceVertical = true
        repairTableView.showsVerticalScrollIndicator = false
        repairTableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        viewContainer.addSubview(repairTableView)
        
        let border1 = CALayer()
        border1.frame = CGRect(x: 0, y: 0, width: repairTableView.frame.width, height: 1)
        border1.backgroundColor = Constants.Colors.standardBackgroundGrayUltraLight.cgColor
        repairTableView.layer.addSublayer(border1)
        
        NotificationCenter.default.addObserver(self, selector: #selector(ProfileRepairTableViewController.statusBarHeightChange(_:)), name: Notification.Name("UIApplicationWillChangeStatusBarFrameNotification"), object: nil)
        
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
        addButton.frame = CGRect(x: 0, y: 0, width: viewContainer.frame.width, height: addButtonHeight)
        addButtonLabel.frame = CGRect(x: 5, y: 5, width: addButton.frame.width - 10, height: addButton.frame.height - 10)
        repairTableView.frame = CGRect(x: 0, y: addButtonHeight, width: viewContainer.frame.width, height: viewContainer.frame.height - addButtonHeight)
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
    
    func addButtonTap(_ gesture: UITapGestureRecognizer)
    {
        
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
        return Constants.Dim.structureCellHeight
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        print("PRTVC - CREATING CELL: \(indexPath.row)")
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.Strings.profileRepairTableViewCellReuseIdentifier, for: indexPath) as! ProfileRepairTableViewCell
        
        cell.cellContainer = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: tableView.frame.height))
        cell.addSubview(cell.cellContainer)
        
        cell.repairImageView = UIImageView(frame: CGRect(x: 10, y: 0, width: cell.cellContainer.frame.height, height: cell.cellContainer.frame.height))
        cell.repairImageView.contentMode = UIViewContentMode.scaleAspectFit
        cell.repairImageView.clipsToBounds = true
        cell.cellContainer.addSubview(cell.repairImageView)
        
        cell.imageSpinner = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: cell.repairImageView.frame.width, height: cell.repairImageView.frame.height))
        cell.imageSpinner.color = Constants.Colors.colorGrayDark
        cell.repairImageView.addSubview(cell.imageSpinner)
        
        cell.repairTitle = UILabel(frame: CGRect(x: cell.cellContainer.frame.height + 20, y: 0, width: cell.cellContainer.frame.width - cell.cellContainer.frame.height - 30, height: cell.cellContainer.frame.height))
        cell.repairTitle.backgroundColor = UIColor.red
        cell.repairTitle.font = UIFont(name: Constants.Strings.fontAltLight, size: 20)
        cell.repairTitle.textColor = Constants.Colors.colorTextDark
        cell.repairTitle.textAlignment = .right
        cell.repairTitle.text = structure.repairs[indexPath.row].repair
        cell.cellContainer.addSubview(cell.repairTitle)
        
        cell.border1.frame = CGRect(x: 0, y: Constants.Dim.structureCellHeight - 1, width: cell.cellContainer.frame.width, height: 1)
        cell.border1.backgroundColor = Constants.Colors.standardBackgroundGrayUltraLight.cgColor
        cell.cellContainer.layer.addSublayer(cell.border1)
        
//        cell.cellContainer = UIView(frame: CGRect(x: 0, y: 0, width: cell.frame.width, height: cell.frame.height))
//        cell.repairImageView = UIImageView(frame: CGRect(x: 10, y: 0, width: 50, height: cell.cellContainer.frame.height))
//        cell.imageSpinner = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: cell.repairImageView.frame.width, height: cell.repairImageView.frame.height))
//        cell.border1.frame = CGRect(x: 0, y: Constants.Dim.structureCellHeight - 1, width: cell.cellContainer.frame.width, height: 1)
        
        cell.imageSpinner.startAnimating()
        if structure.repairs[indexPath.row].images.count > 0
        {
            cell.repairImageView.image = structure.repairs[indexPath.row].images[0]
            cell.imageSpinner.stopAnimating()
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath)
    {
        print("PRTVC - WILL DISPLAY CELL: \(indexPath.row)")
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        print("PRTVC - SELECTED CELL: \(indexPath.row)")
        
        // Unhighlight the cell
        tableView.deselectRow(at: indexPath, animated: true)
        
        // Toggle the stage of this repair
        var newStage = Constants.RepairStage.na
        if structure.repairs[indexPath.row].stage == Constants.RepairStage.na
        {
            newStage = Constants.RepairStage.waiting
        }
        else if structure.repairs[indexPath.row].stage == Constants.RepairStage.waiting
        {
            newStage = Constants.RepairStage.repairing
        }
        else if structure.repairs[indexPath.row].stage == Constants.RepairStage.repairing
        {
            newStage = Constants.RepairStage.complete
        }
        else if structure.repairs[indexPath.row].stage == Constants.RepairStage.complete
        {
            newStage = Constants.RepairStage.na
        }
        structure.repairs[indexPath.row].stage = newStage
        reloadTable()
        
        // Change the setting in the global array and upload the changes
        structureLoop: for structure in Constants.Data.structures
        {
            if structure.structureID == self.structure.structureID
            {
                repairLoop: for repair in structure.repairs
                {
                    if repair.repairID == structure.repairs[indexPath.row].repairID
                    {
                        repair.stage = newStage
                        
                        // Save the updated / new repair stage to Core Data
                        CoreDataFunctions().repairSave(repair: structure.repairs[indexPath.row])
                        break repairLoop
                    }
                }
                break structureLoop
            }
        }
        // Upload the changes
        AWSPrepRequest(requestToCall: AWSRepairPut(repair: structure.repairs[indexPath.row]), delegate: self as AWSRequestDelegate).prepRequest()
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
    
    func returnFromCamera()
    {
        print("PRTVC - RETURN FROM CAMERA")
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
                    print("PRTVC - REFRESH SKILL TABLE")
                    
                    // Reload the TableView
                    self.repairTableView.reloadData()
                }
        })
    }
    func reloadTable()
    {
        // Order the StructureList
        let repairListSort = self.structure.repairs.sorted {
            $0.datetime > $1.datetime
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
                        
                        // Download the latest images for the repairs
                        for repair in self.structure.repairs
                        {
                            for imageID in repair.imageIDs
                            {
                                // Download the repair image(s)
                                let awsObject = AWSDownloadMediaImage(imageID: imageID)
                                awsObject.imageParentID = repair.repairID
                                AWSPrepRequest(requestToCall: awsObject, delegate: self as AWSRequestDelegate).prepRequest()
                            }
                        }
                    }
                    else
                    {
                        print("PRTVC - AWS REPAIR QUERY - FAILURE")
                        // Show the error message
                        let alert = UtilityFunctions().createAlertOkView("Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
                        alert.show()
                    }
                case let awsDownloadMediaImage as AWSDownloadMediaImage:
                    if success
                    {
                        if let repairImage = awsDownloadMediaImage.contentImage
                        {
                            // Find the repair Object in the local array and add the downloaded image to the object variable
                            findRepairLoop: for repairObject in self.structure.repairs
                            {
                                if repairObject.repairID == awsDownloadMediaImage.imageParentID
                                {
                                    repairObject.images.append(repairImage)
                                    break findRepairLoop
                                }
                            }
                            
                            // Find the repair Object in the global array and add the downloaded image to the object variable
                            findStructureLoop: for structureObject in Constants.Data.structures
                            {
                                findRepairLoop: for repairObject in structureObject.repairs
                                {
                                    if repairObject.repairID == awsDownloadMediaImage.imageParentID
                                    {
                                        repairObject.images.append(repairImage)
                                        break findRepairLoop
                                    }
                                }
                                break findStructureLoop
                            }
                            // Reload the TableView
                            self.refreshTable()
                        }
                    }
                    else
                    {
                        // Show the error message
                        let alertController = UtilityFunctions().createAlertOkView("Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
                        self.present(alertController, animated: true, completion: nil)
                    }
                default:
                    print("PRTVC-DEFAULT: THERE WAS AN ISSUE WITH THE DATA RETURNED FROM AWS")
                    
                    // Show the error message
                    let alert = UtilityFunctions().createAlertOkView("Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
                    alert.show()
                }
        })
    }
}
