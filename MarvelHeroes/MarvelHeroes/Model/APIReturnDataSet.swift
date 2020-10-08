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
    
    let data: APIData?
}
