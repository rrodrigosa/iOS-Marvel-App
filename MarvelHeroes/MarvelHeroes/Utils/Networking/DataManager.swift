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
    
    
    // MARK: -> loadCharactersFromDocuments
    func loadCharactersFromDocuments(completion:  @escaping (_ dataSet: APIReturnDataSet?, _ results: [Character]?, _ error: String) -> Void) {
        print("print - (loadCharactersFromDocuments)")

        guard let responseData = retrieveAPIDataFromDocuments() else {
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
            guard let marvelReturnData = self.decodeAPIReturnDataSet(data: responseData) else {
                completion(nil, nil, ErrorMessage.decode.message)
                return
            }
            self.fileManager(apiData: responseData, apiReturnDataSet: marvelReturnData)
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
    
    private func retrieveAPIDataFromDocuments() -> Data? {
        if let filePath = apiDataPath(),
           let fileData = FileManager.default.contents(atPath: filePath.path) {
            return fileData
        }
        return nil
    }
    
    private func retrieveDecodedData() -> APIReturnDataSet? {
        guard let data = retrieveAPIDataFromDocuments() else {
            return nil
        }
        return decodeAPIReturnDataSet(data: data)
    }
    
    private func fileManager(apiData: Data, apiReturnDataSet: APIReturnDataSet) {
        // save everything
        if apiReturnDataSet.data?.offset == 0 {
            configureToStoreAPIData(apiReturnDataSet: apiReturnDataSet)
        }
        // append the new values received by the api then save
        else {
            var apiReturnDataSetCopy = apiReturnDataSet
            apiReturnDataSetCopy.data?.offset = 0
            guard let resultsFromDocuments = retrieveDecodedData()?.data?.results else {
                return
            }
            guard let newResults = apiReturnDataSet.data?.results else {
                return
            }
            apiReturnDataSetCopy.data?.results = resultsFromDocuments
            apiReturnDataSetCopy.data?.results?.append(contentsOf: newResults)
            let count = apiReturnDataSetCopy.data?.results?.count
            apiReturnDataSetCopy.data?.count = count
            configureToStoreAPIData(apiReturnDataSet: apiReturnDataSetCopy)
        }
    }
    
    private func configureToStoreAPIData(apiReturnDataSet: APIReturnDataSet) {
        guard let encodeToData = encodeToData(apiReturnDataSet: apiReturnDataSet) else {
            return
        }
        storeAPIData(apiData: encodeToData)
    }
    
    private func encodeToData(apiReturnDataSet: APIReturnDataSet) -> Data? {
        // encode to data again so unnecessary fields from API are ignored
        do {
            let encoder = JSONEncoder()
            let jsonData = try encoder.encode(apiReturnDataSet)
            return jsonData
        }catch{
            return nil
        }
    }
    
    private func storeAPIData(apiData: Data) {
        if let filePath = apiDataPath() {
            do  {
                try apiData.write(to: filePath, options: .atomic)
            } catch _ {
            }
        }
    }
    
    private func apiDataPath() -> URL? {
        let fileManager = FileManager.default
        guard let documentPath = fileManager.urls(for: .documentDirectory,
                                                  in: FileManager.SearchPathDomainMask.userDomainMask).first else { return nil }
        let appendedDocumentPath = documentPath.appendingPathComponent("apiData.json")
//        print("path: \(appendedDocumentPath)")
        return appendedDocumentPath
    }
    
    func apiDataExistsOnDocuments() -> Bool {
        let fileManager = FileManager.default
        guard let documentPath = fileManager.urls(for: .documentDirectory,
                                                  in: FileManager.SearchPathDomainMask.userDomainMask).first else { return false }
        let appendedDocumentPath = documentPath.appendingPathComponent("apiData.json")
        return fileManager.fileExists(atPath: appendedDocumentPath.path)
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
