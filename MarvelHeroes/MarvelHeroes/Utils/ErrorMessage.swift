//
//  ErrorMessage.swift
//  MarvelHeroes
//
//  Created by RodrigoSA on 12/17/20.
//

import Foundation

enum ErrorMessage: Error {
    case apiNoData
    case decode
    case resultNoData
    case statusCode
    case noStatusCode
    
    var message: String {
        switch self {
        case .apiNoData:
            return "No data received from API".localized
        case .decode:
            return "Could not decode API data into characters".localized
        case .resultNoData:
            return "No character data received from API".localized
        case .statusCode:
            return "Status code: %d".localized
        case .noStatusCode:
            return "No status code received".localized
        }
    }
}
