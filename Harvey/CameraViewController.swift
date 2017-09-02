//
//  CameraViewController.swift
//  Harvey
//
//  Created by Sean Hart on 8/29/17.
//  Copyright © 2017 tangojlabs. All rights reserved.
//

import AVFoundation
import GoogleMaps
import MapKit
import MobileCoreServices
import UIKit


protocol CameraViewControllerDelegate
{
    func reloadMapData()
}

class CameraViewController: UIViewController, AVCaptureFileOutputRecordingDelegate, MKMapViewDelegate, AWSRequestDelegate
{
    var cameraDelegate: CameraViewControllerDelegate?
    
    // MARK: PROPERTIES
    
    var loadingScreen: UIView!
    var captureSession: AVCaptureSession!
    var stillImageOutput: AVCaptureStillImageOutput?
    var captureDeviceInput: AVCaptureDeviceInput!
    var captureDevice: AVCaptureDevice!
    var previewLayer: AVCaptureVideoPreviewLayer!
    
    var imageRingView: UIView!
    
    var actionButton: UIView!
    var actionButtonLabel: UILabel!
    var actionButtonTapView: UIView!
    var loadingIndicator: UIActivityIndicatorView!
    
    var switchCameraView: UIView!
    var switchCameraLabel: UILabel!
    var switchCameraTapView: UIView!
    
    var exitCameraView: UIView!
    var exitCameraImage: UIImageView!
    var exitCameraTapView: UIView!
    
    var mapViewSize: CGFloat = 100 //Constants.Dim.recordResponseEdgeSize
    let imageRingDiameter: CGFloat = 300
    
    var screenSize: CGRect!
    var viewContainer: UIView!
    var cameraView: UIView!
    var mapViewContainer: UIView!
    var mapView: MKMapView!
//    var mapViewTapView1: UIView!
//    var mapViewTapView2: UIView!
//    var mapViewTapView3: UIView!
    
    // The Google Maps Coordinate Object for the current center of the map and the default Camera
    var mapCenter: CLLocationCoordinate2D!
    var defaultCamera: GMSCameraPosition!
    
    // Spot data
    var spot: Spot?
    var previewViewArray = [UIView]()
    var contentSelectedIDs = [String]()
    
    var useBackCamera = true
    
    
    // MARK: INITIALIZING
    
    // Do any additional setup after loading the view.
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        UIApplication.shared.isIdleTimerDisabled = true
        UIApplication.shared.isStatusBarHidden = true
        if self.navigationController != nil
        {
            self.navigationController!.isNavigationBarHidden = true
        }
        
        // Calculate the screenSize
        screenSize = UIScreen.main.bounds
        print("CVC - SCREEN SIZE: \(screenSize)")
        print("CVC - VIEW SIZE: \(self.view.frame)")
        
        // Add the loading screen, leaving NO room for the status bar at the top
        loadingScreen = UIView(frame: CGRect(x: 0, y: 0, width: screenSize.width, height: screenSize.height))
        loadingScreen.backgroundColor = UIColor.darkGray.withAlphaComponent(1.0)
        self.view.addSubview(loadingScreen)
        
        previewLayer = AVCaptureVideoPreviewLayer(layer: self.view.layer)
        
        viewContainer = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height))
        viewContainer.backgroundColor = UIColor.black
        viewContainer.clipsToBounds = false
        self.view.addSubview(viewContainer)
        
        // The cameraView should be square, but centered and filling the viewContainer, so offset the left side off the screen to compensate
        let leftOffset = (screenSize.height - screenSize.width) / 4
        cameraView = UIView(frame: CGRect(x: 0 - leftOffset, y: 0, width: screenSize.height, height: screenSize.height))
        cameraView.backgroundColor = UIColor.black
        cameraView.clipsToBounds = false
        viewContainer.addSubview(cameraView)
        print("CAMERA VIEW FRAME: \(cameraView.frame)")
        
        mapViewContainer = UIView(frame: CGRect(x: (viewContainer.frame.width / 2) - (mapViewSize / 2), y: viewContainer.frame.height - 5 - mapViewSize, width: mapViewSize, height: mapViewSize))
        mapViewContainer.backgroundColor = UIColor.clear
        mapViewContainer.layer.cornerRadius = mapViewSize / 2
        mapViewContainer.clipsToBounds = true
        viewContainer.addSubview(mapViewContainer)
        
        let initialLocation = CLLocation(latitude: Constants.Settings.mapViewDefaultLat, longitude: Constants.Settings.mapViewDefaultLong)
        let regionRadius: CLLocationDistance = 1000
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(initialLocation.coordinate, regionRadius * 2.0, regionRadius * 2.0)
        mapView = MKMapView(frame: CGRect(x: 0, y: 0, width: mapViewSize, height: mapViewSize))
        mapView.delegate = self
        mapView.showsUserLocation = true
        mapView.showsCompass = false
        mapView.showsScale = false
        mapView.showsTraffic = false
        mapView.showsPointsOfInterest = false
        mapView.isUserInteractionEnabled = false
        
        mapViewContainer.addSubview(mapView)
        print("CVC - MV SET 1: TRACKING MODE: \(mapView.userTrackingMode.rawValue)")
        mapView.setRegion(coordinateRegion, animated: true)
        mapView.userTrackingMode = MKUserTrackingMode.followWithHeading
        print("CVC - MV SET 2: TRACKING MODE: \(mapView.userTrackingMode.rawValue)")
        
        for subview in mapView.subviews
        {
            print("CVC - MAP SUBVIEW: \(subview.description)")
        }
        
        // Add the Text Button and overlaid Tap View for more tap coverage
        let actionButtonSize: CGFloat = 40
        actionButton = UIView(frame: CGRect(x: (viewContainer.frame.width / 2) - (actionButtonSize / 2), y: (viewContainer.frame.height / 2) - (actionButtonSize / 2), width: actionButtonSize, height: actionButtonSize))
        actionButton.layer.cornerRadius = 20
        actionButton.backgroundColor = UIColor.white.withAlphaComponent(0.3)
        actionButton.isHidden = true
        viewContainer.addSubview(actionButton)
        
        actionButtonLabel = UILabel(frame: CGRect(x: 5, y: 5, width: 30, height: 30))
        actionButtonLabel.backgroundColor = UIColor.clear
        actionButtonLabel.text = "\u{2713}" //"\u{1F5D1}"
        actionButtonLabel.textAlignment = .center
        actionButtonLabel.font = UIFont(name: "HelveticaNeue-UltraLight", size: 18)
        actionButton.addSubview(actionButtonLabel)
        
        actionButtonTapView = UIView(frame: CGRect(x: (viewContainer.frame.width / 2) - ((actionButtonSize + 20) / 2), y: (viewContainer.frame.height / 2) - ((actionButtonSize + 20) / 2), width: actionButtonSize + 20, height: actionButtonSize + 20))
        actionButtonTapView.layer.cornerRadius = (actionButtonSize + 20) / 2
        actionButtonTapView.backgroundColor = UIColor.clear
        viewContainer.addSubview(actionButtonTapView)
        
        loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: actionButton.frame.width, height: actionButton.frame.height))
        loadingIndicator.color = Constants.Colors.colorTextLight
        actionButton.addSubview(loadingIndicator)
        
        
        // Add the Switch Camera Button and overlaid Tap View for more tap coverage
        switchCameraView = UIView(frame: CGRect(x: viewContainer.frame.width - 60, y: viewContainer.frame.height - 60, width: 40, height: 40))
        switchCameraView.layer.cornerRadius = 20
        switchCameraView.backgroundColor = UIColor.white.withAlphaComponent(0.3)
        viewContainer.addSubview(switchCameraView)
        
        switchCameraLabel = UILabel(frame: CGRect(x: 5, y: 5, width: 30, height: 30))
        switchCameraLabel.backgroundColor = UIColor.clear
        switchCameraLabel.text = "\u{21ba}"
        switchCameraLabel.textAlignment = .center
        switchCameraLabel.font = UIFont(name: "HelveticaNeue-UltraLight", size: 18)
        switchCameraView.addSubview(switchCameraLabel)
        
        switchCameraTapView = UIView(frame: CGRect(x: viewContainer.frame.width - 70, y: viewContainer.frame.height - 70, width: 60, height: 60))
        switchCameraTapView.layer.cornerRadius = 30
        switchCameraTapView.backgroundColor = UIColor.clear
        viewContainer.addSubview(switchCameraTapView)
        
        // Add the Exit Camera Button and overlaid Tap View for more tap coverage
        exitCameraView = UIView(frame: CGRect(x: 20, y: viewContainer.frame.height - 60, width: 40, height: 40))
        exitCameraView.layer.cornerRadius = 20
        exitCameraView.backgroundColor = UIColor.white.withAlphaComponent(0.3)
        viewContainer.addSubview(exitCameraView)
        
//        exitCameraLabel = UILabel(frame: CGRect(x: 5, y: 5, width: 30, height: 30))
//        exitCameraLabel.backgroundColor = UIColor.clear
//        exitCameraLabel.text = "\u{274c}"
//        exitCameraLabel.textAlignment = .center
//        exitCameraLabel.textColor = Constants.Colors.colorTextLight
//        exitCameraLabel.font = UIFont(name: "HelveticaNeue-UltraLight", size: 18)
//        exitCameraView.addSubview(exitCameraLabel)
        
        exitCameraImage = UIImageView(frame: CGRect(x: 5, y: 5, width: 30, height: 30))
        exitCameraImage.contentMode = UIViewContentMode.scaleAspectFit
        exitCameraImage.clipsToBounds = true
        exitCameraImage.image = UIImage(named: Constants.Strings.iconCloseOrange)
        exitCameraView.addSubview(exitCameraImage)
        
        exitCameraTapView = UIView(frame: CGRect(x: 10, y: viewContainer.frame.height - 70, width: 60, height: 60))
        exitCameraTapView.layer.cornerRadius = 30
        exitCameraTapView.backgroundColor = UIColor.clear
        viewContainer.addSubview(exitCameraTapView)
        
        // Add the overall circle for the ring view
//        print("CVC - VC FRAME WIDTH: \(viewContainer.frame.width)")
//        print("CVC - VC FRAME HEIGHT: \(viewContainer.frame.height)")
        imageRingView = UIView(frame: CGRect(x: (viewContainer.frame.width / 2) - (imageRingDiameter / 2), y: (viewContainer.frame.height / 2) - (imageRingDiameter / 2), width: imageRingDiameter, height: imageRingDiameter))
        imageRingView.layer.cornerRadius = imageRingDiameter / 2
        imageRingView.backgroundColor = UIColor.white.withAlphaComponent(0.3)
        imageRingView.isHidden = true
        viewContainer.addSubview(imageRingView)
        
        // Add the path and mask to only show the outer ring
        let path = CGMutablePath()
        path.addArc(center: CGPoint(x: imageRingDiameter / 2, y: imageRingDiameter / 2), radius: (imageRingDiameter / 2) - Constants.Dim.cameraViewImageCellSize, startAngle: 0.0, endAngle: 2 * 3.14, clockwise: false)
        path.addRect(CGRect(x: 0, y: 0, width: imageRingDiameter, height: imageRingDiameter))
        
        let maskLayer = CAShapeLayer()
        maskLayer.path = path
        maskLayer.fillRule = kCAFillRuleEvenOdd
        imageRingView.layer.mask = maskLayer
        imageRingView.clipsToBounds = true
        
        adjustMapAttributionLabel()
        
//        print("CAMERA VIEW: HIDE LOADING SCREEN")
        self.view.sendSubview(toBack: self.loadingScreen)
//        clearTmpDirectory()
        
        // Request a random id for the Spot
        AWSPrepRequest(requestToCall: AWSGetRandomID(randomIdType: Constants.randomIdType.random_spot_id), delegate: self as AWSRequestDelegate).prepRequest()
    }
    
    // Perform setup before the view loads
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(true)
        
//        prepareSessionUseBackCamera(useBackCamera: true)
    }
    
    // These will occur after viewDidLoad
    override func viewDidAppear(_ animated: Bool)
    {
        adjustMapAttributionLabel()
        
        prepareSessionUseBackCamera(useBackCamera: true)
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func adjustMapAttributionLabel()
    {
        let attributionLabel: UIView = mapView.subviews[1]
        let labelWidth = attributionLabel.frame.width
        attributionLabel.frame = CGRect(x: (mapViewContainer.frame.width / 2) - (labelWidth / 2), y: attributionLabel.frame.minY, width: labelWidth, height: attributionLabel.frame.height)
    }
    
    
    // MARK: GESTURE METHODS
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        if let touch = touches.first
        {
            // Find which image the tap was inside
            var contentSelectedIndicator: Bool = false
            for (ivIndex, imageView) in previewViewArray.enumerated()
            {
                if imageView.frame.contains(touch.location(in: imageRingView))
                {
//                    print("CVC - IMAGEVIEW: \(imageView) CONTAINS SELECTION")
                    contentSelectedIndicator = true
                    
                    // Check whether the image has already been selected
                    var alreadySelected = false
                    for (index, _) in contentSelectedIDs.enumerated()
                    {
                        if index == ivIndex
                        {
//                            print("CVC - IMAGEVIEW CHECK 1")
                            alreadySelected = true
                            
                            // The image was selected for a second time, so de-select the image
                            contentSelectedIDs.remove(at: index)
                        }
                    }
//                    print("CVC - IMAGEVIEW CHECK 2")
                    if !alreadySelected
                    {
                        if let spot = spot
                        {
                            contentSelectedIDs.append(spot.spotContent[ivIndex].contentID)
                        }
                    }
//                    print("CVC - imageSelected COUNT 1: \(contentSelectedIDs.count)")
                }
            }
            
            // If at least one image has been selected, show the delete icon
            if contentSelectedIDs.count > 0
            {
                // An image was selected, so change the action button to the delete button
                actionButtonLabel.text = "\u{1F5D1}"
            }
            else
            {
                // No images are selected, so change the action button to the upload button
                actionButtonLabel.text = "\u{2713}"
            }
            
//            print("CVC - SWITCH BUTTON TAP: \(switchCameraTapView.frame.contains(touch.location(in: viewContainer)))")
//            print("CVC - SWITCH BUTTON TAP LOCATION: \(touch.location(in: viewContainer))")
//            print("CVC - SWITCH BUTTON FRAME: \(switchCameraTapView.frame)")
//            if mapViewTapView1.frame.contains(touch.location(in: mapViewContainer)) || mapViewTapView2.frame.contains(touch.location(in: mapViewContainer)) || mapViewTapView3.frame.contains(touch.location(in: mapViewContainer))
//            {
//                print("CVC - TOUCHED MAP")
//                mapTap()
//            }
            if mapViewContainer.frame.contains(touch.location(in: viewContainer))
            {
//                print("CVC - TOUCHED MAP")
                // Ensure that the user's current location is accessible - if not, don't take a picture
                if mapView.userLocation.coordinate.latitude != 0.0 || mapView.userLocation.coordinate.longitude != 0.0
                {
                    mapViewContainer.backgroundColor = Constants.Colors.recordButtonColorRecord
                    captureImage()
                }
                else
                {
                    // Inform the user that their location has not been acquired
                    let alert = UtilityFunctions().createAlertOkView("Unknown Location", message: "I'm sorry, your location cannot be determined.  Please wait until the map shows your current location.")
                    alert.show()
                }
            }
            else if exitCameraTapView.frame.contains(touch.location(in: viewContainer))
            {
//                print("TOUCHED EXIT CAMERA BUTTON")
                exitCamera()
            }
            else if switchCameraTapView.frame.contains(touch.location(in: viewContainer))
            {
//                print("TOUCHED SWITCH CAMERA BUTTON")
                switchCamera()
            }
            else if actionButtonTapView.frame.contains(touch.location(in: viewContainer))
            {
//                print("TOUCHED ACTION BUTTON")
                
                // If images are selected, the delete button is showing, so delete the selected images
                // Otherwise upload the images
                if contentSelectedIDs.count > 0
                {
                    deleteImages()
                }
                else
                {
                    if let spot = spot
                    {
                        // Upload the images
                        for content in spot.spotContent
                        {
                            if let image = content.image
                            {
//                        let imageURL = UtilityFunctions().generateImageUrl(image: content.contentImage, fileName: "\(content.contentID!).jpg")
//                        print("CVC - IMAGE URL FOR UPLOAD: \(imageURL.absoluteString)")
                                
                                let imagePath: String = NSTemporaryDirectory().stringByAppendingPathComponent(path: content.contentID! + ".jpg")
//                                print("CVC - IMAGE PATH: \(imagePath)")
                                let imageURL = URL(fileURLWithPath: imagePath)
                                
                                // Write the image to the file
//                        if let imageData = UIImagePNGRepresentation(content.contentImage)
                                if let imageData = UIImageJPEGRepresentation(image, 0.6)
                                {
                                    try? imageData.write(to: imageURL)
                                    AWSPrepRequest(requestToCall: AWSUploadMediaToBucket(bucket: Constants.Strings.S3BucketMedia, uploadKey: "\(content.contentID!).jpg", mediaURL: imageURL), delegate: self as AWSRequestDelegate).prepRequest()
                                    
                                    // Start the activity indicator and hide the send image
                                    self.actionButtonLabel.removeFromSuperview()
                                    self.loadingIndicator.startAnimating()
                                }
                            }
                        }
                    }
                }
            }
//            else if cameraView.frame.contains(touch.location(in: viewContainer)) && !contentSelectedIndicator
//            {
//                print("TOUCHED CAMERA")
//                captureImage()
//            }
            else if contentSelectedIndicator
            {
                // An image was selected, so highlight the image
                self.refreshImageRing()
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        if let touch = touches.first
        {
//            if mapViewTapView1.frame.contains(touch.location(in: mapViewContainer)) || mapViewTapView2.frame.contains(touch.location(in: mapViewContainer)) || mapViewTapView3.frame.contains(touch.location(in: mapViewContainer))
//            {
//                print("MAP TOUCH ENDED")
//            }
            if mapViewContainer.frame.contains(touch.location(in: viewContainer))
            {
//                print("MAP TOUCH ENDED")
                mapViewContainer.backgroundColor = UIColor.clear
            }
            else if switchCameraTapView.frame.contains(touch.location(in: viewContainer))
            {
//                print("SWITCH CAMERA BUTTON TOUCH ENDED")
            }
            else if actionButtonTapView.frame.contains(touch.location(in: viewContainer))
            {
//                print("ACTION BUTTON TOUCH ENDED")
            }
//            else if cameraView.frame.contains(touch.location(in: viewContainer))
//            {
//                print("CAMERA TOUCH ENDED")
//            }
        }
    }
    
    
    // MARK: MKMAPVIEW DELEGATE METHODS
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation)
    {
//        print("CVC - MV UPDATE 1: TRACKING MODE: \(mapView.userTrackingMode.rawValue)")
//        print("CVC - MV UPDATE: HEADING: \(userLocation.heading)")
    }
    
    
    // MARK: CUSTOM FUNCTIONS
    
    // Dismiss the latest View Controller presented from this VC
    // This version is used when the top VC is popped from a Nav Bar button
    func popViewController(_ sender: UIBarButtonItem)
    {
        popVC()
    }
    func popViewController()
    {
        popVC()
    }
    func popVC()
    {
        if let viewControllers = self.navigationController?.viewControllers
        {
            for controller in viewControllers
            {
                if controller is CameraViewController
                {
                    self.navigationController!.popViewController(animated: true)
                    
                    UIApplication.shared.isIdleTimerDisabled = false
                    UIApplication.shared.isStatusBarHidden = false
                    if self.navigationController != nil
                    {
                        self.navigationController!.isNavigationBarHidden = false
                    }
                }
            }
        }
//        self.navigationController!.popViewController(animated: true)
    }
    
    // Populate the Image Ring
    func refreshImageRing()
    {
        // Clear the imageRing and the imageViewArray
        imageRingView.subviews.forEach({ $0.removeFromSuperview() })
        previewViewArray = [UIView]()
        
        if let spot = spot
        {
//            print("CVC - IMAGE ARRAY COUNT: \(spot.spotContent.count)")
            if spot.spotContent.count > 0
            {
                imageRingView.isHidden = false
                actionButton.isHidden = false
                
                let cellSize: CGFloat = Constants.Dim.cameraViewImageCellSize
                let imageSize: CGFloat = Constants.Dim.cameraViewImageSize
                let imageCellGap: CGFloat = (cellSize - imageSize) / 2
                
                // Add the imageviews to the ring view
                for (index, content) in spot.spotContent.enumerated()
                {
                    let imageViewBase: CGPoint = basepointForCircleOfCircles(index, mainCircleRadius: imageRingDiameter / 2, radius: cellSize / 2, distance: (imageRingDiameter / 2) - (cellSize / 2)) // - (imageCellGap / 2))
                    let cellContainer = UIView(frame: CGRect(x: imageViewBase.x, y: imageViewBase.y, width: cellSize, height: cellSize))
                    cellContainer.layer.cornerRadius = cellSize / 2
                    cellContainer.clipsToBounds = true
                    
                    let imageContainer = UIView(frame: CGRect(x: imageCellGap, y: imageCellGap, width: imageSize, height: imageSize))
                    imageContainer.layer.cornerRadius = imageSize / 2
                    imageContainer.clipsToBounds = true
                    imageContainer.backgroundColor = UIColor.white
                    cellContainer.addSubview(imageContainer)
                    
                    let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: imageSize, height: imageSize))
                    imageView.image = content.image
                    imageContainer.addSubview(imageView)
                    
                    imageRingView.addSubview(cellContainer)
                    previewViewArray.append(cellContainer)
//                    print("CVC - IMAGE ARRAY INDEX: \(index)")
//                    print("CVC - contentSelected COUNT 2: \(contentSelectedIDs.count)")
                    
                    // If the index is stored in the imageSelect array, it has been selected, so highlight the image
                    for contentID in contentSelectedIDs
                    {
                        if contentID == content.contentID
                        {
                            cellContainer.backgroundColor = UIColor.red.withAlphaComponent(0.3)
                        }
                    }
                }
            }
            else
            {
                imageRingView.isHidden = true
                actionButton.isHidden = true
            }
        }
    }
    
    // Called when the map is tapped
    func mapTap()
    {
//        print("CVC - VIEW MAP VC")
        
//        // Create a back button and title for the Nav Bar
//        let backButtonItem = UIBarButtonItem(title: "\u{2190}",
//                                             style: UIBarButtonItemStyle.plain,
//                                             target: self,
//                                             action: #selector(CameraViewController.popViewController(_:)))
//        backButtonItem.tintColor = Constants.Colors.colorTextNavBar
        
//        let ncTitle = UIView(frame: CGRect(x: screenSize.width / 2 - 50, y: 10, width: 100, height: 40))
//        let ncTitleText = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 40))
//        ncTitleText.text = "Caption"
//        ncTitleText.font = UIFont(name: Constants.Strings.fontAlt, size: 14)
//        ncTitleText.textColor = Constants.Colors.colorTextNavBar
//        ncTitleText.textAlignment = .center
//        ncTitle.addSubview(ncTitleText)
        
        // Instantiate the TextViewController and pass the Images to the VC
        let mapVC = MapViewController()
        
//        // Assign the created Nav Bar settings to the Tab Bar Controller
//        mapVC.navigationItem.setLeftBarButton(backButtonItem, animated: true)
//        mapVC.navigationItem.titleView = ncTitle
        
        self.modalTransitionStyle = UIModalTransitionStyle.flipHorizontal
        self.present(mapVC, animated: true, completion: nil)
//        if let navController = self.navigationController
//        {
//            navController.pushViewController(mapVC, animated: true)
//        }
        
//        // Save an action in Core Data
//        CoreDataFunctions().logUserflowSave(viewController: NSStringFromClass(type(of: self)), action: #function.description)
    }
    
//    func triggerCloseCameraView()
//    {
//        print("TRIGGER CLOSE -> BACK TO VIEW CONTROLLER")
//        self.presentingViewController!.dismiss(animated: true, completion:
//            {
//                print("PARENT VC: \(String(describing: self.cameraDelegate))")
//                if let parentVC = self.cameraDelegate
//                {
//                    print("TRY TO CVC HIDE LOADING SCREEN")
//                    parentVC.triggerLoadingScreenOn(screenOn: false)
//                }
//        })
//    }
    
    // Called when the action button is pressed with images selected.  Deletes the selected images from the image array
    func deleteImages()
    {
        // Sort the array and then reverse the order so that the latest indexes are removed first
        contentSelectedIDs.sort()
        contentSelectedIDs.reverse()
        
        for contentID in contentSelectedIDs
        {
            if let spot = spot
            {
                for (index, content) in spot.spotContent.enumerated()
                {
                    if content.contentID == contentID
                    {
                        spot.spotContent.remove(at: index)
//                        print("CVC - REMOVED IMAGE AT INDEX: \(index)")
                    }
                }
            }
        }
        
        if let spot = spot
        {
            // Now run through the images and rename them based on order
            for (index, content) in spot.spotContent.enumerated()
            {
                content.contentID = spot.spotID + "-" + String(index + 1)
            }
            
            // Reset the imageSelected array, hide the delete button, and refresh the collection view
            contentSelectedIDs = [String]()
            actionButtonLabel.text = "\u{2713}"
            if spot.spotContent.count == 0
            {
                actionButton.isHidden = true
            }
            refreshImageRing()
        }
    }
    
    
    // MARK: CAMERA FUNCTIONS
    
    func prepareSessionUseBackCamera(useBackCamera: Bool)
    {
//        print("IN PREPARE SESSION")
        self.useBackCamera = useBackCamera
        
        if let devices = AVCaptureDevice.devices()
        {
            for device in devices
            {
                if ((device as AnyObject).hasMediaType(AVMediaTypeVideo))
                {
                    if (useBackCamera && (device as AnyObject).position == AVCaptureDevicePosition.back)
                    {
                        captureDevice = device as? AVCaptureDevice
                        beginSession()
                    }
                    else if (!useBackCamera && (device as AnyObject).position == AVCaptureDevicePosition.front)
                    {
                        captureDevice = device as? AVCaptureDevice
                        beginSession()
                    }
                }
            }
        }
    }
    
    func beginSession()
    {
        if captureDevice != nil
        {
            captureSession = AVCaptureSession()
            captureSession.sessionPreset = AVCaptureSessionPresetHigh
            
            if let currentInputs = captureSession.inputs
            {
                for inputIndex in currentInputs
                {
                    captureSession.removeInput(inputIndex as! AVCaptureInput)
                }
            }
            
            let err : NSError? = nil
            do
            {
                captureDeviceInput = try AVCaptureDeviceInput(device: captureDevice)
                captureSession.addInput(captureDeviceInput)
            }
            catch _
            {
                print("error: \(String(describing: err?.localizedDescription))")
            }
            
            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill // CHANGE THIS
            self.cameraView.layer.addSublayer(previewLayer)
            previewLayer?.frame = self.cameraView.layer.frame
//            print("CAMERA VIEW LAYER FRAME: \(self.cameraView.layer.frame)")
//            print("PREVIEW LAYER FRAME: \(String(describing: previewLayer?.frame))")
            
            stillImageOutput = AVCaptureStillImageOutput()
            captureSession.addOutput(stillImageOutput)
            if let orientationInt = AVCaptureVideoOrientation(rawValue: UIDevice.current.orientation.rawValue)
            {
//                print("ASSIGNING ORIENTATION 1: \(UIDevice.current.orientation.hashValue)")
                if stillImageOutput != nil
                {
                    stillImageOutput!.connection(withMediaType: AVMediaTypeVideo).videoOrientation = orientationInt
                }
            }
            
            captureSession.startRunning()
        }
    }
    
    func capture(_ captureOutput: AVCaptureFileOutput!, didStartRecordingToOutputFileAt fileURL: URL!, fromConnections connections: [Any]!)
    {
        print("Capture Delegate: Did START Recording to Output File")
    }
    
    func capture(_ captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAt outputFileURL: URL!, fromConnections connections: [Any]!, error: Error!)
    {
        print("Capture Delegate: Did FINISH Recording to Output File")
    }
    
    func switchCamera()
    {
        if self.useBackCamera
        {
            self.useBackCamera = false
        }
        else
        {
            self.useBackCamera = true
        }
        
        if let devices = AVCaptureDevice.devices()
        {
            for device in devices
            {
                if ((device as AnyObject).hasMediaType(AVMediaTypeVideo))
                {
                    if let currentInputs = captureSession.inputs
                    {
                        for inputIndex in currentInputs
                        {
                            captureSession.removeInput(inputIndex as! AVCaptureInput)
                        }
                    }
                    if (self.useBackCamera && (device as AnyObject).position == AVCaptureDevicePosition.back)
                    {
                        do
                        {
                            captureDevice = device as? AVCaptureDevice
                            captureDeviceInput = try AVCaptureDeviceInput(device: captureDevice)
                            captureSession.addInput(captureDeviceInput)
                            captureSession.removeOutput(stillImageOutput)
                            stillImageOutput = AVCaptureStillImageOutput()
                            captureSession.addOutput(stillImageOutput)
                            break
                        }
                        catch _
                        {
                            print("error")
                        }
                    }
                    else if (!self.useBackCamera && (device as AnyObject).position == AVCaptureDevicePosition.front)
                    {
                        do
                        {
                            captureDevice = device as? AVCaptureDevice
                            captureDeviceInput = try AVCaptureDeviceInput(device: captureDevice)
                            captureSession.addInput(captureDeviceInput)
                            captureSession.removeOutput(stillImageOutput)
                            stillImageOutput = AVCaptureStillImageOutput()
                            captureSession.addOutput(stillImageOutput)
                            break
                        }
                        catch _
                        {
                            print("error")
                        }
                    }
                }
            }
        }
    }
    
    func exitCamera()
    {
        popViewController()
    }
    
    
    // MARK: NAVIGATION & CUSTOM FUNCTIONS
    
    func captureImage()
    {
//        print("IN CAPTURE IMAGE")
        if let videoConnection = stillImageOutput!.connection(withMediaType: AVMediaTypeVideo)
        {
            stillImageOutput?.captureStillImageAsynchronously(from: videoConnection, completionHandler:
                { (sampleBuffer, error) -> Void in
                    // Process the image data (sampleBuffer) here to get an image file we can put in our captureImageView
                    if sampleBuffer != nil
                    {
                        let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer)
                        if let dataProvider = CGDataProvider(data: imageData! as CFData)
                        {
                            // UIImage orientation assumes a landscape (left) orientation
                            // We must correct this difference and set the image to default to portrait
                            
                            // Device orientation 1 : Portrait (Set as default)
                            let deviceOrientationValue = UIDevice.current.orientation.rawValue
                            var imageOrientationValue = 3
                            // Device orientation 2 : Portrait Upside Down
                            if deviceOrientationValue == 2
                            {
                                imageOrientationValue = 2
                            }
                            // Device orientation 3 : Landscape Left
                            else if deviceOrientationValue == 3
                            {
                                imageOrientationValue = 0
                            }
                            // Device orientation 4 : Landscape Right
                            else if deviceOrientationValue == 4
                            {
                                imageOrientationValue = 1
                            }
//                            print("CVC - DEVICE ORIENTATION (FOR IMAGE): \(UIDevice.current.orientation.rawValue)")
                            
                            // Resize the image into a square
                            let cgImageRef = CGImage(jpegDataProviderSource: dataProvider, decode: nil, shouldInterpolate: true, intent: CGColorRenderingIntent.defaultIntent)
                            let rawImage = UIImage(cgImage: cgImageRef!, scale: 1.0, orientation: UIImageOrientation.right)
                            let sizedImage = rawImage.cropToBounds(rawImage.size.width, height: rawImage.size.width)
//                            print("CVC - OLD IMAGE ORIENTATION: \(rawImage.imageOrientation.rawValue)")
                            
                            if let cgImage = sizedImage.cgImage
                            {
                                let image = UIImage(cgImage: cgImage, scale: 1.0, orientation: UIImageOrientation(rawValue: imageOrientationValue)!)
                                
                                if let spot = self.spot
                                {
                                    // Check how many images have already been added
                                    let imageCount = spot.spotContent.count
                                    
                                    if imageCount < 12
                                    {
                                        // Create the Spot Content
                                        let contentID = spot.spotID + "-" + String(imageCount + 1)
                                        let userCoords = self.mapView.userLocation.coordinate
                                        
                                        // Record the location for the spotContent
                                        let spotContent = SpotContent(contentID: contentID, spotID: spot.spotID, datetime: Date(), type: Constants.ContentType.image, lat: userCoords.latitude, lng: userCoords.longitude)
                                        spotContent.image = image
                                        spot.spotContent.append(spotContent)
                                        
                                        // Update the spot location
                                        self.spot!.lat = userCoords.latitude
                                        self.spot!.lng = userCoords.longitude
                                        
//                                    print("CVC - NEW IMAGE ORIENTATION: \(image.imageOrientation.rawValue)")
                                        self.refreshImageRing()
                                    }
                                }
                            }
                        }
                    }
            })
        }
    }
    
    // Correct Video Orientation Issues
    func orientationFromTransform(transform: CGAffineTransform) -> (orientation: UIImageOrientation, isPortrait: Bool)
    {
        var assetOrientation = UIImageOrientation.up
        var isPortrait = false
//        print("CHECK A: \(transform.a)")
//        print("CHECK B: \(transform.b)")
//        print("CHECK C: \(transform.c)")
//        print("CHECK D: \(transform.d)")
        if transform.a == 0 && transform.b == 1.0 && transform.c == -1.0 && transform.d == 0
        {
            assetOrientation = .right
            isPortrait = true
        }
        else if transform.a == 0 && transform.b == -1.0 && transform.c == 1.0 && transform.d == 0
        {
            assetOrientation = .left
            isPortrait = true
        }
        else if transform.a == 1.0 && transform.b == 0 && transform.c == 0 && transform.d == 1.0
        {
            assetOrientation = .up
        }
        else if transform.a == -1.0 && transform.b == 0 && transform.c == 0 && transform.d == -1.0
        {
            assetOrientation = .down
        }
//        print("assetOrientation: \(assetOrientation.hashValue)")
        return (assetOrientation, isPortrait)
    }
    
    func clearTmpDirectory()
    {
        do
        {
            let tmpDirectory = try FileManager.default.contentsOfDirectory(atPath: NSTemporaryDirectory())
            try tmpDirectory.forEach
            { file in
                let path = String.init(format: "%@%@", NSTemporaryDirectory(), file)
                try FileManager.default.removeItem(atPath: path)
            }
        }
        catch
        {
            print(error)
        }
    }
    
    // The equation to find the top-left edge of a circle in the circle of circles
    func basepointForCircleOfCircles(_ circle: Int, mainCircleRadius: CGFloat, radius: CGFloat, distance: CGFloat) -> CGPoint
    {
        let numberOfCirclesInCircle: Int = 12
        let angle: CGFloat = (2.0 * CGFloat(circle) * CGFloat.pi) / CGFloat(numberOfCirclesInCircle)
        let radian90: CGFloat = CGFloat(90) * (CGFloat.pi / CGFloat(180))
        let radian45: CGFloat = CGFloat(45) * (CGFloat.pi / CGFloat(180))
        let circleH: CGFloat = radius / cos(radian45)
//        print("CVC - RADIAN90: \(radian90), CIRCLE HYPOTENUSE: \(circleH)")
        let adjustRadian: CGFloat = atan((circleH / 2) / mainCircleRadius) * 2
//        print("CVC - RADIAN45: \(radian45), ADJUST RADIAN: \(adjustRadian)")
        let x = round(mainCircleRadius + distance * cos(angle - radian90 - adjustRadian) - radius)
        let y = round(mainCircleRadius + distance * sin(angle - radian90 - adjustRadian) - radius)
        
//        print("CVC - CIRCLE BASEPOINT FOR CIRCLE: \(circle): \(x), \(y), angle: \(angle), radius: \(radius), distance: \(distance)")
        
        return CGPoint(x: x, y: y)
    }
    
    // MARK: AWS DELEGATE METHODS
    
    func showLoginScreen()
    {
        print("CVC - SHOW LOGIN SCREEN")
    }
    
    func processAwsReturn(_ objectType: AWSRequestObject, success: Bool)
    {
//        print("CVC - processAwsReturn:")
        print(objectType)
        print(success)
        DispatchQueue.main.async(execute:
            {
                // Process the return data based on the method used
                switch objectType
                {
                case let awsGetRandomID as AWSGetRandomID:
                    if success
                    {
                        if let randomID = awsGetRandomID.randomID
                        {
                            if awsGetRandomID.randomIdType == Constants.randomIdType.random_spot_id
                            {
                                // Current user coords
                                let userCoords = self.mapView.userLocation.coordinate
                                
                                // Create the Spot
                                self.spot = Spot(spotID: randomID, userID: Constants.Data.currentUser.userID, datetime: Date(), lat: userCoords.latitude, lng: userCoords.longitude)
                            }
                        }
                    }
                    else
                    {
                        // Show the error message
                        let alertController = UIAlertController(title: "Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.", preferredStyle: UIAlertControllerStyle.alert)
                        let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default)
                        { (result : UIAlertAction) -> Void in
                            print("OK")
                            self.popViewController()
                        }
                        alertController.addAction(okAction)
                        alertController.show()
                        
                        // Stop the activity indicator and shoow the send image
                        self.loadingIndicator.stopAnimating()
                        self.actionButton.addSubview(self.actionButtonLabel)
                    }
                case _ as AWSUploadMediaToBucket:
                    if success
                    {
//                        print("CVC - AWSUploadMediaToBucket SUCCESS")
                        
                        // At least one of the images was successfully uploaded, so upload the Spot data
                        AWSPrepRequest(requestToCall: AWSPutSpotData(spot: self.spot), delegate: self as AWSRequestDelegate).prepRequest()
                    }
                    else
                    {
                        // Show the error message
                        let alert = UtilityFunctions().createAlertOkView("Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
                        alert.show()
                        
                        // Stop the activity indicator and shoow the send image
                        self.loadingIndicator.stopAnimating()
                        self.actionButton.addSubview(self.actionButtonLabel)
                    }
                case _ as AWSPutSpotData:
                    if success
                    {
//                        print("CVC - AWSPutSpotData SUCCESS")
                        
                        // Notify the parent view that the AWS Put completed
                        if let parentVC = self.cameraDelegate
                        {
                            parentVC.reloadMapData()
                        }
                        
                        // Stop the activity indicator and shoow the send image
                        self.loadingIndicator.stopAnimating()
                        self.actionButton.addSubview(self.actionButtonLabel)
                        
                        // Return to the parentVC
                        self.popViewController()
                    }
                    else
                    {
                        // Show the error message
                        let alert = UtilityFunctions().createAlertOkView("Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
                        alert.show()
                        
                        // Stop the activity indicator and shoow the send image
                        self.loadingIndicator.stopAnimating()
                        self.actionButton.addSubview(self.actionButtonLabel)
                    }
                default:
                    print("MVC-DEFAULT: THERE WAS AN ISSUE WITH THE DATA RETURNED FROM AWS")
                    
                    // Show the error message
                    let alertController = UIAlertController(title: "Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.", preferredStyle: UIAlertControllerStyle.alert)
                    let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default)
                    { (result : UIAlertAction) -> Void in
                        print("OK")
                        self.popViewController()
                    }
                    alertController.addAction(okAction)
                    alertController.show()
                }
        })
    }
}

