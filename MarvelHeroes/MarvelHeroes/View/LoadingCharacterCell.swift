//
//  LoadingCharacterCell.swift
//  MarvelHeroes
//
//  Created by RodrigoSA on 1/6/21.
//

import UIKit

class LoadingCharacterCell: UITableViewCell {
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    func startSpinner() {
        activityIndicator.startAnimating()
    }

}
