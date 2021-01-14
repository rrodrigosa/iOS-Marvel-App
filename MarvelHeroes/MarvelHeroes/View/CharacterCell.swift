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
    @IBOutlet weak var imgViewActivityIndicator: UIActivityIndicatorView!
    
    let imageManager = ImageManager.sharedInstance

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
        changeCellHighlightColor()
    }
    
    // MARK: Helper organizeCell
    func configureCell(charactersViewModel: CharactersViewModel, cell: CharacterCell, index: Int, isFiltering: Bool) {
        changeAcessoryColor(cell: cell)
        var character = Character(id: nil, name: nil, description: nil, thumbnail: nil, image: nil)
        if isFiltering {
            character = charactersViewModel.getFilteredCharacter(at: index)
        } else {
            character = charactersViewModel.getCharacter(at: index)
        }
        
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
        
        cell.imgViewActivityIndicator.startAnimating()
        
        // clear cell image because of its reusability
        cell.charactersImgView.image = nil
        
        // Checks if image already exists on user documents or if it's needed to be downloaded
        imageManager.configureImage(character: character, cell: cell) { (image) in
            self.addImageToCell(cell: cell, spinner: cell.imgViewActivityIndicator, image: image)
        }
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
