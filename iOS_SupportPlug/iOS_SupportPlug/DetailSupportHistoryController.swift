//
//  DetailSupportHistoryController.swift
//  iOS_SupportPlug
//
//  Created by macbook pro on 07/09/18.
//  Copyright © 2018 Omni-Bridge. All rights reserved.
//

import UIKit

class DetailSupportHistoryController: UIViewController {
    
    // MARK:- Outlet and Variable declaration
    
    @IBOutlet weak var lblForQuery: UILabel!
    @IBOutlet weak var lblForDate: UILabel!
    @IBOutlet weak var activityLoader: UIActivityIndicatorView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var btnForNoHelpfull: UIButton!
    @IBOutlet weak var btnForHelpfull: UIButton!
    @IBOutlet weak var imgOfUser: UIImageView!
    @IBOutlet weak var txtView: UITextView!
    @IBOutlet weak var constrainForBotomView: NSLayoutConstraint!
    @IBOutlet weak var barBackBtn : UIBarButtonItem!
    var queryId = 0
    var replyArr = NSArray()
    
    // MARK:- View life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.callSupportHistoryReplyAPI(queryId: self.queryId)
        self.tableView.tableFooterView = UIView()
        
        /* NotificationCenter used to get Keyboard notification */
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardNotication), name: NSNotification.Name.UIKeyboardWillShow , object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardNotication), name: NSNotification.Name.UIKeyboardWillHide , object: nil)
        
        self.btnForHelpfull.layer.borderWidth = 1
        self.btnForNoHelpfull.layer.borderWidth = 1
        self.btnForHelpfull.layer.borderColor = UIColor(netHex: 0x5B00AF).cgColor
        self.btnForNoHelpfull.layer.borderColor = UIColor(netHex: 0x5B00AF).cgColor
        
    }
    
    /// Present empty state controller
    func presentEmptyStateController(){
        /// Used at Uicontroller and Uiview of controller and added to current viewcontroller
        let controller = storyboard!.instantiateViewController(withIdentifier: "NoInternetController") as! EmptyStateController
        controller.view.frame = self.view.frame
        self.addChildViewController(controller)
        self.view.addSubview(controller.view)
        controller.didMove(toParentViewController: self)
    }
    /// Used to detect keyboard notification event
    ///
    /// - Parameter notifaction: Notification
    @objc func keyboardNotication(notifaction : Notification){
        if let userInfo = notifaction.userInfo{
            let keyboardFrame : CGRect = userInfo[UIKeyboardFrameEndUserInfoKey] as! CGRect
            let keyboardShowing = notifaction.name == NSNotification.Name.UIKeyboardWillShow
            if keyboardShowing && self.txtView.text == "Write a feedback..."{
                self.txtView.text = ""
            }
            self.constrainForBotomView.constant = keyboardShowing ? -keyboardFrame.height : 0
            UIView.animate(withDuration: 0, delay: 0, options: UIViewAnimationOptions.curveEaseOut, animations: {
                self.view.layoutIfNeeded()
            }) { (completion) in
            }
        }
    }
    /// start loader
    func statrLoader()  {
        self.activityLoader.isHidden = false
        self.activityLoader.startAnimating()
        self.view.isUserInteractionEnabled = false
    }
    /// stop loader
    func stopLoader()  {
        self.activityLoader.stopAnimating()
        self.activityLoader.isHidden = true
        self.view.isUserInteractionEnabled = true
    }
    
    /// present alert view
    ///
    /// - Parameters:
    ///   - title: title
    ///   - message: message
    func createAlertView(title : String , message : String) {
        let alertVc = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alertVc.addAction(UIAlertAction(title: "Okay", style: UIAlertActionStyle.default, handler: nil))
        self.present(alertVc, animated: true, completion: nil)
    }
    /// Used to call main category API ?
    func callSupportHistoryReplyAPI(queryId : Int){
        self.statrLoader()
        APIs.performGet(requestStr: "/support/QueriesDetails", query: "QueryId=\(queryId)") { (data) in
            if let resp = data as? NSDictionary{
                print(resp)
                if let repDict = resp.value(forKey: "data") as? NSDictionary {
                    self.replyArr = repDict.value(forKey: "conversationList") as! NSArray
                    self.lblForQuery.text = repDict.value(forKey: "query") as? String
                    self.lblForDate.text = "Asked on \(General.getDateFromTimeStamp(timeStamp: repDict.value(forKey: "timestamp") as! Double, formator: ".Short")), \(General.getDateFromTimeStamp(timeStamp: repDict.value(forKey: "timestamp") as! Double, formator: "dd/MM/yyyy"))"
                    if repDict.value(forKey: "rating") as? String == "NotGiven" && self.checkForServerReplyToShowFeedbackBtn(){
                        self.btnForNoHelpfull.isHidden = false
                        self.btnForHelpfull.isHidden = false
                    }else{
                        self.btnForNoHelpfull.isHidden = true
                        self.btnForHelpfull.isHidden = true
                    }
                }
            }
            DispatchQueue.main.async {
                self.tableView.reloadData()
                if self.replyArr.count != 0{
                    self.tableView.scrollToRow(at: IndexPath(row: self.replyArr.count - 1, section: 0), at: UITableViewScrollPosition.bottom, animated: true)
                }
            }
            self.stopLoader()
        }
    }
    /// send reply tmaun query
    func callPostApiToSendReply() {
        let jsonData = ["userId": 1004,
                        "Reply": self.txtView.text.trimmingCharacters(in: .whitespaces),
                        "QueryId": self.queryId ] as [String : Any]
        self.statrLoader()
        APIs.performPost(requestStr: "/support/PostReply", jsonData: jsonData) { (response) in
            if let respDict = response as? NSDictionary{
                if respDict.value(forKey: "message") as! String == "Sucessfully."{
                    self.txtView.text = "Write a feedback..."
                    self.callSupportHistoryReplyAPI(queryId: self.queryId)
                }
            }
            self.stopLoader()
        }
    }
    
    /// send reply tmaun query
    func callPostApiToSendFeedbackOfHelpfull(isHelpfull : Bool) {
        let jsonData = ["IsGoodReply": isHelpfull,
                        "QueryId": self.queryId,
                        "UserId": 1004 ] as [String : Any]
        self.statrLoader()
        APIs.performPost(requestStr: "/support/Rating", jsonData: jsonData) { (response) in
            if let respDict = response as? NSDictionary{
                print(respDict)
                if respDict.value(forKey: "message") as! String == "Sucessfully."{
                    self.btnForNoHelpfull.isHidden = true
                    self.btnForHelpfull.isHidden = true
                }
            }
            self.stopLoader()
        }
    }
    
    /// Check for feedback button
    ///
    /// - Returns: status
    func checkForServerReplyToShowFeedbackBtn()-> Bool{
        var nameCount = 0
        for replyDict in self.replyArr{
            let replyName = (replyDict as! NSDictionary).value(forKey: "name") as! String
            if replyName == "Support Team"{
                nameCount += 1
            }
        }
        if nameCount == 1{
            return true
        }
        return false
    }
    // MARK:- Button action methods
    @IBAction func backPressed(_ sender: Any) {
        if self.navigationController?.viewControllers.count == 1{
            let notificationVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SupportController") as! SupportController
            let navigationController = UINavigationController(rootViewController: notificationVC)
            self.present(navigationController, animated: true, completion: nil)
        }else{
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    @IBAction func feedbackToReplyPressed(_ sender: UIButton) {
        if General.isConnectedToNetwork(){
            if sender.tag == 1{
                self.callPostApiToSendFeedbackOfHelpfull(isHelpfull: true)
            }else{
                self.callPostApiToSendFeedbackOfHelpfull(isHelpfull: false)
            }
        }else{
            self.present(General.NetworkErrorAlertView(), animated: true, completion: nil)
        }
    }
    
    @IBAction func ReplyPressed(_ sender: Any) {
        if let text = self.txtView.text{// Check for blank comment
            if text.trimmingCharacters(in: .whitespaces) == "" || text == "Write a feedback..."{
                self.createAlertView(title: "Warning !", message: "Feedback text can't be blank.")
            }else{
                if General.isConnectedToNetwork(){
                    self.callPostApiToSendReply()
                }else{
                    self.present(General.NetworkErrorAlertView(), animated: true, completion: nil)
                }
                self.txtView.resignFirstResponder()
            }
        }
    }
}

/// UITableViewCell for ReplyCell
class ReplyCell : UITableViewCell{
    @IBOutlet weak var lblForName: UILabel!
    @IBOutlet weak var lblForDate: UILabel!
    @IBOutlet weak var lblForReply: UILabel!
    @IBOutlet weak var imgForUser: UIImageView!
    @IBOutlet var viewForBackgound: UIView!
    
}

// MARK: - UITableViewDelegate
extension DetailSupportHistoryController : UITableViewDelegate{
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let height = General.heightForString((self.replyArr[indexPath.row] as! NSDictionary).value(forKey: "description") as! String, width: self.view.bounds.width - 26 , fontSize : 14)
        return (height + 65)
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        
        let view:UIView = UIView.init(frame: CGRect.init(x: 0, y: 0, width: self.view.bounds.size.width, height: 10))
        view.backgroundColor = .clear
        return view
    }
}

// MARK: - UITableViewDataSource
extension DetailSupportHistoryController : UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.replyArr.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ReplyCell") as! ReplyCell
        let replyDict = self.replyArr[indexPath.row] as! NSDictionary
        
        cell.lblForName.text = replyDict.value(forKey: "name") as? String
        cell.lblForDate.text = "Replied on \(General.getDateFromTimeStamp(timeStamp: replyDict.value(forKey: "timestamp") as! Double, formator: ".Short")), \(General.getDateFromTimeStamp(timeStamp: replyDict.value(forKey: "timestamp") as! Double, formator: "dd/MM/yyyy"))"
        cell.lblForReply.text = replyDict.value(forKey: "description") as? String
        cell.imgForUser.image = UIImage(named: "ProfilePicture")
        
        cell.viewForBackgound.layer.masksToBounds = false
        cell.viewForBackgound.layer.cornerRadius = 4.0
        cell.viewForBackgound.layer.shadowOpacity = 0.5
        cell.viewForBackgound.layer.shadowColor = UIColor.gray.cgColor
        cell.viewForBackgound.layer.shadowOffset = CGSize(width: 0, height: 1.5)
        cell.viewForBackgound.layer.shadowRadius = 2
        return cell
    }
}

// MARK: - UITextViewDelegate
extension DetailSupportHistoryController : UITextViewDelegate{
    func textViewDidChange(_ textView: UITextView) {
        let fixedWidth = textView.frame.size.width
        let newSize = textView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude))
        if newSize.height < 52 {// limit the textview height for 2 lines
            textView.frame.size = CGSize(width: max(newSize.width, fixedWidth), height: newSize.height)
        }
    }
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n"{// check for enter pressed
            textView.resignFirstResponder()
        }
        return true
    }
}
