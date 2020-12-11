//
//  CharactersVC.swift
//  MarvelHeroes
//
//  Created by RodrigoSA on 10/7/20.
//

import UIKit

class CharactersController: UITableViewController, UITableViewDataSourcePrefetching, CharactersViewModelDelegate {
    @IBOutlet var charactersTableView: UITableView!
    
    let segueIdentifier = "CellDetails"
    
    private var charactersViewModel: CharactersViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        charactersTableView.dataSource = self
        charactersTableView.prefetchDataSource = self
        
        // add view title
        self.title = "MARVEL CHARACTERS"
        
        charactersViewModel = CharactersViewModel(delegate: self)
        charactersViewModel.fetchCharacters()
        
        // remove empty cells
        charactersTableView.tableFooterView = UIView()
    }
    
    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return charactersViewModel.charactersCount
    }
    
    // MARK: -> cellForRowAt
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CharacterCell", for: indexPath) as! CharacterCell
        cell.organizeCell(charactersViewModel: charactersViewModel, cell: cell, index: indexPath.row)
        return cell
    }
    
    // MARK: -> prefetchRowsAt
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        if indexPaths.contains(where: isLoadingCell) {
            charactersViewModel.fetchCharacters()
        }
    }
    
    func onFetchCompleted(indexPathsToReload: [IndexPath]?) {
        guard let unwrappedIndexPathsToReload = indexPathsToReload else {
            charactersTableView.reloadData()
            return
        }
        addNewTableRows(tableView: charactersTableView, indexPathsToReload: unwrappedIndexPathsToReload)
    }
    
    func onFetchFailed(error: String) {
        // TODO
    }
    
    // MARK: - Navigation
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // informs navitation to start the segue
        performSegue(withIdentifier: segueIdentifier, sender: indexPath)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if  segue.identifier == segueIdentifier,
            let destination = segue.destination as? CharacterCellDetailController
        {
            let indexPath = sender as? IndexPath
            if let unwrappedSelectedRow = indexPath?.row {
                var character = charactersViewModel.getCharacter(at: unwrappedSelectedRow)
                if let unwrappedCharacterId = character.id {
                    if let unwrappedFileExtension = character.thumbnail?.fileExtension {
//                        let image = retrieveImage(imageName: String(unwrappedCharacterId), fileExtension: unwrappedFileExtension)
//                        if let unwrappedImage = image {
//                            character.image = unwrappedImage
//                        } else {
//                            character.image = #imageLiteral(resourceName: "marvel_image_not_available")
//                        }
                        destination.character = character
                    }
                }
            }
        }
    }
    
    func isLoadingCell(for indexPath: IndexPath) -> Bool {
        return indexPath.row >= charactersViewModel.charactersCount - 1
    }
    
    func addNewTableRows(tableView: UITableView, indexPathsToReload: [IndexPath]) {
        charactersTableView.beginUpdates()
        charactersTableView.insertRows(at: indexPathsToReload, with: .automatic)
        charactersTableView.endUpdates()
    }
    
}
