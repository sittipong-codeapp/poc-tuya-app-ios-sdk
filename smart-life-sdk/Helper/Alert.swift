//
//  Alert.swift
//  smart-life-sdk
//
//  Created by Sittipong Suwannatrai on 18/1/23.
//

import Foundation

struct Alert {
    
    static func showBasicAlert(on vc: UIViewController, with title: String, message: String, actions: [UIAlertAction] = [UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default)]) {
        let alertVC = UIAlertController(title: title, message: message, preferredStyle: .alert)

        for action in actions {
            alertVC.addAction(action)
        }
        
        DispatchQueue.main.async {
            vc.present(alertVC, animated: true)
        }
    }
    
    static func showActionSheet(on vc: UIViewController, with title: String, message: String?, actions: [UIAlertAction]) {
        let alertVC = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)

        for action in actions {
            alertVC.addAction(action)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alertVC.addAction(cancelAction)
        
        DispatchQueue.main.async {
            vc.present(alertVC, animated: true)
        }
    }
    
}
