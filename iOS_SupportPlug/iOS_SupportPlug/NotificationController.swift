//
//  NotificationController.swift
//  iOS_SupportPlug
//
//  Created by macbook pro on 11/09/18.
//  Copyright © 2018 Omni-Bridge. All rights reserved.
//

import UIKit

class NotificationController : UIViewController{
    
    // MARK:- Outlet and Variable declaration
    
    @IBOutlet weak var tableForNotification : UITableView!
    @IBOutlet weak var activityLoader : UIActivityIndicatorView!
    @IBOutlet weak var barBackBtn : UIBarButtonItem!
    
    var notificationArr = NSArray()
    var queryId = 0
    // MARK:- View life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableForNotification.tableFooterView = UIView()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.callGetAllNotificationAPI()
    }
    /// Start loader
    func statrLoader()  {
        self.activityLoader.isHidden = false
        self.activityLoader.startAnimating()
        self.view.isUserInteractionEnabled = false
    }
    
    /// Stop loader
    func stopLoader()  {
        self.activityLoader.stopAnimating()
        self.activityLoader.isHidden = true
        self.view.isUserInteractionEnabled = true
    }
    /// Present empty state controller
    func presentEmptyStateController(){
        /// Used at Uicontroller and Uiview of controller and added to current viewcontroller
        let controller = storyboard!.instantiateViewController(withIdentifier: "NoInternetController") as! EmptyStateController
        controller.view.frame = self.tableForNotification.frame
        self.addChildViewController(controller)
        self.view.addSubview(controller.view)
        controller.didMove(toParentViewController: self)
    }
    /// Used to call get all notification API ?
    func callGetAllNotificationAPI(){
        self.statrLoader()
        APIs.performGet(requestStr: "/notification/GetNotifications", query: "userId=1004") { (data) in
            if let resp = data as? NSDictionary{
                if let notiArr = resp.value(forKey: "data") as? NSArray {
                    self.notificationArr = notiArr.sorted(by: { (DictA, DictB) -> Bool in
                        let timestampA = (DictA as! NSDictionary).value(forKey: "timestamp") as! Int
                        let timestampB = (DictB as! NSDictionary).value(forKey: "timestamp") as! Int
                        return timestampA > timestampB
                    }) as NSArray
                }
                self.tableForNotification.reloadData()
            }
            self.stopLoader()
            if self.notificationArr.count == 0{
                self.presentEmptyStateController()
            }
        }
    }
    
    /// send read notification id
    func callReadNotificationAPI(notiId : Int) {
        let jsonData = ["userId": 1004,
                        "notificationId":notiId]
        APIs.performPost(requestStr: "/notification/MarkNotificaitonSeen", jsonData: jsonData) { (response) in
            if let respDict = response as? NSDictionary{
                print("respDict",respDict)
            }
        }
    }
    
    // MARK:- Button action methods
    
    @IBAction func backPressed(_ sender : Any){
        if self.navigationController?.viewControllers.count == 1{
            let notificationVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SupportController") as! SupportController
            let navigationController = UINavigationController(rootViewController: notificationVC)
            self.present(navigationController, animated: true, completion: nil)
        }else{
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "NotificationDetailsSegue"{
            let destVC = segue.destination as! DetailSupportHistoryController
            destVC.queryId = self.queryId
        }
    }
}

/// UITableViewCell for NotificationCell
class NotificationCell: UITableViewCell {
    @IBOutlet weak var lblForNotification : UILabel!
    @IBOutlet weak var lblForDate : UILabel!
    @IBOutlet weak var imageForNotification : UIImageView!
}

// MARK: - UITableViewDelegate
extension NotificationController : UITableViewDelegate{
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let notiDetails = self.notificationArr[indexPath.row] as! NSDictionary
        let height =  General.heightForString(notiDetails.value(forKey: "message") as? String ?? "", width: self.tableForNotification.bounds.width - 70, fontSize: 17)
        return height + 50
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if General.isConnectedToNetwork(){
            if (self.notificationArr[indexPath.row] as! NSDictionary).value(forKey: "type") as? String == "Support"{
                self.queryId = ((self.notificationArr[indexPath.row] as! NSDictionary).value(forKey: "metadata") as! NSDictionary).value(forKey: "queryId") as! Int
                self.callReadNotificationAPI(notiId: (self.notificationArr[indexPath.row] as! NSDictionary).value(forKey: "id") as! Int)
                self.performSegue(withIdentifier: "NotificationDetailsSegue", sender: self)
            }
        }else{
            self.present(General.NetworkErrorAlertView(), animated: true, completion: nil)
        }
    }
}

// MARK: - UITableViewDataSource
extension NotificationController : UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.notificationArr.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NotificationCell", for: indexPath) as! NotificationCell
        let notiDetails = self.notificationArr[indexPath.row] as! NSDictionary
        cell.lblForNotification.text = notiDetails.value(forKey: "message") as? String ?? ""
        cell.lblForDate.text = General.getDateFromTimeStamp(timeStamp: notiDetails.value(forKey: "timestamp") as! Double, formator: "dd/MM/YYYY")
        return cell
    }    
}
