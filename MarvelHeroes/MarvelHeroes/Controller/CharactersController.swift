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
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Search", style: .done, target: self, action: #selector(searchTapped))
        searchBar.delegate = self
        searchBar.placeholder = "Search by name"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        deselectCell()
    }
    
    @objc func searchTapped(sender: UIBarButtonItem) {
        if searchBarActive {
            searchBarActive = false
            navigationItem.rightBarButtonItem?.title = "Search"
            searchBar.resignFirstResponder()
            // resets table with no filtered data
            charactersTableView.reloadData()
            UIView.animate(withDuration: 0.5) {
                self.searchBar.isHidden = true
            }
        } else {
            searchBarActive = true
            navigationItem.rightBarButtonItem?.title = "Close"
            searchBar.becomeFirstResponder()
            searchBar.text = ""
            UIView.animate(withDuration: 0.5) {
                self.searchBar.isHidden = false
            }
        }
    }
    
    var filteredCharacters = [Character]()
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        print("print - bar text: \(searchText)")
        filteredCharacters = charactersViewModel.getCharacters().filter { character in
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
        
        print("print - filteredCharacters count: \(filteredCharacters.count)")
        charactersTableView.reloadData()
    }
    
    var isFiltering: Bool {
        guard let unwrappedBool = searchBar.text?.isEmpty else {
            return false
        }
        return searchBarActive && !unwrappedBool
    }
    
    func searchBarConfigure() {
        
    }
    
    // MARK: - Table view data source
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isFiltering {
            return filteredCharacters.count
        } else {
            return charactersViewModel.charactersCount
        }
    }
    
    // MARK: -> cellForRowAt
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if isLastCell(indexPath: indexPath) {
            reloadRows(indexPath: indexPath)
            let cell = tableView.dequeueReusableCell(withIdentifier: "LoadingCharacterCell", for: indexPath) as! LoadingCharacterCell
            cell.startSpinner()
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "CharacterCell", for: indexPath) as! CharacterCell
            cell.configureCell(charactersViewModel: charactersViewModel, cell: cell, index: indexPath.row)
            return cell
        }
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
                var character = charactersViewModel.getCharacter(at: unwrappedSelectedRow)
                if let unwrappedCharacterId = character.id {
                    if let unwrappedFileExtension = character.thumbnail?.fileExtension {
                        let image = imageManager.retrieveImage(imageName: String(unwrappedCharacterId), fileExtension: unwrappedFileExtension)
                        if let unwrappedImage = image {
                            character.image = unwrappedImage
                        } else {
                            character.image = #imageLiteral(resourceName: "marvel_image_not_available")
                        }
                        destination.character = character
                        destination.marvelAttributionText = marvelAttributionText
                    }
                }
            }
        }
    }
    
    private func viewDidLoadConfigure() {
        title = "Marvel Characters".localized
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
    
    private func reloadRows(indexPath: IndexPath) {
        var indexPathList = [IndexPath]()
        indexPathList.append(indexPath)
        charactersTableView.reloadRows(at: indexPathList, with: .automatic)
    }
    
}
