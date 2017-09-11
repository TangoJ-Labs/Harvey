//
//  InfoWindowAgreement.swift
//  Harvey
//
//  Created by Sean Hart on 9/7/17.
//  Copyright © 2017 tangojlabs. All rights reserved.
//

import UIKit


protocol InfoWindowDelegate
{
    func infoWindowSelectCancel()
    
    func infoWindowSelectOk()
}

class InfoWindowAgreement: UIView, AWSRequestDelegate
{
    var infoWindowDelegate: InfoWindowDelegate?
    
    var screenView: UIView!
    var viewContainer: UIView!
    var headerContainer: UIView!
    var headerLabel: UILabel!
    var textView: UITextView!
    var footerContainer: UIView!
    var cancelButton: UIView!
    var cancelLabel: UILabel!
    var cancelButtonTapRecognizer: UITapGestureRecognizer!
    var agreeButton: UIView!
    var agreeLabel: UILabel!
    var agreeButtonTapRecognizer: UITapGestureRecognizer!
    var loadingIndicator: UIActivityIndicatorView!
    
    // Properties to hold local information
    let headerHeight: CGFloat = 50
    let footerHeight: CGFloat = 50
    
    var currentPage: Int = 1
    var eulaAString: NSAttributedString?
    var privacyAString: NSAttributedString?
    
    override init (frame : CGRect)
    {
        super.init(frame : frame)
        print("IWA - INIT")
        
        self.backgroundColor = Constants.Colors.standardBackground
        
        screenView = UIView(frame: CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height))
        screenView.backgroundColor = UIColor.clear
        self.addSubview(screenView)
        
        viewContainer = UIView(frame: CGRect(x: 20, y: 50, width: screenView.frame.width - 40, height: screenView.frame.height - 100))
        viewContainer.backgroundColor = Constants.Colors.standardBackground
        viewContainer.layer.cornerRadius = 5
        viewContainer.layer.shadowOffset = CGSize(width: 0, height: 0.6)
        viewContainer.layer.shadowOpacity = 0.5
        viewContainer.layer.shadowRadius = 1.0
        screenView.addSubview(viewContainer)
        
        headerContainer = UIView(frame: CGRect(x: 5, y: 0, width: viewContainer.frame.width - 10, height: headerHeight))
        headerContainer.backgroundColor = Constants.Colors.standardBackground
        viewContainer.addSubview(headerContainer)
        
        headerLabel = UILabel(frame: CGRect(x: 0, y: 0, width: headerContainer.frame.width, height: headerContainer.frame.height))
        headerLabel.font = UIFont(name: Constants.Strings.fontAltLight, size: 20)
        headerLabel.textColor = Constants.Colors.colorTextDark
        headerLabel.textAlignment = .center
        headerLabel.text = "EULA"
        headerContainer.addSubview(headerLabel)
        
        textView = UITextView(frame: CGRect(x: 5, y: headerHeight, width: viewContainer.frame.width - 10, height: viewContainer.frame.height - headerHeight - footerHeight))
        textView.font = UIFont(name: Constants.Strings.fontAltLight, size: 10)
        textView.textContainerInset.left = 15
        textView.textContainerInset.right = 15
        textView.textAlignment = .left
        textView.isScrollEnabled = true
        textView.isEditable = false
        textView.isSelectable = false
        textView.isUserInteractionEnabled = true
        viewContainer.addSubview(textView)
        
        footerContainer = UIView(frame: CGRect(x: 5, y: viewContainer.frame.height - footerHeight, width: viewContainer.frame.width - 10, height: footerHeight))
        footerContainer.backgroundColor = Constants.Colors.standardBackground
        viewContainer.addSubview(footerContainer)
        
        cancelButton = UIView(frame: CGRect(x: (footerContainer.frame.width / 2) - 130, y: (footerHeight / 2) - 15, width: 100, height: 30))
        cancelButton.backgroundColor = Constants.Colors.colorOrangeOpaque
        footerContainer.addSubview(cancelButton)
        
        cancelLabel = UILabel(frame: CGRect(x: 10, y: 2, width: cancelButton.frame.width - 20, height: cancelButton.frame.height - 4))
        cancelLabel.font = UIFont(name: Constants.Strings.fontAlt, size: 20)
        cancelLabel.textColor = Constants.Colors.colorTextLight
        cancelLabel.textAlignment = .center
        cancelLabel.text = "CANCEL"
        cancelButton.addSubview(cancelLabel)
        
        cancelButtonTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(AgreementViewController.cancelTapGesture(_:)))
        cancelButtonTapRecognizer.numberOfTapsRequired = 1  // add single tap
        cancelButton.addGestureRecognizer(cancelButtonTapRecognizer)
        
        agreeButton = UIView(frame: CGRect(x: (footerContainer.frame.width / 2) + 30, y: (footerHeight / 2) - 15, width: 100, height: 30))
        agreeButton.backgroundColor = Constants.Colors.colorOrangeOpaque
        footerContainer.addSubview(agreeButton)
        
        loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: agreeButton.frame.width, height: agreeButton.frame.height))
        loadingIndicator.color = Constants.Colors.colorTextLight
        agreeButton.addSubview(loadingIndicator)
        loadingIndicator.stopAnimating()
        
        agreeLabel = UILabel(frame: CGRect(x: 10, y: 2, width: agreeButton.frame.width - 20, height: agreeButton.frame.height - 4))
        agreeLabel.font = UIFont(name: Constants.Strings.fontAlt, size: 20)
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
    
    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
    }
    
    // MARK: TAP GESTURE METHODS
    
    func cancelTapGesture(_ gesture: UITapGestureRecognizer)
    {
        // Regardless of the page, the user has rejected an agreement, so log them out and send them to the LoginVC
        print("IWA - CANCEL TAP")
        // Notify the parent view that the infoWindow needs to close with an action
        if let parentVC = self.infoWindowDelegate
        {
            parentVC.infoWindowSelectCancel()
        }
    }
    
    func agreeTapGesture(_ gesture: UITapGestureRecognizer)
    {
        print("IWA - AGREE TAP")
        // If the user is on the first page, show the next agreement
        if currentPage == 1
        {
            print("IWA - AGREE TAP PG 1")
            headerLabel.text = "PRIVACY POLICY"
            textView.scrollRangeToVisible(NSMakeRange(0, 0))
            textView.attributedText = privacyAString
            
            currentPage = 2
        }
        else if currentPage == 2
        {
            print("IWA - AGREE TAP PG 2")
            // Show the spinner
            agreeLabel.text = ""
            loadingIndicator.startAnimating()
            
            // The user is agreeing to the final page, so fire the AWS record update
            let awsUpdateUser = AWSUpdateUser(userID: Constants.Data.currentUser.userID)
            awsUpdateUser.status = "active"
            
            AWSPrepRequest(requestToCall: awsUpdateUser, delegate: self as AWSRequestDelegate).prepRequest()
            
            // Notify the parent view that the infoWindow needs to close with an action
            if let parentVC = self.infoWindowDelegate
            {
                parentVC.infoWindowSelectOk()
            }
        }
    }
    
    
    // MARK: AWS DELEGATE METHODS
    
    func showLoginScreen()
    {
        print("IWA - SHOW LOGIN SCREEN")
    }
    
    func processAwsReturn(_ objectType: AWSRequestObject, success: Bool)
    {
        DispatchQueue.main.async(execute:
            {
                // Process the return data based on the method used
                switch objectType
                {
                case let awsUpdateUser as AWSUpdateUser:
                    print("IWA - awsUpdateUser: \(awsUpdateUser.userID), \(success)")
                    if success
                    {
                        self.loadingIndicator.stopAnimating()
                        
                        // The user agreement was recorded, hide the infoWindow
                        self.removeFromSuperview()
                        
                        // Notify the parent view that the infoWindow needs to close with an action
                        if let parentVC = self.infoWindowDelegate
                        {
                            parentVC.infoWindowSelectOk()
                        }
                    }
                    else
                    {
                        print("ERROR: AWSUpdateUser")
                        // Show the error message
                        let alert = UtilityFunctions().createAlertOkView("Network Error", message: "I'm sorry, you appear to be having network issues.  You will need to accept the agreements again.")
                        alert.show()
                    }
                default:
                    print("IFW-DEFAULT: THERE WAS AN ISSUE WITH THE DATA RETURNED FROM AWS")
                    
                    // Show the error message
                    let alert = UtilityFunctions().createAlertOkView("Network Error", message: "I'm sorry, you appear to be having network issues.  You will need to accept the agreements again.")
                    alert.show()
                }
        })
    }
}
