//
//  APIReturnDataSet.swift
//  MarvelHeroes
//
//  Created by RodrigoSA on 10/7/20.
//

import Foundation

struct APIReturnDataSet: Decodable {
    let code: Int?
    let status: String?
    let attributionText: String?
    
    let data: APIData?
}

struct APIData: Decodable {
    let offset: Int?
    let limit: Int?
    let total: Int?
    let count: Int?
    let results: [Character]?
}
