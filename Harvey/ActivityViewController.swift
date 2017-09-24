//
//  ActivityTableViewController.swift
//  Harvey
//
//  Created by Sean Hart on 9/13/17.
//  Copyright © 2017 TangoJ Labs, LLC. All rights reserved.
//

import GoogleMaps
import UIKit

class ActivityViewController: UIViewController, UIGestureRecognizerDelegate, GMSMapViewDelegate, AWSRequestDelegate
{
    var spotRequests: [SpotRequest]?
    var hazards: [Hazard]?
    var contentExists: Bool = false
    var backgroundText = ""
    
    convenience init(spotRequests: [SpotRequest])
    {
        self.init(nibName:nil, bundle:nil)
        
        // Order the Array
        let spotRequestsSort = spotRequests.sorted {
            $0.datetime > $1.datetime
        }
        self.spotRequests = spotRequestsSort
        
        print("ATVC - SPOT REQUESTS COUNT: \(spotRequestsSort.count)")
        if spotRequests.count > 0
        {
            contentExists = true
        }
        else
        {
            backgroundText = "You don't have any Photo Requests yet.  Go to the main map to add some!"
        }
    }
    convenience init(hazards: [Hazard])
    {
        self.init(nibName:nil, bundle:nil)
        
        // Order the Array
        let hazardsSort = hazards.sorted {
            $0.datetime > $1.datetime
        }
        self.hazards = hazardsSort
        
        print("ATVC - HAZARDS COUNT: \(hazardsSort.count)")
        if hazards.count > 0
        {
            contentExists = true
        }
        else
        {
            backgroundText = "You don't have any Hazard Reports yet.  Go to the main map to add some!"
        }
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
    var backgroundLabel: UILabel!
    var mapContainer: UIView!
    var mapView: GMSMapView!
    
    var nextButton: UIView!
    var nextButtonImage: UILabel!
    var nextButtonTapGestureRecognizer: UITapGestureRecognizer!
    var lastButton: UIView!
    var lastButtonImage: UILabel!
    var lastButtonTapGestureRecognizer: UITapGestureRecognizer!
    var deleteButton: UIView!
    var deleteButtonImage: UILabel!
    var deleteButtonTapGestureRecognizer: UITapGestureRecognizer!
//    var deleteButtonActivityIndicator: UIActivityIndicatorView!
    
    var marker: GMSMarker!
    var currentIndex: Int = 0
    
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
        viewContainer.backgroundColor = Constants.Colors.standardBackground
        self.view.addSubview(viewContainer)
        
        backgroundLabel = UILabel(frame: CGRect(x: 50, y: 5, width: viewContainer.frame.width - 100, height: viewContainer.frame.height / 2))
        backgroundLabel.textColor = Constants.Colors.colorTextDark
        backgroundLabel.text = backgroundText
        backgroundLabel.numberOfLines = 3
        backgroundLabel.lineBreakMode = NSLineBreakMode.byWordWrapping
        backgroundLabel.textAlignment = .center
        backgroundLabel.font = UIFont(name: "HelveticaNeue-UltraLight", size: 20)
        viewContainer.addSubview(backgroundLabel)
        
        // Add the map container to allow the map to be moved with all subviews
        mapContainer = UIView(frame: CGRect(x: 0, y: 0, width: viewContainer.frame.width, height: viewContainer.frame.height - 100))
        mapContainer.backgroundColor = Constants.Colors.standardBackground
        
        // Create a camera with the default location (if location services are used, this should not be shown for long)
        let defaultCamera = GMSCameraPosition.camera(withLatitude: Constants.Settings.mapViewDefaultLat, longitude: Constants.Settings.mapViewDefaultLong, zoom: Constants.Settings.mapViewDefaultZoom)
        mapView = GMSMapView.map(withFrame: mapContainer.bounds, camera: defaultCamera)
        mapView.padding = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        mapView.delegate = self
//        mapView.mapType = kGMSTypeNormal
//        mapView.isIndoorEnabled = true
        mapView.isBuildingsEnabled = true
        mapView.isMyLocationEnabled = false
        mapView.settings.myLocationButton = false
        mapView.isUserInteractionEnabled = false
        do
        {
            // Set the map style by passing the URL of the local file.
            if let styleURL = Bundle.main.url(forResource: "style", withExtension: "json")
            {
                mapView.mapStyle = try GMSMapStyle(contentsOfFileURL: styleURL)
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
        mapContainer.addSubview(mapView)
        
        // Add buttons to increment the content
        nextButton = UIView(frame: CGRect(x: mapContainer.frame.width - 50, y: (mapContainer.frame.height / 2) - 100, width: 50, height: 200))
        nextButton.backgroundColor = Constants.Colors.standardBackgroundGrayUltraLightTransparent
        nextButton.layer.shadowOffset = CGSize(width: 0, height: 0.6)
        nextButton.layer.shadowOpacity = 0.5
        nextButton.layer.shadowRadius = 1.0
        mapContainer.addSubview(nextButton)
        
        nextButtonImage = UILabel(frame: CGRect(x: 5, y: 5, width: nextButton.frame.width - 10, height: nextButton.frame.height - 10))
        nextButtonImage.textColor = UIColor.white
        nextButtonImage.text = ">"
        nextButtonImage.textAlignment = .center
        nextButtonImage.font = UIFont(name: "HelveticaNeue-UltraLight", size: 28)
        nextButton.addSubview(nextButtonImage)
        
        nextButtonTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ActivityViewController.nextButtonTap(_:)))
        nextButtonTapGestureRecognizer.delegate = self
        nextButton.addGestureRecognizer(nextButtonTapGestureRecognizer)
        
        lastButton = UIView(frame: CGRect(x: 0, y: (mapContainer.frame.height / 2) - 100, width: 50, height: 200))
        lastButton.backgroundColor = Constants.Colors.standardBackgroundGrayUltraLightTransparent
        lastButton.layer.shadowOffset = CGSize(width: 0, height: 0.6)
        lastButton.layer.shadowOpacity = 0.5
        lastButton.layer.shadowRadius = 1.0
        mapContainer.addSubview(lastButton)
        
        lastButtonImage = UILabel(frame: CGRect(x: 5, y: 5, width: lastButton.frame.width - 10, height: lastButton.frame.height - 10))
        lastButtonImage.textColor = UIColor.white
        lastButtonImage.text = "<"
        lastButtonImage.textAlignment = .center
        lastButtonImage.font = UIFont(name: "HelveticaNeue-UltraLight", size: 28)
        lastButton.addSubview(lastButtonImage)
        
        lastButtonTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ActivityViewController.lastButtonTap(_:)))
        lastButtonTapGestureRecognizer.delegate = self
        lastButton.addGestureRecognizer(lastButtonTapGestureRecognizer)
        
        // Add buttons to let the activity owner control the content
        deleteButton = UIView(frame: CGRect(x: 0, y: viewContainer.frame.height - 100, width: viewContainer.frame.width, height: 100))
        deleteButton.backgroundColor = Constants.Colors.colorGrayDark
        deleteButton.layer.shadowOffset = CGSize(width: 0, height: 0.6)
        deleteButton.layer.shadowOpacity = 0.5
        deleteButton.layer.shadowRadius = 1.0
        
        deleteButtonImage = UILabel(frame: CGRect(x: 5, y: 5, width: deleteButton.frame.width - 10, height: deleteButton.frame.height - 10))
        deleteButtonImage.textColor = Constants.Colors.colorTextLight
        deleteButtonImage.text = "DELETE"
        deleteButtonImage.textAlignment = .center
        deleteButtonImage.font = UIFont(name: "HelveticaNeue-UltraLight", size: 28)
        deleteButton.addSubview(deleteButtonImage)
        
        deleteButtonTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ActivityViewController.deleteButtonTap(_:)))
        deleteButtonTapGestureRecognizer.delegate = self
        deleteButton.addGestureRecognizer(deleteButtonTapGestureRecognizer)
        
//        // Add a loading indicator for while the content is waiting to be deleted
//        // Give it the same size and location as the delete button
//        deleteButtonActivityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: deleteButton.frame.width, height: deleteButton.frame.height))
//        deleteButtonActivityIndicator.color = UIColor.white
        
        // Only add the map and other container views if content exists
        if contentExists
        {
            viewContainer.addSubview(mapContainer)
            viewContainer.addSubview(deleteButton)
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(ActivityViewController.statusBarHeightChange(_:)), name: Notification.Name("UIApplicationWillChangeStatusBarFrameNotification"), object: nil)
        
        // Show the first activity
        showMarkerAt(index: 0)
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
        mapContainer.frame = CGRect(x: 0, y: 0, width: viewContainer.frame.width, height: viewContainer.frame.height - 50)
        mapView.frame = mapContainer.bounds
        deleteButton.frame = CGRect(x: mapContainer.frame.width - 66, y: 10, width: 56, height: 56)
        deleteButtonImage.frame = CGRect(x: 5, y: 5, width: deleteButton.frame.width - 10, height: deleteButton.frame.height - 10)
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
    
    
    // MARK: GESTURE RECOGNIZERS
    func nextButtonTap(_ gesture: UITapGestureRecognizer)
    {
        let indexAttempt = currentIndex + 1
        if let requests = spotRequests
        {
            if requests.count > indexAttempt && indexAttempt >= 0
            {
                currentIndex = indexAttempt
                showMarkerAt(index: currentIndex)
            }
        }
        else if let hazds = hazards
        {
            if hazds.count > indexAttempt && indexAttempt >= 0
            {
                currentIndex = indexAttempt
                showMarkerAt(index: currentIndex)
            }
        }
    }
    func lastButtonTap(_ gesture: UITapGestureRecognizer)
    {
        let indexAttempt = currentIndex - 1
        if let requests = spotRequests
        {
            if requests.count > indexAttempt && indexAttempt >= 0
            {
                currentIndex = indexAttempt
                showMarkerAt(index: currentIndex)
            }
        }
        else if let hazds = hazards
        {
            if hazds.count > indexAttempt && indexAttempt >= 0
            {
                currentIndex = indexAttempt
                showMarkerAt(index: currentIndex)
            }
        }
    }
    func deleteButtonTap(_ gesture: UITapGestureRecognizer)
    {
        if let requests = spotRequests
        {
            if requests.count > 0
            {
                print("AVC - DELETE SPOT REQUEST: \(String(describing: requests[currentIndex].requestID))")
                // Ensure the user wants to delete the content
                let alertController = UIAlertController(title: "DELETE PHOTO REQUEST", message: "Are you sure you want to delete this photo request?", preferredStyle: UIAlertControllerStyle.alert)
                let deleteAction = UIAlertAction(title: "Delete", style: UIAlertActionStyle.default)
                { (result : UIAlertAction) -> Void in
                    
                    // Update the SpotRequest object status
                    requests[self.currentIndex].status = "delete"
                    
                    // Send the SpotRequest update
                    AWSPrepRequest(requestToCall: AWSPutSpotRequestData(spotRequest: requests[self.currentIndex]), delegate: self as AWSRequestDelegate).prepRequest()
                    
                    // Remove the object at the list index and load the next object at the nearest upper index
                    // If the list only contains one object, and it is being deleted, just delete the object and remove the unneeded view containers
                    self.spotRequests!.remove(at: self.currentIndex)
                    
                    if self.spotRequests!.count > 0
                    {
                        if requests.count - 1 == self.currentIndex
                        {
                            // The object was already the last in the list, so show the previous object
                            self.showMarkerAt(index: self.currentIndex - 1)
                        }
                        else
                        {
                            // Just show at the currentIndex since the list is now updated
                            self.showMarkerAt(index: self.currentIndex)
                        }
                    }
                    else
                    {
                        self.contentExists = false
                        self.mapContainer.removeFromSuperview()
                        self.deleteButton.removeFromSuperview()
                    }
                    
                    // Delete the spot request from the global list
                    if let thisSpotRequestID = requests[self.currentIndex].requestID
                    {
                        requestLoop: for (index, request) in Constants.Data.allSpotRequest.enumerated()
                        {
                            if let requestID = request.requestID
                            {
                                if requestID == thisSpotRequestID
                                {
                                    Constants.Data.allSpotRequest.remove(at: index)
                                    
                                    break requestLoop
                                }
                            }
                        }
                    }
                }
                let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.default)
                { (result : UIAlertAction) -> Void in
                    print("AVC - DELETE CANCELLED")
                }
                alertController.addAction(cancelAction)
                alertController.addAction(deleteAction)
                self.present(alertController, animated: true, completion: nil)
            }
        }
        else if let hazds = hazards
        {
            if hazds.count > 0
            {
                // Ensure the user wants to delete the content
                let alertController = UIAlertController(title: "DELETE HAZARD REPORT", message: "Are you sure you want to delete this hazard report?", preferredStyle: UIAlertControllerStyle.alert)
                let deleteAction = UIAlertAction(title: "Delete", style: UIAlertActionStyle.default)
                { (result : UIAlertAction) -> Void in
                    
                    // Update the Hazard object status
                    hazds[self.currentIndex].status = "delete"
                    
                    // Send the Hazard update
                    AWSPrepRequest(requestToCall: AWSPutHazardData(hazard: hazds[self.currentIndex]), delegate: self as AWSRequestDelegate).prepRequest()
                    
                    // Remove the object at the list index and load the next object at the nearest upper index
                    // If the list only contains one object, and it is being deleted, just delete the object and remove the unneeded view containers
                    self.hazards!.remove(at: self.currentIndex)
                    
                    if self.hazards!.count > 0
                    {
                        if hazds.count - 1 == self.currentIndex
                        {
                            // The object was already the last in the list, so show the previous object
                            self.showMarkerAt(index: self.currentIndex - 1)
                        }
                        else
                        {
                            // Just show at the currentIndex since the list is now updated
                            self.showMarkerAt(index: self.currentIndex)
                        }
                    }
                    else
                    {
                        self.contentExists = false
                        self.mapContainer.removeFromSuperview()
                        self.deleteButton.removeFromSuperview()
                    }
                    
                    // Delete the hazard from the global list
                    if let thisHazID = hazds[self.currentIndex].hazardID
                    {
                        hazLoop: for (index, haz) in Constants.Data.allHazard.enumerated()
                        {
                            if let hazID = haz.hazardID
                            {
                                if hazID == thisHazID
                                {
                                    Constants.Data.allHazard.remove(at: index)
                                    
                                    break hazLoop
                                }
                            }
                        }
                    }
                }
                let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.default)
                { (result : UIAlertAction) -> Void in
                    print("AVC - DELETE CANCELLED")
                }
                alertController.addAction(cancelAction)
                alertController.addAction(deleteAction)
                self.present(alertController, animated: true, completion: nil)
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
    
    func showMarkerAt(index: Int)
    {
        if let requests = spotRequests
        {
            if requests.count > index && index >= 0
            {
                showSpotRequestMarkerAt(lat: requests[index].lat, lng: requests[index].lng)
            }
        }
        else if let hazds = hazards
        {
            if hazds.count > index && index >= 0
            {
                showHazardMarkerAt(lat: hazds[index].lat, lng: hazds[index].lng)
            }
        }
    }
    func showSpotRequestMarkerAt(lat: Double, lng: Double)
    {
        clearMapMarker()
        let coords = CLLocationCoordinate2DMake(lat, lng)
        marker = GMSMarker()
        marker!.position = coords
        marker!.zIndex = 1
        marker!.iconView = UIImageView(image: UIImage(named: Constants.Strings.markerIconCamera))
        marker!.map = mapView
        
        updateCameraCoords(coords: coords)
    }
    func showHazardMarkerAt(lat: Double, lng: Double)
    {
        clearMapMarker()
        let coords = CLLocationCoordinate2DMake(lat, lng)
        marker = GMSMarker()
        marker!.position = coords
        marker!.groundAnchor = CGPoint(x: 0.5, y: 0.5)
        marker!.zIndex = 1
        marker!.iconView = UIImageView(image: UIImage(named: Constants.Strings.iconHazard))
        marker!.map = mapView
        
        updateCameraCoords(coords: coords)
    }
    func updateCameraCoords(coords: CLLocationCoordinate2D)
    {
        let cameraUpdate = GMSCameraUpdate.setTarget(coords, zoom: 16)
        mapView.animate(with: cameraUpdate)
    }
    
    func clearMapMarker()
    {
        if let mkr = marker
        {
            mkr.map = nil
        }
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
                case _ as AWSPutSpotRequestData:
                    if success
                    {
                        print("AVC - AWSPutSpotRequestData SUCCESS")
                        
                        if let sRequests = self.spotRequests
                        {
                            if sRequests.count == 0
                            {
                                self.popViewController()
                            }
                        }
                    }
                    else
                    {
                        print("AVC - AWSPutSpotRequestData FAILURE")
                        // Show the error message
                        let alertController = UtilityFunctions().createAlertOkView("Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
                        self.present(alertController, animated: true, completion: nil)
                    }
                case _ as AWSPutHazardData:
                    if success
                    {
                        print("AVC - AWSPutHazardData SUCCESS")
                        
                        if let hazs = self.hazards
                        {
                            if hazs.count == 0
                            {
                                self.popViewController()
                            }
                        }
                    }
                    else
                    {
                        print("AVC - AWSPutHazardData FAILURE")
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
