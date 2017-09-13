//
//  ActivityTableViewController.swift
//  Harvey
//
//  Created by Sean Hart on 9/13/17.
//  Copyright © 2017 tangojlabs. All rights reserved.
//

import GoogleMaps
import UIKit

class ActivityTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate, UIGestureRecognizerDelegate, AWSRequestDelegate
{
    var spotRequests: [SpotRequest]?
    var hazards: [Hazard]?
    
    convenience init(spotRequests: [SpotRequest])
    {
        self.init(nibName:nil, bundle:nil)
        
        // Order the Array
        let spotRequestsSort = spotRequests.sorted {
            $0.datetime > $1.datetime
        }
        print("ATVC - SPOT REQUESTS COUNT: \(spotRequestsSort.count)")
        self.spotRequests = spotRequestsSort
    }
    convenience init(hazards: [Hazard])
    {
        self.init(nibName:nil, bundle:nil)
        
        // Order the Array
        let hazardsSort = hazards.sorted {
            $0.datetime > $1.datetime
        }
        print("ATVC - HAZARDS COUNT: \(hazardsSort.count)")
        self.hazards = hazardsSort
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
    
    var activityTableView: UITableView!
    var tableGestureRecognizer: UITapGestureRecognizer!
    
    // Properties to hold local information
    var viewContainerHeight: CGFloat!
    var cellWidth: CGFloat!
    
    let cellHeight: CGFloat = 100
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        print("ATVC - CREATING TVC")
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
        cellWidth = viewContainer.frame.width
        
        // A tableview will hold all comments
        activityTableView = UITableView(frame: CGRect(x: 0, y: 0, width: viewContainer.frame.width, height: viewContainer.frame.height))
        activityTableView.dataSource = self
        activityTableView.delegate = self
        activityTableView.register(ActivityTableViewCell.self, forCellReuseIdentifier: Constants.Strings.activityTableViewCellReuseIdentifier)
        activityTableView.separatorStyle = .none
        activityTableView.backgroundColor = Constants.Colors.standardBackground
        activityTableView.isScrollEnabled = true
        activityTableView.bounces = true
        activityTableView.alwaysBounceVertical = true
        activityTableView.allowsSelection = false
        activityTableView.showsVerticalScrollIndicator = false
        activityTableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        viewContainer.addSubview(activityTableView)
        
        tableGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ActivityTableViewController.tableGesture(_:)))
        tableGestureRecognizer.delegate = self
        activityTableView.addGestureRecognizer(tableGestureRecognizer)
        
        NotificationCenter.default.addObserver(self, selector: #selector(ActivityTableViewController.statusBarHeightChange(_:)), name: Notification.Name("UIApplicationWillChangeStatusBarFrameNotification"), object: nil)
        
        // Request all needed data and prep the cells
        self.refreshDataManually()
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
        activityTableView.frame = CGRect(x: 0, y: 0, width: viewContainer.frame.width, height: viewContainer.frame.height)
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
        var cellCount: Int = 0
        if let requests = spotRequests
        {
            cellCount = requests.count
        }
        else if let haz = hazards
        {
            cellCount = haz.count
        }
        return cellCount
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return cellHeight
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        print("ATVC - CREATING CELL: \(indexPath.row)")
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.Strings.activityTableViewCellReuseIdentifier, for: indexPath) as! ActivityTableViewCell
        
        // Store the spotContent for this cell for reference
        var cellSpotRequest: SpotRequest?
        var cellHazard: Hazard?
        var cellLat: Double = 0.0
        var cellLng: Double = 0.0
        var cellMarkerString = Constants.Strings.markerIconCameraTemp
        
        if let requests = spotRequests
        {
            cellSpotRequest = requests[indexPath.row]
            cellLat = cellSpotRequest!.lat
            cellLng = cellSpotRequest!.lng
            cellMarkerString = Constants.Strings.markerIconCamera
        }
        else if let haz = hazards
        {
            cellHazard = haz[indexPath.row]
            cellLat = cellHazard!.lat
            cellLng = cellHazard!.lng
            cellMarkerString = Constants.Strings.iconHazard
        }
        
        // Remove all subviews
        for subview in cell.subviews
        {
            subview.removeFromSuperview()
        }
        
        cell.cellContainer = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: tableView.frame.width))
        cell.addSubview(cell.cellContainer)
        // Create a camera with the default location (if location services are used, this should not be shown for long)
        let defaultCamera = GMSCameraPosition.camera(withLatitude: cellLat, longitude: cellLng, zoom: 18)
        let mapFrame = CGRect(x: 0, y: 0, width: tableView.frame.width - cellHeight, height: cellHeight)
        cell.mapView = GMSMapView.map(withFrame: mapFrame, camera: defaultCamera)
        cell.mapView.padding = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
//        cell.mapView.delegate = self
//        cell.mapView.mapType = kGMSTypeNormal
//        cell.mapView.isIndoorEnabled = true
        cell.mapView.isBuildingsEnabled = true
        cell.mapView.isMyLocationEnabled = false
        cell.mapView.isUserInteractionEnabled = false
        do
        {
            // Set the map style by passing the URL of the local file.
            if let styleURL = Bundle.main.url(forResource: "style", withExtension: "json")
            {
                cell.mapView.mapStyle = try GMSMapStyle(contentsOfFileURL: styleURL)
            }
            else
            {
                NSLog("Unable to find style.json")
            }
        }
        catch
        {
            NSLog("The style definition could not be loaded: \(error)")
        }
        cell.cellContainer.addSubview(cell.mapView)
        
        // Custom Marker
        let cellMarker = GMSMarker()
        cellMarker.position = CLLocationCoordinate2DMake(cellLat, cellLng)
        cellMarker.zIndex = 1
        cellMarker.iconView = UIImageView(image: UIImage(named: cellMarkerString))
        cellMarker.map = cell.mapView
        
        cell.deleteButtonView = UIView(frame: CGRect(x: tableView.frame.width - cellHeight, y: 0, width: cellHeight, height: cellHeight))
        cell.deleteButtonView.backgroundColor = Constants.Colors.colorGrayDark
        cell.cellContainer.addSubview(cell.deleteButtonView)
        
        cell.deleteButtonImage = UILabel(frame: CGRect(x: 0, y: 0, width: cell.deleteButtonView.frame.width, height: cell.deleteButtonView.frame.height))
        cell.deleteButtonImage.text = "DELETE"
        cell.deleteButtonImage.textColor = Constants.Colors.colorTextLight
        cell.deleteButtonImage.font = UIFont(name: Constants.Strings.fontAlt, size: 18)
        cell.deleteButtonImage.textAlignment = .center
        cell.deleteButtonView.addSubview(cell.deleteButtonImage)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        print("ATVC - SELECTED CELL: \(indexPath.row)")
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
            let tapLocation = gesture.location(in: self.activityTableView)
            print("ATVC - TAP LOCATION: \(tapLocation)")
            if let tappedIndexPath = activityTableView.indexPathForRow(at: tapLocation)
            {
                print("ATVC - TAPPED INDEX PATH: \(tappedIndexPath)")
                if let tappedCell = self.activityTableView.cellForRow(at: tappedIndexPath) as? ActivityTableViewCell
                {
                    let cellTapLocation = gesture.location(in: tappedCell)
                    if tappedCell.deleteButtonView.frame.contains(cellTapLocation)
                    {
                        print("ATVC - TAPPED DELETE FOR: \(tappedIndexPath)")
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
                if self.activityTableView != nil
                {
                    // Reload the TableView
                    self.activityTableView.performSelector(onMainThread: #selector(UITableView.reloadData), with: nil, waitUntilDone: true)
                }
        })
    }
    
    func refreshDataManually()
    {
        
    }
    
    
    // MARK: AWS DELEGATE METHODS
    
    func showLoginScreen()
    {
        print("ATVC - SHOW LOGIN SCREEN")
        
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
                case let awsGetSpotData as AWSGetSpotData:
                    if success
                    {
                        
                    }
                    else
                    {
                        // Show the error message
                        let alertController = UtilityFunctions().createAlertOkView("Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
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
