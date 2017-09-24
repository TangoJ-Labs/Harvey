//
//  ProfileTabSkillViewController.swift
//  Harvey
//
//  Created by Sean Hart on 9/15/17.
//  Copyright © 2017 TangoJ Labs, LLC. All rights reserved.
//

import UIKit


class ProfileTabSkillViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate, AWSRequestDelegate
{
    // Save device settings to adjust view if needed
    var screenSize: CGRect!
    var statusBarHeight: CGFloat!
    var tabBarHeight: CGFloat!
    var navBarHeight: CGFloat!
    var vcHeight: CGFloat!
    var vcOffsetY: CGFloat!
    
    var ncTitleText: UILabel!
    
    // The views to hold major components of the view controller
    var statusBarView: UIView!
    var viewContainer: UIView!
    var titleContainer: UIImageView!
    var titleText: UILabel!
    var titleSpinner: UIActivityIndicatorView!
    var skillTableView: UITableView!
    
    var skillList = [Skill]()
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.edgesForExtendedLayout = UIRectEdge.all

        prepVcLayout()
        
        // Add the Status Bar, Top Bar and Search Bar last so that they are placed above (z-index) all other views
        statusBarView = UIView(frame: CGRect(x: 0, y: 0, width: screenSize.width, height: statusBarHeight))
        statusBarView.backgroundColor = Constants.Colors.colorStatusBar
        self.view.addSubview(statusBarView)
        
        // Add the view container to hold all other views (allows for shadows on all subviews)
        viewContainer = UIView(frame: CGRect(x: 0, y: vcOffsetY, width: screenSize.width, height: vcHeight))
        viewContainer.backgroundColor = Constants.Colors.standardBackground
        self.view.addSubview(viewContainer)
        
        titleContainer = UIImageView(frame: CGRect(x: 0, y: 0, width: viewContainer.frame.width, height: 50))
        titleContainer.backgroundColor = Constants.Colors.standardBackground
        titleContainer.layer.shadowOffset = CGSize(width: 0, height: 0.6)
        titleContainer.layer.shadowOpacity = 0.5
        titleContainer.layer.shadowRadius = 1.0
        viewContainer.addSubview(titleContainer)
        
        titleText = UILabel(frame: CGRect(x: 5, y: 5, width: titleContainer.frame.width - 10, height: titleContainer.frame.height - 10))
        titleText.backgroundColor = UIColor.clear
        titleText.text = "My Skills"
        titleText.textAlignment = .center
        titleText.font = UIFont(name: "HelveticaNeue-UltraLight", size: 18)
        
        titleSpinner = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: titleContainer.frame.width, height: titleContainer.frame.height))
        titleSpinner.color = Constants.Colors.colorGrayDark
        titleContainer.addSubview(titleSpinner)
        
        // A tableview will hold all comments
        skillTableView = UITableView(frame: CGRect(x: 0, y: 50, width: viewContainer.frame.width, height: viewContainer.frame.height - 50))
        skillTableView.dataSource = self
        skillTableView.delegate = self
        skillTableView.register(ProfileSkillTableViewCell.self, forCellReuseIdentifier: Constants.Strings.profileSkillTableViewCellReuseIdentifier)
        skillTableView.separatorStyle = .none
        skillTableView.backgroundColor = UIColor.clear //Constants.Colors.standardBackground
        skillTableView.isScrollEnabled = true
        skillTableView.bounces = true
        skillTableView.alwaysBounceVertical = true
        skillTableView.showsVerticalScrollIndicator = false
        skillTableView.translatesAutoresizingMaskIntoConstraints = false
//        skillTableView.isUserInteractionEnabled = true
//        skillTableView.allowsSelection = true
        skillTableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        viewContainer.addSubview(skillTableView)
        
        let border1 = CALayer()
        border1.frame = CGRect(x: 0, y: 0, width: skillTableView.frame.width, height: 1)
        border1.backgroundColor = Constants.Colors.standardBackgroundGrayUltraLight.cgColor
        skillTableView.layer.addSublayer(border1)
        
        NotificationCenter.default.addObserver(self, selector: #selector(MapViewController.statusBarHeightChange(_:)), name: Notification.Name("UIApplicationWillChangeStatusBarFrameNotification"), object: nil)
        
        // Fill the global arrays with Core Data (if available)
        Constants.Data.skills = CoreDataFunctions().skillRetrieveForUser(userID: Constants.Data.currentUser.userID)
        
        // Copy the global array locally and sort the data
        reloadSkillTable()
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        prepVcLayout()
        statusBarView.frame = CGRect(x: 0, y: 0, width: screenSize.width, height: statusBarHeight)
        viewContainer.frame = CGRect(x: 0, y: vcOffsetY, width: screenSize.width, height: vcHeight)
        titleContainer.frame = CGRect(x: 0, y: 0, width: viewContainer.frame.width, height: 50)
        skillTableView.frame = CGRect(x: 0, y: 50, width: viewContainer.frame.width, height: viewContainer.frame.height - 50)
        titleText.frame = CGRect(x: 5, y: 5, width: titleContainer.frame.width - 10, height: titleContainer.frame.height - 10)
        titleSpinner.frame = CGRect(x: 0, y: 0, width: titleContainer.frame.width, height: titleContainer.frame.height)
        
        requestData()
        self.titleText.removeFromSuperview()
        titleSpinner.startAnimating()
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
    }
    
    
    // MARK: LAYOUT METHODS
    
    func statusBarHeightChange(_ notification: Notification)
    {
        prepVcLayout()
        statusBarView.frame = CGRect(x: 0, y: 0, width: screenSize.width, height: statusBarHeight)
        viewContainer.frame = CGRect(x: 0, y: vcOffsetY, width: screenSize.width, height: vcHeight)
        titleContainer.frame = CGRect(x: 0, y: 0, width: viewContainer.frame.width, height: 50)
        skillTableView.frame = CGRect(x: 0, y: 50, width: viewContainer.frame.width, height: viewContainer.frame.height - 50)
        titleText.frame = CGRect(x: 5, y: 5, width: titleContainer.frame.width - 10, height: titleContainer.frame.height - 10)
        titleSpinner.frame = CGRect(x: 0, y: 0, width: titleContainer.frame.width, height: titleContainer.frame.height)
    }
    
    func prepVcLayout()
    {
        screenSize = UIScreen.main.bounds
        
        // Navigation Bar settings
        let leftButtonItem = UIBarButtonItem(title: "\u{2190}",
                                             style: UIBarButtonItemStyle.plain,
                                             target: self,
                                             action: #selector(UserViewController.popViewController(_:)))
        leftButtonItem.tintColor = Constants.Colors.colorTextNavBar
        
        let rightButtonItem = UIBarButtonItem(title: "",
                                              style: UIBarButtonItemStyle.plain,
                                              target: self,
                                              action: #selector(UserViewController.blankFunc(_:)))
        rightButtonItem.tintColor = Constants.Colors.colorTextNavBar
        
        let ncTitle = UIView(frame: CGRect(x: screenSize.width / 2 - 100, y: 20, width: 200, height: 20))
        ncTitleText = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 20))
        ncTitleText.text = "My Volunteer Profile"
        ncTitleText.textColor = Constants.Colors.colorTextNavBar
        ncTitleText.font = UIFont(name: Constants.Strings.fontAlt, size: 16)
        ncTitleText.textAlignment = .center
        ncTitle.addSubview(ncTitleText)
        
        // Device and Status Bar Settings
        UIApplication.shared.isStatusBarHidden = false
        UIApplication.shared.statusBarStyle = Constants.Settings.statusBarStyle
        statusBarHeight = UIApplication.shared.statusBarFrame.size.height
        navBarHeight = 44
        if let tabCon = self.tabBarController
        {
            tabBarHeight = tabCon.tabBar.frame.height
            print("PTSKVC - STATUS BAR HEIGHT: \(statusBarHeight)")
            print("PTSKVC - TAB BAR HEIGHT: \(tabBarHeight)")
            tabCon.navigationItem.titleView = ncTitle
            tabCon.navigationItem.hidesBackButton = true
            tabCon.navigationItem.setLeftBarButton(leftButtonItem, animated: false)
            
            print("PTSKVC - TAB CON: \(tabCon)")
            if let navCon = tabCon.navigationController
            {
                print("PTSKVC - NAV CON: \(navCon)")
                navBarHeight = navCon.navigationBar.frame.height
                navCon.isNavigationBarHidden = false
                navCon.navigationBar.barTintColor = Constants.Colors.colorOrangeOpaque
            }
        }
        
        self.automaticallyAdjustsScrollViewInsets = false
        
        vcHeight = screenSize.height - statusBarHeight - navBarHeight - tabBarHeight
        vcOffsetY = CGFloat(statusBarHeight) + CGFloat(navBarHeight) //+ CGFloat(tabBarHeight)
        if statusBarHeight == 40
        {
            vcOffsetY = navBarHeight + 20
        }
        print("PTSKVC - CHECK DIMS: \(screenSize), \(vcHeight), \(statusBarHeight), \(navBarHeight), \(tabBarHeight)")
    }
    
    
    // MARK: NAVIGATION / BAR BUTTON METHODS
    
    // Dismiss the latest View Controller presented from this VC
    // This version is used when the top VC is popped from a Nav Bar button
    func popViewController(_ sender: UIBarButtonItem)
    {
        self.navigationController!.popViewController(animated: true)
    }
    func popViewController()
    {
        self.navigationController!.popViewController(animated: true)
    }
    func blankFunc(_ sender: UIBarButtonItem)
    {
    }
    
    
    // MARK: TAP GESTURE RECOGNIZERS
    
    func blockButtonTap(_ gesture: UITapGestureRecognizer)
    {
        
    }
    
    
    // MARK: TABLE VIEW DATA SOURCE
    
    func numberOfSections(in tableView: UITableView) -> Int
    {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return skillList.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return Constants.Dim.skillCellHeight
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        print("PTSKVC - CREATING CELL: \(indexPath.row)")
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.Strings.profileSkillTableViewCellReuseIdentifier, for: indexPath) as! ProfileSkillTableViewCell
        cell.selectionStyle = .none
        
        cell.cellContainer.frame = CGRect(x: 0, y: 0, width: cell.frame.width, height: cell.frame.height)
        cell.skillImageView.frame = CGRect(x: 10, y: 0, width: 50, height: cell.cellContainer.frame.height)
        cell.skillTitle.frame = CGRect(x: 70, y: 0, width: 150, height: cell.cellContainer.frame.height)
        cell.checkContainer.frame = CGRect(x: cell.cellContainer.frame.width - 70, y: 0, width: 70, height: cell.cellContainer.frame.height)
        cell.checkText.frame = CGRect(x: 0, y: 0, width: cell.checkContainer.frame.width, height: cell.checkContainer.frame.height)
        cell.border1.frame = CGRect(x: 0, y: Constants.Dim.skillCellHeight - 1, width: cell.cellContainer.frame.width, height: 1)
        
        cell.skillTitle.text = skillList[indexPath.row].skill
        
        
        cell.checkContainer.backgroundColor = Constants.Colors.spotGrayLight
        cell.checkText.text = "No\nExperience"
        
        if skillList[indexPath.row].level == Constants.Experience.some
        {
            cell.checkContainer.backgroundColor = Constants.Colors.colorYellow
            cell.checkText.text = "Some\nExperience"
        }
        else if skillList[indexPath.row].level == Constants.Experience.expert
        {
            cell.checkContainer.backgroundColor = Constants.Colors.colorOrange
            cell.checkText.text = "Expert"
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath)
    {
        print("PTSKVC - WILL DISPLAY CELL: \(indexPath.row)")
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        print("PTSKVC - SELECTED CELL: \(indexPath.row)")
        
//        // Unhighlight the cell
//        tableView.deselectRow(at: indexPath, animated: false)
        
        // Toggle the experience level for this skill
        var newLevel = Constants.Experience.some
        if skillList[indexPath.row].level == Constants.Experience.none
        {
            newLevel = Constants.Experience.some
        }
        else if skillList[indexPath.row].level == Constants.Experience.some
        {
            newLevel = Constants.Experience.expert
        }
        else if skillList[indexPath.row].level == Constants.Experience.expert
        {
            newLevel = Constants.Experience.none
        }
        skillList[indexPath.row].level = newLevel
        reloadSkillTable()
        
        // Change the setting in the global array and upload the changes
        skillLoop: for skill in Constants.Data.skills
        {
            if skill.skill == skillList[indexPath.row].skill
            {
                skill.level = newLevel
                
                // Save the updated / new skill to Core Data
                CoreDataFunctions().skillSave(skill: skill, deleteSkill: false)
                
                break skillLoop
            }
        }
        // Upload the changes
        AWSPrepRequest(requestToCall: AWSPutSkills(skills: skillList), delegate: self as AWSRequestDelegate).prepRequest()
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath)
    {
    }
    
    func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath)
    {
    }
    
    func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath)
    {
    }
    
    
    // MARK: SCROLL VIEW DELEGATE METHODS
    
    func scrollViewDidScroll(_ scrollView: UIScrollView)
    {
        
    }
    
    
    // MARK: CUSTOM METHODS
    
    func refreshSkillTable()
    {
        DispatchQueue.main.async(execute:
            {
                if self.skillTableView != nil
                {
                    print("PTSKVC - REFRESH SKILL TABLE")
                    
                    // Reload the TableView
                    self.skillTableView.reloadData()
//                    self.skillTableView.performSelector(onMainThread: #selector(UITableView.reloadData), with: nil, waitUntilDone: true)
                }
        })
    }
    func reloadSkillTable()
    {
        self.skillList = Constants.Data.skills
        
        // Order the SkillList
        let skillListSort = self.skillList.sorted {
            $0.order < $1.order
        }
        self.skillList = skillListSort
        
        refreshSkillTable()
    }
    
    func requestData()
    {
        // Request the user's skill history
        AWSPrepRequest(requestToCall: AWSGetSkills(userID: Constants.Data.currentUser.userID), delegate: self as AWSRequestDelegate).prepRequest()
    }
    
    // MARK: AWS DELEGATE METHODS
    
    func showLoginScreen()
    {
        print("PTSKVC - SHOW LOGIN SCREEN")
        
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
                case _ as AWSGetSkills:
                    if success
                    {
                        print("PTSKVC - AWS GET SKILLS - SUCCESS")
                        self.reloadSkillTable()
                        self.titleSpinner.stopAnimating()
                        self.titleContainer.addSubview(self.titleText)
                    }
                    else
                    {
                        print("PTSKVC - AWS GET SKILLS - FAILURE")
                        // Show the error message
                        let alert = UtilityFunctions().createAlertOkView("Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
                        alert.show()
                    }
                case _ as AWSPutSkills:
                    if success
                    {
                        print("PTSKVC - AWS PUT SKILLS - SUCCESS")
                    }
                    else
                    {
                        print("PTSKVC - AWS PUT SKILLS - FAILURE")
                        // Show the error message
                        let alert = UtilityFunctions().createAlertOkView("Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
                        alert.show()
                    }
                default:
                    print("PTSKVC-DEFAULT: THERE WAS AN ISSUE WITH THE DATA RETURNED FROM AWS")
                    
                    // Show the error message
                    let alert = UtilityFunctions().createAlertOkView("Network Error", message: "I'm sorry, you appear to be having network issues.  Please try again.")
                    alert.show()
                }
        })
    }
}
