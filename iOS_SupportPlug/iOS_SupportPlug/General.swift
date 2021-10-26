//
//  General.swift
//  iOS_SupportPlug
//
//  Created by macbook pro on 07/09/18.
//  Copyright © 2018 Omni-Bridge. All rights reserved.
//

import UIKit
import SystemConfiguration

class General {
    /// Used to check connectivity
    ///
    /// - Returns: flag
    class func isConnectedToNetwork() -> Bool {
        var zeroAddress = sockaddr_in(sin_len: 0, sin_family: 0, sin_port: 0, sin_addr: in_addr(s_addr: 0), sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {zeroSockAddress in
                SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
            }
        }
        
        var flags: SCNetworkReachabilityFlags = SCNetworkReachabilityFlags(rawValue: 0)
        if SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) == false {
            return false
        }
        // Working for Cellular and WIFI
        let isReachable = (flags.rawValue & UInt32(kSCNetworkFlagsReachable)) != 0
        let needsConnection = (flags.rawValue & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
        let isConnected = (isReachable && !needsConnection)
        
        return isConnected
    }
    
    /// Create network not availble alert
    ///
    /// - Returns: Alertview
    class func NetworkErrorAlertView() -> UIAlertController {
        let alertVc = UIAlertController(title: "No Internet!", message: "You don't have active internet connection. Please check your connectivity.", preferredStyle: UIAlertControllerStyle.alert)
        alertVc.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        alertVc.view.tintColor = UIColor(netHex: 0x5B00AF)
        return alertVc
    }
    /// Used to calculate heighr for cell at indexpath
    ///
    /// - Parameter string: given string
    /// - Returns: height of cell at indexpath
    class func heightForString(_ string : String , width : CGFloat , fontSize : CGFloat) -> CGFloat{
        let attrString = NSAttributedString(string: string, attributes: [NSAttributedStringKey.font : UIFont.systemFont(ofSize: fontSize)])
        let rect : CGRect = attrString.boundingRect(with: CGSize(width: width, height: CGFloat.greatestFiniteMagnitude), options: .usesLineFragmentOrigin, context: nil)
        return rect.height
    }
    
    /// Used to get formated date
    ///
    /// - Parameters:
    ///   - timeStamp: timeStamp
    ///   - formator: formator type
    /// - Returns: formated date
    class func getDateFromTimeStamp(timeStamp : Double , formator : String) -> String {
        let date = NSDate(timeIntervalSince1970: timeStamp)
        if formator == ".Short"{
            let messageDate = Date.init(timeIntervalSince1970: TimeInterval(timeStamp))
            let dataformatter = DateFormatter.init()
            dataformatter.timeStyle = .short
            let date = dataformatter.string(from: messageDate)
            return date
        }
        let dayTimePeriodFormatter = DateFormatter()
        dayTimePeriodFormatter.dateFormat = formator
        let dateString = dayTimePeriodFormatter.string(from: date as Date)
        return dateString
    }
}

// MARK: - Uicolor extension used to set color by using hex value
extension UIColor {
    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
    
    convenience init(netHex:Int) {
        self.init(red:(netHex >> 16) & 0xff, green:(netHex >> 8) & 0xff, blue:netHex & 0xff)
    }
}
