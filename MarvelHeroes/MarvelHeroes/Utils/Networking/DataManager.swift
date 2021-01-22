//
//  DataManager.swift
//  MarvelHeroes
//
//  Created by RodrigoSA on 10/7/20.
//

import Foundation
import Alamofire
import CryptoSwift

struct KeyDict {
    let publicKey: String!
    let privateKey: String!
}

class DataManager {
    private var keys: NSDictionary?
    private let jsonManager = JsonManager()
    
    // get keys on resources bundle
    func getKeys() -> KeyDict {
        if let path = Bundle.main.path(forResource: "apikeys", ofType: "plist") {
            keys = NSDictionary(contentsOfFile: path)!
        }
        
        if let data = keys {
            return KeyDict(publicKey: data["publicKey"] as! String, privateKey: data["privateKey"] as! String)
        } else {
            return KeyDict(publicKey: "", privateKey: "")
        }
    }
    
    
    // MARK: -> loadCharactersFromDocuments
    func loadCharactersFromDocuments(completion:  @escaping (_ dataSet: APIReturnDataSet?, _ results: [Character]?, _ error: String) -> Void) {
        print("print - (loadCharactersFromDocuments)")

        guard let responseData = jsonManager.retrieveAPIDataFromDocuments() else {
            completion(nil, nil, ErrorMessage.apiNoData.message)
            return
        }
        guard let marvelReturnData = jsonManager.decodeAPIReturnDataSet(data: responseData) else {
            completion(nil, nil, ErrorMessage.decode.message)
            return
        }
        guard marvelReturnData.code == 200 else {
            // nil or something else
            if let unwrappedMarvelReturnDataCode = marvelReturnData.code {
                let message = String(format: ErrorMessage.statusCode.message, unwrappedMarvelReturnDataCode)
                completion(nil, nil, message)
                return
            }
            completion(nil, nil, ErrorMessage.noStatusCode.message)
            return
        }
        guard let results = marvelReturnData.data?.results else {
            completion(nil, nil, ErrorMessage.resultNoData.message)
            return
        }
        completion(marvelReturnData, results, "No Errors")
    }
    
    // MARK: -> requestData
    func downloadCharacters(limit: Int, offset: Int, completion:  @escaping (_ dataSet: APIReturnDataSet?, _ results: [Character]?, _ error: String) -> Void) {
        print("print - (downloadCharacters)")
        let dict: KeyDict = self.getKeys()
        let baseMarvelURL = "https://gateway.marvel.com/v1/public/characters"
        let ts = NSDate().timeIntervalSince1970.description
        
        let params: Parameters = [
            "apikey": dict.publicKey!,
            "ts": ts,
            "hash": (ts + dict.privateKey! + dict.publicKey!).md5(),
            "limit" : limit,
            "offset" : offset,
        ]
        
        AF.request(baseMarvelURL, parameters: params).validate().responseJSON { response in
            guard let responseData = response.data else {
                completion(nil, nil, ErrorMessage.apiNoData.message)
                return
            }
            guard let marvelReturnData = self.jsonManager.decodeAPIReturnDataSet(data: responseData) else {
                completion(nil, nil, ErrorMessage.decode.message)
                return
            }
            self.jsonManager.fileManager(apiReturnDataSet: marvelReturnData)
            guard marvelReturnData.code == 200 else {
                // nil or something else
                if let unwrappedMarvelReturnDataCode = marvelReturnData.code {
                    let message = String(format: ErrorMessage.statusCode.message, unwrappedMarvelReturnDataCode)
                    completion(nil, nil, message)
                    return
                }
                completion(nil, nil, ErrorMessage.noStatusCode.message)
                return
            }
            guard let results = marvelReturnData.data?.results else {
                completion(nil, nil, ErrorMessage.resultNoData.message)
                return
            }
            completion(marvelReturnData, results, "No Errors")
        }
    }
    
}

private enum ErrorMessage: Error {
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
