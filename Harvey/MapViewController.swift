//
//  ViewController.swift
//  Harvey
//
//  Created by Sean Hart on 8/28/17.
//  Copyright © 2017 tangojlabs. All rights reserved.
//

import UIKit
import GoogleMaps

class MapViewController: UIViewController, GMSMapViewDelegate, XMLParserDelegate, CameraViewControllerDelegate, AWSRequestDelegate
{
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
    
    var menuView: UIView!
    var menuMapTrafficContainer: UIView!
    var menuMapTrafficImage: UIImageView!
    var menuMapTrafficIndicator: UIImageView!
    var menuMapTrafficTapGesture: UITapGestureRecognizer!
    var menuMapHydroContainer: UIView!
    var menuMapHydroImage: UIImageView!
    var menuMapHydroIndicator: UIImageView!
    var menuMapHydroTapGesture: UITapGestureRecognizer!
    var menuMapSpotContainer: UIView!
    var menuMapSpotImage: UIImageView!
    var menuMapSpotIndicator: UIImageView!
    var menuMapSpotTapGesture: UITapGestureRecognizer!
    var menuAboutContainer: UIView!
    var menuAboutLabel: UILabel!
    var menuAboutTapGesture: UITapGestureRecognizer!
    
    var mapContainer: UIView!
    var mapView: GMSMapView!
    
    var refreshView: UIView!
    var refreshViewImage: UILabel!
    var refreshViewSpinner: UIActivityIndicatorView!
    var refreshViewTapGesture: UITapGestureRecognizer!
    
    var addSpotRequestAddButton: UIView!
    var addSpotRequestAddButtonSpinner: UIActivityIndicatorView!
    var addSpotRequestAddButtonImage: UIImageView!
    var addSpotRequestAddButtonTapGesture: UITapGestureRecognizer!
    var addSpotRequestButton: UIView!
    var addSpotRequestButtonImage: UIImageView!
    var addSpotRequestButtonTapGesture: UITapGestureRecognizer!
    var addImageButton: UIView!
    var addImageButtonImage: UIImageView!
    var addImageButtonTapGesture: UITapGestureRecognizer!
    
    var infoWindow: UIView!
    var infoWindowExit: UIView!
    var infoWindowExitLabel: UILabel!
    var infoWindowExitTapGesture: UITapGestureRecognizer!
    
    var infoWindowTitle: UILabel!
    var infoWindowObs: UILabel!
    var infoWindowObsTime: UILabel!
    var infoWindowProjHigh: UILabel!
    var infoWindowProjHighTime: UILabel!
    var infoWindowLastUpdate: UILabel!
    
    // Data Variables
    var addSpotRequestToggle: Bool = false
    var newSpotRequest: SpotRequest?
    var newSpotRequestMarker: GMSMarker?
    
    // The Google Maps Coordinate Object for the current center of the map and the default Camera
//    var mapCenter: CLLocationCoordinate2D!
    var defaultCamera: GMSCameraPosition!
    
    let menuWidth: CGFloat = 80
    var menuVisible: Bool = false
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        // Record the status bar settings to adjust the view if needed
        UIApplication.shared.isStatusBarHidden = false
        UIApplication.shared.statusBarStyle = Constants.Settings.statusBarStyle
        statusBarHeight = UIApplication.shared.statusBarFrame.size.height
//        print("MVC - STATUS BAR HEIGHT: \(statusBarHeight)")
        
        // Navigation Bar settings
        navBarHeight = 44.0
        if let navController = self.navigationController
        {
            navController.isNavigationBarHidden = false
            navBarHeight = navController.navigationBar.frame.height
//            print("MVC - NAV BAR HEIGHT: \(navController.navigationBar.frame.height)")
            navController.navigationBar.barTintColor = Constants.Colors.colorOrangeOpaque
//            navController.navigationBar.tintColor = Constants.Colors.colorTextNavBar
//            navController.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName : Constants.Colors.colorOrangeOpaque]
        }
        viewFrameY = self.view.frame.minY
        screenSize = UIScreen.main.bounds
        
        vcHeight = screenSize.height - statusBarHeight - navBarHeight
        vcOffsetY = statusBarHeight + navBarHeight
        if statusBarHeight > 20
        {
            vcOffsetY = 20
        }
//        print("MVC - vcOffsetY: \(vcOffsetY)")
        
        // Add the Status Bar, Top Bar and Search Bar last so that they are placed above (z-index) all other views
        statusBarView = UIView(frame: CGRect(x: 0, y: 0, width: screenSize.width, height: statusBarHeight))
        statusBarView.backgroundColor = Constants.Colors.colorStatusBar
        self.view.addSubview(statusBarView)
        
        // Set the navBar settings - Create bar buttons and title for the Nav Bar
        let leftButtonItem = UIBarButtonItem(image: UIImage(named: Constants.Strings.iconMenu),
                                             style: UIBarButtonItemStyle.plain,
                                             target: self,
                                             action: #selector(MapViewController.toggleMenu(_:)))
        leftButtonItem.tintColor = Constants.Colors.colorTextNavBar
        
        let rightButtonItem = UIBarButtonItem(image: UIImage(named: Constants.Strings.iconProfile),
                                             style: UIBarButtonItemStyle.plain,
                                             target: self,
                                             action: #selector(MapViewController.loadProfileVC(_:)))
        rightButtonItem.tintColor = Constants.Colors.colorTextNavBar
        
        let ncTitle = UIView(frame: CGRect(x: screenSize.width / 2 - 75, y: 10, width: 150, height: 40))
        let ncTitleText = UILabel(frame: CGRect(x: 0, y: 0, width: 150, height: 40))
        ncTitleText.text = "HARVEY"
        ncTitleText.textColor = Constants.Colors.colorTextNavBar
        ncTitleText.font = UIFont(name: Constants.Strings.fontAlt, size: 22)
        ncTitleText.textAlignment = .center
        ncTitle.addSubview(ncTitleText)
        
//        let ncTitleImage = UIImageView(frame: CGRect(x: 0, y: 0, width: 150, height: 40))
//        ncTitleImage.contentMode = UIViewContentMode.scaleAspectFit
//        ncTitleImage.clipsToBounds = true
//        ncTitleImage.image = UIImage(named: Constants.Strings.imageHarvey)
//        ncTitle.addSubview(ncTitleImage)
        
        // Assign the created Nav Bar settings to the Tab Bar Controller
        self.navigationItem.setLeftBarButton(leftButtonItem, animated: true)
        self.navigationItem.setRightBarButton(rightButtonItem, animated: true)
        self.navigationItem.titleView = ncTitle
        
        // Add the view container to hold all other views (allows for shadows on all subviews)
        viewContainer = UIView(frame: CGRect(x: 0, y: vcOffsetY, width: screenSize.width, height: vcHeight))
        viewContainer.backgroundColor = Constants.Colors.standardBackground
        self.view.addSubview(viewContainer)
        
        // Add the menu container to hold menu items under the map
        menuView = UIView(frame: CGRect(x: 0, y: 0, width: menuWidth, height: viewContainer.frame.height))
        menuView.backgroundColor = Constants.Colors.standardBackground
        viewContainer.addSubview(menuView)
        
        menuMapTrafficContainer = UIView(frame: CGRect(x: 0, y: 0, width: menuView.frame.width, height: 50))
        menuView.addSubview(menuMapTrafficContainer)
        menuMapTrafficImage = UIImageView(frame: CGRect(x: 5, y: 5, width: 40, height: 40))
        menuMapTrafficImage.contentMode = UIViewContentMode.scaleAspectFit
        menuMapTrafficImage.clipsToBounds = true
        menuMapTrafficImage.image = UIImage(named: Constants.Strings.iconTraffic)
        menuMapTrafficContainer.addSubview(menuMapTrafficImage)
        menuMapTrafficIndicator = UIImageView(frame: CGRect(x: menuMapTrafficImage.frame.width + 10, y: 5, width: 25, height: 40))
        menuMapTrafficIndicator.contentMode = UIViewContentMode.scaleAspectFit
        menuMapTrafficIndicator.clipsToBounds = true
        menuMapTrafficIndicator.image = UIImage(named: Constants.Strings.iconCheckOrange)
        if Constants.Settings.menuMapTrafficToggle
        {
            menuMapTrafficContainer.addSubview(menuMapTrafficIndicator)
        }
        menuMapTrafficTapGesture = UITapGestureRecognizer(target: self, action: #selector(MapViewController.menuMapTrafficTap(_:)))
        menuMapTrafficTapGesture.numberOfTapsRequired = 1  // add single tap
        menuMapTrafficContainer.addGestureRecognizer(menuMapTrafficTapGesture)
        
        menuMapHydroContainer = UIView(frame: CGRect(x: 0, y: 50, width: menuView.frame.width, height: 50))
        menuView.addSubview(menuMapHydroContainer)
        menuMapHydroImage = UIImageView(frame: CGRect(x: 5, y: 5, width: 40, height: 40))
        menuMapHydroImage.contentMode = UIViewContentMode.scaleAspectFit
        menuMapHydroImage.clipsToBounds = true
        menuMapHydroImage.image = UIImage(named: Constants.Strings.markerIconGauge)
        menuMapHydroContainer.addSubview(menuMapHydroImage)
        menuMapHydroIndicator = UIImageView(frame: CGRect(x: menuMapTrafficImage.frame.width + 10, y: 5, width: 25, height: 40))
        menuMapHydroIndicator.contentMode = UIViewContentMode.scaleAspectFit
        menuMapHydroIndicator.clipsToBounds = true
        menuMapHydroIndicator.image = UIImage(named: Constants.Strings.iconCheckOrange)
        if Constants.Settings.menuMapHydroToggle
        {
            menuMapHydroContainer.addSubview(menuMapHydroIndicator)
        }
        menuMapHydroTapGesture = UITapGestureRecognizer(target: self, action: #selector(MapViewController.menuMapHydroTap(_:)))
        menuMapHydroTapGesture.numberOfTapsRequired = 1  // add single tap
        menuMapHydroContainer.addGestureRecognizer(menuMapHydroTapGesture)
        
        menuMapSpotContainer = UIView(frame: CGRect(x: 0, y: 100, width: menuView.frame.width, height: 50))
        menuView.addSubview(menuMapSpotContainer)
        menuMapSpotImage = UIImageView(frame: CGRect(x: 5, y: 5, width: 40, height: 40))
        menuMapSpotImage.contentMode = UIViewContentMode.scaleAspectFit
        menuMapSpotImage.clipsToBounds = true
        menuMapSpotImage.image = UIImage(named: Constants.Strings.markerIconCamera)
        menuMapSpotContainer.addSubview(menuMapSpotImage)
        menuMapSpotIndicator = UIImageView(frame: CGRect(x: menuMapTrafficImage.frame.width + 10, y: 5, width: 25, height: 40))
        menuMapSpotIndicator.contentMode = UIViewContentMode.scaleAspectFit
        menuMapSpotIndicator.clipsToBounds = true
        menuMapSpotIndicator.image = UIImage(named: Constants.Strings.iconCheckOrange)
        if Constants.Settings.menuMapSpotToggle
        {
            menuMapSpotContainer.addSubview(menuMapSpotIndicator)
        }
        menuMapSpotTapGesture = UITapGestureRecognizer(target: self, action: #selector(MapViewController.menuMapSpotTap(_:)))
        menuMapSpotTapGesture.numberOfTapsRequired = 1  // add single tap
        menuMapSpotContainer.addGestureRecognizer(menuMapSpotTapGesture)
        
        menuAboutContainer = UIView(frame: CGRect(x: 0, y: menuView.frame.height - 50, width: menuView.frame.width, height: 50))
        menuView.addSubview(menuAboutContainer)
        menuAboutLabel = UILabel(frame: CGRect(x: 5, y: 5, width: menuAboutContainer.frame.width - 10, height: 40))
        menuAboutLabel.font = UIFont(name: Constants.Strings.fontAltThink, size: 38)
        menuAboutLabel.textColor = Constants.Colors.colorOrange
        menuAboutLabel.textAlignment = .center
        menuAboutLabel.text = "?"
        menuAboutContainer.addSubview(menuAboutLabel)
        menuAboutTapGesture = UITapGestureRecognizer(target: self, action: #selector(MapViewController.menuAboutTap(_:)))
        menuAboutTapGesture.numberOfTapsRequired = 1  // add single tap
        menuAboutContainer.addGestureRecognizer(menuAboutTapGesture)
        
        // Add the map container to allow the map to be moved with all subviews
        mapContainer = UIView(frame: CGRect(x: 0, y: 0, width: viewContainer.frame.width, height: viewContainer.frame.height))
        mapContainer.backgroundColor = Constants.Colors.standardBackground
        mapContainer.layer.shadowOffset = CGSize(width: 0.2, height: 0.2)
        mapContainer.layer.shadowOpacity = 0.2
        mapContainer.layer.shadowRadius = 1.0
        viewContainer.addSubview(mapContainer)
        
        // Create a camera with the default location (if location services are used, this should not be shown for long)
        defaultCamera = GMSCameraPosition.camera(withLatitude: Constants.Settings.mapViewDefaultLat, longitude: Constants.Settings.mapViewDefaultLong, zoom: Constants.Settings.mapViewDefaultZoom)
        mapView = GMSMapView.map(withFrame: mapContainer.bounds, camera: defaultCamera)
        mapView.padding = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        mapView.delegate = self
//        mapView.mapType = kGMSTypeNormal
//        mapView.isIndoorEnabled = true
        mapView.isTrafficEnabled = true
        mapView.isBuildingsEnabled = true
        mapView.isMyLocationEnabled = true
        mapView.settings.myLocationButton = true
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
        
        // Load the additional view components
        refreshView = UIView(frame: CGRect(x: mapContainer.frame.width - 66, y: 10, width: 56, height: 56))
        refreshView.backgroundColor = Constants.Colors.standardBackground
        refreshView.layer.cornerRadius = 28
        refreshView.layer.shadowOffset = CGSize(width: 0, height: 0.6)
        refreshView.layer.shadowOpacity = 0.5
        refreshView.layer.shadowRadius = 1.0
        mapContainer.addSubview(refreshView)
        
        refreshViewImage = UILabel(frame: CGRect(x: 5, y: 5, width: refreshView.frame.width - 10, height: refreshView.frame.height - 10))
        refreshViewImage.backgroundColor = UIColor.clear
        refreshViewImage.text = "\u{21ba}"
        refreshViewImage.textAlignment = .center
        refreshViewImage.font = UIFont(name: "HelveticaNeue-UltraLight", size: 18)
        
        refreshViewSpinner = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: refreshView.frame.width, height: refreshView.frame.height))
        refreshViewSpinner.color = Constants.Colors.colorOrangeOpaque
        refreshView.addSubview(refreshViewSpinner)
        refreshViewSpinner.startAnimating()
        
        refreshViewTapGesture = UITapGestureRecognizer(target: self, action: #selector(MapViewController.refreshViewTap(_:)))
        refreshViewTapGesture.numberOfTapsRequired = 1  // add single tap
        refreshView.addGestureRecognizer(refreshViewTapGesture)
        
        addSpotRequestAddButton = UIView(frame: CGRect(x: mapContainer.frame.width - 66, y: mapContainer.frame.height - 264, width: 56, height: 56))
        addSpotRequestAddButton.backgroundColor = Constants.Colors.standardBackground
        addSpotRequestAddButton.layer.cornerRadius = 28
        addSpotRequestAddButton.layer.shadowOffset = CGSize(width: 0, height: 0.6)
        addSpotRequestAddButton.layer.shadowOpacity = 0.5
        addSpotRequestAddButton.layer.shadowRadius = 1.0
        
        addSpotRequestAddButtonSpinner = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: addSpotRequestAddButton.frame.width, height: addSpotRequestAddButton.frame.height))
        addSpotRequestAddButtonSpinner.color = Constants.Colors.colorYellow
        addSpotRequestAddButton.addSubview(addSpotRequestAddButtonSpinner)
        
        addSpotRequestAddButtonImage = UIImageView(frame: CGRect(x: 2, y: 7, width: 46, height: 46))
        addSpotRequestAddButtonImage.contentMode = UIViewContentMode.scaleAspectFit
        addSpotRequestAddButtonImage.clipsToBounds = true
        addSpotRequestAddButtonImage.image = UIImage(named: Constants.Strings.iconCheckYellow)
        addSpotRequestAddButton.addSubview(addSpotRequestAddButtonImage)
        
        addSpotRequestAddButtonTapGesture = UITapGestureRecognizer(target: self, action: #selector(MapViewController.uploadSpotRequestTap(_:)))
        addSpotRequestAddButtonTapGesture.numberOfTapsRequired = 1  // add single tap
        addSpotRequestAddButton.addGestureRecognizer(addSpotRequestAddButtonTapGesture)
        
        addSpotRequestButton = UIView(frame: CGRect(x: mapContainer.frame.width - 66, y: mapContainer.frame.height - 198, width: 56, height: 56))
        addSpotRequestButton.backgroundColor = Constants.Colors.standardBackground
        addSpotRequestButton.layer.cornerRadius = 28
        addSpotRequestButton.layer.shadowOffset = CGSize(width: 0, height: 0.6)
        addSpotRequestButton.layer.shadowOpacity = 0.5
        addSpotRequestButton.layer.shadowRadius = 1.0
        mapContainer.addSubview(addSpotRequestButton)
        
        addSpotRequestButtonImage = UIImageView(frame: CGRect(x: 5, y: 5, width: 46, height: 46))
        addSpotRequestButtonImage.contentMode = UIViewContentMode.scaleAspectFit
        addSpotRequestButtonImage.clipsToBounds = true
        addSpotRequestButtonImage.image = UIImage(named: Constants.Strings.markerIconCamera)
        addSpotRequestButton.addSubview(addSpotRequestButtonImage)
        
        addSpotRequestButtonTapGesture = UITapGestureRecognizer(target: self, action: #selector(MapViewController.addSpotRequestButtonTap(_:)))
        addSpotRequestButtonTapGesture.numberOfTapsRequired = 1  // add single tap
        addSpotRequestButton.addGestureRecognizer(addSpotRequestButtonTapGesture)
        
        addImageButton = UIView(frame: CGRect(x: mapContainer.frame.width - 66, y: mapContainer.frame.height - 132, width: 56, height: 56))
        addImageButton.backgroundColor = Constants.Colors.standardBackground
        addImageButton.layer.cornerRadius = 28
        addImageButton.layer.shadowOffset = CGSize(width: 0, height: 0.6)
        addImageButton.layer.shadowOpacity = 0.5
        addImageButton.layer.shadowRadius = 1.0
        mapContainer.addSubview(addImageButton)
        
        addImageButtonImage = UIImageView(frame: CGRect(x: 5, y: 5, width: 46, height: 46))
        addImageButtonImage.contentMode = UIViewContentMode.scaleAspectFit
        addImageButtonImage.clipsToBounds = true
        addImageButtonImage.image = UIImage(named: Constants.Strings.iconCamera)
        addImageButton.addSubview(addImageButtonImage)
        
        addImageButtonTapGesture = UITapGestureRecognizer(target: self, action: #selector(MapViewController.addImageButtonTap(_:)))
        addImageButtonTapGesture.numberOfTapsRequired = 1  // add single tap
        addImageButton.addGestureRecognizer(addImageButtonTapGesture)
        
        // Add the view to show marker data
        infoWindow = UIView(frame: CGRect(x: (mapContainer.frame.width / 2) - 140, y: 80, width: 280, height: 260))
        infoWindow.backgroundColor = Constants.Colors.standardBackground
        infoWindow.layer.cornerRadius = 5
        infoWindow.layer.shadowOffset = CGSize(width: 0, height: 0.6)
        infoWindow.layer.shadowOpacity = 0.5
        infoWindow.layer.shadowRadius = 1.0
        
//        infoWindowExit = UIView(frame: CGRect(x: infoWindow.frame.width - 50, y: 10, width: 40, height: 40))
//        infoWindowExit.layer.cornerRadius = 20
//        infoWindow.addSubview(infoWindowExit)
//        
//        infoWindowExitLabel = UILabel(frame: CGRect(x: 5, y: 5, width: 30, height: 30))
//        infoWindowExitLabel.backgroundColor = UIColor.clear
//        infoWindowExitLabel.text = "\u{274c}"
//        infoWindowExitLabel.textAlignment = .center
//        infoWindowExitLabel.font = UIFont(name: "HelveticaNeue-UltraLight", size: 18)
//        infoWindowExit.addSubview(infoWindowExitLabel)
//        
//        infoWindowExitTapGesture = UITapGestureRecognizer(target: self, action: #selector(MapViewController.infoWindowExitTap(_:)))
//        infoWindowExitTapGesture.numberOfTapsRequired = 1  // add single tap
//        infoWindowExit.addGestureRecognizer(infoWindowExitTapGesture)
        
        // Add info window fields to show data
        infoWindowTitle = UILabel(frame: CGRect(x: 10, y: 5, width: infoWindow.frame.width - 20, height: 60))
        infoWindowTitle.backgroundColor = Constants.Colors.standardBackground
        infoWindowTitle.textAlignment = .center
        infoWindowTitle.numberOfLines = 2
        infoWindowTitle.lineBreakMode = NSLineBreakMode.byWordWrapping
        infoWindowTitle.font = UIFont(name: "HelveticaNeue-Light", size: 18)
        infoWindowTitle.textColor = Constants.Colors.colorTextDark
        infoWindow.addSubview(infoWindowTitle)
        
        infoWindowObs = UILabel(frame: CGRect(x: 10, y: 80, width: infoWindow.frame.width - 20, height: 20))
        infoWindowObs.backgroundColor = UIColor.clear
        infoWindowObs.textAlignment = .left
        infoWindowObs.font = UIFont(name: "HelveticaNeue-Light", size: 16)
        infoWindowObs.textColor = Constants.Colors.colorTextDark
        infoWindow.addSubview(infoWindowObs)
        
        infoWindowObsTime = UILabel(frame: CGRect(x: 10, y: 105, width: infoWindow.frame.width - 20, height: 20))
        infoWindowObsTime.backgroundColor = UIColor.clear
        infoWindowObsTime.textAlignment = .left
        infoWindowObsTime.font = UIFont(name: "HelveticaNeue-Light", size: 16)
        infoWindowObsTime.textColor = Constants.Colors.colorTextDark
        infoWindow.addSubview(infoWindowObsTime)
        
        infoWindowProjHigh = UILabel(frame: CGRect(x: 10, y: 150, width: infoWindow.frame.width - 20, height: 20))
        infoWindowProjHigh.backgroundColor = UIColor.clear
        infoWindowProjHigh.textAlignment = .left
        infoWindowProjHigh.font = UIFont(name: "HelveticaNeue-Light", size: 16)
        infoWindowProjHigh.textColor = Constants.Colors.colorTextDark
        infoWindow.addSubview(infoWindowProjHigh)
        
        infoWindowProjHighTime = UILabel(frame: CGRect(x: 10, y: 175, width: infoWindow.frame.width - 20, height: 20))
        infoWindowProjHighTime.backgroundColor = UIColor.clear
        infoWindowProjHighTime.textAlignment = .left
        infoWindowProjHighTime.font = UIFont(name: "HelveticaNeue-Light", size: 16)
        infoWindowProjHighTime.textColor = Constants.Colors.colorTextDark
        infoWindow.addSubview(infoWindowProjHighTime)
        
        infoWindowLastUpdate = UILabel(frame: CGRect(x: 10, y: infoWindow.frame.height - 20, width: infoWindow.frame.width - 20, height: 15))
        infoWindowLastUpdate.backgroundColor = UIColor.clear
        infoWindowLastUpdate.textAlignment = .left
        infoWindowLastUpdate.font = UIFont(name: "HelveticaNeue-Light", size: 12)
        infoWindowLastUpdate.textColor = Constants.Colors.colorTextDark
        infoWindow.addSubview(infoWindowLastUpdate)
        
        refreshMapData()
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: GOOGLE MAPS DELEGATES
    func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D)
    {
//        print(coordinate)
        // Ensure the infoWindow and menu are hidden
        infoWindow.removeFromSuperview()
        if menuVisible
        {
            toggleMenu()
        }
        
        if addSpotRequestToggle
        {
            self.newSpotRequest = SpotRequest(userID: Constants.Data.currentUser.userID, datetime: Date(), lat: coordinate.latitude, lng: coordinate.longitude)
            
            // Remove the previous and add a marker at the tap coordinates
            if newSpotRequestMarker != nil
            {
                newSpotRequestMarker!.map = nil
            }
            // Custom Marker Icon
            let markerView = UIImageView(image: UIImage(named: Constants.Strings.markerIconCameraTemp))
            newSpotRequestMarker = GMSMarker()
            newSpotRequestMarker!.position = coordinate
            newSpotRequestMarker!.zIndex = 100
            newSpotRequestMarker!.iconView = markerView
            newSpotRequestMarker!.map = mapView
        }
        else
        {
            // Create an array to hold all Spots overlapping the tap point
            var tappedSpots = [Spot]()
            
            // Find all Spots that overlap the tapped point
            for tSpot in Constants.Data.allSpot
            {
//                print("MVC - TB - CHECKING SPOT: \(tSpot.spotID)")
                // Calculate the distance from the tap to the center of the Spot
                let tapFromSpotCenterDistance: Double! = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude).distance(from: CLLocation(latitude: tSpot.lat, longitude: tSpot.lng))
                
                if tapFromSpotCenterDistance <= tSpot.radius
                {
//                    print("MVC - TM - TAPPED SPOT: \(tSpot.spotID)")
                    tappedSpots.append(tSpot)
                }
            }
            
            // If a tapped Spot exists, move the camera to the first one and load the SpotVC (pass all tapped Spots)
            if tappedSpots.count > 0
            {
                // Center the map on the tapped Spot and load the image view controller
                let markerCoords = CLLocationCoordinate2DMake(tappedSpots[0].lat, tappedSpots[0].lng)
                mapCameraPositionAdjust(target: markerCoords)
                
                // Create a back button and title for the Nav Bar
                let backButtonItem = UIBarButtonItem(title: "\u{2190}",
                                                     style: UIBarButtonItemStyle.plain,
                                                     target: self,
                                                     action: #selector(MapViewController.popViewController(_:)))
                backButtonItem.tintColor = Constants.Colors.colorTextNavBar
                
                // Create a title for the view that shows the coordinates of the tapped spot
                let ncTitle = UIView(frame: CGRect(x: screenSize.width / 2 - 75, y: 10, width: 150, height: 40))
                let ncTitleText = UILabel(frame: CGRect(x: 0, y: 0, width: 150, height: 40))
                ncTitleText.text = String(Double(round(1000 * coordinate.latitude)/1000)) + ", " + String(Double(round(1000 * coordinate.longitude)/1000))
                
                ncTitleText.textColor = Constants.Colors.colorTextNavBar
                ncTitleText.font = UIFont(name: Constants.Strings.fontAlt, size: 14)
                ncTitleText.textAlignment = .center
                ncTitle.addSubview(ncTitleText)
                
                // Instantiate the SpotTableViewController and pass the Spot to the VC
                let spotTableVC = SpotTableViewController()
                for spot in tappedSpots
                {
                    spotTableVC.spotContent = spotTableVC.spotContent + spot.spotContent
                }
                
                // Assign the created Nav Bar settings to the Tab Bar Controller
                spotTableVC.navigationItem.setLeftBarButton(backButtonItem, animated: true)
                spotTableVC.navigationItem.titleView = ncTitle
                
//                print("MVC - NAV CONTROLLER: \(String(describing: self.navigationController))")
                if let navController = self.navigationController
                {
                    navController.pushViewController(spotTableVC, animated: true)
                }
            }
        }
    }
    
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool
    {
//        print("MVC - DID TAP: \(marker)")
        let markerData = marker.userData as? Any
        if let markerHydro = markerData as? DataHydro
        {
//            print(markerHydro.title)
            // Center the map on the tapped marker
            let markerCoords = CLLocationCoordinate2DMake(markerHydro.lat, markerHydro.lng)
            mapCameraPositionAdjust(target: markerCoords)
            
            // Add Hydro data to the info window and show
            // Format the datetime for latest data pulled
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM dd, YYYY HH:mm"
//            dateFormatter.dateFormat = "yyyy MMM EEEE HH:mm"
//            dateFormatter.timeZone = NSTimeZone(name: "UTC")
            let dateString = dateFormatter.string(from: markerHydro.datetime)
            
            // Format the title
            var markerTitle = "Hydrologic Alert"
            if let title = markerHydro.title
            {
                if let gaugeIdRange = title.range(of:markerHydro.gaugeID)
                {
                    // Adjust by two for the added "- " after the gauge id in the title
                    let index = title.index(gaugeIdRange.upperBound, offsetBy: 2)
                    markerTitle = title.substring(from: index)
                }
            }
            
            var markerObs = "N/A"
            if let obs = markerHydro.obs
            {
                markerObs = obs
                if let obsCat = markerHydro.obsCat
                {
                    if obsCat != "Not defined"
                    {
                        markerObs = obsCat + ": " + obs
                    }
                }
            }
            var markerHigh = "N/A"
            if let projHigh = markerHydro.projHigh
            {
                markerHigh = projHigh
                if let projHighCat = markerHydro.projHighCat
                {
                    if projHighCat != "Not defined"
                    {
                        markerHigh = projHighCat + ": " + projHigh
                    }
                }
            }
            
            infoWindowTitle.text = markerTitle
            infoWindowObs.text = "Last Observation: " + markerObs
            infoWindowObsTime.text = markerHydro.obsTime
            infoWindowProjHigh.text = "Projected High: " + markerHigh
            infoWindowProjHighTime.text = markerHydro.projHighTime
            infoWindowLastUpdate.text = "Last Updated: " + dateString
            mapContainer.addSubview(infoWindow)
        }
        else if let markerSpotRequest = markerData as? SpotRequest
        {
//            print(markerSpotRequest.requestID)
            // Center the map on the tapped marker
            let markerCoords = CLLocationCoordinate2DMake(markerSpotRequest.lat, markerSpotRequest.lng)
            mapCameraPositionAdjust(target: markerCoords)
            
            mapView.selectedMarker = marker
        }
        else if let markerSpot = markerData as? Spot
        {
//            print(markerSpot.spotID)
        }
        
        return true
    }
    
//    func mapView(_ mapView: GMSMapView, markerInfoWindow marker: GMSMarker) -> UIView?
//    {
//        print("MVC - INFO WINDOW: \(marker)")
//        return nil
//    }
    
    func mapView(_ mapView: GMSMapView, didTapInfoWindowOf marker: GMSMarker)
    {
//        print("MVC - INFO WINDOW TAP: \(marker)")
    }
    
    // Called before the map is moved
    func mapView(_ mapView: GMSMapView, willMove gesture: Bool)
    {
//        print("MVC - MAPVIEW WILL MOVE")
    }
    // Called while the map is moved
    func mapView(_ mapView: GMSMapView, didChange position: GMSCameraPosition)
    {
//        print("MVC - MAPVIEW CHANGING POSITION")
    }
    // Called after the map is moved
    func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition)
    {
//        print("MVC - MAPVIEW CHANGED POSITION - ZOOM: \(mapView.camera.zoom)")
        
        // Adjust the Map Camera back to apply the correct camera angle
        adjustMapViewCamera()
        
//        // Check the markers again since the zoom may have changed
//        processSpotMarkers()
    }
    
    
    // MARK: TAP GESTURES
    func menuMapTrafficTap(_ gesture: UITapGestureRecognizer)
    {
        if Constants.Settings.menuMapTrafficToggle
        {
            mapView.isTrafficEnabled = false
            menuMapTrafficIndicator.removeFromSuperview()
            Constants.Settings.menuMapTrafficToggle = false
        }
        else
        {
            mapView.isTrafficEnabled = true
            menuMapTrafficContainer.addSubview(menuMapTrafficIndicator)
            Constants.Settings.menuMapTrafficToggle = true
        }
    }
    func menuMapHydroTap(_ gesture: UITapGestureRecognizer)
    {
        if Constants.Settings.menuMapHydroToggle
        {
            removeHydroMapFeatures()
            menuMapHydroIndicator.removeFromSuperview()
            Constants.Settings.menuMapHydroToggle = false
        }
        else
        {
            addHydroMapFeatures()
            menuMapHydroContainer.addSubview(menuMapHydroIndicator)
            Constants.Settings.menuMapHydroToggle = true
        }
    }
    func menuMapSpotTap(_ gesture: UITapGestureRecognizer)
    {
        if Constants.Settings.menuMapSpotToggle
        {
            removeSpotMapFeatures()
            menuMapSpotIndicator.removeFromSuperview()
            Constants.Settings.menuMapSpotToggle = false
        }
        else
        {
            addSpotMapFeatures()
            menuMapSpotContainer.addSubview(menuMapSpotIndicator)
            Constants.Settings.menuMapSpotToggle = true
        }
    }
    func menuAboutTap(_ gesture: UITapGestureRecognizer)
    {
        // Create a back button and title for the Nav Bar
        let backButtonItem = UIBarButtonItem(title: "\u{2190}",
                                             style: UIBarButtonItemStyle.plain,
                                             target: self,
                                             action: #selector(MapViewController.popViewController(_:)))
        backButtonItem.tintColor = Constants.Colors.colorTextNavBar
        
        // Create a title for the view that shows the coordinates of the tapped spot
        let ncTitle = UIView(frame: CGRect(x: screenSize.width / 2 - 75, y: 10, width: 150, height: 40))
        let ncTitleText = UILabel(frame: CGRect(x: 0, y: 0, width: 150, height: 40))
        ncTitleText.text = "ABOUT"
        
        ncTitleText.textColor = Constants.Colors.colorTextNavBar
        ncTitleText.font = UIFont(name: Constants.Strings.fontAlt, size: 22)
        ncTitleText.textAlignment = .center
        ncTitle.addSubview(ncTitleText)
        
        // Instantiate the SpotTableViewController and add the nav bar settings
        let aboutVC = AboutViewController()
        aboutVC.navigationItem.setLeftBarButton(backButtonItem, animated: true)
        aboutVC.navigationItem.titleView = ncTitle
        if let navController = self.navigationController
        {
            navController.pushViewController(aboutVC, animated: true)
        }
        
        // Close the menu
        toggleMenu()
    }
    func refreshViewTap(_ gesture: UITapGestureRecognizer)
    {
        refreshMapData()
    }
    
    func addSpotRequestButtonTap(_ gesture: UITapGestureRecognizer)
    {
        spotRequestToggle()
    }
    
    func addImageButtonTap(_ gesture: UITapGestureRecognizer)
    {
        // Load the CameraVC
        let cameraVC = CameraViewController()
        self.navigationController!.pushViewController(cameraVC, animated: true)
//        self.present(cameraVC, animated: true, completion: nil)
    }
    
    func infoWindowExitTap(_ gesture: UITapGestureRecognizer)
    {
        // Hide the infoWindow
        infoWindow.removeFromSuperview()
    }
    
    func uploadSpotRequestTap(_ gesture: UITapGestureRecognizer)
    {
        // Hide the check mark and show the spinner
        addSpotRequestAddButtonImage.removeFromSuperview()
        addSpotRequestAddButtonSpinner.startAnimating()
        
        // Request a randomID for the SpotRequest before upload
        AWSPrepRequest(requestToCall: AWSGetRandomID(randomIdType: Constants.randomIdType.random_spot_id), delegate: self as AWSRequestDelegate).prepRequest()
    }
    
    
    // MARK: DELEGATE METHODS
    
    func refreshMapData()
    {
        // Reload all data - Show the loading indicator
        self.refreshViewImage.removeFromSuperview()
        self.refreshViewSpinner.startAnimating()
        
//        print("MVC - REQUESTING MAP DATA")
        AWSPrepRequest(requestToCall: AWSGetMapData(userLocation: nil), delegate: self as AWSRequestDelegate).prepRequest()
    }
    
    
    // MARK: CUSTOM METHODS
    
    func mapCameraPositionAdjust(target: CLLocationCoordinate2D)
    {
//        let newCamera = GMSCameraPosition(target: target, zoom: mapView.camera.zoom, bearing: mapView.camera.bearing, viewingAngle: mapView.camera.viewingAngle)
//        mapView.camera = newCamera
        let cameraUpdate = GMSCameraUpdate.setTarget(target)
        mapView.animate(with: cameraUpdate)
    }
    
    // Adjust the Map Camera settings to allow or disallow angling the camera view
    // If not in the add blob process, angle the map automatically if the zoom is high enough
    func adjustMapViewCamera()
    {
//        print("MVC - ADJUSTING MAP CAMERA")
//        
//        print("MVC - MAP CAMERA CURRENT VEWING ANGLE: \(mapView.camera.viewingAngle)")
//        print("MVC - MAP CAMERA DESIRED VEWING ANGLE: \(Constants.Settings.mapViewAngledDegrees)")
        // If the map zoom is 16 or higher, automatically angle the camera
        // NOTE: Still firing, even if the view angles are the same - made adjustment by -1 to compensate
        if mapView.camera.zoom >= Constants.Settings.mapViewAngledZoom && mapView.camera.viewingAngle < Constants.Settings.mapViewAngledDegrees - 1
        {
//            print("MVC - ADJUSTING MAP CAMERA - CHECK 2a")
            mapView.animate(toViewingAngle: Constants.Settings.mapViewAngledDegrees)
        }
        else if mapView.camera.zoom < Constants.Settings.mapViewAngledZoom && mapView.camera.viewingAngle > 0
        {
//            print("MVC - ADJUSTING MAP CAMERA - CHECK 2b")
            // Keep the map from being angled if the zoom is too low
            mapView.animate(toViewingAngle: Double(0))
        }
//        print("MVC - ADJUSTED MAP CAMERA")
    }
    
    // Add markers for Spots on the map if the zoom is high enough
    func processSpotMarkers()
    {
        // Nullify all current markers
        for marker in Constants.Data.spotMarkers
        {
            marker.map = nil
        }
        Constants.Data.spotMarkers = [GMSMarker]()
        
        // Ensure that the zoom is low enough (far enough away), and add the markers
        if mapView.camera.zoom < Constants.Settings.mapViewAngledZoom
        {
            for spot in Constants.Data.allSpot
            {
                addSpotMarker(spot)
            }
        }
        // NOT SURE WHAT THIS WAS ABOUT
//        else if Constants.Data.spotMarkers.count < 1
//        {
//            // Nullify all current markers
//            for marker in Constants.Data.spotMarkers
//            {
//                marker.map = nil
//            }
//            Constants.Data.spotMarkers = [GMSMarker]()
//            
//            for spot in Constants.Data.allSpot
//            {
//                addSpotMarker(spot)
//            }
//        }
    }
    func addSpotMarker(_ spot: Spot)
    {
        let dotDiameter: CGFloat = Constants.Dim.dotRadius * 2
        let dot = UIImage(color: Constants.Colors.colorOrangeOpaque, size: CGSize(width: dotDiameter, height: dotDiameter))
        let markerView = UIImageView(image: dot)
        markerView.layer.cornerRadius = markerView.frame.height / 2
        markerView.contentMode = UIViewContentMode.scaleAspectFill
        markerView.clipsToBounds = true
        
        let position = CLLocationCoordinate2DMake(spot.lat, spot.lng)
        let marker = GMSMarker(position: position)
        marker.groundAnchor = CGPoint(x: 0.5, y: 0.5)
        marker.zIndex = Constants.Settings.mapMarkerSpot
        marker.iconView = markerView
        marker.tracksViewChanges = false
        marker.map = mapView
        Constants.Data.spotMarkers.append(marker)
    }
    
    func spotRequestToggle()
    {
        if addSpotRequestToggle
        {
            addSpotRequestToggle = false
            addSpotRequestButtonImage.image = UIImage(named: Constants.Strings.markerIconCamera)
            addSpotRequestAddButton.removeFromSuperview()
            
            // Remove the SpotRequest temporary marker
            if self.newSpotRequestMarker != nil
            {
                self.newSpotRequestMarker!.map = nil
            }
        }
        else
        {
            addSpotRequestToggle = true
            addSpotRequestButtonImage.image = UIImage(named: Constants.Strings.iconCloseYellow)
            mapContainer.addSubview(addSpotRequestAddButton)
        }
    }
    
    // Update the SpotRequests on the map
    func spotRequestUpdate()
    {
        // Remove all the current spotRequests from the map
        for marker in Constants.Data.spotRequestMarkers
        {
            marker.map = nil
        }
        Constants.Data.spotRequestMarkers = [GMSMarker]()
        
        // Add the current requests
        for spotRequest in Constants.Data.allSpotRequest
        {
            if spotRequest.status == "active"
            {
                // Custom Marker Icon
                let markerView = UIImageView(image: UIImage(named: Constants.Strings.markerIconCamera))
                
                // Creates a marker at the Spot Request location
                let marker = GMSMarker()
                marker.position = CLLocationCoordinate2DMake(spotRequest.lat, spotRequest.lng)
                marker.zIndex = Constants.Settings.mapMarkerSpotRequest
                marker.userData = spotRequest
                marker.snippet = "Photo Requested"
                marker.iconView = markerView
//                marker.icon = GMSMarker.markerImage(with: .black)
                marker.map = self.mapView
                Constants.Data.spotRequestMarkers.append(marker)
            }
        }
    }
    
    
    // MARK: NAVIGATION / BAR BUTTON METHODS
    
    // Dismiss the latest View Controller presented from this VC
    // This version is used when the top VC is popped from a Nav Bar button
    func popViewController(_ sender: UIBarButtonItem)
    {
        self.navigationController!.popViewController(animated: true)
    }
    
    // Dismiss the latest View Controller presented from this VC
    func popViewController()
    {
        self.navigationController!.popViewController(animated: true)
    }
    func loadProfileVC(_ sender: UIBarButtonItem)
    {
        // Load the LoginVC
        let loginVC = LoginViewController()
        self.navigationController!.pushViewController(loginVC, animated: true)
    }
    func loadProfileVC()
    {
        // Load the LoginVC
        let loginVC = LoginViewController()
        self.navigationController!.pushViewController(loginVC, animated: true)
    }
    
    func toggleMenu(_ sender: UIBarButtonItem)
    {
        toggleMenuAction()
    }
    func toggleMenu()
    {
        toggleMenuAction()
    }
    func toggleMenuAction()
    {
//        print("MVC - TOGGLE MENU")
        if menuVisible
        {
            // Hide the menu
            UIView.animate(withDuration: 0.5, animations:
                {
                    self.mapContainer.frame = CGRect(x: 0, y: 0, width: self.viewContainer.frame.width, height: self.viewContainer.frame.height)
            }, completion:
                {
                    (value: Bool) in
                    self.menuVisible = false
            })
        }
        else
        {
            // Move the mapContainer to reveal the menu
            UIView.animate(withDuration: 0.5, animations:
                {
                    self.mapContainer.frame = CGRect(x: self.menuWidth, y: 0, width: self.viewContainer.frame.width, height: self.viewContainer.frame.height)
            }, completion:
                {
                    (value: Bool) in
                    self.menuVisible = true
            })
        }
    }
    
    
    // MARK: DATA METHODS
    func removeSpotMapFeatures()
    {
        for circle in Constants.Data.spotCircles
        {
            circle.map = nil
        }
        Constants.Data.spotCircles = [GMSCircle]()
        for marker in Constants.Data.spotMarkers
        {
            marker.map = nil
        }
        Constants.Data.spotMarkers = [GMSMarker]()
        for marker in Constants.Data.spotRequestMarkers
        {
            marker.map = nil
        }
        Constants.Data.spotRequestMarkers = [GMSMarker]()
    }
    func removeHydroMapFeatures()
    {
        for marker in Constants.Data.hydroMarkers
        {
            marker.map = nil
        }
        Constants.Data.hydroMarkers = [GMSMarker]()
    }
    
    func addSpotMapFeatures()
    {
        for spot in Constants.Data.allSpot
        {
            print(spot.spotID)
            // Creates a circle at the Spot location
            
            let circle = GMSCircle()
            circle.position = CLLocationCoordinate2DMake(spot.lat, spot.lng)
            circle.radius = Constants.Dim.spotRadius
            circle.zIndex = Constants.Settings.mapMarkerSpot
            circle.fillColor = Constants.Colors.colorOrange
            circle.strokeColor = Constants.Colors.colorOrange
            circle.strokeWidth = 1
            circle.map = self.mapView
            Constants.Data.spotCircles.append(circle)
            
            self.addSpotMarker(spot)
        }
        for spotRequest in Constants.Data.allSpotRequest
        {
//            print(spotRequest.requestID)
            // Custom Marker Icon
            let markerView = UIImageView(image: UIImage(named: Constants.Strings.markerIconCamera))
            
            // Creates a marker at the Spot Request location
            let marker = GMSMarker()
            marker.position = CLLocationCoordinate2DMake(spotRequest.lat, spotRequest.lng)
            marker.zIndex = Constants.Settings.mapMarkerSpotRequest
            marker.userData = spotRequest
            marker.snippet = "Photo Requested"
            marker.iconView = markerView
//            marker.icon = GMSMarker.markerImage(with: .red)
            marker.map = self.mapView
            Constants.Data.spotRequestMarkers.append(marker)
        }
    }
    func addHydroMapFeatures()
    {
//        print("MVC - HYDRO DATA:")
        for hydro in Constants.Data.allHydro
        {
//            print(hydro.gaugeID)
            // Custom Marker Icon
            let markerView = UIImageView(image: UIImage(named: Constants.Strings.markerIconGauge))
//            markerView.tintColor = UIColor.red
            
            // Creates a marker at the Hydro location
            let marker = GMSMarker()
            marker.position = CLLocationCoordinate2DMake(hydro.lat, hydro.lng)
            marker.zIndex = Constants.Settings.mapMarkerHydro
            marker.userData = hydro
//            marker.iconView = markerView
//            marker.icon = GMSMarker.markerImage(with: .blue)
            marker.icon = UIImage(named: Constants.Strings.markerIconGauge)
            marker.map = self.mapView
            Constants.Data.hydroMarkers.append(marker)
        }
    }
    
    
    // MARK: AWS DELEGATE METHODS
    
    func showLoginScreen()
    {
//        print("MVC - SHOW LOGIN SCREEN")
        loadProfileVC()
    }
    
    func processAwsReturn(_ objectType: AWSRequestObject, success: Bool)
    {
//        print("MVC - processAwsReturn:")
        print(objectType)
        print(success)
        DispatchQueue.main.async(execute:
            {
                // Process the return data based on the method used
                switch objectType
                {
                case _ as AWSGetMapData:
                    if success
                    {
                        // Before populating the map, delete all markers
                        self.removeSpotMapFeatures()
                        self.removeHydroMapFeatures()
                        
                        // Now populate the map, if settings are true
                        if Constants.Settings.menuMapSpotToggle
                        {
                            self.addSpotMapFeatures()
                        }
                        if Constants.Settings.menuMapHydroToggle
                        {
                            self.addHydroMapFeatures()
                        }
                        
                        // All the data has been loaded - Hide the loading indicator
                        self.refreshViewSpinner.stopAnimating()
                        self.refreshView.addSubview(self.refreshViewImage)
                    }
                    else
                    {
                        // Show the error message
                        let alert = UtilityFunctions().createAlertOkView("Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
                        alert.show()
                    }
                case let awsGetRandomID as AWSGetRandomID:
                    if success
                    {
                        // The randomID is only requested for uploading a new SpotRequest, so upload the SpotRequest when the randomID is received
//                        print("MVC - AWSGetRandomID: \(String(describing: awsGetRandomID.randomID))")
                        if let spotRequest = self.newSpotRequest
                        {
                            spotRequest.requestID = awsGetRandomID.randomID
                            
                            // Upload the SpotRequest
                            AWSPrepRequest(requestToCall: AWSPutSpotRequestData(spotRequest: spotRequest), delegate: self as AWSRequestDelegate).prepRequest()
                        }
                    }
                    else
                    {
                        // Show the error message
                        let alert = UtilityFunctions().createAlertOkView("Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
                        alert.show()
                    }
                case _ as AWSPutSpotRequestData:
                    if success
                    {
                        // The SpotRequest was already added to the global array in AWSClasses
//                        print("CVC - AWSPutSpotRequestData SUCCESS")
                        
                        // Remove the SpotRequest temporary marker
                        if self.newSpotRequestMarker != nil
                        {
                            self.newSpotRequestMarker!.map = nil
                        }
                        
                        // Update the SpotRequests
                        self.spotRequestUpdate()
                        
                        // Reset the view controllers involved
                        self.spotRequestToggle()
                        
                        // Show the check mark and hide the spinner
                        self.addSpotRequestAddButton.addSubview(self.addSpotRequestAddButtonImage)
                        self.addSpotRequestAddButtonSpinner.stopAnimating()
                    }
                    else
                    {
                        // Show the error message
                        let alert = UtilityFunctions().createAlertOkView("Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
                        alert.show()
                    }
                default:
//                    print("MVC-DEFAULT: THERE WAS AN ISSUE WITH THE DATA RETURNED FROM AWS")
                    
                    // Show the error message
                    let alert = UtilityFunctions().createAlertOkView("Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
                    alert.show()
                }
        })
    }
}

