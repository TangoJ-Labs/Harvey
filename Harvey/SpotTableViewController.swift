//
//  SpotTableViewController.swift
//  Harvey
//
//  Created by Sean Hart on 8/31/17.
//  Copyright © 2017 TangoJ Labs, LLC. All rights reserved.
//

import FBSDKShareKit
import UIKit


protocol SpotTableViewControllerDelegate
{
    func reloadData()
}

class SpotTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate, UIGestureRecognizerDelegate, UserViewControllerDelegate, AWSRequestDelegate, RequestDelegate
{
    var spots = [Spot]()
    var spotContent = [SpotContent]()
    var allowDelete: Bool = false
    var visibleCells: Int = 0
    var backgroundText: String = ""
    
    convenience init(spots: [Spot], allowDelete: Bool)
    {
        self.init(nibName:nil, bundle:nil)
        
        self.spots = spots
        self.allowDelete = allowDelete
        
        // Create an array of only the content
        for spot in self.spots
        {
            if spot.spotContent.count > 0
            {
                self.spotContent = self.spotContent + spot.spotContent
            }
        }
        print("STVC - CONTENT INIT COUNT: \(self.spotContent.count)")
        if self.spotContent.count > 5
        {
            visibleCells = 5
        }
        else
        {
            visibleCells = self.spotContent.count
            
            if self.spotContent.count == 0
            {
                print("STVC - SHOW BG TEXT")
                backgroundText = "No content exists here.  Go to the main map to add some!"
            }
        }
    }
    
    var spotTableDelegate: SpotTableViewControllerDelegate?
    
    // MARK: PROPERTIES
    
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
    var backgroundLabel: UILabel!
    
    var spotContentTableView: UITableView!
    var tableGestureRecognizer: UITapGestureRecognizer!
    
    // Properties to hold local information
    var viewContainerHeight: CGFloat!
    var spotCellWidth: CGFloat!
//    var spotCellContentHeight: CGFloat!
    var spotMediaSize: CGFloat!
    
    // Settings to increment the number of cells displayed as the user scrolls content into view
    // Prevents all content being displayed at once and overloading the app with content and downloading
    let visibleIncrementSize: Int = 5
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        print("STVC - CONTENT COUNT: \(spotContent.count)")
        
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
        
        backgroundLabel = UILabel(frame: CGRect(x: 50, y: 5, width: viewContainer.frame.width - 100, height: viewContainer.frame.height / 2))
        backgroundLabel.textColor = Constants.Colors.colorTextDark
        backgroundLabel.text = backgroundText
        backgroundLabel.numberOfLines = 3
        backgroundLabel.lineBreakMode = NSLineBreakMode.byWordWrapping
        backgroundLabel.textAlignment = .center
        backgroundLabel.font = UIFont(name: "HelveticaNeue-UltraLight", size: 20)
        viewContainer.addSubview(backgroundLabel)
        
        // Set the main cell standard dimensions
        spotCellWidth = viewContainer.frame.width
        spotMediaSize = viewContainer.frame.width
        
        // A tableview will hold all comments
        spotContentTableView = UITableView(frame: CGRect(x: 0, y: 0, width: viewContainer.frame.width, height: viewContainer.frame.height))
        spotContentTableView.dataSource = self
        spotContentTableView.delegate = self
        spotContentTableView.register(SpotTableViewCell.self, forCellReuseIdentifier: Constants.Strings.spotTableViewCellReuseIdentifier)
        spotContentTableView.separatorStyle = .none
        spotContentTableView.backgroundColor = UIColor.clear //Constants.Colors.standardBackground
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
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        print("STVC - viewWillAppear")
        refreshSpotViewTable()
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
        return visibleCells
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
        
        // Remove all subviews
        for subview in cell.subviews
        {
            subview.removeFromSuperview()
        }
        
        if spotContent.count > indexPath.row
        {
            // Store the spotContent for this cell for reference
            let cellSpotContent = spotContent[indexPath.row]
            
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
//                print("STVC - CURRENT TIME: \(Date().timeIntervalSince1970), CONTENT TIME: \(datetime), CONTENT AGE: \(datetime.timeIntervalSinceNow), AGE ROUNDED: \(Date(timeIntervalSince1970: Double(Int(datetime.timeIntervalSinceNow / 3600))))")
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
            
            // If the delete button is allowed, place it over the user image
            if allowDelete
            {
                cell.deleteButtonView = UIView(frame: CGRect(x: 10, y: cell.cellImageView.frame.height - 60, width: 50, height: 50))
                cell.deleteButtonView.backgroundColor = Constants.Colors.colorGrayDark
                cell.cellContainer.addSubview(cell.deleteButtonView)
                
                cell.deleteButtonImage = UILabel(frame: CGRect(x: 0, y: 0, width: cell.deleteButtonView.frame.width, height: cell.deleteButtonView.frame.height))
                cell.deleteButtonImage.text = "DELETE"
                cell.deleteButtonImage.textColor = Constants.Colors.colorTextLight
                cell.deleteButtonImage.font = UIFont(name: Constants.Strings.fontAlt, size: 12)
                cell.deleteButtonImage.textAlignment = .center
                
                // Add a loading indicator in case the content is waiting to be deleted
                // Give it the same size and location as the delete button
                cell.deleteButtonActivityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: cell.deleteButtonView.frame.width, height: cell.deleteButtonView.frame.height))
                cell.deleteButtonActivityIndicator.color = UIColor.white
                
                if cellSpotContent.deletePending
                {
                    cell.deleteButtonView.addSubview(cell.deleteButtonActivityIndicator)
                    cell.deleteButtonActivityIndicator.startAnimating()
                }
                else
                {
                    cell.deleteButtonView.addSubview(cell.deleteButtonImage)
                }
                
                // Show the current user's image in all the cells
                if let image = Constants.Data.currentUser.image
                {
                    cell.userImageView.image = image
                    cell.cellContainer.addSubview(cell.userImageView)
                    cell.userImageActivityIndicator.stopAnimating()
                }
                else if let image = Constants.Data.currentUser.thumbnail
                {
                    cell.userImageView.image = image
                    cell.cellContainer.addSubview(cell.userImageView)
                    cell.userImageActivityIndicator.stopAnimating()
                }
                else
                {
                    // For some reason the thumbnail has not yet downloaded for this user - request the image again
                    RequestPrep(requestToCall: FBDownloadUserImage(facebookID: Constants.Data.currentUser.facebookID, largeImage: false), delegate: self as RequestDelegate).prepRequest()
                }
            }
            else
            {
                // Various users' content is shown - show the user image
                // Find the associated user and assign the image, if available (if not, don't show the user imageview)
                spotLoop: for spot in Constants.Data.allSpot
                {
                    if spot.spotID == cellSpotContent.spotID
                    {
                        userLoop: for user in Constants.Data.allUsers
                        {
                            if user.userID == spot.userID
                            {
                                if let image = user.thumbnail
                                {
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
            }
            
            // Add the content image, if available - otherwise download and indicate as being downloaded so it does not fire again
            if let contentImage = cellSpotContent.image
            {
                cell.cellImageView.image = contentImage
                
                // Stop animating the activity indicator
                cell.mediaActivityIndicator.stopAnimating()
            }
            else
            {
                if !spotContent[indexPath.row].imageDownloading
                {
                    // Get the missing image
                    AWSPrepRequest(requestToCall: AWSGetMediaImage(spotContent: cellSpotContent), delegate: self as AWSRequestDelegate).prepRequest()
                    
                    // Save the downloading indicator on the object in the array, otherwise it will download again
                    spotContent[indexPath.row].imageDownloading = true
                }
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath)
    {
        print("STVC - VISIBLE CELLS: \(visibleCells) - WILL DISPLAY CELL: \(indexPath.row)")
        
        // Determine if the last visible cell is being shown - if so, show more cells
        // (subtract one from the cell count since the table indices start at 0)
        if indexPath.row == visibleCells - 1
        {
            // Increase the cells viewable and refresh the table (ensure not more than the original list count)
            let oldVisibleCellCount = visibleCells
            if spotContent.count >= oldVisibleCellCount + visibleIncrementSize
            {
                visibleCells = oldVisibleCellCount + visibleIncrementSize
            }
            else
            {
                visibleCells = spotContent.count
            }
            print("STVC - INCREASING CELL RANGE TO: \(visibleCells)")
            
            // Only refresh if the count changed
            if visibleCells > oldVisibleCellCount
            {
                refreshSpotViewTable()
            }
        }
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
            print("STVC - TAP LOCATION: \(tapLocation)")
            if let tappedIndexPath = spotContentTableView.indexPathForRow(at: tapLocation)
            {
                print("STVC - TAPPED INDEX PATH: \(tappedIndexPath)")
                if spotContent.count > 0
                {
                    if let tappedCell = self.spotContentTableView.cellForRow(at: tappedIndexPath) as? SpotTableViewCell
                    {
                        let cellTapLocation = gesture.location(in: tappedCell)
                        if tappedCell.userImageView.frame.contains(cellTapLocation)
                        {
                            // Load the UserVC
                            print("STVC - SPOT CONTENT COUNT: \(spotContent.count)")
                            if spotContent.count > tappedIndexPath.row
                            {
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
                                                userVC.userDelegate = self
                                                self.navigationController!.pushViewController(userVC, animated: true)
                                                break userLoop
                                            }
                                        }
                                        break spotLoop
                                    }
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
                            // If delete isn't allowed, the user is tapping on the user image, if it is, the user is tapping on the delete button
                            if !allowDelete
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
                                let inaccurateAction = UIAlertAction(title: "Inaccurate", style: UIAlertActionStyle.default)
                                { (result : UIAlertAction) -> Void in
                                    
                                    // Flag the image as objectionable
                                    let contentID = self.spotContent[tappedIndexPath.row].contentID
                                    let spotID = self.spotContent[tappedIndexPath.row].spotID
                                    print("STVC - FLAG 01 FOR CONTENT: \(String(describing: contentID))")
                                    
                                    // Send the SpotContent update
                                    AWSPrepRequest(requestToCall: AWSUpdateSpotContentData(contentID: contentID, spotID: spotID, statusUpdate: "flag-01"), delegate: self as AWSRequestDelegate).prepRequest()
                                }
                                let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.default)
                                { (result : UIAlertAction) -> Void in
                                    print("STVC - FLAG CANCELLED")
                                }
                                alertController.addAction(objectionableAction)
                                alertController.addAction(inaccurateAction)
                                alertController.addAction(cancelAction)
                                self.present(alertController, animated: true, completion: nil)
                            }
                            else
                            {
                                print("STVC - DELETE IMAGE: \(spotContent[tappedIndexPath.row].contentID)")
                                
                                // Ensure the user wants to delete the content
                                let alertController = UIAlertController(title: "DELETE PHOTO", message: "Are you sure you want to delete this photo?", preferredStyle: UIAlertControllerStyle.alert)
                                let deleteAction = UIAlertAction(title: "Delete", style: UIAlertActionStyle.default)
                                { (result : UIAlertAction) -> Void in
                                    
                                    // Flag the image as objectionable
                                    let contentID = self.spotContent[tappedIndexPath.row].contentID
                                    let spotID = self.spotContent[tappedIndexPath.row].spotID
                                    print("STVC - DELETE FOR CONTENT: \(String(describing: contentID))")
                                    
                                    // Send the SpotContent update
                                    AWSPrepRequest(requestToCall: AWSUpdateSpotContentData(contentID: contentID, spotID: spotID, statusUpdate: "delete"), delegate: self as AWSRequestDelegate).prepRequest()
                                    
                                    // Update the content so that it displays as waiting for the delete command to complete
                                    self.spotContent[tappedIndexPath.row].deletePending = true
                                    
                                    // Update the tableview
                                    self.refreshSpotViewTable()
                                }
                                let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.default)
                                { (result : UIAlertAction) -> Void in
                                    print("STVC - DELETE CANCELLED")
                                }
                                alertController.addAction(cancelAction)
                                alertController.addAction(deleteAction)
                                self.present(alertController, animated: true, completion: nil)
                            }
                        }
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
                    print("STVC - REFRESH SPOT VIEW TABLE")
                    
                    // Reload the TableView
                    self.spotContentTableView.reloadData()
//                    self.spotContentTableView.performSelector(onMainThread: #selector(UITableView.reloadData), with: nil, waitUntilDone: true)
                }
        })
    }
    func reloadSpotViewTable()
    {
        if self.spotContentTableView != nil
        {
            print("STVC - RELOAD SPOT VIEW TABLE")
            if self.spotContent.count > 5
            {
                visibleCells = 5
            }
            else
            {
                visibleCells = self.spotContent.count
            }
            
//            self.spotContentTableView.reloadData()
            self.spotContentTableView.performSelector(onMainThread: #selector(UITableView.reloadData), with: nil, waitUntilDone: true)
        }
    }
    func updateData()
    {
        // Remove all banned user's data from the local list
        // Create a new list with all non-blocked users' data (removing the data directly will fault out)
        var nonBlockedSpots = [Spot]()
        var nonBlockedSpotContent = [SpotContent]()
        for spot in spots
        {
            print("STVC - CHECK USER: \(index): \(spot.userID)")
            var userBlocked = false
            for user in Constants.Data.allUserBlockList
            {
                print("STVC - BLOCKED USER: \(user)")
                if user == spot.userID
                {
                    print("STVC - ALL SPOT COUNT: \(Constants.Data.allSpot.count)")
                    print("STVC - REMOVE BLOCKED USER: \(index)")
                    userBlocked = true
                }
            }
            if !userBlocked
            {
                nonBlockedSpots.append(spot)
                for spotContent in spot.spotContent
                {
                    nonBlockedSpotContent.append(spotContent)
                }
            }
        }
        spots = nonBlockedSpots
        spotContent = nonBlockedSpotContent
        
        print("STVC - SPOT COUNT: \(spots.count)")
        if spotContent.count > 0
        {
            reloadSpotViewTable()
        }
        else
        {
            reloadSpotViewTable()
            popViewController()
        }
        
        // Remove all banned user's data from the global list
        UtilityFunctions().updateUserConnections()
        UtilityFunctions().removeBlockedUsersFromGlobalSpotArray()
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
                        // The flagging / delete update was successful, so remove the image from the current view
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
