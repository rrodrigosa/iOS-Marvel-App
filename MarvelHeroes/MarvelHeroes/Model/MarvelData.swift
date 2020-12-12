//
//  MarvelData.swift
//  MarvelHeroes
//
//  Created by RodrigoSA on 10/7/20.
//

import Foundation
import UIKit

struct APIData: Decodable {
    let offset: Int?
    let limit: Int?
    let total: Int?
    let count: Int?
    let results: [Character]?
}

struct Character: Decodable {
    let id: Int?
    let name: String?
    var description: String?
    let thumbnail: APIImageResult?
    
    var image: UIImage?
    
    private enum CodingKeys: String, CodingKey {
        case id, name, description, thumbnail
    }
}

struct APIImageResult: Decodable {
    let fileExtension: String?
    private let _path: String!
    
    private var path: String? {
        return self.securePath(path: _path)
    }
    
    func getUrlWithParameters(imageVariant: ImageVariants = .standard_fantastic) -> URL? {
        return URL(string: self.securePath(path: self._path) + imageVariant.rawValue + "." + self.fileExtension!)
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

enum ImageVariants: String {
    /// Image size: 65x65px
    case standard_small = "/standard_small"
    /// Image size: 100x100px
    case standard_medium = "/standard_medium"
    /// Image size: 140x140px
    case standard_large = "/standard_large"
    /// Image size: 180x180px
    case standard_amazing = "/standard_amazing"
    /// Image size: 200x200px
    case standard_xlarge = "/standard_xlarge"
    /// Image size: 250x250px
    case standard_fantastic = "/standard_fantastic"
}
