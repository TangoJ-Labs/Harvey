//
//  ViewController.swift
//  Harvey
//
//  Created by Sean Hart on 8/28/17.
//  Copyright © 2017 tangojlabs. All rights reserved.
//

import CoreData
import FBSDKLoginKit
import GoogleMaps
import MobileCoreServices
import UIKit

class MapViewController: UIViewController, GMSMapViewDelegate, XMLParserDelegate, CameraViewControllerDelegate, InfoWindowDelegate, AWSRequestDelegate, HoleViewDelegate
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
    var menuMapSpotContainer: UIView!
    var menuMapSpotImage: UIImageView!
    var menuMapSpotIndicator: UIImageView!
    var menuMapSpotTapGesture: UITapGestureRecognizer!
    var menuMapHydroContainer: UIView!
    var menuMapHydroImage: UIImageView!
    var menuMapHydroIndicator: UIImageView!
    var menuMapHydroTapGesture: UITapGestureRecognizer!
    var menuMapShelterContainer: UIView!
    var menuMapShelterImage: UIImageView!
    var menuMapShelterIndicator: UIImageView!
    var menuMapShelterTapGesture: UITapGestureRecognizer!
    var menuMapHazardContainer: UIView!
    var menuMapHazardImage: UIImageView!
    var menuMapHazardIndicator: UIImageView!
    var menuMapHazardTapGesture: UITapGestureRecognizer!
    var menuTimeContainer: UIView!
    var menuTimeDayIndicator: UIImageView!
    var menuTimeWeekIndicator: UIImageView!
    var menuTimeMonthIndicator: UIImageView!
    var menuTimeYearIndicator: UIImageView!
    var menuAboutContainer: UIView!
    var menuAboutLabel: UILabel!
    var menuAboutTapGesture: UITapGestureRecognizer!
    
    var mapContainer: UIView!
    var mapView: GMSMapView!
    
    var refreshView: UIView!
    var refreshViewImage: UILabel!
    var refreshViewSpinner: UIActivityIndicatorView!
    var refreshViewTapGesture: UITapGestureRecognizer!
    
    var addHazardButton: UIView!
    var addHazardButtonImage: UIImageView!
    var addHazardButtonSpinner: UIActivityIndicatorView!
    var addHazardButtonTapGesture: UITapGestureRecognizer!
    var addSpotRequestButton: UIView!
    var addSpotRequestButtonImage: UIImageView!
    var addSpotRequestButtonSpinner: UIActivityIndicatorView!
    var addSpotRequestButtonTapGesture: UITapGestureRecognizer!
    var addPinContainer: UIView!
    var addPinButton: UIView!
    var addPinButtonImage: UIImageView!
    var addPinButtonTapGesture: UITapGestureRecognizer!
    var addImageButton: UIView!
    var addImageButtonImage: UIImageView!
    var addImageButtonTapGesture: UITapGestureRecognizer!
    
    var infoWindowAgreement: InfoWindowAgreement!
    var infoWindowHydro: InfoWindowHydro!
    var infoWindowShelter: InfoWindowShelter!
    
    
    // Data Variables
    var addHazardActive: Bool = false
    var newHazardPrepInProgress: Bool = false
    var newHazard: Hazard?
    var newHazardMarker: GMSMarker?
    
    var addSpotRequestActive: Bool = false
    var newSpotRequestPrepInProgress: Bool = false
    var newSpotRequest: SpotRequest?
    var newSpotRequestMarker: GMSMarker?
    
    // The Google Maps Coordinate Object for the current center of the map and the default Camera
//    var mapCenter: CLLocationCoordinate2D!
    var defaultCamera: GMSCameraPosition!
    
    let menuWidth: CGFloat = 80
    var menuVisible: Bool = false
    var pinContainerVisible: Bool = false
    var spotMarkersVisible: Bool = false //Start this off false since the 'toggle' will be called to add features
    var initialDataRequest: Bool = false //Record whether the initial data request has occured - request does not happen until the user's location is determined
    
    // Record whether a data download is in progress
    var downloadingSpot: Bool = false
    var downloadingHydro: Bool = false
    var downloadingShelter: Bool = false
    var downloadingHazard: Bool = false
    
    // Check whether the user needs to agree to the terms again - default is that they need to see it unless specified otherwise
    var showAgreement: Bool = true
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        prepVcLayout()
        
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
        ncTitleText.text = "HARVEYTOWN"
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
        menuMapTrafficTapGesture = UITapGestureRecognizer(target: self, action: #selector(MapViewController.menuMapTrafficTap(_:)))
        menuMapTrafficTapGesture.numberOfTapsRequired = 1  // add single tap
        menuMapTrafficContainer.addGestureRecognizer(menuMapTrafficTapGesture)
        
        menuMapSpotContainer = UIView(frame: CGRect(x: 0, y: 50, width: menuView.frame.width, height: 50))
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
        menuMapSpotTapGesture = UITapGestureRecognizer(target: self, action: #selector(MapViewController.menuMapSpotTap(_:)))
        menuMapSpotTapGesture.numberOfTapsRequired = 1  // add single tap
        menuMapSpotContainer.addGestureRecognizer(menuMapSpotTapGesture)
        
        menuMapHazardContainer = UIView(frame: CGRect(x: 0, y: 100, width: menuView.frame.width, height: 50))
        menuView.addSubview(menuMapHazardContainer)
        menuMapHazardImage = UIImageView(frame: CGRect(x: 5, y: 5, width: 40, height: 40))
        menuMapHazardImage.contentMode = UIViewContentMode.scaleAspectFit
        menuMapHazardImage.clipsToBounds = true
        menuMapHazardImage.image = UIImage(named: Constants.Strings.iconHazard)
        menuMapHazardContainer.addSubview(menuMapHazardImage)
        menuMapHazardIndicator = UIImageView(frame: CGRect(x: menuMapTrafficImage.frame.width + 10, y: 5, width: 25, height: 40))
        menuMapHazardIndicator.contentMode = UIViewContentMode.scaleAspectFit
        menuMapHazardIndicator.clipsToBounds = true
        menuMapHazardIndicator.image = UIImage(named: Constants.Strings.iconCheckOrange)
        menuMapHazardTapGesture = UITapGestureRecognizer(target: self, action: #selector(MapViewController.menuMapHazardTap(_:)))
        menuMapHazardTapGesture.numberOfTapsRequired = 1  // add single tap
        menuMapHazardContainer.addGestureRecognizer(menuMapHazardTapGesture)
        
        menuMapShelterContainer = UIView(frame: CGRect(x: 0, y: 150, width: menuView.frame.width, height: 50))
        menuView.addSubview(menuMapShelterContainer)
        menuMapShelterImage = UIImageView(frame: CGRect(x: 5, y: 5, width: 40, height: 40))
        menuMapShelterImage.contentMode = UIViewContentMode.scaleAspectFit
        menuMapShelterImage.clipsToBounds = true
        menuMapShelterImage.image = UIImage(named: Constants.Strings.markerIconShelter)
        menuMapShelterContainer.addSubview(menuMapShelterImage)
        menuMapShelterIndicator = UIImageView(frame: CGRect(x: menuMapTrafficImage.frame.width + 10, y: 5, width: 25, height: 40))
        menuMapShelterIndicator.contentMode = UIViewContentMode.scaleAspectFit
        menuMapShelterIndicator.clipsToBounds = true
        menuMapShelterIndicator.image = UIImage(named: Constants.Strings.iconCheckOrange)
        menuMapShelterTapGesture = UITapGestureRecognizer(target: self, action: #selector(MapViewController.menuMapShelterTap(_:)))
        menuMapShelterTapGesture.numberOfTapsRequired = 1  // add single tap
        menuMapShelterContainer.addGestureRecognizer(menuMapShelterTapGesture)
        
        menuMapHydroContainer = UIView(frame: CGRect(x: 0, y: 200, width: menuView.frame.width, height: 50))
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
        menuMapHydroTapGesture = UITapGestureRecognizer(target: self, action: #selector(MapViewController.menuMapHydroTap(_:)))
        menuMapHydroTapGesture.numberOfTapsRequired = 1  // add single tap
        menuMapHydroContainer.addGestureRecognizer(menuMapHydroTapGesture)
        
        // The time selections for the map spots
        menuTimeContainer = UIView(frame: CGRect(x: 0, y: menuView.frame.height - 250, width: menuWidth, height: 200))
        menuView.addSubview(menuTimeContainer)
        let border1 = CALayer()
        border1.frame = CGRect(x: 5, y: 25, width: 2, height: 150)
        border1.backgroundColor = Constants.Colors.standardBackgroundGray.cgColor
        menuTimeContainer.layer.addSublayer(border1)
        let menuTimeDot1 = UIView(frame: CGRect(x: 3, y: 22, width: 6, height: 6))
        menuTimeDot1.layer.cornerRadius = 3
        menuTimeDot1.backgroundColor = Constants.Colors.standardBackgroundGray
        menuTimeContainer.addSubview(menuTimeDot1)
        let menuTimeDot2 = UIView(frame: CGRect(x: 3, y: 72, width: 6, height: 6))
        menuTimeDot2.layer.cornerRadius = 3
        menuTimeDot2.backgroundColor = Constants.Colors.standardBackgroundGray
        menuTimeContainer.addSubview(menuTimeDot2)
        let menuTimeDot3 = UIView(frame: CGRect(x: 3, y: 122, width: 6, height: 6))
        menuTimeDot3.layer.cornerRadius = 3
        menuTimeDot3.backgroundColor = Constants.Colors.standardBackgroundGray
        menuTimeContainer.addSubview(menuTimeDot3)
        let menuTimeDot4 = UIView(frame: CGRect(x: 3, y: 172, width: 6, height: 6))
        menuTimeDot4.layer.cornerRadius = 3
        menuTimeDot4.backgroundColor = Constants.Colors.standardBackgroundGray
        menuTimeContainer.addSubview(menuTimeDot4)
        
        menuTimeDayIndicator = UIImageView(frame: CGRect(x: 15, y: 0, width: menuWidth - 20, height: 20))
        menuTimeDayIndicator.contentMode = UIViewContentMode.scaleAspectFit
        menuTimeDayIndicator.clipsToBounds = true
        menuTimeDayIndicator.image = UIImage(named: Constants.Strings.iconCheckOrange)
        let menuTimeLabelDay = UILabel(frame: CGRect(x: 15, y: 0, width: menuWidth - 20, height: 50))
        menuTimeLabelDay.isUserInteractionEnabled = true
        menuTimeLabelDay.font = UIFont(name: Constants.Strings.fontAlt, size: 12)
        menuTimeLabelDay.textColor = Constants.Colors.standardBackgroundGray
        menuTimeLabelDay.textAlignment = .left
        menuTimeLabelDay.text = "Past Day"
        menuTimeContainer.addSubview(menuTimeLabelDay)
        let menuTimeDayTapGesture = UITapGestureRecognizer(target: self, action: #selector(MapViewController.menuTimeDayTap(_:)))
        menuTimeDayTapGesture.numberOfTapsRequired = 1  // add single tap
        menuTimeLabelDay.addGestureRecognizer(menuTimeDayTapGesture)
        menuTimeWeekIndicator = UIImageView(frame: CGRect(x: 15, y: 50, width: menuWidth - 20, height: 20))
        menuTimeWeekIndicator.contentMode = UIViewContentMode.scaleAspectFit
        menuTimeWeekIndicator.clipsToBounds = true
        menuTimeWeekIndicator.image = UIImage(named: Constants.Strings.iconCheckOrange)
        let menuTimeLabelWeek = UILabel(frame: CGRect(x: 15, y: 50, width: menuWidth - 20, height: 50))
        menuTimeLabelWeek.isUserInteractionEnabled = true
        menuTimeLabelWeek.font = UIFont(name: Constants.Strings.fontAlt, size: 12)
        menuTimeLabelWeek.textColor = Constants.Colors.standardBackgroundGray
        menuTimeLabelWeek.textAlignment = .left
        menuTimeLabelWeek.text = "Past Week"
        menuTimeContainer.addSubview(menuTimeLabelWeek)
        let menuTimeWeekTapGesture = UITapGestureRecognizer(target: self, action: #selector(MapViewController.menuTimeWeekTap(_:)))
        menuTimeWeekTapGesture.numberOfTapsRequired = 1  // add single tap
        menuTimeLabelWeek.addGestureRecognizer(menuTimeWeekTapGesture)
        menuTimeMonthIndicator = UIImageView(frame: CGRect(x: 15, y: 100, width: menuWidth - 20, height: 20))
        menuTimeMonthIndicator.contentMode = UIViewContentMode.scaleAspectFit
        menuTimeMonthIndicator.clipsToBounds = true
        menuTimeMonthIndicator.image = UIImage(named: Constants.Strings.iconCheckOrange)
        let menuTimeLabelMonth = UILabel(frame: CGRect(x: 15, y: 100, width: menuWidth - 20, height: 50))
        menuTimeLabelMonth.isUserInteractionEnabled = true
        menuTimeLabelMonth.font = UIFont(name: Constants.Strings.fontAlt, size: 12)
        menuTimeLabelMonth.textColor = Constants.Colors.standardBackgroundGray
        menuTimeLabelMonth.textAlignment = .left
        menuTimeLabelMonth.text = "Past Month"
        menuTimeContainer.addSubview(menuTimeLabelMonth)
        let menuTimeMonthTapGesture = UITapGestureRecognizer(target: self, action: #selector(MapViewController.menuTimeMonthTap(_:)))
        menuTimeMonthTapGesture.numberOfTapsRequired = 1  // add single tap
        menuTimeLabelMonth.addGestureRecognizer(menuTimeMonthTapGesture)
        menuTimeYearIndicator = UIImageView(frame: CGRect(x: 15, y: 150, width: menuWidth - 20, height: 20))
        menuTimeYearIndicator.contentMode = UIViewContentMode.scaleAspectFit
        menuTimeYearIndicator.clipsToBounds = true
        menuTimeYearIndicator.image = UIImage(named: Constants.Strings.iconCheckOrange)
        let menuTimeLabelYear = UILabel(frame: CGRect(x: 15, y: 150, width: menuWidth - 20, height: 50))
        menuTimeLabelYear.isUserInteractionEnabled = true
        menuTimeLabelYear.font = UIFont(name: Constants.Strings.fontAlt, size: 12)
        menuTimeLabelYear.textColor = Constants.Colors.standardBackgroundGray
        menuTimeLabelYear.textAlignment = .left
        menuTimeLabelYear.text = "Past Year"
        menuTimeContainer.addSubview(menuTimeLabelYear)
        let menuTimeYearTapGesture = UITapGestureRecognizer(target: self, action: #selector(MapViewController.menuTimeYearTap(_:)))
        menuTimeYearTapGesture.numberOfTapsRequired = 1  // add single tap
        menuTimeLabelYear.addGestureRecognizer(menuTimeYearTapGesture)
        
        // The about button at the bottom of the menu
        menuAboutContainer = UIView(frame: CGRect(x: 0, y: menuView.frame.height - 50, width: menuWidth, height: 50))
        menuView.addSubview(menuAboutContainer)
        menuAboutLabel = UILabel(frame: CGRect(x: 5, y: 5, width: menuAboutContainer.frame.width - 10, height: 40))
        menuAboutLabel.font = UIFont(name: Constants.Strings.fontAltThick, size: 38)
        menuAboutLabel.textColor = Constants.Colors.colorGrayLight
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
        mapView.isBuildingsEnabled = true
        mapView.isMyLocationEnabled = true
        mapView.settings.myLocationButton = true
        mapView.addObserver(self, forKeyPath: "myLocation", options: NSKeyValueObservingOptions.new, context: nil)
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
        
        // PIN CONTAINER
        
        addPinContainer = UIView(frame: CGRect(x: mapContainer.frame.width - 66, y: mapContainer.frame.height - 198, width: 56, height: 56))
        addPinContainer.backgroundColor = Constants.Colors.standardBackground
        addPinContainer.layer.cornerRadius = 28
        addPinContainer.layer.shadowOffset = CGSize(width: 0, height: 0.6)
        addPinContainer.layer.shadowOpacity = 0.5
        addPinContainer.layer.shadowRadius = 1.0
        mapContainer.addSubview(addPinContainer)
        
        // PIN CONTAINER
        // HAZARD BUTTON
        
        addHazardButton = UIView(frame: CGRect(x: mapContainer.frame.width - 66, y: mapContainer.frame.height - 198, width: 56, height: 56))
        addHazardButton.backgroundColor = UIColor.clear
        addHazardButton.layer.cornerRadius = 28
        mapContainer.addSubview(addHazardButton)
        
        addHazardButtonImage = UIImageView(frame: CGRect(x: 5, y: 5, width: 46, height: 46))
        addHazardButtonImage.contentMode = UIViewContentMode.scaleAspectFit
        addHazardButtonImage.clipsToBounds = true
        addHazardButtonImage.image = UIImage(named: Constants.Strings.iconHazard)
        addHazardButton.addSubview(addHazardButtonImage)
        
        addHazardButtonSpinner = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: addHazardButton.frame.width, height: addHazardButton.frame.height))
        addHazardButtonSpinner.color = Constants.Colors.colorRed
        addHazardButton.addSubview(addHazardButtonSpinner)
        
        addHazardButtonTapGesture = UITapGestureRecognizer(target: self, action: #selector(MapViewController.addHazardButtonTap(_:)))
        addHazardButtonTapGesture.numberOfTapsRequired = 1  // add single tap
        addHazardButton.addGestureRecognizer(addHazardButtonTapGesture)
        
        // HAZARD BUTTON
        // SPOT REQUEST BUTTON
        
        addSpotRequestButton = UIView(frame: CGRect(x: mapContainer.frame.width - 66, y: mapContainer.frame.height - 198, width: 56, height: 56))
        addSpotRequestButton.backgroundColor = UIColor.clear
        addSpotRequestButton.layer.cornerRadius = 28
        mapContainer.addSubview(addSpotRequestButton)
        
        addSpotRequestButtonImage = UIImageView(frame: CGRect(x: 5, y: 5, width: 46, height: 46))
        addSpotRequestButtonImage.contentMode = UIViewContentMode.scaleAspectFit
        addSpotRequestButtonImage.clipsToBounds = true
        addSpotRequestButtonImage.image = UIImage(named: Constants.Strings.markerIconCamera)
        addSpotRequestButton.addSubview(addSpotRequestButtonImage)
        
        addSpotRequestButtonSpinner = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: addSpotRequestButton.frame.width, height: addSpotRequestButton.frame.height))
        addSpotRequestButtonSpinner.color = Constants.Colors.colorYellow
        addSpotRequestButton.addSubview(addSpotRequestButtonSpinner)
        
        addSpotRequestButtonTapGesture = UITapGestureRecognizer(target: self, action: #selector(MapViewController.addSpotRequestButtonTap(_:)))
        addSpotRequestButtonTapGesture.numberOfTapsRequired = 1  // add single tap
        addSpotRequestButton.addGestureRecognizer(addSpotRequestButtonTapGesture)
        
        // SPOT REQUEST BUTTON
        // PIN BUTTON
        
        addPinButton = UIView(frame: CGRect(x: mapContainer.frame.width - 66, y: mapContainer.frame.height - 198, width: 56, height: 56))
        addPinButton.backgroundColor = Constants.Colors.standardBackground
        addPinButton.layer.cornerRadius = 28
        addPinButton.layer.shadowOffset = CGSize(width: 0, height: 0.6)
        addPinButton.layer.shadowOpacity = 0.5
        addPinButton.layer.shadowRadius = 1.0
        mapContainer.addSubview(addPinButton)
        
        addPinButtonImage = UIImageView(frame: CGRect(x: 5, y: 5, width: 46, height: 46))
        addPinButtonImage.contentMode = UIViewContentMode.scaleAspectFit
        addPinButtonImage.clipsToBounds = true
        addPinButtonImage.image = UIImage(named: Constants.Strings.iconPinsMulti)
        addPinButton.addSubview(addPinButtonImage)
        
        addPinButtonTapGesture = UITapGestureRecognizer(target: self, action: #selector(MapViewController.addPinButtonTap(_:)))
        addPinButtonTapGesture.numberOfTapsRequired = 1  // add single tap
        addPinButton.addGestureRecognizer(addPinButtonTapGesture)
        
        // PIN BUTTON
        
        // IMAGE BUTTON
        
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
        
        // IMAGE BUTTON
        
        // Add the infowindow views to show the popups
        infoWindowHydro = InfoWindowHydro(frame: CGRect(x: (mapContainer.frame.width / 2) - 140, y: 80, width: 280, height: 260))
        infoWindowHydro.backgroundColor = Constants.Colors.standardBackground
        infoWindowHydro.layer.cornerRadius = 5
        infoWindowHydro.layer.shadowOffset = CGSize(width: 0, height: 0.6)
        infoWindowHydro.layer.shadowOpacity = 0.5
        infoWindowHydro.layer.shadowRadius = 1.0
        
        infoWindowShelter = InfoWindowShelter(frame: CGRect(x: (mapContainer.frame.width / 2) - 140, y: 80, width: 280, height: 330))
        infoWindowShelter.backgroundColor = Constants.Colors.standardBackground
        infoWindowShelter.layer.cornerRadius = 5
        infoWindowShelter.layer.shadowOffset = CGSize(width: 0, height: 0.6)
        infoWindowShelter.layer.shadowOpacity = 0.5
        infoWindowShelter.layer.shadowRadius = 1.0
        
        
        // Create the popup window for the user agreement
        infoWindowAgreement = InfoWindowAgreement(frame: CGRect(x: 0, y: 0, width: viewContainer.frame.width, height: viewContainer.frame.height))
        infoWindowAgreement.infoWindowDelegate = self
        infoWindowAgreement.backgroundColor = UIColor.clear
        if showAgreement
        {
            viewContainer.addSubview(infoWindowAgreement)
        }
        
        // Initiate basic setup and data request
        // Recall the Tutorial Views data in Core Data.  If it is empty for the current ViewController's tutorial, it has not been seen by the curren user.
        let tutorialView = CoreDataFunctions().tutorialViewRetrieve()
        print("MVC: TUTORIAL VIEW MAPVIEW: \(String(describing: tutorialView.tutorialMapViewDatetime))")
        if tutorialView.tutorialMapViewDatetime == nil
//        if 2 == 2
        {
            print("MVC-CHECK 1")
            let holeView = HoleView(holeViewPosition: 1, frame: viewContainer.bounds, circleOffsetX: 0, circleOffsetY: 0, circleRadius: 0, textOffsetX: (viewContainer.bounds.width / 2) - 130, textOffsetY: 60, textWidth: 260, textFontSize: 24, text: "Welcome to Harveytown!\n\nHarveytown is a disaster recovery app currently focused on hurricane-impacted areas.")
            holeView.holeViewDelegate = self
            viewContainer.addSubview(holeView)
        }
        else
        {
            print("MVC-CHECK 2")
            prepareMap()
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(MapViewController.statusBarHeightChange(_:)), name: Notification.Name("UIApplicationWillChangeStatusBarFrameNotification"), object: nil)
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: OBSERVER FUNCTIONS
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?)
    {
//        print("MVC - OBSERVER: \(keyPath)")
        if keyPath == "myLocation"
        {
            if let userLocation = mapView.myLocation
            {
//                print("MVC - OBSERVER - MY LOCATION: \(userLocation)")
                // If the initial data request has not occured, the user's location is now known, so request the map data
                if !initialDataRequest
                {
                    requestMapData(userLocation: userLocation)
                }
            }
        }
    }
    
    func statusBarHeightChange(_ notification: Notification)
    {
//        print("MVC - NOTIFICATION: \(notification)")
        
        prepVcLayout()
        
        statusBarView.frame = CGRect(x: 0, y: 0, width: screenSize.width, height: statusBarHeight)
        viewContainer.frame = CGRect(x: 0, y: vcOffsetY, width: screenSize.width, height: vcHeight)
        menuView.frame = CGRect(x: 0, y: 0, width: menuWidth, height: viewContainer.frame.height)
        mapContainer.frame = CGRect(x: 0, y: 0, width: viewContainer.frame.width, height: viewContainer.frame.height)
        mapView.frame = mapContainer.bounds
    }
    
    func prepVcLayout()
    {
        // Record the status bar settings to adjust the view if needed
        UIApplication.shared.isStatusBarHidden = false
        UIApplication.shared.statusBarStyle = Constants.Settings.statusBarStyle
        statusBarHeight = UIApplication.shared.statusBarFrame.size.height
        print("MVC - STATUS BAR HEIGHT: \(statusBarHeight)")
        
        // Navigation Bar settings
        navBarHeight = 44.0
        if let navController = self.navigationController
        {
            navController.isNavigationBarHidden = false
            navBarHeight = navController.navigationBar.frame.height
            print("MVC - NAV BAR HEIGHT: \(navController.navigationBar.frame.height)")
            navController.navigationBar.barTintColor = Constants.Colors.colorOrangeOpaque
//            navController.navigationBar.tintColor = Constants.Colors.colorTextNavBar
//            navController.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName : Constants.Colors.colorOrangeOpaque]
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
        print("MVC - vcOffsetY: \(vcOffsetY)")
    }
    
    // MARK: GOOGLE MAPS DELEGATES
    func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D)
    {
        print(coordinate)
        // Ensure the infoWindow and menu are hidden
        infoWindowHydro.removeFromSuperview()
        infoWindowShelter.removeFromSuperview()
        if menuVisible
        {
            toggleMenu()
        }
        
        if addHazardActive
        {
            print("MVC - DID TAP - IN addHazardActive: \(newHazardPrepInProgress)")
            if !newHazardPrepInProgress
            {
                self.newHazard = Hazard(userID: Constants.Data.currentUser.userID, datetime: Date(), lat: coordinate.latitude, lng: coordinate.longitude, type: Constants.HazardType.general)
                
                // Remove the previous and add a marker at the tap coordinates
                if newHazardMarker != nil
                {
                    newHazardMarker!.map = nil
                }
                // Custom Marker Icon
                let markerView = UIImageView(image: UIImage(named: Constants.Strings.iconHazard))
                newHazardMarker = GMSMarker()
                newHazardMarker!.position = coordinate
                newHazardMarker!.groundAnchor = CGPoint(x: 0.5, y: 0.5)
                newHazardMarker!.zIndex = 200
                newHazardMarker!.iconView = markerView
                newHazardMarker!.map = mapView
            }
        }
        else if addSpotRequestActive
        {
            print("MVC - DID TAP - IN addSpotRequestToggle: \(newSpotRequestPrepInProgress)")
            if !newSpotRequestPrepInProgress
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
        }
        else
        {
            checkSpotTap(coordinate: coordinate)
        }
    }
    
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool
    {
//        print("MVC - DID TAP: \(marker)")
        let markerData = marker.userData as? Any
        if let markerHydro = markerData as? Hydro
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
            
            infoWindowHydro.infoWindowTitle.text = markerTitle
            infoWindowHydro.infoWindowObs.text = "Last Observation: " + markerObs
            infoWindowHydro.infoWindowObsTime.text = markerHydro.obsTime
            infoWindowHydro.infoWindowProjHigh.text = "Projected High: " + markerHigh
            infoWindowHydro.infoWindowProjHighTime.text = markerHydro.projHighTime
            infoWindowHydro.infoWindowLastUpdate.text = "Last Updated: " + dateString
            mapContainer.addSubview(infoWindowHydro)
        }
        else if let markerSpot = markerData as? Spot
        {
            print(markerSpot.spotID)
            // Center the map on the tapped marker
            let markerCoords = CLLocationCoordinate2DMake(markerSpot.lat, markerSpot.lng)
            mapCameraPositionAdjust(target: markerCoords)
            
            checkSpotTap(coordinate: markerCoords)
            
            mapView.selectedMarker = marker
        }
        else if let markerSpotRequest = markerData as? SpotRequest
        {
            print(markerSpotRequest.requestID)
            // Center the map on the tapped marker
            let markerCoords = CLLocationCoordinate2DMake(markerSpotRequest.lat, markerSpotRequest.lng)
            mapCameraPositionAdjust(target: markerCoords)
            
            mapView.selectedMarker = marker
        }
        else if let markerShelter = markerData as? Shelter
        {
            // Center the map on the tapped marker
            let markerCoords = CLLocationCoordinate2DMake(markerShelter.lat, markerShelter.lng)
            mapCameraPositionAdjust(target: markerCoords)
            
            print(markerShelter.name)
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM dd, YYYY HH:mm"
            let dateString = dateFormatter.string(from: markerShelter.datetime)
            
            // Only add the type to the name if the type is not "unknown"
            if markerShelter.type != "unknown"
            {
                infoWindowShelter.labelTitle.text = markerShelter.name + " (" + markerShelter.type + ")"
            }
            else
            {
                infoWindowShelter.labelTitle.text = markerShelter.name
            }
            infoWindowShelter.label1A.text = "Status: " + markerShelter.condition
            if let phone = markerShelter.phone
            {
                infoWindowShelter.label1B.text = phone
            }
            infoWindowShelter.label2A.text = markerShelter.address
            infoWindowShelter.label2B.text = markerShelter.city
            if let info = markerShelter.info
            {
                infoWindowShelter.textView1.text = "Info: " + info
            }
            infoWindowShelter.labelFooter.text = "Last Updated: " + dateString
            mapContainer.addSubview(infoWindowShelter)
        }
        else if let markerHazard = markerData as? Hazard
        {
            print(markerHazard.hazardID)
            // Center the map on the tapped marker
            let markerCoords = CLLocationCoordinate2DMake(markerHazard.lat, markerHazard.lng)
            mapCameraPositionAdjust(target: markerCoords)
            
            mapView.selectedMarker = marker
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
        print("MVC - INFO WINDOW TAP: \(String(describing: marker.userData))")
        let markerData = marker.userData as? Any
        if let markerSpotRequest = markerData as? SpotRequest
        {
            infoWindowHydro.infoWindowTitle.text = "Photo Requested"
            infoWindowHydro.infoWindowObs.text = "Take a photo in this area"
            infoWindowHydro.infoWindowObsTime.text = "to fulfill this request."
            infoWindowHydro.infoWindowProjHigh.text = ""
            infoWindowHydro.infoWindowProjHighTime.text = ""
            infoWindowHydro.infoWindowLastUpdate.text = ""
            mapContainer.addSubview(infoWindowHydro)
        }
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
        
        // Check the markers again since the zoom may have changed
        zoomCheckSpotMarkers()
    }
    // Called when my location button is tapped
    func didTapMyLocationButton(for mapView: GMSMapView) -> Bool
    {
        if let myLocation = mapView.myLocation
        {
            let cameraUpdate = GMSCameraUpdate.setTarget(myLocation.coordinate, zoom: Constants.Settings.mapMyLocationTapZoom)
            mapView.animate(with: cameraUpdate)
        }
        
        // Ensure the markers and content are updated, if needed
        // Adjust the Map Camera back to apply the correct camera angle
        adjustMapViewCamera()
        
        // Check the markers again since the zoom may have changed
        zoomCheckSpotMarkers()
        
        return true
    }
    
    
    // MARK: TAP GESTURES
    func menuMapTrafficTap(_ gesture: UITapGestureRecognizer)
    {
        if Constants.Settings.menuMapTraffic == Constants.MenuMapTraffic.yes
        {
            mapView.isTrafficEnabled = false
            menuMapTrafficIndicator.removeFromSuperview()
            Constants.Settings.menuMapTraffic = Constants.MenuMapTraffic.no
        }
        else
        {
            mapView.isTrafficEnabled = true
            menuMapTrafficContainer.addSubview(menuMapTrafficIndicator)
            Constants.Settings.menuMapTraffic = Constants.MenuMapTraffic.yes
        }
        
        // Record the setting update in Core Data
        CoreDataFunctions().mapSettingSaveFromGlobalSettings()
    }
    func menuMapSpotTap(_ gesture: UITapGestureRecognizer)
    {
        if Constants.Settings.menuMapSpot == Constants.MenuMapSpot.yes
        {
            removeSpotMapFeatures()
            menuMapSpotIndicator.removeFromSuperview()
            Constants.Settings.menuMapSpot = Constants.MenuMapSpot.no
        }
        else
        {
            addSpotMapFeatures()
            menuMapSpotContainer.addSubview(menuMapSpotIndicator)
            Constants.Settings.menuMapSpot = Constants.MenuMapSpot.yes
        }
        
        // Record the setting update in Core Data
        CoreDataFunctions().mapSettingSaveFromGlobalSettings()
    }
    func menuMapHydroTap(_ gesture: UITapGestureRecognizer)
    {
        print("MVC - HYDRO TAP")
        if Constants.Settings.menuMapHydro == Constants.MenuMapHydro.yes
        {
            removeHydroMapFeatures()
            menuMapHydroIndicator.removeFromSuperview()
            Constants.Settings.menuMapHydro = Constants.MenuMapHydro.no
        }
        else
        {
            addHydroMapFeatures()
            menuMapHydroContainer.addSubview(menuMapHydroIndicator)
            Constants.Settings.menuMapHydro = Constants.MenuMapHydro.yes
        }
        
        // Record the setting update in Core Data
        CoreDataFunctions().mapSettingSaveFromGlobalSettings()
    }
    func menuMapShelterTap(_ gesture: UITapGestureRecognizer)
    {
        if Constants.Settings.menuMapShelter == Constants.MenuMapShelter.yes
        {
            removeShelterMapFeatures()
            menuMapShelterIndicator.removeFromSuperview()
            Constants.Settings.menuMapShelter = Constants.MenuMapShelter.no
        }
        else
        {
            addShelterMapFeatures()
            menuMapShelterContainer.addSubview(menuMapShelterIndicator)
            Constants.Settings.menuMapShelter = Constants.MenuMapShelter.yes
        }
        
        // Record the setting update in Core Data
        CoreDataFunctions().mapSettingSaveFromGlobalSettings()
    }
    func menuMapHazardTap(_ gesture: UITapGestureRecognizer)
    {
        if Constants.Settings.menuMapHazard == Constants.MenuMapHazard.yes
        {
            removeHazardMapFeatures()
            menuMapHazardIndicator.removeFromSuperview()
            Constants.Settings.menuMapHazard = Constants.MenuMapHazard.no
        }
        else
        {
            addHazardMapFeatures()
            menuMapHazardContainer.addSubview(menuMapHazardIndicator)
            Constants.Settings.menuMapHazard = Constants.MenuMapHazard.yes
        }
        
        // Record the setting update in Core Data
        CoreDataFunctions().mapSettingSaveFromGlobalSettings()
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
    func menuTimeDayTap(_ gesture: UITapGestureRecognizer)
    {
        Constants.Settings.menuMapTimeFilter = Constants.MenuMapTimeFilter.day
        toggleMenuTime()
        
        // Record the setting update in Core Data
        CoreDataFunctions().mapSettingSaveFromGlobalSettings()
    }
    func menuTimeWeekTap(_ gesture: UITapGestureRecognizer)
    {
        Constants.Settings.menuMapTimeFilter = Constants.MenuMapTimeFilter.week
        toggleMenuTime()
        
        // Record the setting update in Core Data
        CoreDataFunctions().mapSettingSaveFromGlobalSettings()
    }
    func menuTimeMonthTap(_ gesture: UITapGestureRecognizer)
    {
        Constants.Settings.menuMapTimeFilter = Constants.MenuMapTimeFilter.month
        toggleMenuTime()
        
        // Record the setting update in Core Data
        CoreDataFunctions().mapSettingSaveFromGlobalSettings()
    }
    func menuTimeYearTap(_ gesture: UITapGestureRecognizer)
    {
        Constants.Settings.menuMapTimeFilter = Constants.MenuMapTimeFilter.year
        toggleMenuTime()
        
        // Record the setting update in Core Data
        CoreDataFunctions().mapSettingSaveFromGlobalSettings()
    }
    
    func refreshViewTap(_ gesture: UITapGestureRecognizer)
    {
        if let userLocation = mapView.myLocation
        {
            requestMapData(userLocation: userLocation)
        }
    }
    
    func addImageButtonTap(_ gesture: UITapGestureRecognizer)
    {
        // Load the CameraVC
        let cameraVC = CameraViewController()
        cameraVC.cameraDelegate = self
        self.navigationController!.pushViewController(cameraVC, animated: true)
//        self.present(cameraVC, animated: true, completion: nil)
    }
    
    func infoWindowExitTap(_ gesture: UITapGestureRecognizer)
    {
        // Hide the infoWindow
        infoWindowHydro.removeFromSuperview()
//        infoWindowObs.textAlignment = .left
//        infoWindowObsTime.textAlignment = .left
    }
    
    func addPinButtonTap(_ gesture: UITapGestureRecognizer)
    {
        if pinContainerVisible
        {
            self.addPinButtonImage.image = UIImage(named: Constants.Strings.iconPinsMulti)
            self.pinContainerVisible = false
            
            // Reset all toggles
            if addSpotRequestActive && !newSpotRequestPrepInProgress
            {
                // Ensure the other marker selections are not selected
                addSpotRequestDeactivate()
            }
            if addHazardActive && !newHazardPrepInProgress
            {
                // Ensure the other marker selections are not selected
                addHazardDeactivate()
            }
            
            // Hide the pin container
            UIView.animate(withDuration: 0.5, animations:
                {
                    self.addPinContainer.frame = CGRect(x: self.mapContainer.frame.width - 66, y: self.mapContainer.frame.height - 198, width: 56, height: 56)
                    self.addSpotRequestButton.frame = CGRect(x: self.mapContainer.frame.width - 66, y: self.mapContainer.frame.height - 198, width: 56, height: 56)
                    self.addHazardButton.frame = CGRect(x: self.mapContainer.frame.width - 66, y: self.mapContainer.frame.height - 198, width: 56, height: 56)
            }, completion:
                {
                    (value: Bool) in
                    
            })
        }
        else
        {
            self.addPinButtonImage.image = UIImage(named: Constants.Strings.iconCloseDark)
            self.pinContainerVisible = true
            
            // Expand the container to show the pin selection buttons
            UIView.animate(withDuration: 0.5, animations:
                {
                    self.addPinContainer.frame = CGRect(x: self.mapContainer.frame.width - 66, y: self.mapContainer.frame.height - (198 + 56 * 2), width: 56, height: 56 * 3)
                    self.addSpotRequestButton.frame = CGRect(x: self.mapContainer.frame.width - 66, y: self.mapContainer.frame.height - (198 + 56), width: 56, height: 56)
                    self.addHazardButton.frame = CGRect(x: self.mapContainer.frame.width - 66, y: self.mapContainer.frame.height - (198 + 56 * 2), width: 56, height: 56)
            }, completion:
                {
                    (value: Bool) in
                    
            })
        }
    }
    func addHazardButtonTap(_ gesture: UITapGestureRecognizer)
    {
        print("MVC - addHazardButtonTap: \(newHazardPrepInProgress)")
        if !newHazardPrepInProgress
        {
            if addHazardActive
            {
                print("MVC - addHazardButtonTap 2")
                // The addHazard process is already active, so a second tap means the user clicked the check mark
                // Hold the Hazard interaction while uploading
                newHazardPrepInProgress = true
                
                // Hide the check mark and show the spinner
                addHazardButtonImage.removeFromSuperview()
                addHazardButtonSpinner.startAnimating()
                
                // Request a randomID for the Hazard before upload - the upload will fire when the id is downloaded
                AWSPrepRequest(requestToCall: AWSGetRandomID(randomIdType: Constants.randomIdType.random_hazard_id), delegate: self as AWSRequestDelegate).prepRequest()
            }
            else
            {
                print("MVC - addHazardButtonTap 3")
                // The addHazard process was not active, so activate it now that the user has made that selection
                addHazardActivate()
            }
        }
    }
    func addSpotRequestButtonTap(_ gesture: UITapGestureRecognizer)
    {
        print("MVC - addHazardButtonTap: \(newSpotRequestPrepInProgress)")
        if !newSpotRequestPrepInProgress
        {
            if addSpotRequestActive
            {
                print("MVC - addSpotRequestButtonTap 2")
                // The addSpotRequest process is already active, so a second tap means the user clicked the check mark
                // Hold the SpotRequest interaction while uploading
                newSpotRequestPrepInProgress = true
                
                // Hide the check mark and show the spinner
                addSpotRequestButtonImage.removeFromSuperview()
                addSpotRequestButtonSpinner.startAnimating()
                
                // Request a randomID for the SpotRequest before upload
                AWSPrepRequest(requestToCall: AWSGetRandomID(randomIdType: Constants.randomIdType.random_spot_id), delegate: self as AWSRequestDelegate).prepRequest()
            }
            else
            {
                print("MVC - addSpotRequestButtonTap 3")
                // The addSpotRequest process was not active, so activate it now that the user has made that selection
                addSpotRequestActivate()
            }
        }
    }
    
    func addHazardActivate()
    {
        print("MVC - addHazardActivate")
        // Ensure the other marker selections are not selected
        addSpotRequestDeactivate()
        
        // Indicate that the addHazard process is in progress and change the image
        addHazardActive = true
        addHazardButtonImage.image = UIImage(named: Constants.Strings.iconCheckOrange)
    }
    func addHazardDeactivate()
    {
        print("MVC - addHazardDeactivate")
        addHazardActive = false
        
        // Remove the Hazard temporary marker
        if self.newHazardMarker != nil
        {
            self.newHazardMarker!.map = nil
        }
        
        // Show the icon and hide the spinner
        addHazardButtonImage.image = UIImage(named: Constants.Strings.iconHazard)
        addHazardButton.addSubview(addHazardButtonImage)
        addHazardButtonSpinner.stopAnimating()
    }
    
    func addSpotRequestActivate()
    {
        print("MVC - addSpotRequestActivate")
        // Ensure the other marker selections are not selected
        addHazardDeactivate()
        
        // Indicate that the addSpotRequest process is in progress and change the image
        addSpotRequestActive = true
        addSpotRequestButtonImage.image = UIImage(named: Constants.Strings.iconCheckYellowPin)
    }
    func addSpotRequestDeactivate()
    {
        print("MVC - addSpotRequestDeactivate")
        addSpotRequestActive = false
        
        // Remove the SpotRequest temporary marker
        if self.newSpotRequestMarker != nil
        {
            self.newSpotRequestMarker!.map = nil
        }
        
        // Show the icon and hide the spinner
        addSpotRequestButtonImage.image = UIImage(named: Constants.Strings.markerIconCamera)
        addSpotRequestButton.addSubview(addSpotRequestButtonImage)
        addSpotRequestButtonSpinner.stopAnimating()
    }
    
    
    // MARK: DELEGATE METHODS
    
    func reloadMapData()
    {
        print("MVC - RELOAD MAP")
        // Before populating the map, delete all markers
        self.removeSpotMapFeatures()
        self.removeHydroMapFeatures()
        self.removeShelterMapFeatures()
        self.removeHazardMapFeatures()
        
        // Now populate the map, if settings are true
        if Constants.Settings.menuMapSpot == Constants.MenuMapSpot.yes
        {
            self.addSpotMapFeatures()
        }
        if Constants.Settings.menuMapHydro == Constants.MenuMapHydro.yes
        {
            self.addHydroMapFeatures()
        }
        if Constants.Settings.menuMapShelter == Constants.MenuMapShelter.yes
        {
            self.addShelterMapFeatures()
        }
        if Constants.Settings.menuMapHazard == Constants.MenuMapHazard.yes
        {
            self.addHazardMapFeatures()
        }
        
        // Check to see whether any data is still downloading - if not, stop the spinner
        if !downloadingSpot && !downloadingHydro && !downloadingShelter && !downloadingHazard
        {
            // All the data has been loaded - Hide the loading indicator
            self.refreshViewSpinner.stopAnimating()
            self.refreshView.addSubview(self.refreshViewImage)
        }
    }
    
    
    // MARK: CUSTOM METHODS
    
    func toggleMenuTime()
    {
        // Change the check mark indicator
        switch Constants.Settings.menuMapTimeFilter
        {
        case Constants.MenuMapTimeFilter.day:
            menuTimeContainer.addSubview(menuTimeDayIndicator)
            menuTimeWeekIndicator.removeFromSuperview()
            menuTimeMonthIndicator.removeFromSuperview()
            menuTimeYearIndicator.removeFromSuperview()
        case Constants.MenuMapTimeFilter.week:
            menuTimeDayIndicator.removeFromSuperview()
            menuTimeContainer.addSubview(menuTimeWeekIndicator)
            menuTimeMonthIndicator.removeFromSuperview()
            menuTimeYearIndicator.removeFromSuperview()
        case Constants.MenuMapTimeFilter.month:
            menuTimeDayIndicator.removeFromSuperview()
            menuTimeWeekIndicator.removeFromSuperview()
            menuTimeContainer.addSubview(menuTimeMonthIndicator)
            menuTimeYearIndicator.removeFromSuperview()
        case Constants.MenuMapTimeFilter.year:
            menuTimeDayIndicator.removeFromSuperview()
            menuTimeWeekIndicator.removeFromSuperview()
            menuTimeMonthIndicator.removeFromSuperview()
            menuTimeContainer.addSubview(menuTimeYearIndicator)
        default:
            menuTimeContainer.addSubview(menuTimeDayIndicator)
            menuTimeWeekIndicator.removeFromSuperview()
            menuTimeMonthIndicator.removeFromSuperview()
            menuTimeYearIndicator.removeFromSuperview()
        }
        
        // Reload the data with the new filter
        reloadMapData()
    }
    func requestMapData(userLocation: CLLocation)
    {
//        print("MVC - REFRESH MAP DATA")
        // Reload all data - Show the loading indicator
        self.refreshViewImage.removeFromSuperview()
        self.refreshViewSpinner.startAnimating()
        
//        print("MVC - REQUESTING MAP DATA")
        var userLoc = [String : Double]()
        userLoc["lat"] = userLocation.coordinate.latitude
        userLoc["lng"] = userLocation.coordinate.longitude
        
        AWSPrepRequest(requestToCall: AWSGetSpotData(userLocation: userLoc), delegate: self as AWSRequestDelegate).prepRequest()
        AWSPrepRequest(requestToCall: AWSGetHydroData(userLocation: userLoc), delegate: self as AWSRequestDelegate).prepRequest()
        AWSPrepRequest(requestToCall: AWSGetShelterData(userLocation: userLoc), delegate: self as AWSRequestDelegate).prepRequest()
        AWSPrepRequest(requestToCall: AWSGetHazardData(), delegate: self as AWSRequestDelegate).prepRequest()
        AWSPrepRequest(requestToCall: AWSGetUsers(), delegate: self as AWSRequestDelegate).prepRequest()
        AWSPrepRequest(requestToCall: AWSGetUserConnections(), delegate: self as AWSRequestDelegate).prepRequest()
        
        // Set all the downloading indicators to true
        downloadingSpot = true
        downloadingHydro = true
        downloadingShelter = true
        downloadingHazard = true
        
        // Ensure that the initialDataRequest is true
        initialDataRequest = true
    }
    func prepareMap()
    {
        // RECALL THE CORE DATA SETTINGS
        recallGlobalSettingsFromCoreData()
        
        // PREPARE THE MAP
        toggleMenuTime()
        if let userLocation = mapView.myLocation
        {
            requestMapData(userLocation: userLocation)
        }
        
        // Set the menu features that rely on global settings
        if Constants.Settings.menuMapTraffic == Constants.MenuMapTraffic.yes
        {
            menuMapTrafficContainer.addSubview(menuMapTrafficIndicator)
            mapView.isTrafficEnabled = true
        }
        if Constants.Settings.menuMapSpot == Constants.MenuMapSpot.yes
        {
            menuMapSpotContainer.addSubview(menuMapSpotIndicator)
        }
        if Constants.Settings.menuMapHydro == Constants.MenuMapHydro.yes
        {
            menuMapHydroContainer.addSubview(menuMapHydroIndicator)
        }
        if Constants.Settings.menuMapShelter == Constants.MenuMapShelter.yes
        {
            menuMapShelterContainer.addSubview(menuMapShelterIndicator)
        }
        if Constants.Settings.menuMapHazard == Constants.MenuMapHazard.yes
        {
            menuMapHazardContainer.addSubview(menuMapHazardIndicator)
        }
    }
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
    
    // Determine which Spots are at a coordinate location and show the ImageVC for all content for selected Spots
    func checkSpotTap(coordinate: CLLocationCoordinate2D)
    {
        // Create an array to hold all Spots overlapping the tap point
        var tappedSpots = [Spot]()
        
        // Find all Spots that overlap the tapped point
        for tSpot in Constants.Data.allSpot
        {
//            print("MVC - TB - CHECKING SPOT: \(tSpot.spotID)")
            // Only check the location of the Spot if it falls within the filtered time range
            if tSpot.datetime.timeIntervalSince1970 >= Date().timeIntervalSince1970 - Constants().menuMapTimeFilterSeconds(Constants.Settings.menuMapTimeFilter)
            {
                // Calculate the distance from the tap to the center of the Spot
                let tapFromSpotCenterDistance: Double! = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude).distance(from: CLLocation(latitude: tSpot.lat, longitude: tSpot.lng))
                
                if tapFromSpotCenterDistance <= tSpot.radius
                {
                    print("MVC - TM - TAPPED SPOT: \(tSpot.spotID)")
                    tappedSpots.append(tSpot)
                }
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
            ncTitleText.text = String(Double(round(100000 * coordinate.latitude)/100000)) + ", " + String(Double(round(100000 * coordinate.longitude)/100000))
            
            ncTitleText.textColor = Constants.Colors.colorTextNavBar
            ncTitleText.font = UIFont(name: Constants.Strings.fontAlt, size: 14)
            ncTitleText.textAlignment = .center
            ncTitle.addSubview(ncTitleText)
            
            // Instantiate a SpotContent array to hold all content
            var spotContent = [SpotContent]()
            for spot in tappedSpots
            {
                if spot.spotContent.count > 0
                {
                    spotContent = spotContent + spot.spotContent
                }
            }
            
            // Create the SpotVC, pass the content, and assign the created Nav Bar settings to the Tab Bar Controller
            let spotTableVC = SpotTableViewController(spotContent: spotContent, allowDelete: false)
            spotTableVC.navigationItem.setLeftBarButton(backButtonItem, animated: true)
            spotTableVC.navigationItem.titleView = ncTitle
            
//            print("MVC - NAV CONTROLLER: \(String(describing: self.navigationController))")
            if let navController = self.navigationController
            {
                navController.pushViewController(spotTableVC, animated: true)
            }
        }
    }
    
    // Add markers for Spots on the map if the zoom is high enough (used for map zoom change check)
    func zoomCheckSpotMarkers()
    {
        // Check the zoom level - if high enough, show the markers (or keep them);
        // if low enough, remove the markers (or don't add them)
        
        // Ensure that the zoom is low enough (far enough away), and add the markers (if not already visible)
//        print("MVC - TSM - MAP ZOOM: \(mapView.camera.zoom)")
//        print("MVC - TSM - spotMarkersVisible: \(spotMarkersVisible)")
        if mapView.camera.zoom < Constants.Settings.mapViewAngledZoom && !spotMarkersVisible
        {
//            print("MVC - ALL SPOT COUNT: \(Constants.Data.allSpot.count)")
            for spot in Constants.Data.allSpot
            {
                addSpotMarker(spot)
            }
//            print("MVC - TOGGLING spotMarkersVisible TRUE")
            // Toggle the indicator
            spotMarkersVisible = true
        }
        else if mapView.camera.zoom >= Constants.Settings.mapViewAngledZoom && spotMarkersVisible
        {
            // Nullify all current markers
            for marker in Constants.Data.spotMarkers
            {
                marker.map = nil
            }
            Constants.Data.spotMarkers = [GMSMarker]()
            
//            print("MVC - TOGGLING spotMarkersVisible FALSE")
            // Toggle the indicator
            spotMarkersVisible = false
        }
    }
    // Add markers for Spots on the map if the zoom is high enough (used for updating without toggle)
    func processSpotMarkers()
    {
        // Check the zoom level - if high enough, show the markers (or keep them);
        // if low enough, remove the markers (or don't add them)
        
        // Ensure that the zoom is low enough (far enough away), and add the markers (if not already visible)
//        print("MVC - PSM - MAP ZOOM: \(mapView.camera.zoom)")
//        print("MVC - PSM - spotMarkersVisible: \(spotMarkersVisible)")
        if mapView.camera.zoom < Constants.Settings.mapViewAngledZoom
        {
//            print("MVC - ALL SPOT COUNT: \(Constants.Data.allSpot.count)")
            for spot in Constants.Data.allSpot
            {
                addSpotMarker(spot)
            }
        }
        else if mapView.camera.zoom >= Constants.Settings.mapViewAngledZoom
        {
            // Nullify all current markers
            for marker in Constants.Data.spotMarkers
            {
                marker.map = nil
            }
            Constants.Data.spotMarkers = [GMSMarker]()
        }
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
        // Load the ProfileVC
        let profileVC = ProfileViewController()
        self.navigationController!.pushViewController(profileVC, animated: true)
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
    
    
    // MARK: INFO WINDOW METHODS
    
    func infoWindowSelectCancel()
    {
        UtilityFunctions().logOutFBAndClearData()
        
        // Load the LoginVC
        let loginVC = LoginViewController()
        self.navigationController!.pushViewController(loginVC, animated: true)
    }
    
    func infoWindowSelectOk()
    {
        reloadMapData()
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
    func removeShelterMapFeatures()
    {
        for marker in Constants.Data.shelterMarkers
        {
            marker.map = nil
        }
        Constants.Data.shelterMarkers = [GMSMarker]()
    }
    func removeHazardMapFeatures()
    {
        for marker in Constants.Data.hazardMarkers
        {
            marker.map = nil
        }
        Constants.Data.hazardMarkers = [GMSMarker]()
    }
    
    func addSpotMapFeatures()
    {
        for spot in Constants.Data.allSpot
        {
//            print("MVC - ADD SPOT MAP FEATURES \(spot.spotID)")
            // Ensure the spot datetime falls within the filter setting
            if spot.datetime.timeIntervalSince1970 >= Date().timeIntervalSince1970 - Constants().menuMapTimeFilterSeconds(Constants.Settings.menuMapTimeFilter)
            {
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
//                self.addSpotMarker(spot)
            }
        }
        // Run the zoom check to see if the markers should be added
        self.processSpotMarkers()
        
        for spotRequest in Constants.Data.allSpotRequest
        {
//            print(spotRequest.requestID)
            // Ensure the spot datetime falls within the filter setting
            if spotRequest.datetime.timeIntervalSince1970 >= Date().timeIntervalSince1970 - Constants().menuMapTimeFilterSeconds(Constants.Settings.menuMapTimeFilter)
            {
                // Creates a marker at the Spot Request location
                let marker = GMSMarker()
                marker.position = CLLocationCoordinate2DMake(spotRequest.lat, spotRequest.lng)
                marker.zIndex = Constants.Settings.mapMarkerSpotRequest
                marker.userData = spotRequest
                marker.snippet = "Photo Requested"
                marker.icon = UIImage(named: Constants.Strings.markerIconCamera)
                marker.map = self.mapView
                Constants.Data.spotRequestMarkers.append(marker)
            }
        }
    }
    func addHydroMapFeatures()
    {
//        print("MVC - HYDRO DATA COUNT: \(Constants.Data.allHydro.count)")
        for hydro in Constants.Data.allHydro
        {
            // Creates a marker at the Hydro location
            let marker = GMSMarker()
            marker.position = CLLocationCoordinate2DMake(hydro.lat, hydro.lng)
            marker.zIndex = Constants.Settings.mapMarkerHydro
            marker.userData = hydro
            marker.icon = UIImage(named: Constants.Strings.markerIconGauge)
            marker.map = self.mapView
            Constants.Data.hydroMarkers.append(marker)
        }
    }
    func addShelterMapFeatures()
    {
//        print("MVC - SHELTER DATA:")
        for shelter in Constants.Data.allShelter
        {
            if shelter.name != "na"
            {
                // Creates a marker at the Shelter location
                let marker = GMSMarker()
                marker.position = CLLocationCoordinate2DMake(shelter.lat, shelter.lng)
                marker.zIndex = Constants.Settings.mapMarkerShelter
                marker.userData = shelter
                marker.icon = UIImage(named: Constants.Strings.markerIconShelter)
                marker.map = self.mapView
                Constants.Data.shelterMarkers.append(marker)
            }
        }
    }
    func addHazardMapFeatures()
    {
        print("MVC - Hazard DATA:")
        for hazard in Constants.Data.allHazard
        {
            if hazard.status != "inactive"
            {
                // Creates a marker at the Hazard location
                let marker = GMSMarker()
                marker.position = CLLocationCoordinate2DMake(hazard.lat, hazard.lng)
                marker.zIndex = Constants.Settings.mapMarkerHazard
                marker.groundAnchor = CGPoint(x: 0.5, y: 0.5)
                marker.userData = hazard
                marker.snippet = "Hazard Reported"
                marker.icon = UIImage(named: Constants.Strings.iconHazard)
                marker.map = self.mapView
                Constants.Data.hazardMarkers.append(marker)
            }
        }
    }
    
    func recallGlobalSettingsFromCoreData()
    {
        let mapSettingArray = CoreDataFunctions().mapSettingRetrieve()
        if mapSettingArray.count > 0
        {
            let mapSetting: MapSetting = mapSettingArray[0]
            print("MVC: MAP SETTING TRAFFIC: \(mapSetting.menuMapTraffic)")
            print("MVC: MAP SETTING SPOT: \(mapSetting.menuMapSpot)")
            print("MVC: MAP SETTING HYDRO: \(mapSetting.menuMapHydro)")
            print("MVC: MAP SETTING SHELTER: \(mapSetting.menuMapShelter)")
            print("MVC: MAP SETTING TIME: \(mapSetting.menuMapTimeFilter)")
            
            if mapSetting.menuMapTraffic != 0
            {
                Constants.Settings.menuMapTraffic = Constants().menuMapTraffic(Int(mapSetting.menuMapTraffic))
            }
            if mapSetting.menuMapSpot != 0
            {
                Constants.Settings.menuMapSpot = Constants().menuMapSpot(Int(mapSetting.menuMapSpot))
            }
            if mapSetting.menuMapHydro != 0
            {
                Constants.Settings.menuMapHydro = Constants().menuMapHydro(Int(mapSetting.menuMapHydro))
            }
            if mapSetting.menuMapShelter != 0
            {
                Constants.Settings.menuMapShelter = Constants().menuMapShelter(Int(mapSetting.menuMapShelter))
            }
            if mapSetting.menuMapTimeFilter != 0
            {
                Constants.Settings.menuMapTimeFilter = Constants().menuMapTimeFilter(Int(mapSetting.menuMapTimeFilter))
            }
        }
        else
        {
            print("MVC - NO CORE DATA MAP SETTINGS YET")
        }
    }
    
    
    // MARK: AWS DELEGATE METHODS
    
    func showLoginScreen()
    {
//        print("MVC - SHOW LOGIN SCREEN")
        loadProfileVC()
        
        // Load the LoginVC
        let loginVC = LoginViewController()
        self.navigationController!.pushViewController(loginVC, animated: true)
    }
    
    func processAwsReturn(_ objectType: AWSRequestObject, success: Bool)
    {
//        print("MVC - processAwsReturn:")
        DispatchQueue.main.async(execute:
            {
                // Process the return data based on the method used
                switch objectType
                {
                case _ as AWSGetSpotData:
                    if success
                    {
                        // Reset the SpotMarker indicator (if the zoom is low enough? - seems to be working w/o check)
//                        if mapView.camera.zoom < Constants.Settings.mapViewAngledZoom
                        self.spotMarkersVisible = false
                        
                        // Mark the proper data as downloaded
                        self.downloadingSpot = false
                        
                        self.reloadMapData()
                    }
                    else
                    {
                        print("MVC-ERROR: AWSGetSpotData")
                        // Show the error message
                        let alert = UtilityFunctions().createAlertOkView("Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
                        alert.show()
                    }
                case _ as AWSGetHydroData:
                    if success
                    {
                        // Mark the proper data as downloaded
                        self.downloadingHydro = false
                        
                        self.reloadMapData()
                    }
                    else
                    {
                        print("MVC-ERROR: AWSGetHydroData")
                        // Show the error message
                        let alert = UtilityFunctions().createAlertOkView("Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
                        alert.show()
                    }
                case _ as AWSGetShelterData:
                    if success
                    {
                        // Mark the proper data as downloaded
                        self.downloadingShelter = false
                        
                        self.reloadMapData()
                    }
                    else
                    {
                        print("MVC-ERROR: AWSGetShelterData")
                        // Show the error message
                        let alert = UtilityFunctions().createAlertOkView("Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
                        alert.show()
                    }
                case _ as AWSGetHazardData:
                    if success
                    {
                        // Mark the proper data as downloaded
                        self.downloadingHazard = false
                        
                        self.reloadMapData()
                    }
                    else
                    {
                        print("MVC-ERROR: AWSGetShelterData")
                        // Show the error message
                        let alert = UtilityFunctions().createAlertOkView("Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
                        alert.show()
                    }
                case let awsGetRandomID as AWSGetRandomID:
                    if success
                    {
                        // The randomID is only requested once the upload command is given, so upload the data when the randomID is received
//                        print("MVC - AWSGetRandomID: \(String(describing: awsGetRandomID.randomID))")
                        if awsGetRandomID.randomIdType == Constants.randomIdType.random_spot_id
                        {
                            if let spotRequest = self.newSpotRequest
                            {
                                spotRequest.requestID = awsGetRandomID.randomID
                                
                                // Upload the SpotRequest
                                AWSPrepRequest(requestToCall: AWSPutSpotRequestData(spotRequest: spotRequest), delegate: self as AWSRequestDelegate).prepRequest()
                            }
                        }
                        else if awsGetRandomID.randomIdType == Constants.randomIdType.random_hazard_id
                        {
                            if let hazard = self.newHazard
                            {
                                print("MVC-AWSGetRandomID for HAZARD for user: \(hazard.userID)")
                                hazard.hazardID = awsGetRandomID.randomID
                                
                                // Upload the Hazard
                                AWSPrepRequest(requestToCall: AWSPutHazardData(hazard: hazard), delegate: self as AWSRequestDelegate).prepRequest()
                            }
                        }
                    }
                    else
                    {
                        print("MVC-ERROR: AWSGetRandomID")
                        // Show the error message
                        let alert = UtilityFunctions().createAlertOkView("Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
                        alert.show()
                    }
                case _ as AWSPutSpotRequestData:
                    if success
                    {
                        // The SpotRequest was already added to the global array in AWSClasses
                        print("MVC - AWSPutSpotRequestData SUCCESS")
                        
                        // Release the hold on adding a new SpotRequest while uploading
                        self.newSpotRequestPrepInProgress = false
                        
                        // Reset the view controllers involved
                        self.addSpotRequestDeactivate()
                        
                        // Update the SpotRequests
                        self.reloadMapData()
                    }
                    else
                    {
                        print("ERROR: AWSPutSpotRequestData")
                        // Show the error message
                        let alert = UtilityFunctions().createAlertOkView("Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
                        alert.show()
                    }
                case _ as AWSPutHazardData:
                    if success
                    {
                        // The Hazard was already added to the global array in AWSClasses
                        print("MVC - AWSPutHazardData SUCCESS")
                        
                        // Release the hold on adding a new Hazard while uploading
                        self.newHazardPrepInProgress = false
                        
                        // Reset the view controllers involved
                        self.addHazardDeactivate()
                        
                        // Update the Hazards
                        self.reloadMapData()
                    }
                    else
                    {
                        print("ERROR: AWSPutSpotRequestData")
                        // Show the error message
                        let alert = UtilityFunctions().createAlertOkView("Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
                        alert.show()
                    }
                case _ as AWSGetUsers:
                    if success
                    {
                        print("MVC-SUCCESS: AWSGetUsers")
                    }
                    else
                    {
                        print("MVC-ERROR: AWSGetUsers")
                        // Show the error message
                        let alert = UtilityFunctions().createAlertOkView("Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
                        alert.show()
                    }
                case _ as AWSGetUserConnections:
                    if success
                    {
                        print("MVC-SUCCESS: AWSGetUserConnections")
                    }
                    else
                    {
                        print("MVC-ERROR: AWSGetUserConnections")
                        // Show the error message
                        let alert = UtilityFunctions().createAlertOkView("Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
                        alert.show()
                    }
                default:
                    print("MVC-DEFAULT: THERE WAS AN ISSUE WITH THE DATA RETURNED FROM AWS")
                    
                    // Show the error message
                    let alert = UtilityFunctions().createAlertOkView("Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
                    alert.show()
                }
        })
    }
    
    // PROCESS REQUEST RETURNS
    func processRequestReturn(_ requestCalled: RequestObject, success: Bool)
    {
        // Process the return data based on the method used
        switch requestCalled
        {
        case let fbGetUserData as FBGetUserData:
            if success
            {
                print("MVC-SUCCESS: FBGetUserData: \(fbGetUserData.facebookName)")
            }
            else
            {
                print("ERROR: AWSGetHydroData")
                // Show the error message
                let alert = UtilityFunctions().createAlertOkView("Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
                alert.show()
            }
        case let fbDownloadUserImage as FBDownloadUserImage:
            if success
            {
                print("MVC-SUCCESS: FBDownloadUserImage: \(fbDownloadUserImage.facebookID), \(fbDownloadUserImage.large)")
            }
            else
            {
                print("MVC-ERROR: AWSGetHydroData")
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
    
    
    // MARK: HOLE VIEW DELEGATE
    
    func holeViewRemoved(removingViewAtPosition: Int)
    {
        // Give a short tutorial for new users
        
        switch removingViewAtPosition
        {
        case 1:
            // Show users how to add photo requests (SpotRequests)
            print("MVC-CHECK TUTORIAL 1")
            let holeView = HoleView(holeViewPosition: 2, frame: viewContainer.bounds, circleOffsetX: viewContainer.frame.width - 38, circleOffsetY: viewContainer.frame.height - 170, circleRadius: 40, textOffsetX: (viewContainer.bounds.width / 2) - 130, textOffsetY: 50, textWidth: 260, textFontSize: 24, text: "Add a pin to the map to request a photo at any location.\n\nUse this feature to request environmental and weather condition updates at other locations.")
            holeView.holeViewDelegate = self
            viewContainer.addSubview(holeView)
            
        case 2:
            // Show users how to add photos to fulfill requests
            print("MVC-CHECK TUTORIAL 2")
            let holeView = HoleView(holeViewPosition: 3, frame: viewContainer.bounds, circleOffsetX: viewContainer.frame.width - 38, circleOffsetY: viewContainer.frame.height - 105, circleRadius: 40, textOffsetX: (viewContainer.bounds.width / 2) - 130, textOffsetY: 100, textWidth: 260, textFontSize: 24, text: "Add a photo when you are near a photo request location to automatically fulfill the request.")
            holeView.holeViewDelegate = self
            viewContainer.addSubview(holeView)
        
        case 3:
            // Conclude the tutorial
            print("MVC-CHECK TUTORIAL 3")
            let holeView = HoleView(holeViewPosition: 4, frame: viewContainer.bounds, circleOffsetX: 0, circleOffsetY: 0, circleRadius: 0, textOffsetX: (viewContainer.bounds.width / 2) - 130, textOffsetY: (viewContainer.bounds.height / 2) - 130, textWidth: 260, textFontSize: 24, text: "Check out other map pins for additional data.\n\nMore features and data are in development.")
            holeView.holeViewDelegate = self
            viewContainer.addSubview(holeView)
            
        default:
            // The tutorial has ended - prepare the app for use
            prepareMap()
            print("MVC-CHECK TUTORIAL 4")
            // Record the Tutorial View in Core Data
            let moc = DataController().managedObjectContext
            let tutorialView = NSEntityDescription.insertNewObject(forEntityName: "TutorialView", into: moc) as! TutorialView
            tutorialView.setValue(NSDate(), forKey: "tutorialMapViewDatetime")
            CoreDataFunctions().tutorialViewSave(tutorialView: tutorialView)
        }
    }
}

