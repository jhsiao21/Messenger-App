//
//  UIViewController+Ext.swift
//  Messenger
//
//  Created by LoganMacMini on 2024/2/3.
//

import Foundation
import UIKit

extension UIViewController {
    func showUIAlert(title: String = "Error", message: String, actionTitle: String = "Confirm") {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: actionTitle, style: .default, handler: nil))
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
}
