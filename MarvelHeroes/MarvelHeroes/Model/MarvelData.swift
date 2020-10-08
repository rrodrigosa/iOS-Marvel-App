//
//  MarvelData.swift
//  MarvelHeroes
//
//  Created by RodrigoSA on 10/7/20.
//

import Foundation

struct APIData: Codable {
    let offset: Int?
    let limit: Int?
    let total: Int?
    let count: Int?
    let results: [APIResult]?
}

struct APIResult: Codable {
    let id: Int?
    let name: String?
    let description: String?
    let thumbnail: APIImageResult?
}

struct APIImageResult: Codable {
    private let fileExtension: String?
    private let _path: String!
    
    private var path: String? {
        return self.securePath(path: _path)
    }
    
    var url: URL? {
        return URL(string: self.securePath(path: self._path) + "." + self.fileExtension!)
    }
    
    private func securePath(path:String) -> String {
        if path.hasPrefix("http://") {
            let range = path.range(of: "http://")
            var newPath = path
            newPath.removeSubrange(range!)
            return "https://" + newPath
        } else {
            return path
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case _path = "path"
        case fileExtension = "extension"
    }
}
