//
//  APIReturnDataSet.swift
//  MarvelHeroes
//
//  Created by RodrigoSA on 10/7/20.
//

import Foundation

struct APIReturnDataSet: Codable {
    let code: Int?
    let status: String?
    let attributionText: String?
    
    var data: APIData?
}

struct APIData: Codable {
    var offset: Int?
    let limit: Int?
    let total: Int?
    var count: Int?
    var results: [Character]?
}
