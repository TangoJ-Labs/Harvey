//
//  ProfileRepairImageViewController.swift
//  Harvey
//
//  Created by Sean Hart on 10/7/17.
//  Copyright © 2017 TangoJ Labs, LLC. All rights reserved.
//

import UIKit


class RepairImageViewController: UIViewController, UIGestureRecognizerDelegate, UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate, AWSRequestDelegate, CameraViewControllerDelegate
{
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
    var repairImageTableView: UITableView!
    var addImageButton: UIView!
    var addImageLabel: UILabel!
    var tableBorder: CALayer!
    
    var addButton: UIView!
    var addButtonLabel: UILabel!
    var addButtonTapGestureRecognizer: UITapGestureRecognizer!
    
    var addButtonHeight: CGFloat = 0 //70
    
    var repair: Repair?
    var allowEdit: Bool = false
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        prepVcLayout()
        
        if allowEdit
        {
            addButtonHeight = 70
        }
        
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
        backgroundLabel.text = "You haven't added any images for this repair.  Tap the button below to add some."
        
        // A tableview will hold all repair images
        repairImageTableView = UITableView(frame: CGRect(x: 0, y: 0, width: viewContainer.frame.width, height: viewContainer.frame.height - addButtonHeight))
        repairImageTableView.dataSource = self
        repairImageTableView.delegate = self
        repairImageTableView.register(RepairImageTableViewCell.self, forCellReuseIdentifier: Constants.Strings.repairImageTableViewCellReuseIdentifier)
        repairImageTableView.separatorStyle = .none
        repairImageTableView.backgroundColor = UIColor.clear //Constants.Colors.standardBackground
        repairImageTableView.isScrollEnabled = true
        repairImageTableView.bounces = true
        repairImageTableView.alwaysBounceVertical = true
        repairImageTableView.showsVerticalScrollIndicator = false
        repairImageTableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        viewContainer.addSubview(repairImageTableView)
        
        tableBorder = CALayer()
        tableBorder.frame = CGRect(x: 0, y: 0, width: repairImageTableView.frame.width, height: 1)
        tableBorder.backgroundColor = Constants.Colors.standardBackgroundGrayUltraLight.cgColor
        
        addButton = UIView(frame: CGRect(x: 0, y: viewContainer.frame.height - addButtonHeight, width: viewContainer.frame.width, height: addButtonHeight))
        addButton.backgroundColor = Constants.Colors.colorGrayDark
        addButton.layer.shadowOffset = CGSize(width: 0, height: 0.6)
        addButton.layer.shadowOpacity = 0.5
        addButton.layer.shadowRadius = 1.0
        if allowEdit
        {
            viewContainer.addSubview(addButton)
        }
        
        addButtonLabel = UILabel(frame: CGRect(x: 5, y: 5, width: addButton.frame.width - 10, height: addButton.frame.height - 10))
        addButtonLabel.textColor = Constants.Colors.colorTextLight
        addButtonLabel.text = "+"
        addButtonLabel.textAlignment = .center
        addButtonLabel.font = UIFont(name: "HelveticaNeue-UltraLight", size: 40)
        addButtonLabel.numberOfLines = 1
        addButtonLabel.lineBreakMode = NSLineBreakMode.byWordWrapping
        addButton.addSubview(addButtonLabel)
        
        addButtonTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(RepairImageViewController.addButtonTap(_:)))
        addButtonTapGestureRecognizer.delegate = self
        addButton.addGestureRecognizer(addButtonTapGestureRecognizer)
        
        NotificationCenter.default.addObserver(self, selector: #selector(RepairImageViewController.statusBarHeightChange(_:)), name: Notification.Name("UIApplicationWillChangeStatusBarFrameNotification"), object: nil)
        
        reloadTable()
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
        repairImageTableView.frame = CGRect(x: 0, y: 0, width: viewContainer.frame.width, height: viewContainer.frame.height - addButtonHeight)
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
        ncTitleText.textColor = Constants.Colors.colorTextNavBar
        ncTitleText.font = UIFont(name: Constants.Strings.fontAlt, size: 16)
        ncTitleText.textAlignment = .center
        ncTitle.addSubview(ncTitleText)
        
        if let repair = self.repair
        {
            ncTitleText.text = repair.repair
        }
        
        // Assign the created Nav Bar settings
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
        print("RIVC - CHECK DIMS: \(screenSize), \(vcHeight), \(statusBarHeight), \(navBarHeight)")
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
        print("RIVC - ADD BUTTON")
        self.loadCamera()
//        // If the images array is empty, just load the camera, otherwise warn that current images will be replaced
//        if repair.repairImages.count == 0
//        {
//            self.loadCamera()
//        }
//        else
//        {
//            // Explain that taking new Repair photos will replace all previous photos
//            let alertController = UIAlertController(title: "Photo Replacement", message: "New photos will delete and replace all current photos.", preferredStyle: UIAlertControllerStyle.alert)
//            let laterAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.default)
//            { (result : UIAlertAction) -> Void in
//                print("PTSVC - CAMERA POPUP - CANCEL")
//            }
//            alertController.addAction(laterAction)
//            let okAction = UIAlertAction(title: "Ok", style: UIAlertActionStyle.default)
//            { (result : UIAlertAction) -> Void in
//                print("PTSVC - CAMERA POPUP - OK")
//                self.loadCamera()
//            }
//            alertController.addAction(okAction)
//            alertController.show()
//        }
    }
    
    // MARK: TABLE VIEW DATA SOURCE
    
    func numberOfSections(in tableView: UITableView) -> Int
    {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        var rowCount = 0
        if let repair = self.repair
        {
            rowCount = repair.repairImages.count
            // Only add the table border if it contains data
            if rowCount > 0
            {
                repairImageTableView.layer.addSublayer(tableBorder)
            }
            else
            {
                tableBorder.removeFromSuperlayer()
            }
        }
        return rowCount
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return screenSize.width
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        print("RIVC - CREATING CELL: \(indexPath.row)")
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.Strings.repairImageTableViewCellReuseIdentifier, for: indexPath) as! RepairImageTableViewCell
        
        // Remove all subviews
        for subview in cell.subviews
        {
            subview.removeFromSuperview()
        }
        
        cell.cellContainer = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: tableView.frame.width))
        cell.addSubview(cell.cellContainer)
        
        cell.repairImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: cell.cellContainer.frame.width, height: cell.cellContainer.frame.width))
        cell.repairImageView.contentMode = UIViewContentMode.scaleAspectFill
        cell.repairImageView.clipsToBounds = true
        
        cell.imageSpinner = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: cell.repairImageView.frame.width, height: cell.repairImageView.frame.height))
        cell.imageSpinner.color = Constants.Colors.colorGrayDark
        cell.cellContainer.addSubview(cell.imageSpinner)
        
        cell.border1.frame = CGRect(x: 0, y: cell.cellContainer.frame.height - 1, width: cell.cellContainer.frame.width, height: 1)
        cell.border1.backgroundColor = Constants.Colors.standardBackgroundGrayUltraLight.cgColor
        cell.cellContainer.layer.addSublayer(cell.border1)
        
        cell.imageSpinner.startAnimating()
        if let repair = self.repair
        {
            if let image = repair.repairImages[indexPath.row].image
            {
                cell.cellContainer.addSubview(cell.repairImageView)
                cell.repairImageView.image = image
                cell.imageSpinner.stopAnimating()
            }
            else
            {
                // Download the image
                print("RIVC - DOWNLOAD IMAGE: \(repair.repairImages[indexPath.row].imageID)")
                AWSPrepRequest(requestToCall: AWSDownloadMediaImage(imageID: repair.repairImages[indexPath.row].imageID), delegate: self as AWSRequestDelegate).prepRequest()
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath)
    {
        print("RIVC - WILL DISPLAY CELL: \(indexPath.row)")
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        print("RIVC - SELECTED CELL: \(indexPath.row)")
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
        print("RIVC - RETURN FROM CAMERA")
        // The new RepairImage data was added to the global arrays - reload the data and table to show
        reloadTable()
    }
    
    
    // MARK: CUSTOM METHODS
    
    func refreshTable()
    {
        DispatchQueue.main.async(execute:
            {
                if self.repairImageTableView != nil
                {
                    print("RIVC - REFRESH SKILL TABLE")
                    
                    // Reload the TableView
                    self.repairImageTableView.reloadData()
                }
        })
    }
    func reloadTable()
    {
        if let repair = self.repair
        {
            // Recall the repair from the global array
            structureLoop: for structure in Constants.Data.structures
            {
                if structure.structureID == repair.structureID
                {
                    repairLoop: for gRepair in structure.repairs
                    {
                        if gRepair.repairID == repair.repairID
                        {
                            self.repair = gRepair
                            break repairLoop
                        }
                    }
                    break structureLoop
                }
            }
            
            // Order the images
            let imagesSorted = repair.repairImages.sorted {
                $0.datetime > $1.datetime
            }
            repair.repairImages = imagesSorted
            print("RIVC - IMAGE COUNT: \(repair.repairImages.count)")
            
            // If the image count is 0, display the background message
            if repair.repairImages.count == 0
            {
                self.repairImageTableView.addSubview(self.backgroundLabel)
            }
            else
            {
                self.backgroundLabel.removeFromSuperview()
            }
        }
        self.viewSpinner.stopAnimating()
        refreshTable()
    }
    
    func loadCamera()
    {
        if let repair = self.repair
        {
            // Load the repair view (multiple photos allowed)
            if let navCon = self.navigationController
            {
                // Load the CameraVC
                let cameraVC = CameraMultiImageViewController()
                cameraVC.cameraDelegate = self
                cameraVC.forRepair = true
                cameraVC.repair = repair
                navCon.pushViewController(cameraVC, animated: true)
            }
        }
    }
    
    
    // MARK: AWS DELEGATE METHODS
    
    func showLoginScreen()
    {
        print("RIVC - SHOW LOGIN SCREEN")
        
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
                        print("RIVC - AWSDownloadMediaImage - SUCCESS")
                        if let image = awsDownloadMediaImage.contentImage
                        {
                            // Find the RepairImage Object in the local array and add the downloaded image to the object
                            if let repair = self.repair
                            {
                                findRepairImageLoop: for repairImageObject in repair.repairImages
                                {
                                    if repairImageObject.imageID == awsDownloadMediaImage.imageID
                                    {
                                        print("RIVC - AWSDownloadMediaImage - ADDED IMAGE TO LOCAL LIST")
                                        repairImageObject.image = image
                                        break findRepairImageLoop
                                    }
                                }
                                
                                // Find the Repair Object in the global array and add the downloaded image to the object variable
                                findStructureLoop: for structureObject in Constants.Data.structures
                                {
                                    if structureObject.structureID == repair.structureID
                                    {
                                        findRepairLoop: for gRepair in structureObject.repairs
                                        {
                                            if gRepair.repairID == repair.repairID
                                            {
                                                findRepairImageLoop: for repairImageObject in gRepair.repairImages
                                                {
                                                    if repairImageObject.imageID == awsDownloadMediaImage.imageID
                                                    {
                                                        print("RIVC - AWSDownloadMediaImage - ADDED IMAGE TO LOCAL LIST")
                                                        repairImageObject.image = image
                                                        break findRepairImageLoop
                                                    }
                                                }
                                                break findRepairLoop
                                            }
                                        }
                                        break findStructureLoop
                                    }
                                }
                                // Reload the TableView
                                self.reloadTable()
                            }
                        }
                    }
                    else
                    {
                        // Show the error message
                        let alertController = UtilityFunctions().createAlertOkView("Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
                        self.present(alertController, animated: true, completion: nil)
                    }
                default:
                    print("RIVC-DEFAULT: THERE WAS AN ISSUE WITH THE DATA RETURNED FROM AWS")
                    
                    // Show the error message
                    let alert = UtilityFunctions().createAlertOkView("Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
                    alert.show()
                }
        })
    }
}
