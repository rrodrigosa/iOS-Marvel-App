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
           
        // if there isn't any image on the cell, proceed to manage the image
        if cell.charactersImgView.image == nil {
            // only instantiate spinner on imageView position if no images are set
            let spinner = UIActivityIndicatorView(style: .medium)
            startSpinner(spinner: spinner, cell: cell)
            
        }
        
        
//        if let unwrappedUrl = cellData.thumbnail?.url {
//            AF.request(unwrappedUrl).responseImage { response in
//                if case .success(let image) = response.result {
//
//                    // tests with image here
//                    cell.charactersImgView.image = image
//                }
//            }
//        }
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

    // MARK: - Helper methods
    private func startSpinner(spinner: UIActivityIndicatorView, cell: CharacterCell) {
        spinner.center = cell.charactersImgView.center
        cell.charactersContentView.addSubview(spinner)
        spinner.startAnimating()
    }
    
}
