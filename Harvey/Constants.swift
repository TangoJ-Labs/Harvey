//
//  Constants.swift
//  Harvey
//
//  Created by Sean Hart on 8/28/17.
//  Copyright © 2017 tangojlabs. All rights reserved.
//

//import AWSCore
import GoogleMaps
import UIKit

struct Constants
{
    struct Colors
    {
        static let standardBackground = UIColor.white
        static let standardBackgroundTransparent = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.8) //#FFF
        static let standardBackgroundGray = UIColor(red: 104/255, green: 104/255, blue: 104/255, alpha: 1.0) //#686868
        static let standardBackgroundGrayTransparent = UIColor(red: 104/255, green: 104/255, blue: 104/255, alpha: 0.3) //#686868
        static let standardBackgroundGrayUltraLight = UIColor(red: 242/255, green: 242/255, blue: 242/255, alpha: 1.0) //#F2F2F2
        static let standardBackgroundGrayUltraLightTransparent = UIColor(red: 242/255, green: 242/255, blue: 242/255, alpha: 0.3) //#F2F2F2
        
        static let colorStatusBar = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 1.0) //#FFF
//        static let colorStatusBarLight = UIColor(red: 187/255, green: 172/255, blue: 210/255, alpha: 1.0) //#BBACD2
        static let colorTopBar = UIColor(red: 138/255, green: 112/255, blue: 178/255, alpha: 1.0) //#8A70B2
        static let colorBorderGrayLight = UIColor(red: 204/255, green: 204/255, blue: 204/255, alpha: 1.0) //#CCC
        
        static let colorTextNavBar = UIColor.white
        static let colorGrayLight = UIColor(red: 204/255, green: 204/255, blue: 204/255, alpha: 1.0) //#CCC
        static let colorGrayDark = UIColor(red: 38/255, green: 38/255, blue: 38/255, alpha: 1.0) //#262626
        
        static let colorFacebookDarkBlue = UIColor(red: 59/255, green: 89/255, blue: 152/255, alpha: 1.0) //#3B5998
    }
    
    struct Settings
    {
        static let gKey = "AIzaSyBKa1WknlP96r0whyI6lFkLuJcPr97un5w"
        static let mapStyleUrl = URL(string: "mapbox://styles/tangojlabs/ciqwaddsl0005b7m0xwctftow")
        
        static let mapViewDefaultLat: CLLocationDegrees = 29.758624
        static let mapViewDefaultLong: CLLocationDegrees = -95.366795
        static let mapViewDefaultZoom: Float = 10
        static let mapViewAngledZoom: Float = 16
        static let mapViewAngledDegrees: Double = 60.0
        
//        static var locationManagerSetting: LocationManagerSettingType = Constants.LocationManagerSettingType.significant
        static var statusBarStyle: UIStatusBarStyle = UIStatusBarStyle.default
    }
}
