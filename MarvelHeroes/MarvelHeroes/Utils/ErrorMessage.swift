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
    case thumbnailDownload
    
    var message: String {
        switch self {
        case .apiNoData:
            return "No data received from API"
        case .decode:
            return "Could not decode API data into characters"
        case .resultNoData:
            return "No data received on API result"
        case .statusCode:
            return "Status code: %d"
        case .noStatusCode:
            return "No status code received"
        case .thumbnailDownload:
            return "Could not download thumbnail. Try again later"
        }
    }
}
