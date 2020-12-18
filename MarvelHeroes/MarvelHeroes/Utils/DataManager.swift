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
    
    // MARK: -> requestData
    func downloadCharacters(limit: Int, offset: Int, completion:  @escaping (_ dataSet: APIReturnDataSet?, _ results: [Character]?, _ error: String) -> Void) {
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
            guard let marvelReturnData = self.decodeAPIReturnDataSet(data: responseData) else {
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
    }
    
    func decodeAPIReturnDataSet(data: Data) -> APIReturnDataSet? {
        do {
            let decodedData = try JSONDecoder().decode(APIReturnDataSet.self,
                                                       from: data)
            return decodedData
        } catch {
            return nil
        }
    }
    
}

