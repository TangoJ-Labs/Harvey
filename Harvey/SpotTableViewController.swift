//
//  SpotTableViewController.swift
//  Harvey
//
//  Created by Sean Hart on 8/31/17.
//  Copyright © 2017 tangojlabs. All rights reserved.
//

import FBSDKShareKit
import UIKit

class SpotTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate, UIGestureRecognizerDelegate, AWSRequestDelegate, RequestDelegate
{
    var spotContent: [SpotContent]!
    
    convenience init(spotContent: [SpotContent]!)
    {
        self.init(nibName:nil, bundle:nil)
        
        self.spotContent = spotContent
    }
    
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
    
    var spotContentTableView: UITableView!
    var tableGestureRecognizer: UITapGestureRecognizer!
    
    // Properties to hold local information
    var viewContainerHeight: CGFloat!
    var spotCellWidth: CGFloat!
//    var spotCellContentHeight: CGFloat!
    var spotMediaSize: CGFloat!
    
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        prepVcLayout()
        self.automaticallyAdjustsScrollViewInsets = false
        
        // Add the Status Bar, Top Bar and Search Bar last so that they are placed above (z-index) all other views
        statusBarView = UIView(frame: CGRect(x: 0, y: 0, width: screenSize.width, height: statusBarHeight))
        statusBarView.backgroundColor = Constants.Colors.colorStatusBar
        self.view.addSubview(statusBarView)
        
        // Add the view container to hold all other views (allows for shadows on all subviews)
        viewContainer = UIView(frame: CGRect(x: 0, y: vcOffsetY, width: self.view.bounds.width, height: vcHeight))
        viewContainer.backgroundColor = Constants.Colors.standardBackgroundGrayUltraLight
        self.view.addSubview(viewContainer)
        
        // Set the main cell standard dimensions
        spotCellWidth = viewContainer.frame.width
        spotMediaSize = viewContainer.frame.width
        
        // A tableview will hold all comments
        spotContentTableView = UITableView(frame: CGRect(x: 0, y: 0, width: viewContainer.frame.width, height: viewContainer.frame.height))
        spotContentTableView.dataSource = self
        spotContentTableView.delegate = self
        spotContentTableView.register(SpotTableViewCell.self, forCellReuseIdentifier: Constants.Strings.spotTableViewCellReuseIdentifier)
        spotContentTableView.separatorStyle = .none
        spotContentTableView.backgroundColor = Constants.Colors.standardBackground
        spotContentTableView.isScrollEnabled = true
        spotContentTableView.bounces = true
        spotContentTableView.alwaysBounceVertical = true
        spotContentTableView.allowsSelection = false
        spotContentTableView.showsVerticalScrollIndicator = false
//        spotContentTableView.isUserInteractionEnabled = true
//        spotContentTableView.allowsSelection = true
        spotContentTableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        viewContainer.addSubview(spotContentTableView)
        
        tableGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(SpotTableViewController.tableGesture(_:)))
        tableGestureRecognizer.delegate = self
        spotContentTableView.addGestureRecognizer(tableGestureRecognizer)
        
        NotificationCenter.default.addObserver(self, selector: #selector(MapViewController.statusBarHeightChange(_:)), name: Notification.Name("UIApplicationWillChangeStatusBarFrameNotification"), object: nil)
        
        // Order the SpotContent Array
        spotContent.sort {
            $0.datetime > $1.datetime
        }
        
        // Request all needed data and prep the cells
        self.refreshDataManually()
    }
    
    
    // MARK: LAYOUT METHODS
    
    func statusBarHeightChange(_ notification: Notification)
    {
        prepVcLayout()
        
        statusBarView.frame = CGRect(x: 0, y: 0, width: screenSize.width, height: statusBarHeight)
        viewContainer.frame = CGRect(x: 0, y: vcOffsetY, width: screenSize.width, height: vcHeight)
        spotContentTableView.frame = CGRect(x: 0, y: 0, width: viewContainer.frame.width, height: viewContainer.frame.height)
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
        let cellCount = spotContent.count
        return cellCount
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        let cellHeight: CGFloat = tableView.frame.width
        return cellHeight
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
//        print("STVC - CREATING CELL: \(indexPath.row)")
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.Strings.spotTableViewCellReuseIdentifier, for: indexPath) as! SpotTableViewCell
//        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.Strings.spotTableViewCellReuseIdentifier, for: indexPath)
        
//        cell.cellContainer.frame = CGRect(x: 0, y: 0, width: tableView.frame.width, height: tableView.frame.width)
        
        // Store the spotContent for this cell for reference
        let cellSpotContent = spotContent[indexPath.row]
        
        // Remove all subviews
        for subview in cell.subviews
        {
            subview.removeFromSuperview()
        }
        
        cell.cellContainer = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: tableView.frame.width + 50))
        cell.addSubview(cell.cellContainer)
        
//        cell.footerContainer = UIView(frame: CGRect(x: 0, y: cell.cellContainer.frame.height - 50, width: cell.cellContainer.frame.width, height: 50))
//        cell.footerContainer.backgroundColor = Constants.Colors.standardBackground
//        cell.cellContainer.addSubview(cell.footerContainer)
        
        cell.cellImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: cell.cellContainer.frame.width, height: cell.cellContainer.frame.width))
        cell.cellImageView.contentMode = UIViewContentMode.scaleAspectFit
        cell.cellImageView.clipsToBounds = true
        cell.cellContainer.addSubview(cell.cellImageView)
        
        // Add a loading indicator until the Media has downloaded
        // Give it the same size and location as the imageView
        cell.mediaActivityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: cell.cellImageView.frame.width, height: cell.cellImageView.frame.height))
        cell.mediaActivityIndicator.color = UIColor.black
        cell.cellImageView.addSubview(cell.mediaActivityIndicator)
        cell.mediaActivityIndicator.startAnimating()
        
        cell.userImageView = UIImageView(frame: CGRect(x: 10, y: 10, width: 50, height: 50))
//        cell.userImageView = UIImageView(frame: CGRect(x: 0, y: cell.cellContainer.frame.height - 50, width: 50, height: 50))
        cell.userImageView.backgroundColor = Constants.Colors.standardBackgroundGrayTransparent
        cell.userImageView.contentMode = UIViewContentMode.scaleAspectFit
        cell.userImageView.clipsToBounds = true
        cell.cellContainer.addSubview(cell.userImageView)
        
        // Add a loading indicator until the user image has downloaded
        // Give it the same size and location as the user image
        cell.userImageActivityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: cell.userImageView.frame.width, height: cell.userImageView.frame.height))
        cell.userImageActivityIndicator.color = UIColor.black
        cell.userImageView.addSubview(cell.userImageActivityIndicator)
        cell.userImageActivityIndicator.startAnimating()
        
        cell.datetimeLabel = UILabel(frame: CGRect(x: cell.cellImageView.frame.width - 60, y: cell.cellImageView.frame.height - 60, width: 50, height: 50))
//        cell.datetimeLabel = UILabel(frame: CGRect(x: 50, y: cell.cellContainer.frame.height - 50, width: 50, height: 50))
        cell.datetimeLabel.backgroundColor = Constants.Colors.standardBackgroundGrayTransparent
        cell.datetimeLabel.font = UIFont(name: Constants.Strings.fontAlt, size: 16)
        cell.datetimeLabel.textColor = Constants.Colors.colorTextLight
        cell.datetimeLabel.textAlignment = .center
        cell.datetimeLabel.numberOfLines = 2
        cell.datetimeLabel.lineBreakMode = NSLineBreakMode.byWordWrapping
        cell.cellContainer.addSubview(cell.datetimeLabel)
        
        cell.shareButtonView = UIView(frame: CGRect(x: cell.cellImageView.frame.width - 60, y: 10, width: 50, height: 50))
//        cell.shareButtonView = UIView(frame: CGRect(x: cell.cellContainer.frame.width - 50, y: cell.cellContainer.frame.height - 50, width: 50, height: 50))
        cell.shareButtonView.backgroundColor = Constants.Colors.standardBackgroundGrayTransparent
        cell.cellContainer.addSubview(cell.shareButtonView)
        
        cell.shareButtonImage = UIImageView(frame: CGRect(x: 10, y: 10, width: 30, height: 30))
        cell.shareButtonImage.image = UIImage(named: Constants.Strings.iconShareArrow)
        cell.shareButtonImage.contentMode = UIViewContentMode.scaleAspectFit
        cell.shareButtonImage.clipsToBounds = true
        cell.shareButtonView.addSubview(cell.shareButtonImage)
        
        cell.flagButtonView = UIView(frame: CGRect(x: 10, y: cell.cellImageView.frame.height - 60, width: 50, height: 50))
//        cell.flagButtonView = UIView(frame: CGRect(x: cell.cellContainer.frame.width - 100, y: cell.cellContainer.frame.height - 50, width: 50, height: 50))
        cell.flagButtonView.backgroundColor = Constants.Colors.standardBackgroundGrayTransparent
        cell.cellContainer.addSubview(cell.flagButtonView)
        
        cell.flagButtonImage = UILabel(frame: CGRect(x: 10, y: 10, width: 30, height: 30))
//        cell.flagButtonImage.image = UIImage(named: Constants.Strings.iconShareArrow)
//        cell.flagButtonImage.contentMode = UIViewContentMode.scaleAspectFit
//        cell.flagButtonImage.clipsToBounds = true
        cell.flagButtonImage.font = UIFont(name: Constants.Strings.fontAlt, size: 30)
        cell.flagButtonImage.textColor = Constants.Colors.colorTextLight
        cell.flagButtonImage.textAlignment = .center
        cell.flagButtonImage.text = "\u{2691}" // "\u{26A0}"
        cell.flagButtonView.addSubview(cell.flagButtonImage)
        
        if indexPath.row > 0
        {
            let border1 = CALayer()
            border1.frame = CGRect(x: 0, y: 0, width: cell.cellContainer.frame.width, height: 1)
            border1.backgroundColor = Constants.Colors.standardBackgroundGrayUltraLight.cgColor
            cell.cellContainer.layer.addSublayer(border1)
        }
        cell.datetimeLabel.text = String(indexPath.row)
        if let datetime = cellSpotContent.datetime
        {
            // Capture the number of hours it has been since the Spot was created (as a positive integer)
            let dateAgeHrs: Int = -1 * Int(datetime.timeIntervalSinceNow / 3600)
            
            // Set the datetime label.  If the Spot's recency is less than 5 days (120 hours), just show the day and time.
            // If the Spot's recency is more than 5 days, include the date
            let formatter = DateFormatter()
            formatter.amSymbol = "am"
            formatter.pmSymbol = "pm"
            
            // Set the date age label.  If the age is less than 24 hours, just show it in hours.  Otherwise, show the number of days and hours.
            var stringDate = String(dateAgeHrs / Int(24)) + "\ndays" //+ String(dateAgeHrs % 24) + " hrs"
            if dateAgeHrs < 24
            {
                stringDate = String(dateAgeHrs) + "\nhrs"
            }
            else if dateAgeHrs < 48
            {
                stringDate = "1\nday"
            }
            else if dateAgeHrs < 120
            {
                formatter.dateFormat = "E\nh:mm\na" //"E, H:mma"
                stringDate = formatter.string(from: datetime as Date)
                cell.datetimeLabel.font = UIFont(name: Constants.Strings.fontAlt, size: 12)
                cell.datetimeLabel.numberOfLines = 3
            }
            else
            {
                formatter.dateFormat = "E\nMMM d" // "E, MMM d"   "E, MMM d, H:mma"
                stringDate = formatter.string(from: datetime as Date)
                cell.datetimeLabel.font = UIFont(name: Constants.Strings.fontAlt, size: 14)
            }
            cell.datetimeLabel.text = stringDate
        }
        
        // Find the associated user and assign the image, if available (if not, don't show the user imageview)
        spotLoop: for spot in Constants.Data.allSpot
        {
            print("STVC-SPOT CHECK: \(spot.spotID)")
            if spot.spotID == cellSpotContent.spotID
            {
                print("STVC-SPOT FOUND: \(spot.spotID)")
                userLoop: for user in Constants.Data.allUsers
                {
                    print("STVC-USER CHECK: \(user.userID)")
                    if user.userID == spot.userID
                    {
                        print("STVC-USER FOUND: \(user.userID)")
                        print("STVC - USER-CHECK 1: \(user.userID)")
                        print("STVC - FBID-CHECK 2: \(user.facebookID)")
                        print("STVC - TYPE-CHECK 3: \(user.type)")
                        print("STVC - STATUS-CHECK 4: \(user.status)")
                        print("STVC - CONN-CHECK 5: \(user.connection)")
                        print("STVC - DATETIME-CHECK 6: \(user.datetime)")
                        print("STVC - NAME-CHECK 7: \(user.name)")
                        print("STVC - THUMBNAIL-CHECK 8: \(user.image?.size)")
                        print("STVC - IMAGE-CHECK 9: \(user.thumbnail?.size)")
                        if let image = user.thumbnail
                        {
                            print("STVC-IMAGE ADDED")
                            cell.userImageView.image = image
                            cell.cellContainer.addSubview(cell.userImageView)
                            cell.userImageActivityIndicator.stopAnimating()
                        }
                        else
                        {
                            // For some reason the thumbnail has not yet downloaded for this user - request the image again
                            RequestPrep(requestToCall: FBDownloadUserImage(facebookID: user.facebookID, largeImage: false), delegate: self as RequestDelegate).prepRequest()
                        }
                        break userLoop
                    }
                }
                break spotLoop
            }
        }
        
//        // Add FB Share stuff
//        if let image = cellSpotContent.image
//        {
//            let photo : FBSDKSharePhoto = FBSDKSharePhoto()
//            photo.image = image
//            photo.isUserGenerated = true
//            let fbShareContent : FBSDKSharePhotoContent = FBSDKSharePhotoContent()
//            fbShareContent.photos = [photo]
//            
//            let shareButton = FBSDKShareButton()
//            shareButton.center = cell.cellContainer.center
//            shareButton.shareContent = fbShareContent
//            cell.cellContainer.addSubview(shareButton)
//        }
        
        // Assign the spot content image to the image if available - if not, assign the thumbnail until the real image downloads
        if let contentImage = cellSpotContent.image
        {
//            print("STVC - ADDING IMAGE: \(contentImage)")
            cell.cellImageView.image = contentImage
            
            // Stop animating the activity indicator
            cell.mediaActivityIndicator.stopAnimating()
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
//        print("STVC - SELECTED CELL: \(indexPath.row)")
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
    
    
    // MARK: GESTURE RECOGNIZERS
    
    func tableGesture(_ gesture: UITapGestureRecognizer)
    {
        if gesture.state == UIGestureRecognizerState.ended
        {
            let tapLocation = gesture.location(in: self.spotContentTableView)
//            print("STVC - TAP LOCATION: \(tapLocation)")
            if let tappedIndexPath = spotContentTableView.indexPathForRow(at: tapLocation)
            {
//                print("STVC - TAPPED INDEX PATH: \(tappedIndexPath)")
                if let tappedCell = self.spotContentTableView.cellForRow(at: tappedIndexPath) as? SpotTableViewCell
                {
                    let cellTapLocation = gesture.location(in: tappedCell)
                    if tappedCell.userImageView.frame.contains(cellTapLocation)
                    {
                        // Load the UserVC
                        let spotID = spotContent[tappedIndexPath.row].spotID
                        spotLoop: for spot in Constants.Data.allSpot
                        {
                            if spot.spotID == spotID
                            {
                                userLoop: for user in Constants.Data.allUsers
                                {
                                    if user.userID == spot.userID
                                    {
                                        print("STVC - USER TAP: \(user.userID)")
                                        let userVC = UserViewController(user: user)
                                        self.navigationController!.pushViewController(userVC, animated: true)
                                        break userLoop
                                    }
                                }
                                break spotLoop
                            }
                        }
                    }
                    if tappedCell.shareButtonView.frame.contains(cellTapLocation)
                    {
                        // Share the image on Facebook
//                        print("STVC - SHARE CONTAINS")
                        if let image = spotContent[tappedIndexPath.row].image
                        {
                            let photo : FBSDKSharePhoto = FBSDKSharePhoto()
                            photo.image = image
                            photo.isUserGenerated = true
                            let fbShareContent : FBSDKSharePhotoContent = FBSDKSharePhotoContent()
                            fbShareContent.photos = [photo]

                            let shareDialog = FBSDKShareDialog()
                            shareDialog.shareContent = fbShareContent
                            shareDialog.mode = .native
                            if let fbShareResponse = try? shareDialog.show()
                            {
                                print("STVC - FB SHARE RESPONSE: \(fbShareResponse)")
                            }
                        }
                    }
                    else if tappedCell.flagButtonView.frame.contains(cellTapLocation)
                    {
                        // Ensure the user wants to flag the content "Are you sure you want to report this image as objectionable or inaccurate?"
                        let alertController = UIAlertController(title: "REPORT IMAGE", message: "", preferredStyle: UIAlertControllerStyle.alert)
                        let objectionableAction = UIAlertAction(title: "Inappropriate", style: UIAlertActionStyle.default)
                        { (result : UIAlertAction) -> Void in
                            
                            // Flag the image as objectionable
                            let contentID = self.spotContent[tappedIndexPath.row].contentID
                            let spotID = self.spotContent[tappedIndexPath.row].spotID
                            print("STVC - FLAG 00 FOR CONTENT: \(String(describing: contentID))")
                            
                            // Send the SpotContent update
                            AWSPrepRequest(requestToCall: AWSUpdateSpotContentData(contentID: contentID, spotID: spotID, statusUpdate: "flag-00"), delegate: self as AWSRequestDelegate).prepRequest()
                        }
                        alertController.addAction(objectionableAction)
                        let inaccurateAction = UIAlertAction(title: "Inaccurate", style: UIAlertActionStyle.default)
                        { (result : UIAlertAction) -> Void in
                            
                            // Flag the image as objectionable
                            let contentID = self.spotContent[tappedIndexPath.row].contentID
                            let spotID = self.spotContent[tappedIndexPath.row].spotID
                            print("STVC - FLAG 01 FOR CONTENT: \(String(describing: contentID))")
                            
                            // Send the SpotContent update
                            AWSPrepRequest(requestToCall: AWSUpdateSpotContentData(contentID: contentID, spotID: spotID, statusUpdate: "flag-01"), delegate: self as AWSRequestDelegate).prepRequest()
                        }
                        alertController.addAction(inaccurateAction)
                        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.default)
                        { (result : UIAlertAction) -> Void in
                            print("STVC - FLAG CANCELLED")
                        }
                        alertController.addAction(cancelAction)
                        self.present(alertController, animated: true, completion: nil)
                    }
                }
            }
        }
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
    
    func refreshSpotViewTable()
    {
        DispatchQueue.main.async(execute:
            {
                if self.spotContentTableView != nil
                {
                    // Reload the TableView
                    self.spotContentTableView.performSelector(onMainThread: #selector(UITableView.reloadData), with: nil, waitUntilDone: true)
                }
        })
    }
    
    func refreshDataManually()
    {
        for spotContentObject in spotContent
        {
            if spotContentObject.image == nil
            {
                // Upload the SpotRequest
                AWSPrepRequest(requestToCall: AWSGetMediaImage(spotContent: spotContentObject), delegate: self as AWSRequestDelegate).prepRequest()
            }
        }
    }
    
    
    // MARK: AWS DELEGATE METHODS
    
    func showLoginScreen()
    {
        print("BAVC - SHOW LOGIN SCREEN")
        
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
                case let awsGetMediaImage as AWSGetMediaImage:
                    if success
                    {
                        if let contentImage = awsGetMediaImage.contentImage
                        {
                            // Find the spotContent Object in the local array and add the downloaded image to the object variable
                            findSpotContentLoop: for contentObject in self.spotContent
                            {
                                if contentObject.contentID == awsGetMediaImage.spotContent.contentID
                                {
                                    // Set the local image property to the downloaded image
                                    contentObject.image = contentImage
                                    if let filePath = awsGetMediaImage.spotContent.imageFilePath
                                    {
                                        contentObject.imageFilePath = filePath
                                    }
                                    
                                    break findSpotContentLoop
                                }
                            }
                            
                            // Find the spotContent Object in the global array and add the downloaded image to the object variable
                            findSpotLoop: for spotObject in Constants.Data.allSpot
                            {
                                if spotObject.spotID == awsGetMediaImage.spotContent.spotID
                                {
                                    findSpotContentLoop: for contentObject in spotObject.spotContent
                                    {
                                        if contentObject.contentID == awsGetMediaImage.spotContent.contentID
                                        {
                                            // Set the local image property to the downloaded image
                                            contentObject.image = contentImage
                                            if let filePath = awsGetMediaImage.spotContent.imageFilePath
                                            {
                                                contentObject.imageFilePath = filePath
                                            }
                                            
                                            break findSpotContentLoop
                                        }
                                    }
                                    
                                    break findSpotLoop
                                }
                            }

                            
                            // Reload the TableView
                            self.refreshSpotViewTable()
                        }
                    }
                    else
                    {
                        // Show the error message
                        let alertController = UtilityFunctions().createAlertOkView("AWSGetMediaImage - Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
                        self.present(alertController, animated: true, completion: nil)
                    }
                case let awsUpdateSpotContentData as AWSUpdateSpotContentData:
                    if success
                    {
                        // The flagging update was successful, so remove the image from the current view
                        // THE GLOBAL ARRAY WAS UPDATED IN THE AWS CLASS RESPONSE
                        localSpotContentLoop: for (index, spotContentObject) in self.spotContent.enumerated()
                        {
                            if spotContentObject.contentID == awsUpdateSpotContentData.contentID
                            {
                                // Remove the SpotContent object
                                self.spotContent.remove(at: index)
                                
                                // Update the tableview
                                self.refreshSpotViewTable()
                                
                                break localSpotContentLoop
                            }
                        }
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
    
    func processRequestReturn(_ requestCalled: RequestObject, success: Bool)
    {
        // Process the return data based on the method used
        switch requestCalled
        {
        case _ as FBDownloadUserImage:
            if success
            {
                print("STVC-FBDownloadUserImage")
                self.refreshSpotViewTable()
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
