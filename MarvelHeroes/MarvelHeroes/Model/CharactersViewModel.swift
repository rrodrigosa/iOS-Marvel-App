//
//  CharactersViewModel.swift
//  MarvelHeroes
//
//  Created by RodrigoSA on 12/7/20.
//

import Foundation

protocol CharactersViewModelDelegate: AnyObject {
    func onFetchCompleted(indexPathsToReload: [IndexPath]?)
    func onFetchFailed(error: String)
}

final class CharactersViewModel {
    private weak var delegate: CharactersViewModelDelegate?
    
    private var characters: [APIResult] = []
    private let limit = 50
    private var offset = 0
    private var isFetchingAPIData = false
    private let dataManager = DataManager()
    
    var charactersCount: Int {
        return characters.count
    }
    
    func character(at index: Int) -> APIResult {
        return characters[index]
    }
    
    func fetchCharacters() {
        guard !isFetchingAPIData else {
            return
        }
        isFetchingAPIData = true
        
        dataManager.downloadCharacters(limit: limit, offset: offset) {
            (data: APIReturnDataSet?, results: [APIResult]?, error: String) in
            self.isFetchingAPIData = false
            
            // Fetch ok
            if let unwrappedResults = results {
                self.characters += unwrappedResults
                
                if let unwrappedAPIReturnDataSet = data {
                    if let unwrappedData = unwrappedAPIReturnDataSet.data {
                        if let unwrappedCount = unwrappedData.count {
                            self.offset += unwrappedCount
                        }
                    }
                }
                
                if (self.offset >= self.limit) {
                    let indexPathsToReload = self.calculateIndexPathsToReload(from: unwrappedResults)
                    self.delegate?.onFetchCompleted(indexPathsToReload: indexPathsToReload)
                } else {
                    self.delegate?.onFetchCompleted(indexPathsToReload: nil)
                }
            }
            // Fetch error
            else {
                self.delegate?.onFetchFailed(error: "error")
            }
        }
    }
    
      private func calculateIndexPathsToReload(from newCharacters: [APIResult]) -> [IndexPath] {
        let startIndex = characters.count - newCharacters.count
        let endIndex = startIndex + newCharacters.count
        return (startIndex..<endIndex).map { IndexPath(row: $0, section: 0) }
      }
    
}
