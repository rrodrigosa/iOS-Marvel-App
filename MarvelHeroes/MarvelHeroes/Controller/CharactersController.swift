//
//  CharactersVC.swift
//  MarvelHeroes
//
//  Created by RodrigoSA on 10/7/20.
//

import UIKit
import Alamofire
import AlamofireImage

class CharactersController: UITableViewController {
    
    @IBOutlet var charactersTableView: UITableView!
    
    let segueIdentifier = "CellDetails"
    
    var charAttributionText: String?
    var charList: [APIResult] = []
    var prevImportList: [APIResult] = []
    var loadingData = false
    let limit:Int = 50
    var offset:Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // remove empty cells
        charactersTableView.tableFooterView = UIView()
        // add view title
        self.title = "MARVEL CHARACTERS"
        
        populateTable(limit: limit, offset: offset)
    }
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
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
        performSegue(withIdentifier: segueIdentifier, sender: indexPath.row)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if  segue.identifier == segueIdentifier,
            let destination = segue.destination as? CharacterCellController
        {
            let selectedRow = sender as? Int
            if let unwrappedSelectedRow = selectedRow {
                let character = charList[unwrappedSelectedRow]
                destination.character = character
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
        
        if let unwrappedId = cellData.id {
            // Checks if image already exists on user documents or if it's needed to be downloaded
            imageManager(characterId: String(unwrappedId), imageUrl: cellData.thumbnail?.url, spinner: spinner, cell: cell, index: index) { (image) in
                // update the character object with the image
                self.charList[index].image = image
                self.addImageToCell(cell: cell, spinner: spinner, image: image)
            }
        }
        return cell
    }
    
    // MARK: Helper imageManager
    private func imageManager(characterId: String, imageUrl: URL?, spinner: UIActivityIndicatorView, cell: CharacterCell, index: Int, completion: @escaping (UIImage) -> Void) {
        // open a background thread to prevent ui freeze
        DispatchQueue.global().async {
            // tries to retrieve the image from documents folder
            let imageFromDocuments = self.retrieveImage(imageName: characterId)
            
            // if image was retrieved from folder, update it
            if let unwrappedImageFromDocuments = imageFromDocuments {
                DispatchQueue.main.async {
                    completion(unwrappedImageFromDocuments)
                }
            }
            // if image wasn't retrieved try to download from the internet
            else {
                if let unwrappedImageUrl = imageUrl {
                    self.downloadManager(imageUrl: unwrappedImageUrl) { image in
                        if let unwrappedImage = image {
                            // save images locally on user documents folder so it can be used whenever it's needed
                            self.storeImage(image: unwrappedImage, imageName: characterId)
                            DispatchQueue.main.async {
                                completion(unwrappedImage)
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
    private func storeImage(image: UIImage, imageName: String) {
        if let jpgRepresentation = image.jpegData(compressionQuality: 1) {
            if let imagePath = imagePath(imageName: imageName) {
                do  {
                    try jpgRepresentation.write(to: imagePath,
                                                options: .atomic)
                } catch let err {
                }
            }
        }
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
    private func downloadManager(imageUrl: URL, completion: @escaping (UIImage?) -> Void) {
        AF.request(imageUrl).responseImage { response in
            if case .success(let image) = response.result {
                completion(image)
            } else {
                completion(#imageLiteral(resourceName: "marvel_image_not_available"))
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
