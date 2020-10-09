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
    let limit:Int = 10
    var offset:Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // remove empty cells
        self.charactersTableView.tableFooterView = UIView()
        // add view title
        self.title = "Characters List"
        
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
        let cellData = self.charList[indexPath.row]
        
        cell.charactersNameLabel.text = cellData.name
        cell.charactersDescriptionLabel.text = cellData.description
        
        let spinner = UIActivityIndicatorView(style: .medium)
        startSpinner(spinner: spinner, cell: cell)
        return cell
    }
    
    // MARK: -> willDisplay
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        if !self.loadingData && indexPath.row == self.charList.count - 1 {
            self.loadingData = true
            self.populateTable(limit:limit, offset:offset)
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
                
                let indexPath = tableView.indexPathForSelectedRow!
                let cell = tableView.cellForRow(at: indexPath ) as! CharacterCell
                
                if let unwrappedImg = cell.charactersImgView.image {
                    destination.characterImg = unwrappedImg
                } else {
                    destination.characterImg = #imageLiteral(resourceName: "marvel_image_not_available")
                }
                
                if let unwrappedDescription = character.description {
                    destination.characterDescription = unwrappedDescription
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
                        print("found duplicate for result.id:\(String(describing: result.id))!")
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
                // if download was not successful
                else {
                    DispatchQueue.main.async {
                        self.addImageNotFound(spinner: spinner, cell: cell)
                    }
                }
            }
        }
    }
    
    // MARK: Helper retrieveImage
    private func retrieveImage(imageName: String) -> UIImage? {
        if let imagePath = self.imagePath(imageName: imageName),
            let imageData = FileManager.default.contents(atPath: imagePath.path),
            let image = UIImage(data: imageData) {
            return image
        }
        return nil
    }
    
    // MARK: Helper storeImage
    private func storeImage(image: UIImage, imageName: String) {
        if let jpgRepresentation = image.jpegData(compressionQuality: 1) {
            if let imagePath = self.imagePath(imageName: imageName) {
                do  {
                    try jpgRepresentation.write(to: imagePath,
                                                options: .atomic)
                } catch let err {
                    print("rdsa - -------------")
                    print("rdsa - Saving image locally resulted in error: ", err)
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
//                print("rdsa - -------------")
//                print("rdsa - documents path: ", appendedDocumentPath)
        return appendedDocumentPath
    }
    
    // MARK: Helper downloadManager
    private func downloadManager(imageUrl: URL, completion: @escaping (UIImage?) -> Void) {
        AF.request(imageUrl).responseImage { response in
            if case .success(let image) = response.result {
                completion(image)
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
    
    // MARK: Helper addImageNotFound
    private func addImageNotFound(spinner: UIActivityIndicatorView, cell: CharacterCell) {
        spinner.stopAnimating()
        cell.charactersImgView.image = #imageLiteral(resourceName: "marvel_image_not_available")
    }
    
}
