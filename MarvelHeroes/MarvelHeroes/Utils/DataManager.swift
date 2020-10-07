//
//  DataManager.swift
//  MarvelHeroes
//
//  Created by RodrigoSA on 10/7/20.
//

import Foundation

protocol DataDelegate {
    func didReceive(data: [Character])
    func didFail(_with error: Error)
}

public class DataManager {
    var delegate: DataDelegate?
    
    func setData(decodedData: [Character]) -> Void {
        delegate?.didReceive(data: decodedData)
    }
    
    func setError(error: Error) {
        delegate?.didFail(_with: error)
    }
    
}

