//
//  AgreementViewController.swift
//  Harvey
//
//  Created by Sean Hart on 9/7/17.
//  Copyright © 2017 TangoJ Labs, LLC. All rights reserved.
//

import UIKit

class AgreementViewController: UIViewController
{
    // Save device settings to adjust view if needed
    var screenSize: CGRect!
    var statusBarHeight: CGFloat!
    var navBarHeight: CGFloat!
    var viewFrameY: CGFloat!
    
    var ncTitle: UIView!
    var ncTitleText: UILabel!
    
    // Add the view components
    var viewContainer: UIView!
    var textView: UITextView!
    
    var footerContainer: UIView!
    var cancelButton: UIView!
    var cancelLabel: UILabel!
    var cancelButtonTapRecognizer: UITapGestureRecognizer!
    var agreeButton: UIView!
    var agreeLabel: UILabel!
    var agreeButtonTapRecognizer: UITapGestureRecognizer!
    
//    var privacyHeaderContainer: UIView!
//    var privacyHeaderLabel: UILabel!
//    var privacySlider: UISlider!
//    var privacySliderTextView: UITextView!
//    var privacyCancelButton: UIView!
//    var privacyCancelLabel: UILabel!
//    var privacyAgreeButton: UIView!
//    var privacyAgreeLabel: UIView!
    
    // Properties to hold local information
    var viewContainerHeight: CGFloat!
    let footerHeight: CGFloat = 50
    
    var currentPage: Int = 1
    var eulaAString: NSAttributedString?
    var privacyAString: NSAttributedString?
    
    override func viewDidLoad()
    {
        super.viewDidLoad()

        // Device and Status Bar Settings
        UIApplication.shared.isStatusBarHidden = false
        UIApplication.shared.statusBarStyle = Constants.Settings.statusBarStyle
        statusBarHeight = UIApplication.shared.statusBarFrame.size.height
        navBarHeight = self.navigationController?.navigationBar.frame.height
        viewFrameY = self.view.frame.minY
        screenSize = UIScreen.main.bounds
        
        self.navigationItem.hidesBackButton = true
        self.automaticallyAdjustsScrollViewInsets = false
        
        // Add the view container to hold all other views (allows for shadows on all subviews)
        let viewContainerOffset = statusBarHeight + navBarHeight - viewFrameY
        self.viewContainerHeight = self.view.bounds.height - viewContainerOffset
        viewContainer = UIView(frame: CGRect(x: 0, y: viewContainerOffset, width: self.view.bounds.width, height: self.viewContainerHeight))
        viewContainer.backgroundColor = Constants.Colors.standardBackground
        self.view.addSubview(viewContainer)
        
        ncTitle = UIView(frame: CGRect(x: screenSize.width / 2 - 100, y: 10, width: 200, height: 40))
        ncTitleText = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 40))
        ncTitleText.text = "EULA"
        ncTitleText.textColor = Constants.Colors.colorTextNavBar
        ncTitleText.font = UIFont(name: Constants.Strings.fontAlt, size: 22)
        ncTitleText.textAlignment = .center
        ncTitle.addSubview(ncTitleText)
        
        // Assign the created Nav Bar settings to the Tab Bar Controller
        self.navigationItem.titleView = ncTitle
        
        textView = UITextView(frame: CGRect(x: 0, y: 0, width: viewContainer.frame.width, height: viewContainer.frame.height - footerHeight))
        textView.font = UIFont(name: Constants.Strings.fontAltLight, size: 10)
        textView.textContainerInset.left = 15
        textView.textContainerInset.right = 15
        textView.textAlignment = .left
        textView.isScrollEnabled = true
        textView.isEditable = false
        textView.isSelectable = false
        textView.isUserInteractionEnabled = true
        viewContainer.addSubview(textView)
        
        footerContainer = UIView(frame: CGRect(x: 0, y: viewContainer.frame.height - footerHeight, width: viewContainer.frame.width, height: footerHeight))
        footerContainer.backgroundColor = Constants.Colors.standardBackground
        footerContainer.layer.shadowOffset = CGSize(width: 0.5, height: 2)
        footerContainer.layer.shadowOpacity = 0.5
        footerContainer.layer.shadowRadius = 1.0
        viewContainer.addSubview(footerContainer)
        
        cancelButton = UIView(frame: CGRect(x: (footerContainer.frame.width / 2) - 130, y: (footerHeight / 2) - 15, width: 100, height: 30))
        cancelButton.backgroundColor = Constants.Colors.colorOrange
        footerContainer.addSubview(cancelButton)
        
        cancelLabel = UILabel(frame: CGRect(x: 10, y: 2, width: cancelButton.frame.width - 20, height: cancelButton.frame.height - 4))
        cancelLabel.font = UIFont(name: Constants.Strings.fontAltLight, size: 20)
        cancelLabel.textColor = Constants.Colors.colorTextLight
        cancelLabel.textAlignment = .center
        cancelLabel.text = "CANCEL"
        cancelButton.addSubview(cancelLabel)
        
        cancelButtonTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(AgreementViewController.cancelTapGesture(_:)))
        cancelButtonTapRecognizer.numberOfTapsRequired = 1  // add single tap
        cancelButton.addGestureRecognizer(cancelButtonTapRecognizer)
        
        agreeButton = UIView(frame: CGRect(x: (footerContainer.frame.width / 2) + 30, y: (footerHeight / 2) - 15, width: 100, height: 30))
        agreeButton.backgroundColor = Constants.Colors.colorOrange
        footerContainer.addSubview(agreeButton)
        
        agreeLabel = UILabel(frame: CGRect(x: 10, y: 2, width: agreeButton.frame.width - 20, height: agreeButton.frame.height - 4))
        agreeLabel.font = UIFont(name: Constants.Strings.fontAltLight, size: 20)
        agreeLabel.textColor = Constants.Colors.colorTextLight
        agreeLabel.textAlignment = .center
        agreeLabel.text = "AGREE"
        agreeButton.addSubview(agreeLabel)
        
        agreeButtonTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(AgreementViewController.agreeTapGesture(_:)))
        agreeButtonTapRecognizer.numberOfTapsRequired = 1  // add single tap
        agreeButton.addGestureRecognizer(agreeButtonTapRecognizer)
        
        // Load the text
        if let eulaPath = Bundle.main.path(forResource: "eula", ofType: "txt")
        {
            do
            {
                let url = URL(fileURLWithPath: eulaPath)
                let eulaAttString:NSAttributedString = try NSAttributedString(url: url, options: [NSDocumentTypeDocumentAttribute:NSPlainTextDocumentType], documentAttributes: nil)
                eulaAString = eulaAttString
                textView.attributedText = eulaAttString
            }
            catch let error
            {
                print("AgVC - EULA TEXT - Got an error \(error)")
            }
        }
        if let privacyPath = Bundle.main.url(forResource: "privacy", withExtension: "txt")
        {
            do
            {
                let privacyAttString:NSAttributedString = try NSAttributedString(url: privacyPath, options: [NSDocumentTypeDocumentAttribute:NSPlainTextDocumentType], documentAttributes: nil)
                privacyAString = privacyAttString
            }
            catch let error
            {
                print("AgVC - PRIVACY TEXT - Got an error \(error)")
            }
        }
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
    }
    

    // MARK: TAP GESTURE METHODS
    
    func cancelTapGesture(_ gesture: UITapGestureRecognizer)
    {
        // Regardless of the page, the user has rejected an agreement, so log them out and send them to the LoginVC
        
    }
    
    func agreeTapGesture(_ gesture: UITapGestureRecognizer)
    {
        // If the user is on the first page, show the next agreement
        if currentPage == 1
        {
            ncTitleText.text = "PRIVACY POLICY"
            textView.scrollRangeToVisible(NSMakeRange(0, 0))
            textView.attributedText = privacyAString
            
            currentPage = 2
        }
        else if currentPage == 2
        {
            // The user is agreeing to the final page, so move them to the next VC
            loadMapVC()
        }
    }
    
    
    // MARK: CUSTOM METHODS
    
    func loadMapVC()
    {
        // Load the MapVC
        let mapVC = MapViewController()
        self.navigationController!.pushViewController(mapVC, animated: true)
    }
}
