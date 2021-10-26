//
//  APIs.swift
//  iOS_API_DashBoardPlug
//
//  Created by macbook pro on 18/07/18.
//  Copyright © 2018 Omni-Bridge. All rights reserved.
//

import Foundation

class APIs : NSObject{
    /// Host API
    static let HOST_API = "\(UserDefaults.standard.value(forKey: "StartURLFromServer") ?? "")/api"
    
    /// POST method
    ///
    /// - Parameters:
    ///   - requestStr: Request string
    ///   - jsonData: Json object
    ///   - completion: callback
    static func performPost(requestStr: String, jsonData:Any!, completion: @escaping (_ data: Any?) -> Void) {
        DispatchQueue.global(qos: .background).async {
            let urlStr = "\(self.HOST_API)\(requestStr)"
            let targetURL = URL.init(string: urlStr)
            let request = NSMutableURLRequest(url: targetURL! as URL)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            let data = self.convertJsonObjectToData(jsonData)
            request.httpBody = data
            let task = URLSession.shared.dataTask(with: request as URLRequest) { (data, resp, error) -> Void in
                DispatchQueue.main.async(execute: { () -> Void in
                    if (data != nil) {
                        let json = self.convertDataToJsonObject(data!)
                        completion(json)
                    } else {
                        print(error ?? "error")
                        completion(nil)
                    }
                })
                return()
            }
            task.resume()
        }
    }
    /// GET method
    ///
    /// - Parameters:
    ///   - requestStr: Request string
    ///   - query: Query string
    ///   - completion: callback
    static func performGet(requestStr: String, query:String, completion: @escaping (_ data: Any?) -> Void) {
        DispatchQueue.global(qos: .background).async {
            let urlStr = "\(self.HOST_API)\(requestStr)?\(query)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
            let targetURL = URL.init(string: urlStr!)
            let request = NSMutableURLRequest(url: targetURL! as URL)
            request.httpMethod = "GET"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            let sessionConfig = URLSessionConfiguration.default
            sessionConfig.timeoutIntervalForRequest = 60
            let task = URLSession(configuration: sessionConfig).dataTask(with: request as URLRequest) { (data, resp, error) -> Void in
                DispatchQueue.main.async(execute: { () -> Void in
                    if (data != nil) {
                        let json = self.convertDataToJsonObject(data!)
                        completion(json)
                    } else {
                        print(error ?? "error")
                        completion(nil)
                    }
                })
                return()
            }
            task.resume()
        }
    }
    
    /// Used to conver json into nsdata
    ///
    /// - Parameter jsonObj: json object
    /// - Returns: nddata
    static func convertJsonObjectToData(_ jsonObj:Any) -> Data! {
        do {
            let data = try JSONSerialization.data(withJSONObject: jsonObj, options: JSONSerialization.WritingOptions.prettyPrinted)
            return data
        } catch let error {
            print(error)
            return nil
        }
    }
    
    /// Used to conver data into json
    ///
    /// - Parameter data: NSdata
    /// - Returns: Json object
    static func convertDataToJsonObject(_ data:Data) -> Any! {
        do {
            let data = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments)
            return data
        } catch let error {
            print(error)
            return nil
        }
    }
}


/// Get Configuration API starting URL
struct GetApiConfig {
    
    static let URL_INDEX = 0
    static let URL_IDENTIFIER = "devBaseUrl"
    
    static func execute() -> Bool {
        let urlStr = "https://www.plug-able.com/PlugsApiConfig.json".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        let targetURL = URL.init(string: urlStr!)
        let request = NSMutableURLRequest(url: targetURL! as URL)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        var success = false
        let semaphore = DispatchSemaphore(value: 0)
        let task = URLSession.shared.dataTask(with: request as URLRequest) { (data, resp, error) -> Void in
            if (data != nil) {
                if let json = APIs.convertDataToJsonObject(data!) as? NSDictionary{
                    if let apiConfigArr = json.value(forKey: "apiConfig") as? NSArray{
                        if let url = (apiConfigArr[self.URL_INDEX] as? NSDictionary)?.value(forKey: self.URL_IDENTIFIER) as? String{
                            print(url)
                            UserDefaults.standard.set(url, forKey: "StartURLFromServer")
                            success = true
                        }
                    }
                }
            } else {
                print(error ?? "error")
            }
            
            semaphore.signal()
        }
        task.resume()
        _ = semaphore.wait(timeout: DispatchTime.distantFuture)
        return success
    }
}
