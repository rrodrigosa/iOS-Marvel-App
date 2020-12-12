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
    
    private var characters: [Character] = []
    private let limit = 50
    private var offset = 0
    private var isFetchingAPIData = false
    private let dataManager = DataManager()
    
    init(delegate: CharactersViewModelDelegate) {
        self.delegate = delegate
    }
    
    var charactersCount: Int {
        return characters.count
    }
    
    func getCharacters() -> [Character] {
        return characters
    }
    
    func getCharacter(at index: Int) -> Character {
        return characters[index]
    }
    
    func setCharacterNoDescription(at index: Int) {
        characters[index].description = "No description available"
    }
    
    func fetchCharacters() {
        guard !isFetchingAPIData else {
            return
        }
        isFetchingAPIData = true
        
        dataManager.downloadCharacters(limit: limit, offset: offset) {
            (data: APIReturnDataSet?, results: [Character]?, error: String) in
            self.isFetchingAPIData = false
            
            // Fetch ok
            if let unwrappedResults = results {
                self.characters.append(contentsOf: unwrappedResults)
                
                if let unwrappedAPIReturnDataSet = data {
                    if let unwrappedData = unwrappedAPIReturnDataSet.data {
                        if let unwrappedCount = unwrappedData.count {
                            self.offset += unwrappedCount
                        }
                        
                        if let unwrappedOffset = unwrappedData.offset {
                            if (unwrappedOffset >= self.limit) {
                                let indexPathsToReload = self.calculateIndexPathsToReload(from: unwrappedResults)
                                self.delegate?.onFetchCompleted(indexPathsToReload: indexPathsToReload)
                            } else {
                                self.delegate?.onFetchCompleted(indexPathsToReload: .none)
                            }
                        }
                    }
                }
            }
            // Fetch error
            else {
                self.delegate?.onFetchFailed(error: "error")
            }
        }
    }
    
    private func calculateIndexPathsToReload(from newCharacters: [Character]) -> [IndexPath] {
        let startIndex = characters.count - newCharacters.count
        let endIndex = startIndex + newCharacters.count
        return (startIndex..<endIndex).map { IndexPath(row: $0, section: 0) }
    }
    
}
