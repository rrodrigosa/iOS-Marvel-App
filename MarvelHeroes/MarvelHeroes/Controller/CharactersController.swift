//
//  CharactersVC.swift
//  MarvelHeroes
//
//  Created by RodrigoSA on 10/7/20.
//

import UIKit

class CharactersController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITableViewDataSourcePrefetching, CharactersViewModelDelegate, AlertExtension {
    @IBOutlet var charactersTableView: UITableView!
    @IBOutlet weak var downloadIndicatorView: UIView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var footerView: FooterView!
    
    let segueIdentifier = "CellDetails"
    let imageManager = ImageManager.sharedInstance
    private var charactersViewModel: CharactersViewModel!
    private var marvelAttributionText: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewDidLoadConfigure()
    }
    
    // MARK: - Table view data source
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return charactersViewModel.charactersCount
    }
    
    // MARK: -> cellForRowAt
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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
        updateFooterView()
        guard let unwrappedIndexPathsToReload = indexPathsToReload else {
            activityIndicator.stopAnimating()
            downloadIndicatorView.isHidden = true
            charactersTableView.isHidden = false
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
        charactersViewModel = CharactersViewModel(delegate: self)
        charactersViewModel.fetchCharacters()
    }
    
    func isLoadingCell(for indexPath: IndexPath) -> Bool {
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
    
}
