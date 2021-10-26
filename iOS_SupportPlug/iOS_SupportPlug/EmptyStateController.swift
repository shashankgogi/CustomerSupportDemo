//
//  EmptyStateController.swift
//  iOS_SupportPlug
//
//  Created by macbook pro on 10/09/18.
//  Copyright © 2018 Omni-Bridge. All rights reserved.
//

import Foundation
import UIKit

class EmptyStateController: UIViewController {
    
    // MARK:- view life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /// Used tp present alert view
    ///
    /// - Parameter sender: Uibutton
    @IBAction func refreshPressed(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
}
