//
//  SpotTableViewController.swift
//  Harvey
//
//  Created by Sean Hart on 8/31/17.
//  Copyright © 2017 tangojlabs. All rights reserved.
//

import UIKit

class SpotTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate, AWSRequestDelegate
{
    // Save device settings to adjust view if needed
    var screenSize: CGRect!
    var statusBarHeight: CGFloat!
    var navBarHeight: CGFloat!
    var viewFrameY: CGFloat!
    
    // Add the view components
    var viewContainer: UIView!
    var spotContentTableView: UITableView!
//    lazy var refreshControl: UIRefreshControl = UIRefreshControl()
    
    // Properties to hold local information
    var viewContainerHeight: CGFloat!
    var spotCellWidth: CGFloat!
//    var spotCellContentHeight: CGFloat!
    var spotMediaSize: CGFloat!
    
    // This data should be filled when the ViewController is initialized
    var spotContent = [SpotContent]()
    
    override func viewDidLoad()
    {
        super.viewDidLoad()

        // Device and Status Bar Settings
        UIApplication.shared.isStatusBarHidden = false
        UIApplication.shared.statusBarStyle = Constants.Settings.statusBarStyle
        statusBarHeight = UIApplication.shared.statusBarFrame.size.height
        navBarHeight = self.navigationController?.navigationBar.frame.height
        viewFrameY = self.view.frame.minY
        screenSize = UIScreen.main.bounds
        
        self.automaticallyAdjustsScrollViewInsets = false
        
        // Add the view container to hold all other views (allows for shadows on all subviews)
        let viewContainerOffset = statusBarHeight + navBarHeight - viewFrameY
        self.viewContainerHeight = self.view.bounds.height - viewContainerOffset
        viewContainer = UIView(frame: CGRect(x: 0, y: viewContainerOffset, width: self.view.bounds.width, height: self.viewContainerHeight))
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
        
//        // Create a refresh control for the CollectionView and add a subview to move the refresh control where needed
//        refreshControl = UIRefreshControl()
//        refreshControl.attributedTitle = NSAttributedString(string: "")
//        refreshControl.addTarget(self, action: #selector(SpotTableViewController.refreshDataManually), for: UIControlEvents.valueChanged)
//        spotContentTableView.addSubview(refreshControl)
//        spotTableView.contentOffset = CGPoint(x: 0, y: -self.refreshControl.frame.size.height)
        
        // Order the SpotContent Array
        spotContent.sort {
            $0.datetime > $1.datetime
        }
        
        // Request all needed data and prep the cells
        self.refreshDataManually()
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
        let cellHeight: CGFloat = viewContainer.frame.width + 20
        return cellHeight
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.Strings.spotTableViewCellReuseIdentifier, for: indexPath) as! SpotTableViewCell
        
//        print("STVC - CREATING CELL: \(indexPath.row)")
        // Store the spotContent for this cell for reference
        let cellSpotContent = spotContent[indexPath.row]
        
//        // Remove all subviews
//        for subview in cell.subviews
//        {
//            subview.removeFromSuperview()
//        }
        
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
            var stringDate = String(dateAgeHrs / Int(24)) + " days ago" //+ String(dateAgeHrs % 24) + " hrs"
            if dateAgeHrs < 24
            {
                stringDate = String(dateAgeHrs) + " hrs ago"
            }
            else if dateAgeHrs < 48
            {
                stringDate = "1 day ago"
            }
            else if dateAgeHrs < 120
            {
                formatter.dateFormat = "E, H:mma"
                stringDate = formatter.string(from: datetime as Date)
            }
            else
            {
                formatter.dateFormat = "E, MMM d" // "E, MMM d, H:mma"
                stringDate = formatter.string(from: datetime as Date)
            }
            cell.datetimeLabel.text = stringDate
        }
        
        // Start animating the activity indicator
        cell.mediaActivityIndicator.startAnimating()
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
                default:
                    print("STVC-DEFAULT: THERE WAS AN ISSUE WITH THE DATA RETURNED FROM AWS")
                    // Show the error message
                    let alertController = UtilityFunctions().createAlertOkView("DEFAULT - Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
                    self.present(alertController, animated: true, completion: nil)
                }
        })
    }
}
