//
//  APIReturnDataSet.swift
//  MarvelHeroes
//
//  Created by RodrigoSA on 10/7/20.
//

import Foundation

struct APIReturnDataSet: Codable {
    var code: Int?
    var status: String?
    var attributionText: String?
    
    var data: APIData?
    
    enum CodingKeys: String, CodingKey {
        case code
        case status
        case attributionText
        case data
    }

    
}
