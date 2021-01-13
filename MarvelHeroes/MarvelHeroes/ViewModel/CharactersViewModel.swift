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
    private var filteredCharacters: [Character] = []
    private let limit = 50
    private var offset = 0
    private var isFetchingAPIData = false
    private let dataManager = DataManager()
    private var marvelAttributionText = ""
    
    init(delegate: CharactersViewModelDelegate) {
        self.delegate = delegate
    }
    
    var charactersCount: Int {
        return characters.count
    }
    
    var filteredCharactersCount: Int {
        return filteredCharacters.count
    }
    
    func getCharacters() -> [Character] {
        return characters
    }
    
    func getCharacter(at index: Int) -> Character {
        return characters[index]
    }
    
    func getFilteredCharacter(at index: Int) -> Character {
        return filteredCharacters[index]
    }
    
    func setCharacterNoDescription(at index: Int) {
        characters[index].description = "No description available".localized
    }
    
    func getMarvelAttributionText() -> String {
        return marvelAttributionText
    }
    
    func fetchCharacters() {
        guard !isFetchingAPIData else {
            return
        }
        isFetchingAPIData = true
        
        dataManager.downloadCharacters(limit: limit, offset: offset) {
            (data: APIReturnDataSet?, results: [Character]?, error: String) in
            self.isFetchingAPIData = false
            
            guard let unwrappedAPIReturnDataSet = data, let unwrappedResults = results else {
                self.delegate?.onFetchFailed(error: error)
                return
            }
            
            if !self.characters.isEmpty {
                // removes the blank character object before appending new data
                self.characters.removeLast()
            }
            
            self.characters.append(contentsOf: unwrappedResults)
            
            // add a blank character at the end of the list, so a loading cell can be added to that position
            self.characters.append(Character(id: 0, name: "", description: "", thumbnail: nil, image: nil))
            
            if let unwrappedAttributionText = unwrappedAPIReturnDataSet.attributionText {
                self.marvelAttributionText = unwrappedAttributionText
            }
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
    
    private func calculateIndexPathsToReload(from newCharacters: [Character]) -> [IndexPath] {
        let startIndex = characters.count - newCharacters.count
        let endIndex = startIndex + newCharacters.count
        return (startIndex..<endIndex).map { IndexPath(row: $0, section: 0) }
    }
    
    func filterCharacters(searchText: String) {
        filteredCharacters = getCharacters().filter { character in
            if let unwrappedBool = character.name?.contains(searchText) {
                if unwrappedBool { // remove
                    print("print - name: \(character.name!) | Bool: \(unwrappedBool)")
                    return unwrappedBool
                }
                return false
            } else {
                return false
            }
        }
    }
    
}
