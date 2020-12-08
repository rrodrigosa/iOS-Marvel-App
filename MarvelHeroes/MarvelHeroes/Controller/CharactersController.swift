//
//  CharactersVC.swift
//  MarvelHeroes
//
//  Created by RodrigoSA on 10/7/20.
//

import UIKit
import Alamofire
import AlamofireImage
import ImageIO

class CharactersController: UITableViewController, UITableViewDataSourcePrefetching, CharactersViewModelDelegate {
    @IBOutlet var charactersTableView: UITableView!
    
    let segueIdentifier = "CellDetails"
    let imageCache = AutoPurgingImageCache()
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
        changeCellHighlightColor(cell: cell)
        let cellData = charactersViewModel.getCharacter(at: indexPath.row)
        return organizeCell(cell: cell, cellData: cellData, index: indexPath.row)
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
            let destination = segue.destination as? CharacterCellController
        {
            let indexPath = sender as? IndexPath
            if let unwrappedIndexPath = indexPath {
                let cell = charactersTableView.cellForRow(at: unwrappedIndexPath) as! CharacterCell
                if let unwrappedSelectedRow = indexPath?.row {
                    var character = charactersViewModel.getCharacter(at: unwrappedSelectedRow)
                    if let unwrappedImg = cell.charactersImgView.image {
                        character.image = unwrappedImg
                        destination.character = character
                    }
                }
            }
        }
    }
    
    // MARK: Helper organizeCell
    func organizeCell(cell: CharacterCell, cellData: APIResult, index: Int) -> CharacterCell {
        // Character name
        cell.charactersNameLabel.text = cellData.name
        
        // Character description
        if (cellData.description == "" || cellData.description == nil) {
            cell.charactersDescriptionLabel.text = "No description available"
            // update the character object with no description available
            charactersViewModel.setCharacterNoDescription(at: index)
        } else {
            cell.charactersDescriptionLabel.text = cellData.description
        }
        
        // Spinner
        let spinner = UIActivityIndicatorView(style: .medium)
        startSpinner(spinner: spinner, cell: cell)
        
        // clear cell image because of its reusability
        cell.charactersImgView.image = nil
        
        if let unwrappedId = cellData.id {
            // Checks if image already exists on user documents or if it's needed to be downloaded
            imageManager(characterName: cellData.name!, characterId: String(unwrappedId), imageUrl: cellData.thumbnail?.url, cell: cell, index: index) { (image) in
                self.addImageToCell(cell: cell, spinner: spinner, image: image)
            }
        }
        return cell
    }
    
    // MARK: Helper imageManager
    private func imageManager(characterName: String, characterId: String, imageUrl: URL?, cell: CharacterCell, index: Int, completion: @escaping (UIImage) -> Void) {
        // Fetch from alamofire image cache
        let cachedImage = self.imageCache.image(withIdentifier: characterId)
        if let unwrappedCachedImage = cachedImage {
            DispatchQueue.main.async {
                completion(unwrappedCachedImage)
            }
        }
        else {
            // open a background thread to prevent ui freeze
            DispatchQueue.global().async {
                let imageExists = self.checkIfImageExists(imageName: characterId)
                if imageExists == true {
                    let imagePath = self.imagePath(imageName: characterId)
                    if let unwrappedImagePath = imagePath {
                        let resizedImage = self.configureResizeImage(path: unwrappedImagePath, cell: cell, characterId: characterId)
                        if let unwrappedResizedImage = resizedImage {
                            DispatchQueue.main.async {
                                completion(unwrappedResizedImage)
                            }
                        }
                    }
                }
                // if image wasn't retrieved try to download from the internet
                else {
                    if let unwrappedImageUrl = imageUrl {
                        self.downloadManager(imageUrl: unwrappedImageUrl, imageName: characterId) { path in
                            if let unwrappedImagePath = path {
                                let resizedImage = self.configureResizeImage(path: unwrappedImagePath, cell: cell, characterId: characterId)
                                if let unwrappedResizedImage = resizedImage {
                                    DispatchQueue.main.async {
                                        completion(unwrappedResizedImage)
                                    }
                                }
                            }
                        }
                    }
                    // if there is no url
                    else {
                        DispatchQueue.main.async {
                            completion(#imageLiteral(resourceName: "marvel_image_not_available"))
                        }
                    }
                }
            }
        }
    }
    
    private func configureResizeImage(path: URL, cell: CharacterCell, characterId: String) -> UIImage? {
        let width = cell.charactersImgView.bounds.size.width
        let height = cell.charactersImgView.bounds.size.height
        let size = CGSize(width: width, height: height)
        let resizedImage = self.resizeImage(at: path, for: size)
        if let unwrappedResizedImage = resizedImage {
            // Add/update to alamofire image cache
            self.imageCache.add(unwrappedResizedImage, withIdentifier: characterId)
            return unwrappedResizedImage
        }
        return nil
    }
    
    func resizeImage(at url: URL, for size: CGSize) -> UIImage? {
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageIfAbsent: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: max(size.width, size.height)
        ]
        
        guard let imageSource = CGImageSourceCreateWithURL(url as NSURL, nil),
              let image = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary)
        else {
            return nil
        }
        
        return UIImage(cgImage: image)
    }
    
    private func checkIfImageExists(imageName: String) -> Bool? {
        if let imagePath = imagePath(imageName: imageName),
           let _ = FileManager.default.contents(atPath: imagePath.path) {
            return true
        }
        return false
    }
    
    // MARK: Helper retrieveImage
    private func retrieveImage(imageName: String) -> UIImage? {
        if let imagePath = imagePath(imageName: imageName),
           let imageData = FileManager.default.contents(atPath: imagePath.path),
           let image = UIImage(data: imageData) {
            return image
        }
        return nil
    }
    
    // MARK: Helper storeImage
    private func storeImage(image: UIImage, imageName: String) -> URL? {
        if let jpgRepresentation = image.jpegData(compressionQuality: 1) {
            if let imagePath = imagePath(imageName: imageName) {
                do  {
                    try jpgRepresentation.write(to: imagePath,
                                                options: .atomic)
                    return imagePath
                } catch let err {
                    return nil
                }
            }
        }
        return nil
    }
    
    // MARK: Helper imagePath
    private func imagePath(imageName: String) -> URL? {
        let fileManager = FileManager.default
        // path to save the images on documents directory
        guard let documentPath = fileManager.urls(for: .documentDirectory,
                                                  in: FileManager.SearchPathDomainMask.userDomainMask).first else { return nil }
        let appendedDocumentPath = documentPath.appendingPathComponent(imageName)
        return appendedDocumentPath
    }
    
    // MARK: Helper downloadManager
    private func downloadManager(imageUrl: URL, imageName: String, completion: @escaping (URL?) -> Void) {
        AF.request(imageUrl).responseImage { response in
            if case .success(let image) = response.result {
                let path = self.storeImage(image: image, imageName: imageName)
                completion(path)
            } else {
                completion(nil)
            }
        }
    }
    
    // MARK: Helper startSpinner
    private func startSpinner(spinner: UIActivityIndicatorView, cell: CharacterCell) {
        spinner.center = cell.charactersImgView.center
        cell.charactersContentView.addSubview(spinner)
        spinner.startAnimating()
    }
    
    // MARK: Helper addImageToCell
    private func addImageToCell(cell: CharacterCell, spinner: UIActivityIndicatorView, image: UIImage) {
        DispatchQueue.main.async {
            spinner.stopAnimating()
            cell.charactersImgView.image = image
        }
    }
    
    private func changeCellHighlightColor(cell: CharacterCell) {
        // can't change cell highlight color to custom color on interface builder
        let bgColorView = UIView()
        bgColorView.backgroundColor = UIColor(named: "MarvelCellHighlightRed")
        cell.selectedBackgroundView = bgColorView
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
