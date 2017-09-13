//
//  Constants.swift
//  Harvey
//
//  Created by Sean Hart on 8/28/17.
//  Copyright © 2017 tangojlabs. All rights reserved.
//

import AWSCore
import GoogleMaps
import UIKit

struct Constants
{
    static var credentialsProvider = AWSCognitoCredentialsProvider(regionType: Constants.Strings.awsRegion, identityPoolId: Constants.Strings.awsCognitoIdentityPoolID)
    
    enum SpotStatus: Int
    {
        case waiting = 0
        case fulfilled = 1
    }
    
    enum randomIdType: String
    {
        case random_hazard_id = "random_hazard_id"
        case random_sos_id = "random_sos_id"
        case random_spot_id = "random_spot_id"
        case random_media_id = "random_media_id"
    }
    
    enum ContentType: Int
    {
        case text = 0
        case image = 1
        case video = 2
    }
    func contentType(_ contentTypeInt: Int) -> Constants.ContentType
    {
        // Evaluate the contentType Integer received and convert it to the appropriate ContentType
        switch contentTypeInt
        {
        case 0:
            return Constants.ContentType.text
        case 1:
            return Constants.ContentType.image
        case 2:
            return Constants.ContentType.video
        default:
            return Constants.ContentType.text
        }
    }
    
    enum HazardType: Int
    {
        case general = 0
        case road = 1
        case building = 2
    }
    func hazardType(_ hazardTypeInt: Int) -> Constants.HazardType
    {
        // Evaluate the hazardType Integer received and convert it to the appropriate HazardType
        switch hazardTypeInt
        {
        case 0:
            return Constants.HazardType.general
        case 1:
            return Constants.HazardType.road
        case 2:
            return Constants.HazardType.building
        default:
            return Constants.HazardType.general
        }
    }
    
    // CORE DATA NOTE: SOME SETTINGS MIGHT START AT 1, NOT 0 - OBJ-C DEFAULTS TO 0, SO CORE DATA UNSURE IF PREVIOUSLY FILLED IF USING 0
    enum MenuMapHydro: Int
    {
        case no = 1
        case yes = 2
    }
    func menuMapHydro(_ menuMapHydroInt: Int) -> Constants.MenuMapHydro
    {
        switch menuMapHydroInt
        {
        case 1:
            return Constants.MenuMapHydro.no
        case 2:
            return Constants.MenuMapHydro.yes
        default:
            return Constants.MenuMapHydro.yes
        }
    }
    enum MenuMapSpot: Int
    {
        case no = 1
        case yes = 2
    }
    func menuMapSpot(_ menuMapSpotInt: Int) -> Constants.MenuMapSpot
    {
        switch menuMapSpotInt
        {
        case 1:
            return Constants.MenuMapSpot.no
        case 2:
            return Constants.MenuMapSpot.yes
        default:
            return Constants.MenuMapSpot.yes
        }
    }
    enum MenuMapShelter: Int
    {
        case no = 1
        case yes = 2
    }
    func menuMapShelter(_ menuMapShelterInt: Int) -> Constants.MenuMapShelter
    {
        switch menuMapShelterInt
        {
        case 1:
            return Constants.MenuMapShelter.no
        case 2:
            return Constants.MenuMapShelter.yes
        default:
            return Constants.MenuMapShelter.yes
        }
    }
    enum MenuMapHazard: Int
    {
        case no = 1
        case yes = 2
    }
    func menuMapHazard(_ menuMapHazardInt: Int) -> Constants.MenuMapHazard
    {
        switch menuMapHazardInt
        {
        case 1:
            return Constants.MenuMapHazard.no
        case 2:
            return Constants.MenuMapHazard.yes
        default:
            return Constants.MenuMapHazard.yes
        }
    }
    enum MenuMapSOS: Int
    {
        case no = 1
        case yes = 2
    }
    func menuMapSOS(_ menuMapSOSInt: Int) -> Constants.MenuMapSOS
    {
        switch menuMapSOSInt
        {
        case 1:
            return Constants.MenuMapSOS.no
        case 2:
            return Constants.MenuMapSOS.yes
        default:
            return Constants.MenuMapSOS.yes
        }
    }
    enum MenuMapTraffic: Int
    {
        case no = 1
        case yes = 2
    }
    func menuMapTraffic(_ menuMapTrafficInt: Int) -> Constants.MenuMapTraffic
    {
        switch menuMapTrafficInt
        {
        case 1:
            return Constants.MenuMapTraffic.no
        case 2:
            return Constants.MenuMapTraffic.yes
        default:
            return Constants.MenuMapTraffic.yes
        }
    }
    enum MenuMapTimeFilter: Int
    {
        case day = 1
        case week = 2
        case month = 3
        case year = 4
    }
    func menuMapTimeFilter(_ menuMapTimeFilterInt: Int) -> Constants.MenuMapTimeFilter
    {
        // Evaluate the menuMapTimeFilter Integer received and convert it to the appropriate MenuMapTimeFilter
        switch menuMapTimeFilterInt
        {
        case 1:
            return Constants.MenuMapTimeFilter.day
        case 2:
            return Constants.MenuMapTimeFilter.week
        case 3:
            return Constants.MenuMapTimeFilter.month
        case 4:
            return Constants.MenuMapTimeFilter.year
        default:
            return Constants.MenuMapTimeFilter.day
        }
    }
    func menuMapTimeFilterSeconds(_ menuMapTimeFilter: Constants.MenuMapTimeFilter) -> Double
    {
        // Evaluate the menuTime Object received and convert it to the appropriate Integer representing seconds in recency
        switch menuMapTimeFilter
        {
        case Constants.MenuMapTimeFilter.day:
            return 60 * 60 * 24
        case Constants.MenuMapTimeFilter.week:
            return 60 * 60 * 24 * 7
        case Constants.MenuMapTimeFilter.month:
            return 60 * 60 * 24 * 31
        case Constants.MenuMapTimeFilter.year:
            return 60 * 60 * 24 * 365
        default:
            return 60 * 60 * 24
        }
    }
    
    struct Colors
    {
        static let standardBackground = UIColor.white
        static let standardBackgroundTransparent = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.8) //#FFF
        static let standardBackgroundGray = UIColor(red: 104/255, green: 104/255, blue: 104/255, alpha: 1.0) //#686868
        static let standardBackgroundGrayTransparent = UIColor(red: 104/255, green: 104/255, blue: 104/255, alpha: 0.6) //#686868
        static let standardBackgroundGrayUltraLight = UIColor(red: 242/255, green: 242/255, blue: 242/255, alpha: 1.0) //#F2F2F2
        static let standardBackgroundGrayUltraLightTransparent = UIColor(red: 242/255, green: 242/255, blue: 242/255, alpha: 0.3) //#F2F2F2
        
        static let colorRed = UIColor.red //UIColor(red: 235/255, green: 109/255, blue: 36/255, alpha: 0.4) //#EB6D24
        static let colorOrange = UIColor(red: 235/255, green: 109/255, blue: 36/255, alpha: 0.4) //#EB6D24
        static let colorOrangeOpaque = UIColor(red: 235/255, green: 109/255, blue: 36/255, alpha: 1.0) //#EB6D24
        static let colorYellow = UIColor(red: 249/255, green: 160/255, blue: 30/255, alpha: 0.4) //#F9A01E
        static let colorYellowOpaque = UIColor(red: 249/255, green: 160/255, blue: 30/255, alpha: 1.0) //#F9A01E
        static let colorBlue = UIColor(red: 68/255, green: 169/255, blue: 223/255, alpha: 0.4) //#44A9DF
        static let colorBlueOpaque = UIColor(red: 68/255, green: 169/255, blue: 223/255, alpha: 1.0) //#44A9DF
        
        static let colorStatusBar = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 1.0) //#FFF
//        static let colorStatusBarLight = UIColor(red: 187/255, green: 172/255, blue: 210/255, alpha: 1.0) //#BBACD2
        static let colorTopBar = UIColor(red: 138/255, green: 112/255, blue: 178/255, alpha: 1.0) //#8A70B2
        static let colorBorderGrayLight = UIColor(red: 204/255, green: 204/255, blue: 204/255, alpha: 1.0) //#CCC
        
        static let colorTextNavBar = UIColor.white
        static let colorTextLight = UIColor.white
        static let colorTextDark = UIColor(red: 38/255, green: 38/255, blue: 38/255, alpha: 1.0) //#262626
        static let colorGrayLight = UIColor(red: 204/255, green: 204/255, blue: 204/255, alpha: 1.0) //#CCC
        static let colorGrayDark = UIColor(red: 38/255, green: 38/255, blue: 38/255, alpha: 1.0) //#262626
        
        static let colorFacebookDarkBlue = UIColor(red: 59/255, green: 89/255, blue: 152/255, alpha: 1.0) //#3B5998
        
        static let recordButtonEdgeColor = UIColor(red: 96.0/255, green: 137.0/255, blue: 41.0/255, alpha: 1.0).cgColor //#608929
        static let recordButtonBorderColor = UIColor(red: 96.0/255, green: 137.0/255, blue: 41.0/255, alpha: 1.0).cgColor //#608929
        static let recordButtonColor = UIColor(red: 140.0/255, green: 197.0/255, blue: 63.0/255, alpha: 1.0) //#8CC53F
        static let recordButtonEdgeColorRecord = UIColor(red: 179/255, green: 0/255, blue: 0/255, alpha: 1.0).cgColor //# alpha: 0.3
        static let recordButtonBorderColorRecord = UIColor(red: 255/255, green: 0/255, blue: 0/255, alpha: 1.0).cgColor //# alpha: 1.0
        static let recordButtonColorRecord = UIColor(red: 255/255, green: 0/255, blue: 0/255, alpha: 1.0) //# alpha: 0.5
        
        static let colorCameraImageCellBackground = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.3) //#FFF
        
        static let spotInvisible = UIColor.clear
        static let spotGrayLight = UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 0.2) //#000000
        static let spotGray = UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 0.4) //#000000
        static let spotGrayOpaque = UIColor(red: 154/255, green: 154/255, blue: 154/255, alpha: 1.0) //#999999
        static let spotYellowLight = UIColor(red: 252/255, green: 178/255, blue: 73/255, alpha: 0.2) //#FCB249
        static let spotYellow = UIColor(red: 252/255, green: 178/255, blue: 73/255, alpha: 0.4) //#FCB249
        static let spotYellowMinorTransparent = UIColor(red: 252/255, green: 178/255, blue: 73/255, alpha: 0.7) //#FCB249
        static let spotYellowOpaque = UIColor(red: 252/255, green: 178/255, blue: 73/255, alpha: 1.0) //#FCB249
        static let spotYellowDark = UIColor(red: 201/255, green: 118/255, blue: 3/255, alpha: 1.0) //#C97603
    }
    
    struct Data
    {
        static var badgeNumber = 0
        static var attemptedLogin: Bool = false
        static var serverTries: Int = 0 // Used to prevent looping through failed requests
        static var serverLastRefresh: TimeInterval = Date().timeIntervalSince1970 // Used to prevent looping through failed requests in a short period of time
        static var lastCredentials: TimeInterval = Date().timeIntervalSince1970
        static var stillSendingSpot: Bool = false
        
        static var allSpot = [Spot]()
        static var allSpotRequest = [SpotRequest]()
        static var allHydro = [Hydro]()
        static var allShelter = [Shelter]()
        static var allHazard = [Hazard]()
        static var allSOS = [SOS]()
        
        static var spotCircles = [GMSCircle]()
        static var spotMarkers = [GMSMarker]()
        static var spotRequestMarkers = [GMSMarker]()
        static var hydroMarkers = [GMSMarker]()
        static var shelterMarkers = [GMSMarker]()
        static var hazardMarkers = [GMSMarker]()
        static var sosMarkers = [GMSMarker]()
        
        static var currentUser = User()
        static var allUsers = [User]()
        static var allUserBlockList = [String]()
    }
    
    struct Dim
    {
        static let cameraViewImageSize: CGFloat = 50
        static let cameraViewImageCellSize: CGFloat = 60
        
        static let userTableCellHeight: CGFloat = 50
        
        static let spotRadius: Double = 50 // in meters - see radius in Spot
        static let dotRadius: CGFloat = 5
    }
    
    struct Settings
    {
        static var appVersion = ""
        static let gKey = "AIzaSyBKa1WknlP96r0whyI6lFkLuJcPr97un5w"
        static let mapStyleUrl = URL(string: "mapbox://styles/tangojlabs/ciqwaddsl0005b7m0xwctftow")
        static let maxServerTries: Int = 5
        static let maxServerTryRefreshTime: Double = 5000 // in milliseconds
        
        static let mapViewDefaultLat: CLLocationDegrees = 29.758624
        static let mapViewDefaultLong: CLLocationDegrees = -95.366795
        static let mapViewDefaultZoom: Float = 10
        static let mapViewAngledZoom: Float = 16
        static let mapViewAngledDegrees: Double = 60.0
        
        static let mapMarkerSpot: Int32 = 1
        static let mapMarkerSpotRequest: Int32 = 2
        static let mapMarkerHydro: Int32 = 3
        static let mapMarkerShelter: Int32 = 4
        static let mapMarkerHazard: Int32 = 5
        static let mapMarkerSOS: Int32 = 6
        static let mapMyLocationTapZoom: Float = 18
        
        static var menuMapHydro: Constants.MenuMapHydro = Constants.MenuMapHydro.yes
        static var menuMapSpot: Constants.MenuMapSpot = Constants.MenuMapSpot.yes
        static var menuMapTraffic: Constants.MenuMapTraffic = Constants.MenuMapTraffic.yes
        static var menuMapShelter: Constants.MenuMapShelter = Constants.MenuMapShelter.yes
        static var menuMapHazard: Constants.MenuMapHazard = Constants.MenuMapHazard.yes
        static var menuMapSOS: Constants.MenuMapSOS = Constants.MenuMapSOS.yes
        static var menuMapTimeFilter: Constants.MenuMapTimeFilter = Constants.MenuMapTimeFilter.month
        
//        static var locationManagerSetting: LocationManagerSettingType = Constants.LocationManagerSettingType.significant
        static var statusBarStyle: UIStatusBarStyle = UIStatusBarStyle.lightContent
    }
    
    struct Strings
    {
        static let awsRegion = AWSRegionType.usEast1
        static let awsCognitoIdentityPoolID = "us-east-1:e831ff1a-257a-4363-abe0-ca6ef52a3c0d"
        
        static let S3BucketMedia = "harvey-media"
        
        static let fontDefault = "Helvetica-Light"
        static let fontDefaultLight = "Helvetica-UltraLight"
        static let fontDefaultThick = "Helvetica"
        static let fontAlt = "HelveticaNeue-Light"
        static let fontAltLight = "HelveticaNeue-UltraLight"
        static let fontAltThick = "HelveticaNeue"
        
        static let spotTableViewCellReuseIdentifier = "spotTableViewCell"
        static let userTableViewCellReuseIdentifier = "userTableViewCell"
        static let activityTableViewCellReuseIdentifier = "activityTableViewCell"
        
        static let imageHarvey = "Harvey.png"
        static let iconAccountGray = "icon_account_gray.png"
        static let iconAccountWhite = "icon_account_white.png"
        static let iconCamera = "icon_camera.png"
        static let iconCheckOrange = "icon_check_orange.png"
        static let iconCloseOrange = "icon_close_orange.png"
        static let iconCheckYellow = "icon_check_yellow.png"
        static let iconCheckYellowPin = "icon_check_yellow_pin.png"
        static let iconCloseYellow = "icon_close_yellow.png"
        static let iconCloseDark = "icon_close_dark.png"
        static let iconLocation = "icon_location.png"
        static let iconMenu = "icon_menu.png"
        static let iconProfile = "icon_profile.png"
        static let iconSearch = "icon_search.png"
        static let iconShareArrow = "icon_share_arrow.png"
        static let iconTraffic = "icon_traffic.png"
        static let iconHazard = "icon_hazard.png"
        static let iconPinsMulti = "icon_pins_multi.png"
        static let markerIconCamera = "marker_icon_camera_yellow.png"
        static let markerIconCameraTemp = "marker_icon_camera_temp_yellow.png"
        static let markerIconGauge = "marker_icon_gauge_blue_opaque.png"
        static let markerIconShelter = "marker_icon_shelter.png"
        static let markerIconSOS = "marker_icon_flag_red.png"
    }
    
    
//    struct Agreements
//    {
//        static let eula = ""
//        static let privacy = ""
//    }
}
