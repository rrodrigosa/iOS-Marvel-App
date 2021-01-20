//
//  FileManager.swift
//  MarvelHeroes
//
//  Created by RodrigoSA on 1/19/21.
//

import Foundation

class JsonManager {
    func decodeAPIReturnDataSet(data: Data) -> APIReturnDataSet? {
        do {
            let decodedData = try JSONDecoder().decode(APIReturnDataSet.self,
                                                       from: data)
            return decodedData
        } catch {
            return nil
        }
    }
    
    func retrieveAPIDataFromDocuments() -> Data? {
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
    
    func fileManager(apiData: Data, apiReturnDataSet: APIReturnDataSet) {
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
