//
//  ViewController.swift
//  Harvey
//
//  Created by Sean Hart on 8/28/17.
//  Copyright © 2017 tangojlabs. All rights reserved.
//

import UIKit
import GoogleMaps

class MapViewController: UIViewController, GMSMapViewDelegate, XMLParserDelegate
{
    // Save device settings to adjust view if needed
    var screenSize: CGRect!
    var statusBarHeight: CGFloat!
    var navBarHeight: CGFloat!
    var viewFrameY: CGFloat!
    var vcHeight: CGFloat!
    var vcOffsetY: CGFloat!
    
    // The views to hold major components of the view controller
    var viewContainer: UIView!
    var statusBarView: UIView!
    var mapView: GMSMapView!
    
    // XML variables
    var strXMLData:String = ""
    var currentElement:String = ""
    var passData:Bool=false
    var passName:Bool=false
    var parser = XMLParser()
    
    // The Google Maps Coordinate Object for the current center of the map and the default Camera
//    var mapCenter: CLLocationCoordinate2D!
    var defaultCamera: GMSCameraPosition!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        // Record the status bar settings to adjust the view if needed
        UIApplication.shared.isStatusBarHidden = false
        UIApplication.shared.statusBarStyle = Constants.Settings.statusBarStyle
        statusBarHeight = UIApplication.shared.statusBarFrame.size.height
        print("MVC - STATUS BAR HEIGHT: \(statusBarHeight)")
        navBarHeight = 44.0
        if let navController = self.navigationController
        {
            print("MVC - NAV BAR HEIGHT: \(navController.navigationBar.frame.height)")
            navBarHeight = navController.navigationBar.frame.height
        }
        viewFrameY = self.view.frame.minY
        screenSize = UIScreen.main.bounds
        
        vcHeight = screenSize.height - statusBarHeight //- navBarHeight
        vcOffsetY = statusBarHeight //+ navBarHeight
        if statusBarHeight > 20
        {
            vcOffsetY = 20
        }
        print("MVC - vcOffsetY: \(vcOffsetY)")
        
        // Add the Status Bar, Top Bar and Search Bar last so that they are placed above (z-index) all other views
        statusBarView = UIView(frame: CGRect(x: 0, y: 0, width: screenSize.width, height: statusBarHeight))
        statusBarView.backgroundColor = Constants.Colors.colorStatusBar
        self.view.addSubview(statusBarView)
        
        // Add the view container to hold all other views (allows for shadows on all subviews)
        viewContainer = UIView(frame: CGRect(x: 0, y: vcOffsetY, width: screenSize.width, height: vcHeight))
        viewContainer.backgroundColor = Constants.Colors.standardBackground
        viewContainer.layer.shadowOffset = CGSize(width: 0, height: 0.2)
        viewContainer.layer.shadowOpacity = 0.2
        viewContainer.layer.shadowRadius = 1.0
        self.view.addSubview(viewContainer)
        print(viewContainer.bounds)
        
        // Create a camera with the default location (if location services are used, this should not be shown for long)
        defaultCamera = GMSCameraPosition.camera(withLatitude: Constants.Settings.mapViewDefaultLat, longitude: Constants.Settings.mapViewDefaultLong, zoom: Constants.Settings.mapViewDefaultZoom)
        mapView = GMSMapView.map(withFrame: viewContainer.bounds, camera: defaultCamera)
        mapView.padding = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        mapView.delegate = self
//        mapView.mapType = kGMSTypeNormal
//        mapView.isIndoorEnabled = true
        mapView.isMyLocationEnabled = true
        mapView.settings.myLocationButton = true
        viewContainer.addSubview(mapView)
        
//        // Creates a marker in the center of the map.
//        let marker = GMSMarker()
//        marker.position = CLLocationCoordinate2D(latitude: Constants.Settings.mapViewDefaultLat, longitude: Constants.Settings.mapViewDefaultLong)
//        marker.title = "MAP"
//        marker.snippet = "CENTER"
//        marker.map = mapView
        
        // Load the map data
        let url: String = "http://traffic.houstontranstar.org/data/rss/incidents_rss.xml"
        let urlToSend: URL = URL(string: url)!
        // Parse the XML
        parser = XMLParser(contentsOf: urlToSend)!
        parser.delegate = self
        
        let success:Bool = parser.parse()
        
        if success {
            print("parse success!")
            print(strXMLData)
            
        } else {
            print("parse failure!")
        }
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // Parser delegate functions
//    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String])
//    {
//        print("didStartElement")
//        print(elementName)
//        print(namespaceURI)
//        print(qName)
//        print(attributeDict)
//    }
//    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?)
//    {
//        print("didEndElement")
//        print(elementName)
//        print(namespaceURI)
//        print(qName)
//    }
//    func parser(_ parser: XMLParser, foundCharacters string: String)
//    {
//        print("foundCharacters")
//        print(string)
//    }
//    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error)
//    {
//        print("failure error: ", parseError)
//    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String])
    {
        currentElement=elementName;
        if (elementName=="id" || elementName=="name" || elementName=="cost" || elementName=="description")
        {
            if (elementName=="name")
            {
                passName=true;
            }
            passData=true;
        }
    }
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?)
    {
        currentElement="";
        if (elementName=="id" || elementName=="name" || elementName=="cost" || elementName=="description")
        {
            if (elementName=="name")
            {
                passName=false;
            }
            passData=false;
        }
    }
    func parser(_ parser: XMLParser, foundCharacters string: String)
    {
        if (passName)
        {
            strXMLData=strXMLData+"\n\n" + string
        }
        if (passData)
        {
            print(string)
        }
    }
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error)
    {
        print("failure error: ", parseError)
    }
}

