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

class CharactersController: UITableViewController {
    
    @IBOutlet var charactersTableView: UITableView!
    
    let segueIdentifier = "CellDetails"
    
    var charAttributionText: String?
    var charList: [APIResult] = []
    var prevImportList: [APIResult] = []
    var loadingData = false
    let limit:Int = 50
    var offset:Int = 0
    
    let imageCache = AutoPurgingImageCache()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // remove empty cells
        charactersTableView.tableFooterView = UIView()
        // add view title
        self.title = "MARVEL CHARACTERS"
        
        populateTable(limit: limit, offset: offset)
    }
    
    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return charList.count
    }
    
    // MARK: -> cellForRowAt
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CharacterCell", for: indexPath) as! CharacterCell
        changeCellHighlightColor(cell: cell)
        let cellData = charList[indexPath.row]
        return organizeCell(cell: cell, cellData: cellData, index: indexPath.row)
    }
    
    // MARK: -> willDisplay
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if !loadingData && indexPath.row == charList.count - 1 {
            loadingData = true
            populateTable(limit:limit, offset:offset)
        }
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
                let cell = tableView.cellForRow(at: unwrappedIndexPath) as! CharacterCell
                if let unwrappedSelectedRow = indexPath?.row {
                    var character = charList[unwrappedSelectedRow]
                    if let unwrappedImg = cell.charactersImgView.image {
                        character.image = unwrappedImg
                        destination.character = character
                    }
                }
            }
        }
    }
    
    // MARK: - Helper populateTable
    private func populateTable(limit:Int, offset:Int) {
        DataManager().downloadCharacters(limit: limit, offset: offset) {
            (data: APIReturnDataSet?, results: [APIResult]?, error: String) in
            
            var newImport: [APIResult] = []
            
            for result in results! {
                var duplicate = false
                
                for item in self.prevImportList {
                    if result.id == item.id {
                        duplicate = true
                    }
                }
                
                if !duplicate {
                    newImport.append(result)
                }
            }
            // append to master array trimmed result set
            self.charList += newImport
            // increment offset by what we received
            self.offset += (data?.data?.count)!
            // copy response array to previous imported array
            self.prevImportList = results!
            
            self.charAttributionText = data?.attributionText
            
            self.loadingData = false
            self.tableView.reloadData()
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
            charList[index].description = "No description available"
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
            imageManager(characterId: String(unwrappedId), imageUrl: cellData.thumbnail?.url, cell: cell, index: index) { (image) in
                self.addImageToCell(cell: cell, spinner: spinner, image: image)
            }
        }
        return cell
    }
    
    // MARK: Helper imageManager
    private func imageManager(characterId: String, imageUrl: URL?, cell: CharacterCell, index: Int, completion: @escaping (UIImage) -> Void) {
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
    
}
