//
//  Helper.swift
//  MarvelHeroes
//
//  Created by RodrigoSA on 12/11/20.
//

import Alamofire
import AlamofireImage

class ImageManager {
    static let sharedInstance = ImageManager()
    let imageCache = AutoPurgingImageCache()
    private var dictionaryDataRequest: [Int:DataRequest] = [:]
    
    private init() {
    }
    
    // MARK: Helper imageManager
    func configureImage(character: Character, cell: CharacterCell, completion: @escaping (UIImage) -> Void) {
        guard let unwrappedCharacterId = character.id, let unwrappedFileExtension = character.thumbnail?.fileExtension else {
            completion(#imageLiteral(resourceName: "marvel_image_not_available"))
            return
        }
        let characterId = String(unwrappedCharacterId)
        let cachedImage = imageCache.image(withIdentifier: characterId)
        if let unwrappedCachedImage = cachedImage {
            DispatchQueue.main.async {
                completion(unwrappedCachedImage)
            }
        }
        else {
            DispatchQueue.global().async {
                let imageExists = self.checkIfImageExists(imageName: characterId, fileExtension: unwrappedFileExtension)
                if imageExists == true {
                    let imagePath = self.imagePath(imageName: characterId, fileExtension: unwrappedFileExtension)
                    if let unwrappedImagePath = imagePath {
                        let resizedImage = self.configureResizeImage(path: unwrappedImagePath, cell: cell, characterId: characterId)
                        if let unwrappedResizedImage = resizedImage {
                            DispatchQueue.main.async {
                                completion(unwrappedResizedImage)
                            }
                        }
                    }
                }
                else {
                    if let unwrappedImageUrl = character.thumbnail?.getUrlWithParameters() {
                        if (unwrappedImageUrl.absoluteString.contains("image_not_available")) {
                            DispatchQueue.main.async {
                                completion(#imageLiteral(resourceName: "marvel_image_not_available"))
                            }
                        } else {
                            self.downloadManager(imageUrl: unwrappedImageUrl, imageName: characterId, fileExtension: unwrappedFileExtension) { path in
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
                    }
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
        guard let unwrappedId = Int(imageName) else {
            return
        }
        // check if there is a open request with this character id
        guard dictionaryDataRequest[unwrappedId] == nil else {
            return
        }
        
        let dataRequest = AF.request(imageUrl).responseImage { response in
            if case .success(let image) = response.result {
                let path = self.storeImage(image: image, imageName: imageName, fileExtension: fileExtension)
                self.dictionaryDataRequest[unwrappedId] = nil
                completion(path)
            } else {
                self.dictionaryDataRequest[unwrappedId] = nil
                completion(nil)
            }
        }
        dictionaryDataRequest[unwrappedId] = dataRequest
    }
    
    func cancelDownload(characterId: Int) {
        guard let unwrappedDictionary = dictionaryDataRequest[characterId] else {
            return
        }
        unwrappedDictionary.cancel()
    }
    
    func configureResizeImage(path: URL, cell: CharacterCell, characterId: String) -> UIImage? {
        let width = cell.charactersImgView.bounds.size.width
        let height = cell.charactersImgView.bounds.size.height
        let size = CGSize(width: width, height: height)
        let resizedImage = resizeImage(at: path, for: size)
        if let unwrappedResizedImage = resizedImage {
            self.imageCache.add(unwrappedResizedImage, withIdentifier: characterId)
            return unwrappedResizedImage
        }
        return nil
    }
    
    private func resizeImage(at url: URL, for size: CGSize) -> UIImage? {
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
    
    func checkIfImageExists(imageName: String, fileExtension: String) -> Bool? {
        if let imagePath = imagePath(imageName: imageName, fileExtension: fileExtension),
           let _ = FileManager.default.contents(atPath: imagePath.path) {
            return true
        }
        return false
    }
    
    func retrieveImage(imageName: String, fileExtension: String) -> UIImage? {
        if let imagePath = imagePath(imageName: imageName, fileExtension: fileExtension),
           let imageData = FileManager.default.contents(atPath: imagePath.path),
           let image = UIImage(data: imageData) {
            return image
        }
        return nil
    }
    
    func storeImage(image: UIImage, imageName: String, fileExtension: String) -> URL? {
        if let jpgRepresentation = image.jpegData(compressionQuality: 1) {
            if let imagePath = imagePath(imageName: imageName, fileExtension: fileExtension) {
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
    
    func imagePath(imageName: String, fileExtension: String) -> URL? {
        let fileManager = FileManager.default
        guard let documentPath = fileManager.urls(for: .documentDirectory,
                                                  in: FileManager.SearchPathDomainMask.userDomainMask).first else { return nil }
        let appendedDocumentPath = documentPath.appendingPathComponent(imageName).appendingPathExtension(fileExtension)
        return appendedDocumentPath
    }

}
