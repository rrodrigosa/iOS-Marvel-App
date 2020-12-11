//
//  Helper.swift
//  MarvelHeroes
//
//  Created by RodrigoSA on 12/11/20.
//

import Foundation
import UIKit
import AlamofireImage

class ImageManager {
    static let sharedInstance = ImageManager()
    
    let imageCache = AutoPurgingImageCache()
    
    func configureResizeImage(path: URL, cell: CharacterCell, characterId: String) -> UIImage? {
        let width = cell.charactersImgView.bounds.size.width
        let height = cell.charactersImgView.bounds.size.height
        let size = CGSize(width: width, height: height)
        let resizedImage = resizeImage(at: path, for: size)
        if let unwrappedResizedImage = resizedImage {
            // Add/update to alamofire image cache
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
        // path to save the images on documents directory
        guard let documentPath = fileManager.urls(for: .documentDirectory,
                                                  in: FileManager.SearchPathDomainMask.userDomainMask).first else { return nil }
        let appendedDocumentPath = documentPath.appendingPathComponent(imageName).appendingPathExtension(fileExtension)
        return appendedDocumentPath
    }

}
