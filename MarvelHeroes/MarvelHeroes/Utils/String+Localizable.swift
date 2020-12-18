//
//  String+Localizable.swift
//  MarvelHeroes
//
//  Created by RodrigoSA on 12/17/20.
//

import Foundation

extension String {
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
}
