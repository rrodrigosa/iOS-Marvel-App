//
//  CharacterCell.swift
//  MarvelHeroes
//
//  Created by RodrigoSA on 10/7/20.
//

import UIKit
import Alamofire
import AlamofireImage

class CharacterCell: UITableViewCell {

    @IBOutlet weak var charactersContentView: UIView!
    @IBOutlet weak var charactersImgView: UIImageView!
    @IBOutlet weak var charactersNameLabel: UILabel!
    @IBOutlet weak var charactersDescriptionLabel: UILabel!
    
    let imageManager = ImageManager.sharedInstance

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
        changeCellHighlightColor()
    }
    
    // MARK: Helper organizeCell
    func organizeCell(charactersViewModel: CharactersViewModel, cell: CharacterCell, index: Int) {
        let character = charactersViewModel.getCharacter(at: index)
        
        // Character name
        cell.charactersNameLabel.text = character.name
        
        // Character description
        if (character.description == "" || character.description == nil) {
            cell.charactersDescriptionLabel.text = "No description available"
            // update the character object with no description available
            charactersViewModel.setCharacterNoDescription(at: index)
        } else {
            cell.charactersDescriptionLabel.text = character.description
        }
        
        // Spinner
        let spinner = UIActivityIndicatorView(style: .medium)
        startSpinner(spinner: spinner, cell: cell)
        
        // clear cell image because of its reusability
        cell.charactersImgView.image = nil
        
        // Checks if image already exists on user documents or if it's needed to be downloaded
        configureImage(character: character, cell: cell) { (image) in
            self.addImageToCell(cell: cell, spinner: spinner, image: image)
        }
    }
    
    // MARK: Helper imageManager
    private func configureImage(character: APIResult, cell: CharacterCell, completion: @escaping (UIImage) -> Void) {
        guard let unwrappedCharacterId = character.id, let unwrappedFileExtension = character.thumbnail?.fileExtension else {
            completion(#imageLiteral(resourceName: "marvel_image_not_available"))
            return
        }
        let characterId = String(unwrappedCharacterId)
        
        // Fetch from alamofire image cache
        let cachedImage = imageManager.imageCache.image(withIdentifier: characterId)
        if let unwrappedCachedImage = cachedImage {
            DispatchQueue.main.async {
                completion(unwrappedCachedImage)
            }
        }
        else {
            // open a background thread to prevent ui freeze
            DispatchQueue.global().async {
                let imageExists = self.imageManager.checkIfImageExists(imageName: characterId, fileExtension: unwrappedFileExtension)
                if imageExists == true {
                    let imagePath = self.imageManager.imagePath(imageName: characterId, fileExtension: unwrappedFileExtension)
                    if let unwrappedImagePath = imagePath {
                        let resizedImage = self.imageManager.configureResizeImage(path: unwrappedImagePath, cell: cell, characterId: characterId)
                        if let unwrappedResizedImage = resizedImage {
                            DispatchQueue.main.async {
                                completion(unwrappedResizedImage)
                            }
                        }
                    }
                }
                // if image wasn't retrieved try to download from the internet
                else {
                    if let unwrappedImageUrl = character.thumbnail?.getUrlWithParameters() {
                        if (unwrappedImageUrl.absoluteString.contains("image_not_available")) {
                            DispatchQueue.main.async {
                                completion(#imageLiteral(resourceName: "marvel_image_not_available"))
                            }
                        } else {
                            self.downloadManager(imageUrl: unwrappedImageUrl, imageName: characterId, fileExtension: unwrappedFileExtension) { path in
                                if let unwrappedImagePath = path {
                                    let resizedImage = self.imageManager.configureResizeImage(path: unwrappedImagePath, cell: cell, characterId: characterId)
                                    if let unwrappedResizedImage = resizedImage {
                                        DispatchQueue.main.async {
                                            completion(unwrappedResizedImage)
                                        }
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
    
    // MARK: Helper downloadManager
    private func downloadManager(imageUrl: URL, imageName: String, fileExtension: String, completion: @escaping (URL?) -> Void) {
        AF.request(imageUrl).responseImage { response in
            if case .success(let image) = response.result {
                let path = self.imageManager.storeImage(image: image, imageName: imageName, fileExtension: fileExtension)
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
    
    private func changeCellHighlightColor() {
        // can't change cell highlight color to custom color on interface builder
        let bgColorView = UIView()
        bgColorView.backgroundColor = UIColor(named: "MarvelCellHighlightRed")
        selectedBackgroundView = bgColorView
    }

}
