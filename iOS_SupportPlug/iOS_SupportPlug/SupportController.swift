//
//  ViewController.swift
//  iOS_SupportPlug
//
//  Created by macbook pro on 05/09/18.
//  Copyright © 2018 Omni-Bridge. All rights reserved.
//

import UIKit
import DropDown

class SupportController: UIViewController {
    
    // MARK:- Outlet and Variable declaration
    
    @IBOutlet weak var btnForMainCategory: UIButton!
    @IBOutlet weak var btnForQuesCategory: UIButton!
    @IBOutlet weak var txtViewForQuery: UITextView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var lblForCharCount: UILabel!
    @IBOutlet weak var activityLoader: UIActivityIndicatorView!
    
    let mainCayegoryDropDown = DropDown()
    let quesCayegoryDropDown = DropDown()
    
    var mainCategotyArr =  NSArray()
    var quesCategotyArr =  NSArray()
    
    var mainCategotyId =  0
    var quesCategotyId =  0
    
    // MARK:- View life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.scrollView.contentSize = CGSize(width: self.scrollView.frame.size.height, height: self.scrollView.frame.size.height)
        self.txtViewForQuery.layer.borderColor = UIColor(netHex: 0x7E7E83).cgColor
        statrLoader()
        callMainCategoryAPI()
    }
    
    // MARK:- Custom methods
    
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
    
    
    /// Used to call main category API
    func callMainCategoryAPI(){
        APIs.performGet(requestStr: "/support/getmaincategories", query: "") { (data) in
            if let resp = data as? NSDictionary{
                if let categoryArr = resp.value(forKey: "data") as? NSArray {
                    var mainCateArr = [String]()
                    self.mainCategotyArr = categoryArr
                    for catDict in categoryArr{
                        mainCateArr.append((catDict as! NSDictionary).value(forKey: "name") as! String)
                    }
                    self.setMainCategoryDropDown(catArr: mainCateArr)
                }
            }
            self.stopLoader()
        }
    }
    
    /// Used to call main category API ?
    func callQuesCategoryAPI(catId : Int){
        self.statrLoader()
        APIs.performGet(requestStr: "/support/GetCategories", query: "MainCategoryId=\(catId)") { (data) in
            if let resp = data as? NSDictionary{
                if let categoryArr = resp.value(forKey: "data") as? NSArray {
                    var quesCateArr = [String]()
                    quesCateArr.append("Select question category")
                    self.quesCategotyArr = categoryArr
                    for catDict in categoryArr{
                        quesCateArr.append((catDict as! NSDictionary).value(forKey: "name") as! String)
                    }
                    self.setQuesCategoryDropDown(queArr: quesCateArr)
                }
            }
            self.stopLoader()
        }
    }
    
    /// Posting query on server
    func callPostApiToSedQuery() {
        var jsonData = ["userId": 1004,
                        "query": self.txtViewForQuery.text.trimmingCharacters(in: .whitespaces),
                        "mainCategoryId": self.mainCategotyId ,
                        "questionCategoryId": self.quesCategotyId] as [String : Any]
        if quesCategotyId == 0{
            jsonData = ["userId": 1004,
                        "query": self.txtViewForQuery.text.trimmingCharacters(in: .whitespaces),
                        "mainCategoryId": self.mainCategotyId ]
        }
        self.statrLoader()
        APIs.performPost(requestStr: "/support/Query", jsonData: jsonData) { (response) in
            if let respDict = response as? NSDictionary{
                if respDict.value(forKey: "message") as! String == "Query Submited sucessfully."{
                    self.txtViewForQuery.text = "Enter your query here..."
                    self.mainCategotyId = 0
                    self.quesCategotyId = 0
                    self.mainCayegoryDropDown.clearSelection()
                    self.quesCayegoryDropDown.clearSelection()
                    self.setQuesCategoryDropDown(queArr: [String]())
                    self.lblForCharCount.text = "160"
                    self.txtViewForQuery.resignFirstResponder()
                    self.btnForMainCategory.setTitle("Select Main Category", for: .normal)
                    self.btnForQuesCategory.setTitle("Select Question Category (optional)", for: .normal)
                    self.createAlertView(title: "Thank You!", message: "Your query has been sent successfully! We'll reply within 24hrs.")
                }else{
                    self.createAlertView(title: "Alert !", message: respDict.value(forKey: "message") as! String)
                }
            }
            self.stopLoader()
        }
    }
    
    /// Setting main category dropdown
    ///
    /// - Parameter catArr: category name array
    func setMainCategoryDropDown(catArr : [String]){
        mainCayegoryDropDown.anchorView = self.btnForMainCategory // UIView or UIBarButtonItem
        mainCayegoryDropDown.bottomOffset = CGPoint(x: 0, y: self.btnForMainCategory.bounds.height)
        mainCayegoryDropDown.dataSource = catArr
        mainCayegoryDropDown.selectionAction = { (index: Int, item: String) in
            self.btnForMainCategory.setTitle(item, for: .normal)
            if let catId = (self.mainCategotyArr[index]  as! NSDictionary).value(forKey: "id"){
                if self.mainCategotyId != catId as! Int{
                    self.callQuesCategoryAPI(catId: catId as! Int)
                    self.quesCategotyId = 0
                    self.btnForQuesCategory.setTitle("Select Question Category (optional)", for: .normal)
                }
                self.mainCategotyId = catId as! Int
            }
        }
    }
    /// Setting question category dropdown
    ///
    /// - Parameter catArr: question name array
    func setQuesCategoryDropDown(queArr : [String]){
        quesCayegoryDropDown.anchorView = self.btnForQuesCategory // UIView or UIBarButtonItem
        quesCayegoryDropDown.bottomOffset = CGPoint(x: 0, y: self.btnForQuesCategory.bounds.height)
        quesCayegoryDropDown.dataSource = queArr
        quesCayegoryDropDown.selectionAction = { (index: Int, item: String) in
            if index == 0{
                self.quesCategotyId = 0
                self.btnForQuesCategory.setTitle("Select Question Category (optional)", for: .normal)
            }else if let queId = (self.quesCategotyArr[index - 1]  as! NSDictionary).value(forKey: "id"){
                self.quesCategotyId = queId as! Int
                self.btnForQuesCategory.setTitle(item, for: .normal)
            }
        }
    }
    
    /// Present alert view
    ///
    /// - Parameters:
    ///   - title: tite
    ///   - message: message
    func createAlertView(title : String , message : String) {
        let alertVc = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alertVc.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        alertVc.view.tintColor = UIColor(netHex: 0x5B00AF)
        self.present(alertVc, animated: true, completion: nil)
    }
    
    // MARK:- Button action methods
    
    @IBAction func MainCategoryPressed(_ sender: Any) {
        mainCayegoryDropDown.show()
    }
    @IBAction func QuesCategoryPressed(_ sender: Any) {
        quesCayegoryDropDown.show()
    }
    @IBAction func ShowHistoryPressed(_ sender: Any) {
        if General.isConnectedToNetwork(){
            self.performSegue(withIdentifier: "HistorySegue", sender: self)
            self.txtViewForQuery.text = "Enter your query here..."
            self.mainCategotyId = 0
            self.quesCategotyId = 0
            self.mainCayegoryDropDown.clearSelection()
            self.quesCayegoryDropDown.clearSelection()
            self.setQuesCategoryDropDown(queArr: [String]())
            self.lblForCharCount.text = "160"
            self.btnForMainCategory.setTitle("Select Main Category", for: .normal)
            self.btnForQuesCategory.setTitle("Select Question Category (optional)", for: .normal)
            self.txtViewForQuery.resignFirstResponder()
        }else{
            self.present(General.NetworkErrorAlertView(), animated: true, completion: nil)
        }
    }
    
    @IBAction func SendPressed(_ sender: Any) {
        if self.txtViewForQuery.text.trimmingCharacters(in: .whitespaces).count == 0 || self.txtViewForQuery.text == "Enter your query here..." {
            self.createAlertView(title: "Alert !", message: "Query text can not be empty")
            return
        }else if mainCategotyId == 0{
            self.createAlertView(title: "Alert !", message: "Please select main category !")
            return
        }else if General.isConnectedToNetwork(){
            self.callPostApiToSedQuery()
        }else{
            self.present(General.NetworkErrorAlertView(), animated: true, completion: nil)
        }
    }
}

// MARK: - UITextViewDelegate
extension  SupportController : UITextViewDelegate{
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == "Enter your query here..."{
            self.txtViewForQuery.text = ""
        }
    }
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty{
            self.txtViewForQuery.text = "Enter your query here..."
        }
    }
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let charCount = self.txtViewForQuery.text.count - range.length + text.count
        if text == "\n"{
            textView.resignFirstResponder()
            return true
        }else if text == " " && charCount == 1{
            return false
        }
        if charCount < 161{
            self.lblForCharCount.text = "\(160 - charCount)"
        }
        return charCount <= 160
    }
    
}
