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
    func didReceive(data: [Character])
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
            self.keys = NSDictionary(contentsOfFile: path)!
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
    
    
    // MARK: -> delegate
    func setData(decodedData: [Character]) -> Void {
        delegate?.didReceive(data: decodedData)
    }
    
    func setError(error: Error) {
        delegate?.didFail(_with: error)
    }
    
}

