//
//  CharactersVC.swift
//  MarvelHeroes
//
//  Created by RodrigoSA on 10/7/20.
//

import UIKit

class CharactersController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITableViewDataSourcePrefetching, CharactersViewModelDelegate, AlertExtension, UISearchBarDelegate {
    
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet var charactersTableView: UITableView!
    @IBOutlet weak var downloadIndicatorView: UIView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var footerView: FooterView!
    
    let segueIdentifier = "CellDetails"
    let imageManager = ImageManager.sharedInstance
    private var charactersViewModel: CharactersViewModel!
    private var marvelAttributionText: String?
    private var searchBarActive = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewDidLoadConfigure()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        deselectCell()
    }
    
    @objc func searchTapped(sender: UIBarButtonItem) {
        searchBarActive = true
        navigationItem.rightBarButtonItem?.isEnabled = false
        navigationItem.rightBarButtonItem?.tintColor = .clear
        searchBar.becomeFirstResponder()
        UIView.animate(withDuration: 0.5) {
            self.searchBar.isHidden = false
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        charactersViewModel.filterCharacters(searchText: searchText)
        charactersTableView.reloadData()
    }
    
    var isFiltering: Bool {
        guard let unwrappedBool = searchBar.text?.isEmpty else {
            return false
        }
        return searchBarActive && !unwrappedBool
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBarActive = false
        navigationItem.rightBarButtonItem?.isEnabled = true
        navigationItem.rightBarButtonItem?.tintColor = .white
        searchBar.text = ""
        searchBar.resignFirstResponder()
        // resets table with no filtered data
        charactersTableView.reloadData()
        UIView.animate(withDuration: 0.5) {
            self.searchBar.isHidden = true
        }
    }
    
    // MARK: - Table view data source
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isFiltering {
            return charactersViewModel.filteredCharactersCount
        } else {
            return charactersViewModel.charactersCount
        }
    }
    
    // MARK: -> cellForRowAt
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if isLastCell(indexPath: indexPath) && !charactersViewModel.allAPIDataRetrieved {
            let cell = tableView.dequeueReusableCell(withIdentifier: "LoadingCharacterCell", for: indexPath) as! LoadingCharacterCell
            cell.startSpinner()
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "CharacterCell", for: indexPath) as! CharacterCell
            cell.configureCell(charactersViewModel: charactersViewModel, cell: cell, index: indexPath.row, isFiltering: isFiltering)
            return cell
        }
    }
    
    // MARK: -> didEndDisplaying
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let id = charactersViewModel.getCharacter(at: indexPath.row).id
        guard let unwrappedId = id else {
            return
        }
        imageManager.cancelDownload(characterId: unwrappedId)
    }
    
    // MARK: -> prefetchRowsAt
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        if indexPaths.contains(where: isLastCell) {
            charactersViewModel.fetchCharacters()
        }
    }
    
    func onFetchCompleted(indexPathsToReload: [IndexPath]?) {
        updateFooterView()
        guard let unwrappedIndexPathsToReload = indexPathsToReload else {
            activityIndicator.stopAnimating()
            downloadIndicatorView.isHidden = true
            stackView.isHidden = false
            charactersTableView.reloadData()
            return
        }
        addNewTableRows(tableView: charactersTableView, indexPathsToReload: unwrappedIndexPathsToReload)
    }
    
    func onFetchFailed(error: String) {
        let title = "Error".localized
        let retryAction = UIAlertAction(title: "Retry".localized, style: .default, handler: { action in
            self.charactersViewModel.fetchCharacters()
        })
        alert(title: title, message: error, actions: [retryAction])
    }
    
    // MARK: - Navigation
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: segueIdentifier, sender: indexPath)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if  segue.identifier == segueIdentifier,
            let destination = segue.destination as? CharacterCellDetailController
        {
            let indexPath = sender as? IndexPath
            if let unwrappedSelectedRow = indexPath?.row {
                var character = Character(id: nil, name: nil, description: nil, thumbnail: nil, image: nil)
                if isFiltering {
                    character = charactersViewModel.getFilteredCharacter(at: unwrappedSelectedRow)
                } else {
                    character = charactersViewModel.getCharacter(at: unwrappedSelectedRow)
                }
                
                if let unwrappedCharacterId = character.id {
                    if let unwrappedFileExtension = character.thumbnail?.fileExtension {
                        let image = imageManager.retrieveImage(imageName: String(unwrappedCharacterId), fileExtension: unwrappedFileExtension)
                        if let unwrappedImage = image {
                            character.image = unwrappedImage
                        } else {
                            character.image = #imageLiteral(resourceName: "marvel_image_not_available")
                        }
                    }
                }
                destination.character = character
                destination.marvelAttributionText = marvelAttributionText
            }
        }
    }
    
    private func viewDidLoadConfigure() {
        title = "Marvel Characters".localized
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Search", style: .done, target: self, action: #selector(searchTapped))
        searchBar.delegate = self
        charactersTableView.delegate = self
        charactersTableView.dataSource = self
        charactersTableView.prefetchDataSource = self
        charactersTableView.keyboardDismissMode = .onDrag
        charactersViewModel = CharactersViewModel(delegate: self)
        charactersViewModel.fetchCharacters()
    }
    
    func isLastCell(indexPath: IndexPath) -> Bool {
        return indexPath.row >= charactersViewModel.charactersCount - 1
    }
    
    func addNewTableRows(tableView: UITableView, indexPathsToReload: [IndexPath]) {
        charactersTableView.beginUpdates()
        charactersTableView.insertRows(at: indexPathsToReload, with: .automatic)
        charactersTableView.endUpdates()
    }
    
    private func updateFooterView() {
        marvelAttributionText = charactersViewModel.getMarvelAttributionText()
        if let unwrappedMarvelAttributionText = marvelAttributionText {
            footerView.updateFooterLabelText(marvelAttributionText: unwrappedMarvelAttributionText)
        }
    }
    
    private func deselectCell() {
        if let index = self.charactersTableView.indexPathForSelectedRow {
            self.charactersTableView.deselectRow(at: index, animated: false)
        }
    }
    
}
