//
//  CharacterCell.swift
//  MarvelHeroes
//
//  Created by RodrigoSA on 10/7/20.
//

import UIKit

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
    func configureCell(charactersViewModel: CharactersViewModel, cell: CharacterCell, index: Int) {
        changeAcessoryColor(cell: cell)
        let character = charactersViewModel.getCharacter(at: index)
        
        // Character name
        cell.charactersNameLabel.text = character.name
        
        // Character description
        if (character.description == "" || character.description == nil) {
            cell.charactersDescriptionLabel.text = "No description available".localized
            // update the character object with no description available
            charactersViewModel.setCharacterNoDescription(at: index)
        } else {
            cell.charactersDescriptionLabel.text = character.description
        }
        
        // Spinner
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.color = UIColor(named: "MarvelBackgroundRed")
        startSpinner(spinner: spinner, cell: cell)
        
        // clear cell image because of its reusability
        cell.charactersImgView.image = nil
        
        // Checks if image already exists on user documents or if it's needed to be downloaded
        imageManager.configureImage(character: character, cell: cell) { (image) in
            self.addImageToCell(cell: cell, spinner: spinner, image: image)
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
    
    // default accessory disclosureIndicator doesn't change colors. Using SF Symbols, available for iOS 13 and later
    private func changeAcessoryColor(cell: CharacterCell) {
        let imageTest = UIImage(systemName: "chevron.right")
        let imageView = UIImageView(image: imageTest)
        cell.accessoryView = imageView
    }

}
