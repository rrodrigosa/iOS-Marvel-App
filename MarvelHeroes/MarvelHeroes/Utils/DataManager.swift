//
//  DataManager.swift
//  MarvelHeroes
//
//  Created by RodrigoSA on 10/7/20.
//

import Foundation
import Alamofire
import CryptoSwift

protocol DataDelegate {
    func didReceive(data: [APIResult])
    func didFail(_with error: Error)
}

struct KeyDict {
    let publicKey: String!
    let privateKey: String!
}

public class DataManager {
    var delegate: DataDelegate?
    
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
    // for online json - TODO
    func requestData() {
    }
    
    func downloadCharacters(limit: Int, offset: Int, completion:  @escaping (_ dataSet: APIReturnDataSet?, _ results: [APIResult]?, _ errorString:String) -> Void) {
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
                completion(nil, [], "Error no data received")
                return
            }
            guard let marvelReturnData = self.decodeAPIReturnDataSet(data: responseData) else {
                completion(nil, [], "Error initializating marvel data object")
                return
            }
            guard marvelReturnData.code == 200 else {
                completion(nil, [], "Error Return Code: \(String(describing: marvelReturnData.code))")
                return
            }
            guard let results = marvelReturnData.data?.results else {
                completion(nil, [], "No data returned")
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
    
    // MARK: -> delegate
    func setData(decodedData: [APIResult]) -> Void {
        delegate?.didReceive(data: decodedData)
    }
    
    func setError(error: Error) {
        delegate?.didFail(_with: error)
    }
    
}

