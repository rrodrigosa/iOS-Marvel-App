//
//  Alerts.swift
//  MarvelHeroes
//
//  Created by RodrigoSA on 12/17/20.
//

import Foundation
import UIKit

protocol AlertExtension {
    func alert(title: String, message: String, actions: [UIAlertAction]?)
}

extension AlertExtension where Self: UIViewController {
    func alert(title: String, message: String, actions: [UIAlertAction]? = nil) {
        guard presentedViewController == nil else {
            return
        }
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        actions?.forEach { action in
            alertController.addAction(action)
        }
        present(alertController, animated: true)
    }
}
