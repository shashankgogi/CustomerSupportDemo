//
//  SupportHistoryController.swift
//  iOS_SupportPlug
//
//  Created by macbook pro on 06/09/18.
//  Copyright © 2018 Omni-Bridge. All rights reserved.
//

import UIKit

class SupportHistoryController: UIViewController {
    
    // MARK:- Outlet and Variable declaration
    
    @IBOutlet weak var activityLoader: UIActivityIndicatorView!
    @IBOutlet weak var tableViewForHistory: UITableView!
    
    var historyArr = NSArray()
    var selectedIndex = 0
    
    // MARK:- View life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableViewForHistory.tableFooterView = UIView()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        self.callSupportHistoryAPI(userId: 1004)
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
        controller.view.frame = self.tableViewForHistory.frame
        self.addChildViewController(controller)
        self.view.addSubview(controller.view)
        controller.didMove(toParentViewController: self)
    }
    /// Used to call support history API.
    func callSupportHistoryAPI(userId : Int){
        self.statrLoader()
        APIs.performGet(requestStr: "/support/Queries", query: "UserId=\(userId)") { (data) in
            if let resp = data as? NSDictionary{
                if let hisArr = resp.value(forKey: "data") as? NSArray {
                    self.historyArr = hisArr.sorted(by: { (DictA, DictB) -> Bool in
                        let timestampA = (DictA as! NSDictionary).value(forKey: "timestamp") as! Int
                        let timestampB = (DictB as! NSDictionary).value(forKey: "timestamp") as! Int
                        return timestampA > timestampB
                    }) as NSArray
                }
            }
            self.tableViewForHistory.reloadData()
            self.stopLoader()
            if self.historyArr.count == 0{
                self.presentEmptyStateController()
            }
        }
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "DetailSegue"{
            let historyDeatailsVC = segue.destination as! DetailSupportHistoryController
            historyDeatailsVC.queryId = (self.historyArr[selectedIndex] as! NSDictionary).value(forKey: "id") as! Int
        }
    }
    // MARK:- Button action methods
    
    @IBAction func backPressed(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
}

/// UITableViewCell of HistoryCell
class HistoryCell: UITableViewCell {
    @IBOutlet weak var lblForQuery: UILabel!
    @IBOutlet weak var lblForDate: UILabel!
    @IBOutlet weak var lblForConversation: UILabel!
    
}
// MARK:- UITableViewDelegate
extension SupportHistoryController : UITableViewDelegate{
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let height = General.heightForString((self.historyArr[indexPath.row] as! NSDictionary).value(forKey: "query") as! String, width: self.view.bounds.width - 26 , fontSize : 18)
        return (height + 60)
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.selectedIndex = indexPath.row
        if General.isConnectedToNetwork(){
            self.performSegue(withIdentifier: "DetailSegue", sender: self)
        }else{
            self.present(General.NetworkErrorAlertView(), animated: true, completion: nil)
        }
    }
}

// MARK:- UITableViewDataSource
extension SupportHistoryController : UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.historyArr.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "HistoryCell") as! HistoryCell
        let hisDict = self.historyArr[indexPath.row] as! NSDictionary
        cell.lblForQuery.text = hisDict.value(forKey: "query") as? String
        cell.lblForDate.text = "Asked on \(General.getDateFromTimeStamp(timeStamp: hisDict.value(forKey: "timestamp") as! Double, formator: ".Short")), \(General.getDateFromTimeStamp(timeStamp: hisDict.value(forKey: "timestamp") as! Double, formator: "dd/MM/yyyy"))"
        cell.lblForConversation.text = "Conversation (\(hisDict.value(forKey: "conversationCount") ?? 0))"
        return cell
    }
    
    
}
