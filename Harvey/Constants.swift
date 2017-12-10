//
//  Constants.swift
//  Harvey
//
//  Created by Sean Hart on 8/28/17.
//  Copyright © 2017 TangoJ Labs, LLC. All rights reserved.
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
        case random_structure_id = "random_structure_id"
        case random_repair_id = "random_repair_id"
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
    enum MenuMapStructure: Int
    {
        case no = 1
        case yes = 2
    }
    func menuMapStructure(_ menuMapStructureInt: Int) -> Constants.MenuMapStructure
    {
        switch menuMapStructureInt
        {
        case 1:
            return Constants.MenuMapStructure.no
        case 2:
            return Constants.MenuMapStructure.yes
        default:
            return Constants.MenuMapStructure.yes
        }
    }
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
            return Constants.MenuMapTraffic.no
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
    
    enum Experience: Int
    {
        case none = 0
        case some = 1
        case expert = 2
    }
    func experience(_ experienceInt: Int) -> Constants.Experience
    {
        // Evaluate the experienceInt Integer received and convert it to the appropriate Experience
        switch experienceInt
        {
        case 0:
            return Constants.Experience.none
        case 1:
            return Constants.Experience.some
        case 2:
            return Constants.Experience.expert
        default:
            return Constants.Experience.none
        }
    }
    func experienceTitle(_ experienceInt: Int) -> String
    {
        // Evaluate the experienceInt Integer received and convert it to the appropriate String title
        switch experienceInt
        {
        case 0:
            return "No\nExperience"
        case 1:
            return "Some\nExperience"
        case 2:
            return "Expert"
        default:
            return "No\nExperience"
        }
    }
    func experienceColor(_ experienceInt: Int) -> UIColor
    {
        // Evaluate the experienceInt Integer received and convert it to the appropriate background color
        switch experienceInt
        {
        case 0:
            return Constants.Colors.spotGrayLight
        case 1:
            return Constants.Colors.colorYellow
        case 2:
            return Constants.Colors.colorBlue
        default:
            return Constants.Colors.spotGrayLight
        }
    }
    
    enum StructureType: Int
    {
        case residence = 0
        case retail = 1
        case office = 2
        case other = 3
    }
    func structureType(_ structureTypeInt: Int) -> Constants.StructureType
    {
        // Evaluate the structureTypeInt Integer received and convert it to the appropriate Structure
        switch structureTypeInt
        {
        case 0:
            return Constants.StructureType.residence
        case 1:
            return Constants.StructureType.retail
        case 2:
            return Constants.StructureType.office
        case 3:
            return Constants.StructureType.other
        default:
            return Constants.StructureType.other
        }
    }
    
    enum StructureStage: Int
    {
        case na = 0
        case needhelp = 1
        case repairing = 2
        case complete = 3
        case other = 4
    }
    func structureStage(_ structureStageInt: Int) -> Constants.StructureStage
    {
        // Evaluate the structureStageInt Integer received and convert it to the appropriate StructureStage
        switch structureStageInt
        {
        case 0:
            return Constants.StructureStage.na
        case 1:
            return Constants.StructureStage.needhelp
        case 2:
            return Constants.StructureStage.repairing
        case 3:
            return Constants.StructureStage.complete
        case 4:
            return Constants.StructureStage.other
        default:
            return Constants.StructureStage.na
        }
    }
//    func structureStageTitle(_ structureStageInt: Int) -> String
//    {
//        // Evaluate the structureStageInt Integer received and convert it to the appropriate String title
//        switch structureStageInt
//        {
//        case 0:
//            return "No\nExperience"
//        case 1:
//            return "Some\nExperience"
//        case 2:
//            return "Repair in Progress"
//        case 3:
//            return "Repair Completed"
//        default:
//            return "No\nExperience"
//        }
//    }
//    func structureStageColor(_ structureStageInt: Int) -> UIColor
//    {
//        // Evaluate the structureStageInt Integer received and convert it to the appropriate background color
//        switch structureStageInt
//        {
//        case 0:
//            return Constants.Colors.spotGrayLight
//        case 1:
//            return Constants.Colors.colorOrange
//        case 2:
//            return Constants.Colors.colorYellow
//        case 3:
//            return Constants.Colors.colorBlue
//        default:
//            return Constants.Colors.spotGrayLight
//        }
//    }
    
    enum RepairStage: Int
    {
        case na = 0
        case needhelp = 1
        case repairing = 2
        case complete = 3
        case other = 4
    }
    func repairStage(_ repairStageInt: Int) -> Constants.RepairStage
    {
        // Evaluate the repairStageInt Integer received and convert it to the appropriate RepairStage
        switch repairStageInt
        {
        case 0:
            return Constants.RepairStage.na
        case 1:
            return Constants.RepairStage.needhelp
        case 2:
            return Constants.RepairStage.repairing
        case 3:
            return Constants.RepairStage.complete
        case 4:
            return Constants.RepairStage.other
        default:
            return Constants.RepairStage.na
        }
    }
    func repairStageToggle(_ currentRepairStage: Constants.RepairStage) -> Constants.RepairStage
    {
        // Evaluate the currentRepairStage received and convert it to the next RepairStage
        switch currentRepairStage
        {
        case RepairStage.na:
            return Constants.RepairStage.needhelp
        case RepairStage.needhelp:
            return Constants.RepairStage.repairing
        case RepairStage.repairing:
            return Constants.RepairStage.complete
        case RepairStage.complete:
            return Constants.RepairStage.other
        case RepairStage.other:
            return Constants.RepairStage.na
//        default:
//            return Constants.RepairStage.na
        }
    }
    func repairStageTitle(_ repairStageInt: Int) -> String
    {
        // Evaluate the repairStageInt Integer received and convert it to the appropriate String title
        switch repairStageInt
        {
        case 0:
            return "no repair needed"
        case 1:
            return "need help"
        case 2:
            return "repairing"
        case 3:
            return "complete"
        case 4:
            return "other stage"
        default:
            return "no repair needed"
        }
    }
    func repairStageColor(_ repairStageInt: Int) -> UIColor
    {
        // Evaluate the repairStageInt Integer received and convert it to the appropriate background color
        switch repairStageInt
        {
        case 0:
            return Constants.Colors.repair0
        case 1:
            return Constants.Colors.repair1
        case 2:
            return Constants.Colors.repair2
        case 3:
            return Constants.Colors.repair3
        case 4:
            return Constants.Colors.repair4
        default:
            return Constants.Colors.repair0
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
        
        static let repair0 = UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 1.0) //#FFFFFF
        static let repair1 = UIColor(red: 179/255, green: 71/255, blue: 0/255, alpha: 1.0) //#B34700
        static let repair2 = UIColor(red: 179/255, green: 143/255, blue: 0/255, alpha: 1.0) //#B38F00
        static let repair3 = UIColor(red: 36/255, green: 143/255, blue: 36/255, alpha: 1.0) //#248F24
        static let repair4 = UIColor(red: 26/255, green: 26/255, blue: 26/255, alpha: 1.0) //#1A1A1A
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
        
        static var structureMarkers = [GMSMarker]()
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
        
        static var skills = [Skill]()
        static var structures = [Structure]()
        static var structureUsers = [StructureUser]()
        static var repairs = [Repair]()
    }
    
    struct Dim
    {
        static let cameraViewImageSize: CGFloat = 50
        static let cameraViewImageCellSize: CGFloat = 60
        
        static let userTableCellHeight: CGFloat = 50
        static let repairCellHeight: CGFloat = 60
        static let skillCellHeight: CGFloat = 100
        
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
        static let requestTimeout = 20.0
        
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
        static let mapMarkerStructure: Int32 = 6
        static let mapMarkerSOS: Int32 = 7
        static let mapMyLocationTapZoom: Float = 18
        
        static var menuMapStructure: Constants.MenuMapStructure = Constants.MenuMapStructure.yes
        static var menuMapSpot: Constants.MenuMapSpot = Constants.MenuMapSpot.yes
        static var menuMapTraffic: Constants.MenuMapTraffic = Constants.MenuMapTraffic.no
        static var menuMapHazard: Constants.MenuMapHazard = Constants.MenuMapHazard.yes
        static var menuMapHydro: Constants.MenuMapHydro = Constants.MenuMapHydro.yes
        static var menuMapShelter: Constants.MenuMapShelter = Constants.MenuMapShelter.yes
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
        static let profileTabSkillTableViewCellReuseIdentifier = "profileTabSkillTableViewCell"
        static let profileTabStructureTableViewCellReuseIdentifier = "profileTabStructureTableViewCell"
        static let profileRepairTableViewCellReuseIdentifier = "profileRepairTableViewCell"
        static let repairImageTableViewCellReuseIdentifier = "repairImageTableViewCell"
        static let structureTableViewCellReuseIdentifier = "structureTableViewCellReuseIdentifier"
        
        static let imageHarvey = "Harvey.png"
        static let iconAccountGray = "icon_account_gray.png"
        static let iconAccountWhite = "icon_account_white.png"
        static let iconCamera = "icon_camera.png"
        static let iconCheckHazard = "icon_check_hazard.png"
        static let iconCheckOrange = "icon_check_orange.png"
        static let iconCloseOrange = "icon_close_orange.png"
        static let iconCheckYellow = "icon_check_yellow.png"
        static let iconCheckYellowPin = "icon_check_yellow_pin.png"
        static let iconCloseYellow = "icon_close_yellow.png"
        static let iconCloseDark = "icon_close_dark.png"
        static let iconHouse = "house.png"
        static let iconLocation = "icon_location.png"
        static let iconMenu = "icon_menu.png"
        static let iconProfile = "icon_profile.png"
        static let iconSearch = "icon_search.png"
        static let iconSettings = "icon_settings.png"
        static let iconShareArrow = "icon_share_arrow.png"
        static let iconTools = "tools.png"
        static let iconTraffic = "icon_traffic.png"
        static let iconHazard = "icon_hazard.png"
        static let iconPinsMulti = "icon_pins_multi2.png"
        static let markerIconCamera = "marker_icon_camera_yellow.png"
        static let markerIconCameraTemp = "marker_icon_camera_temp_yellow.png"
        static let markerIconGauge = "marker_icon_gauge_blue_opaque.png"
        static let markerIconStructure = "marker_icon_structure.png"
        static let markerIconStructureSkillMatch = "marker_icon_structure_skill_match.png"
        static let markerIconShelter = "marker_icon_shelter.png"
        static let markerIconSOS = "marker_icon_flag_red.png"
        
//        static let urlRandomId = "http://192.168.1.7:5000/app/randomid"
//        static let urlLogin = "http://192.168.1.7:5000/app/login"
//        static let urlSettings = "http://192.168.1.7:5000/app/settings"
//        static let urlUserCheck = "http://192.168.1.7:5000/app/user/check"
//        static let urlUserUpdate = "http://192.168.1.7:5000/app/user/update"
//        static let urlUserQueryActive = "http://192.168.1.7:5000/app/user/query/active"
//        static let urlUserConnectionQuery = "http://192.168.1.7:5000/app/user/connection/query"
//        static let urlUserConnectionPut = "http://192.168.1.7:5000/app/user/connection/put"
//        static let urlSkillQuery = "http://192.168.1.7:5000/app/skill/query"
//        static let urlSkillPut = "http://192.168.1.7:5000/app/skill/put"
//        static let urlStructureQuery = "http://192.168.1.7:5000/app/structure/query"
//        static let urlStructurePut = "http://192.168.1.7:5000/app/structure/put"
//        static let urlStructureDelete = "http://192.168.1.7:5000/app/structure/delete"
//        static let urlStructureUserQuery = "http://192.168.1.7:5000/app/structure-user/query"
//        static let urlStructureUserPut = "http://192.168.1.7:5000/app/structure-user/put"
//        static let urlRepairQuery = "http://192.168.1.7:5000/app/repair/query"
//        static let urlRepairPut = "http://192.168.1.7:5000/app/repair/put"
//        static let urlSpotQueryActive = "http://192.168.1.7:5000/app/spot/query/active"
//        static let urlSpotPut = "http://192.168.1.7:5000/app/spot/put"
//        static let urlSpotContentStatusUpdate = "http://192.168.1.7:5000/app/spot/spotcontent/statusupdate"
//        static let urlSpotRequestPut = "http://192.168.1.7:5000/app/spot/spotrequest/put"
//        static let urlShelterQueryActive = "http://192.168.1.7:5000/app/shelter/query/active"
//        static let urlHazardQueryActive = "http://192.168.1.7:5000/app/hazard/query/active"
//        static let urlHazardPut = "http://192.168.1.7:5000/app/hazard/put"
//        static let urlHydroQuery = "http://192.168.1.7:5000/app/hydro/query/active"
        
//        static let urlRandomId = "http://127.0.0.1:5000/app/randomid"
//        static let urlLogin = "http://127.0.0.1:5000/app/login"
//        static let urlSettings = "http://127.0.0.1:5000/app/settings"
//        static let urlUserCheck = "http://127.0.0.1:5000/app/user/check"
//        static let urlUserUpdate = "http://127.0.0.1:5000/app/user/update"
//        static let urlUserQueryActive = "http://127.0.0.1:5000/app/user/query/active"
//        static let urlUserConnectionQuery = "http://127.0.0.1:5000/app/user/connection/query"
//        static let urlUserConnectionPut = "http://127.0.0.1:5000/app/user/connection/put"
//        static let urlSkillQuery = "http://127.0.0.1:5000/app/skill/query"
//        static let urlSkillPut = "http://127.0.0.1:5000/app/skill/put"
//        static let urlStructureQuery = "http://127.0.0.1:5000/app/structure/query"
//        static let urlStructurePut = "http://127.0.0.1:5000/app/structure/put"
//        static let urlStructureDelete = "http://127.0.0.1:5000/app/structure/delete"
//        static let urlStructureUserQuery = "http://127.0.0.1:5000/app/structure-user/query"
//        static let urlStructureUserPut = "http://127.0.0.1:5000/app/structure-user/put"
//        static let urlRepairQuery = "http://127.0.0.1:5000/app/repair/query"
//        static let urlRepairPut = "http://127.0.0.1:5000/app/repair/put"
//        static let urlSpotQueryActive = "http://127.0.0.1:5000/app/spot/query/active"
//        static let urlSpotPut = "http://127.0.0.1:5000/app/spot/put"
//        static let urlSpotContentStatusUpdate = "http://127.0.0.1:5000/app/spot/spotcontent/statusupdate"
//        static let urlSpotRequestPut = "http://127.0.0.1:5000/app/spot/spotrequest/put"
//        static let urlShelterQueryActive = "http://127.0.0.1:5000/app/shelter/query/active"
//        static let urlHazardQueryActive = "http://127.0.0.1:5000/app/hazard/query/active"
//        static let urlHazardPut = "http://127.0.0.1:5000/app/hazard/put"
//        static let urlHydroQuery = "http://127.0.0.1:5000/app/hydro/query/active"
        
        static let urlRandomId = "https://www.harveytown.org/app/randomid"
        static let urlLogin = "https://www.harveytown.org/app/login"
        static let urlSettings = "https://www.harveytown.org/app/settings"
        static let urlUserCheck = "https://www.harveytown.org/app/user/check"
        static let urlUserUpdate = "https://www.harveytown.org/app/user/update"
        static let urlUserQueryActive = "https://www.harveytown.org/app/user/query/active"
        static let urlUserConnectionQuery = "https://www.harveytown.org/app/user/connection/query"
        static let urlUserConnectionPut = "https://www.harveytown.org/app/user/connection/put"
        static let urlSkillQuery = "https://www.harveytown.org/app/skill/query"
        static let urlSkillPut = "https://www.harveytown.org/app/skill/put"
        static let urlStructureQuery = "https://www.harveytown.org/app/structure/query"
        static let urlStructurePut = "https://www.harveytown.org/app/structure/put"
        static let urlStructureDelete = "https://www.harveytown.org/app/structure/delete"
        static let urlStructureUserQuery = "https://www.harveytown.org/app/structure-user/query"
        static let urlStructureUserPut = "https://www.harveytown.org/app/structure-user/put"
        static let urlRepairQuery = "https://www.harveytown.org/app/repair/query"
        static let urlRepairPut = "https://www.harveytown.org/app/repair/put"
        static let urlSpotQueryActive = "https://www.harveytown.org/app/spot/query/active"
        static let urlSpotPut = "https://www.harveytown.org/app/spot/put"
        static let urlSpotContentStatusUpdate = "https://www.harveytown.org/app/spot/spotcontent/statusupdate"
        static let urlSpotRequestPut = "https://www.harveytown.org/app/spot/spotrequest/put"
        static let urlShelterQueryActive = "https://www.harveytown.org/app/shelter/query/active"
        static let urlHazardQueryActive = "https://www.harveytown.org/app/hazard/query/active"
        static let urlHazardPut = "https://www.harveytown.org/app/hazard/put"
        static let urlHydroQuery = "https://www.harveytown.org/app/hydro/query/active"
    }
    
    
//    struct Agreements
//    {
//        static let eula = ""
//        static let privacy = ""
//    }
}
