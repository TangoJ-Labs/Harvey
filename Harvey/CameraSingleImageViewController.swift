//
//  CameraSingleImageViewController.swift
//  Harvey
//
//  Created by Sean Hart on 9/18/17.
//  Copyright © 2017 TangoJ Labs, LLC. All rights reserved.
//

import AVFoundation
import GoogleMaps
import MapKit
import MobileCoreServices
import UIKit


class CameraSingleImageViewController: UIViewController, AVCaptureFileOutputRecordingDelegate, MKMapViewDelegate, AWSRequestDelegate
{
    var cameraDelegate: CameraViewControllerDelegate?
    
    // MARK: PROPERTIES
    
    var loadingScreen: UIView!
    var captureSession: AVCaptureSession!
    var stillImageOutput: AVCaptureStillImageOutput?
    var captureDeviceInput: AVCaptureDeviceInput!
    var captureDevice: AVCaptureDevice!
    var previewLayer: AVCaptureVideoPreviewLayer!
    
    var viewContainer: UIView!
    var cameraView: UIView!
    var mapViewContainer: UIView!
    var mapView: MKMapView!
    
    var imageReviewView: UIView!
    var imageReviewImage: UIImageView!
    var confirmButton: UIView!
    var confirmButtonLabel: UILabel!
    var confirmButtonTapView: UIView!
    var confirmLoadingIndicator: UIActivityIndicatorView!
    var cancelButton: UIView!
    var cancelButtonLabel: UILabel!
    var cancelButtonTapView: UIView!
    
    var exitCameraView: UIView!
    var exitCameraImage: UIImageView!
    var exitCameraTapView: UIView!
    
    // The Google Maps Coordinate Object for the current center of the map and the default Camera
    var mapCenter: CLLocationCoordinate2D!
    var defaultCamera: GMSCameraPosition!
    
    var screenSize: CGRect!
    var mapViewSize: CGFloat = 100
    let reviewButtonHeight: CGFloat = 60
    
    var newStructure: Bool = true
    var structure = Structure()
//    var imageID: String?
//    var image: UIImage?
//    var datetime: Date?
//    var coords: CLLocationCoordinate2D?
    
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
        print("CSIVC - SCREEN SIZE: \(screenSize)")
        print("CSIVC - VIEW SIZE: \(self.view.frame)")
        
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
        print("CSIVC - CAMERA VIEW FRAME: \(cameraView.frame)")
        
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
        print("CSIVC - MV SET 1: TRACKING MODE: \(mapView.userTrackingMode.rawValue)")
        mapView.setRegion(coordinateRegion, animated: true)
        mapView.userTrackingMode = MKUserTrackingMode.followWithHeading
        print("CSIVC - MV SET 2: TRACKING MODE: \(mapView.userTrackingMode.rawValue)")
        
        for subview in mapView.subviews
        {
            print("CSIVC - MAP SUBVIEW: \(subview.description)")
        }
        
        // Add the Exit Camera Button and overlaid Tap View for more tap coverage
        exitCameraView = UIView(frame: CGRect(x: 20, y: viewContainer.frame.height - 60, width: 40, height: 40))
        exitCameraView.layer.cornerRadius = 20
        exitCameraView.backgroundColor = UIColor.white.withAlphaComponent(0.3)
        viewContainer.addSubview(exitCameraView)
        
        exitCameraImage = UIImageView(frame: CGRect(x: 5, y: 5, width: 30, height: 30))
        exitCameraImage.contentMode = UIViewContentMode.scaleAspectFit
        exitCameraImage.clipsToBounds = true
        exitCameraImage.image = UIImage(named: Constants.Strings.iconCloseOrange)
        exitCameraView.addSubview(exitCameraImage)
        
        exitCameraTapView = UIView(frame: CGRect(x: 10, y: viewContainer.frame.height - 70, width: 60, height: 60))
        exitCameraTapView.layer.cornerRadius = 30
        exitCameraTapView.backgroundColor = UIColor.clear
        viewContainer.addSubview(exitCameraTapView)
        
        // Add the image review box
        imageReviewView = UIView(frame: CGRect(x: (viewContainer.frame.width / 2) - 130, y: 100, width: 260, height: 260 + reviewButtonHeight))
        imageReviewView.backgroundColor = Constants.Colors.standardBackground
        
        imageReviewImage = UIImageView(frame: CGRect(x: 0, y: 0, width: imageReviewView.frame.width, height: imageReviewView.frame.height - reviewButtonHeight))
        imageReviewImage.contentMode = UIViewContentMode.scaleAspectFill
        imageReviewImage.clipsToBounds = true
        imageReviewView.addSubview(imageReviewImage)
        
        confirmButton = UIView(frame: CGRect(x: imageReviewView.frame.width / 2, y: imageReviewView.frame.height - reviewButtonHeight, width: imageReviewView.frame.width / 2, height: reviewButtonHeight))
        confirmButton.backgroundColor = Constants.Colors.colorGrayLight
        imageReviewView.addSubview(confirmButton)
        
        confirmButtonLabel = UILabel(frame: CGRect(x: 5, y: 5, width: confirmButton.frame.width - 10, height: confirmButton.frame.height - 10))
        confirmButtonLabel.backgroundColor = UIColor.clear
        confirmButtonLabel.text = "Save"
        confirmButtonLabel.textAlignment = .center
        confirmButtonLabel.font = UIFont(name: "HelveticaNeue-UltraLight", size: 18)
        confirmButtonLabel.textColor = Constants.Colors.colorTextDark
        confirmButton.addSubview(confirmButtonLabel)
        
        confirmLoadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: confirmButton.frame.width, height: confirmButton.frame.height))
        confirmLoadingIndicator.color = Constants.Colors.colorTextDark
        confirmButton.addSubview(confirmLoadingIndicator)
        
        cancelButton = UIView(frame: CGRect(x: 0, y: imageReviewView.frame.height - reviewButtonHeight, width: imageReviewView.frame.width / 2, height: reviewButtonHeight))
        cancelButton.backgroundColor = Constants.Colors.colorGrayDark
        imageReviewView.addSubview(cancelButton)
        
        cancelButtonLabel = UILabel(frame: CGRect(x: 5, y: 5, width: confirmButton.frame.width - 10, height: confirmButton.frame.height - 10))
        cancelButtonLabel.backgroundColor = UIColor.clear
        cancelButtonLabel.text = "Delete"
        cancelButtonLabel.textAlignment = .center
        cancelButtonLabel.font = UIFont(name: "HelveticaNeue-UltraLight", size: 18)
        cancelButtonLabel.textColor = Constants.Colors.colorTextLight
        cancelButton.addSubview(cancelButtonLabel)
        
        adjustMapAttributionLabel()
        
        print("CSIVC - CAMERA VIEW: HIDE LOADING SCREEN")
        self.view.sendSubview(toBack: self.loadingScreen)
//        clearTmpDirectory()
        
        print("CSIVC - VIEW DID APPEAR - STRUCTURE ID: \(structure.structureID)")
        // Request a random id for the Structure if one is not already present
        if structure.structureID == nil
        {
            AWSPrepRequest(requestToCall: AWSCreateRandomID(randomIdType: Constants.randomIdType.random_structure_id), delegate: self as AWSRequestDelegate).prepRequest()
        }
        
        // Request a random id for the Image
        AWSPrepRequest(requestToCall: AWSCreateRandomID(randomIdType: Constants.randomIdType.random_media_id), delegate: self as AWSRequestDelegate).prepRequest()
    }
    
    // Perform setup before the view loads
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(true)
    }
    
    // These will occur after viewDidLoad
    override func viewDidAppear(_ animated: Bool)
    {
        adjustMapAttributionLabel()
        
        if AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo) ==  AVAuthorizationStatus.authorized
        {
            print("CSIVC - CAMERA ALREADY AUTHORIZED")
            self.prepareSessionUseBackCamera(useBackCamera: true)
        }
        else
        {
            AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo, completionHandler: { (granted: Bool) -> Void in
                if granted == true
                {
                    print("CSIVC - CAMERA NOW AUTHORIZED")
                    self.prepareSessionUseBackCamera(useBackCamera: true)
                }
                else
                {
                    print("CSIVC - CAMERA NOT PERMISSIONED")
                    // Show the popup message instructing the user to change the phone camera settings for the app
                    let alertController = UIAlertController(title: "Camera Not Authorized", message: "Harveytown does not have permission to use your camera.  Please go to your phone settings to allow access.", preferredStyle: UIAlertControllerStyle.alert)
                    let okAction = UIAlertAction(title: "Close", style: UIAlertActionStyle.default)
                    { (result : UIAlertAction) -> Void in
                        print("CSIVC - POPUP CLOSE")
                        self.popViewController()
                    }
                    alertController.addAction(okAction)
                    alertController.show()
                }
            })
        }
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
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
            if mapViewContainer.frame.contains(touch.location(in: viewContainer))
            {
                print("CSIVC - TOUCHED MAP")
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
                print("CSIVC - TOUCHED EXIT CAMERA BUTTON")
                exitCamera()
            }
            else if confirmButton.frame.contains(touch.location(in: imageReviewView))
            {
                print("CSIVC - TOUCHED ACTION BUTTON")
                // Show the spinner, upload the image, then pop the Camera VC back to the parentVC
                uploadImage()
            }
            else if cancelButton.frame.contains(touch.location(in: imageReviewView))
            {
                print("CSIVC - DELETE BUTTON TAPPED")
                // Remove structure image and hide the popup
                structure.image = nil
                imageReviewView.removeFromSuperview()
            }
        }
    }
    
//    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?)
//    {
//        if let touch = touches.first
//        {
//            if mapViewContainer.frame.contains(touch.location(in: viewContainer))
//            {
//                print("MAP TOUCH ENDED")
//                mapViewContainer.backgroundColor = UIColor.clear
//            }
//        }
//    }
    
    
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
                if controller is CameraSingleImageViewController
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
    
    // Show the spinner, upload the image, then pop the Camera VC back to the parentVC
    func uploadImage()
    {
        print("CSIVC - UPLOAD IMAGE")
        if let capturedImage = structure.image
        {
            // Check whether the randomID was already downloaded - if not display a popup to wait
            if let mediaID = structure.imageID
            {
                confirmButtonLabel.removeFromSuperview()
                confirmLoadingIndicator.startAnimating()
                let imagePath: String = NSTemporaryDirectory().stringByAppendingPathComponent(path: "path" + ".jpg")
                print("CVC - IMAGE PATH: \(imagePath)")
                let imageURL = URL(fileURLWithPath: imagePath)
                
                // Write the image to the file
                if let imageData = UIImageJPEGRepresentation(capturedImage, 0.6)  // Decrease the quality slightly (second parameter)
                {
                    try? imageData.write(to: imageURL)
                    AWSPrepRequest(requestToCall: AWSUploadMediaToBucket(bucket: Constants.Strings.S3BucketMedia, uploadKey: "\(mediaID).jpg", mediaURL: imageURL, imageIndex: 0), delegate: self as AWSRequestDelegate).prepRequest()
                }
                else
                {
                    // Show the error message
                    let alert = UtilityFunctions().createAlertOkView("Image Error", message: "I'm sorry, there was an issue saving your image.  Please try again.")
                    alert.show()
                }
            }
            else
            {
                // Show the error message
                let alert = UtilityFunctions().createAlertOkView("Slow Network", message: "I'm sorry, there was an issue gathering the needed data.  Please try again.")
                alert.show()
            }
        }
    }
    
    func uploadStructure(structureID: String!)
    {
        // Determine if the structure is new
        var newStruct = true
        structLoop: for structure in Constants.Data.structures
        {
            if structure.structureID == structureID
            {
                newStruct = false
                break structLoop
            }
        }
        // Upload the Structure data
        if structure.imageID != nil && structure.lat != nil && structure.lng != nil && structure.datetime != nil
        {
            AWSPrepRequest(requestToCall: AWSStructurePut(structure: structure, new: newStruct), delegate: self as AWSRequestDelegate).prepRequest()
        }
    }
    
    
    // MARK: CAMERA FUNCTIONS
    
    func prepareSessionUseBackCamera(useBackCamera: Bool)
    {
        print("CSIVC - IN PREPARE SESSION")
        if let devices = AVCaptureDevice.devices()
        {
            for device in devices
            {
                if ((device as AnyObject).hasMediaType(AVMediaTypeVideo))
                {
                    if (device as AnyObject).position == AVCaptureDevicePosition.back
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
                captureSession.removeOutput(stillImageOutput)
            }
            catch _
            {
                print("error: \(String(describing: err?.localizedDescription))")
            }
            
            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill // CHANGE THIS?
            self.cameraView.layer.addSublayer(previewLayer)
            previewLayer?.frame = self.cameraView.layer.frame
            print("CSIVC - CAMERA VIEW LAYER FRAME: \(self.cameraView.layer.frame)")
            print("CSIVC - PREVIEW LAYER FRAME: \(String(describing: previewLayer?.frame))")
            
            stillImageOutput = AVCaptureStillImageOutput()
            captureSession.addOutput(stillImageOutput)
            if let orientationInt = AVCaptureVideoOrientation(rawValue: UIDevice.current.orientation.rawValue)
            {
                print("CSIVC - ASSIGNING ORIENTATION 1: \(UIDevice.current.orientation.hashValue)")
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
        print("CSIVC - Capture Delegate: Did START Recording to Output File")
    }
    
    func capture(_ captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAt outputFileURL: URL!, fromConnections connections: [Any]!, error: Error!)
    {
        print("CSIVC - Capture Delegate: Did FINISH Recording to Output File")
    }
    
    func exitCamera()
    {
        popViewController()
    }
    
    
    // MARK: NAVIGATION & CUSTOM FUNCTIONS
    
    func captureImage()
    {
        print("CSIVC - IN CAPTURE IMAGE")
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
                            // Save the context data when the image is recorded
                            // Only update the datetime if it is nil
                            print("CSIVC - CAPTURE IMAGE - DATETIME: \(self.structure.datetime)")
                            if self.structure.datetime == nil
                            {
                                self.structure.datetime = Date(timeIntervalSinceNow: 0)
                            }
                            self.structure.lat = self.mapView.userLocation.coordinate.latitude
                            self.structure.lng = self.mapView.userLocation.coordinate.longitude
                            
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
                            print("CSIVC - DEVICE ORIENTATION (FOR IMAGE): \(UIDevice.current.orientation.rawValue)")
                            
                            // Resize the image into a square
                            let cgImageRef = CGImage(jpegDataProviderSource: dataProvider, decode: nil, shouldInterpolate: true, intent: CGColorRenderingIntent.defaultIntent)
                            let rawImage = UIImage(cgImage: cgImageRef!, scale: 1.0, orientation: UIImageOrientation.right)
                            let sizedImage = rawImage.cropToBounds(rawImage.size.width, height: rawImage.size.width)
                            //                            print("CVC - OLD IMAGE ORIENTATION: \(rawImage.imageOrientation.rawValue)")
                            
                            if let cgImage = sizedImage.cgImage
                            {
                                let imageRaw = UIImage(cgImage: cgImage, scale: 1.0, orientation: UIImageOrientation(rawValue: imageOrientationValue)!)
                                print("CSIVC - OLD IMAGE ORIENTATION: \(imageRaw.imageOrientation.hashValue)")
                                
                                // Remove the orientation of the image and save to the local image
                                self.structure.image = imageRaw.imageByNormalizingOrientation()
                                
                                print("CSIVC - NEW IMAGE ORIENTATION: \(String(describing: self.structure.image?.imageOrientation.hashValue))")
                                
                                // Show the image in the review popup
                                self.imageReviewImage.image = self.structure.image
                                self.viewContainer.addSubview(self.imageReviewView)
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
    
    // MARK: AWS DELEGATE METHODS
    
    func showLoginScreen()
    {
        print("CSIVC - SHOW LOGIN SCREEN")
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
                case let awsCreateRandomID as AWSCreateRandomID:
                    if success
                    {
                        if let randomID = awsCreateRandomID.randomID
                        {
                            if awsCreateRandomID.randomIdType == Constants.randomIdType.random_structure_id
                            {
                                // Save the randomID
                                print("CSIVC - RANDOM ID - STRUCTURE: \(randomID)")
                                self.structure.structureID = randomID
                            }
                            else if awsCreateRandomID.randomIdType == Constants.randomIdType.random_media_id
                            {
                                // Save the randomID
                                print("CSIVC - RANDOM ID - IMAGE: \(randomID)")
                                self.structure.imageID = randomID
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
                            // If the randomID cannot be retrieved, return to the parent view
                            self.popViewController()
                        }
                        alertController.addAction(okAction)
                        alertController.show()
                        
                        // Stop the activity indicator and shoow the send image
                        self.confirmLoadingIndicator.stopAnimating()
                        self.confirmButton.addSubview(self.confirmButtonLabel)
                    }
                case _ as AWSUploadMediaToBucket:
                    if success
                    {
                        print("CSIVC - AWSUploadMediaToBucket SUCCESS")
                        // The image was successfully uploaded, so close the camera view and send the media data to the parentVC
                        // Ensure that the context data is not nil
                        if self.structure.datetime != nil && self.structure.lat != nil && self.structure.lng != nil
                        {
                            // If the structure is new, upload the data as a new object, else replace the existing structure image with the new image
                            if self.newStructure
                            {
                                // Add an entry in StructureUser
                                if self.structure.structureID != nil && self.structure.datetime != nil
                                {
                                    print("CSIVC - UPLOADING STRUCTURE: \(self.structure.structureID)")
                                    AWSPrepRequest(requestToCall: AWSStructureUserPut(structureID: self.structure.structureID, userID: Constants.Data.currentUser.userID, timestamp: self.structure.datetime.timeIntervalSince1970), delegate: self as AWSRequestDelegate).prepRequest()
                                }
                            }
                            else
                            {
                                if let currentStructureID = self.structure.structureID
                                {
                                    self.uploadStructure(structureID: currentStructureID)
                                }
                            }
                        }
                        else
                        {
                            // Show the error message
                            let alert = UtilityFunctions().createAlertOkView("Data Error", message: "I'm sorry, there was an issue with the data.  Please try again.")
                            alert.show()
                        }
                    }
                    else
                    {
                        // Show the error message
                        let alert = UtilityFunctions().createAlertOkView("Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
                        alert.show()
                    }
                case let awsStructureUserPut as AWSStructureUserPut:
                    if success
                    {
                        print("CSIVC - AWSStructureUserPut SUCCESS")
                        self.uploadStructure(structureID: awsStructureUserPut.structureID)
                    }
                    else
                    {
                        print("CSIVC - AWSStructureUserPut FAILURE")
                        // Show the error message
                        let alert = UtilityFunctions().createAlertOkView("Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
                        alert.show()
                    }
                case let awsStructurePut as AWSStructurePut:
                    if success
                    {
                        print("CSIVC - AWSStructurePut SUCCESS")
                        // Add the Structure and StructureUser info to the global arrays, or replace, if it already exists
                        if awsStructurePut.newStruct == 0
                        {
                            print("CSIVC - UPDATING STRUCTURE DATA")
                            structLoop: for (sIndex, structure) in Constants.Data.structures.enumerated()
                            {
                                if structure.structureID == awsStructurePut.structure.structureID
                                {
                                    Constants.Data.structures[sIndex] = awsStructurePut.structure
                                    break structLoop
                                }
                            }
                        }
                        else
                        {
                            print("CSIVC - ADDING STRUCTURE & STRUCTURE USER")
                            Constants.Data.structures.append(awsStructurePut.structure)
                            // Since the structure is new, add the user to the structure's user list (otherwise it should already exist)
                            let newStructureUser = StructureUser(structureID: awsStructurePut.structure.structureID, userID: Constants.Data.currentUser.userID, datetime: awsStructurePut.structure.datetime)
                            Constants.Data.structureUsers.append(newStructureUser)
                        }
                        
                        // Notify the parent view that the AWS Put completed
                        if let parentVC = self.cameraDelegate
                        {
                            parentVC.returnFromCamera(updatedRow: nil)
                        }
                        
                        // Stop the activity indicator and shoow the send image
                        self.confirmLoadingIndicator.stopAnimating()
                        self.confirmButton.addSubview(self.confirmButtonLabel)
                        
                        // Return to the parentVC
                        self.popViewController()
                    }
                    else
                    {
                        print("CSIVC - AWSStructurePut FAILURE")
                        // Show the error message
                        let alert = UtilityFunctions().createAlertOkView("Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
                        alert.show()
                        
                        // Stop the activity indicator and shoow the send image
                        self.confirmLoadingIndicator.stopAnimating()
                        self.confirmButton.addSubview(self.confirmButtonLabel)
                    }
                default:
                    print("CSIVC-DEFAULT: THERE WAS AN ISSUE WITH THE DATA RETURNED FROM AWS")
                    
                    // Show the error message
                    let alert = UtilityFunctions().createAlertOkView("Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
                    alert.show()
                    
                    // Stop the activity indicator and shoow the send image
                    self.confirmLoadingIndicator.stopAnimating()
                    self.confirmButton.addSubview(self.confirmButtonLabel)
                }
        })
    }
}
