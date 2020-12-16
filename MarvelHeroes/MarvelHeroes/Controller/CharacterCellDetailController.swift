//
//  CharacterCellController.swift
//  MarvelHeroes
//
//  Created by RodrigoSA on 10/7/20.
//

import UIKit

class CharacterCellDetailController: UIViewController {

    @IBOutlet weak var characterImgView: UIImageView!
    @IBOutlet weak var characterDescriptionLabel: UILabel!
    @IBOutlet weak var footerView: FooterView!
    
    var character: Character?
    var marvelAttributionText: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        characterImgView.image = character?.image
        characterDescriptionLabel.text = character?.description
        
        if let unwrappedMarvelAttributionText = marvelAttributionText {
            footerView.updateFooterLabelText(marvelAttributionText: unwrappedMarvelAttributionText)
        }
    }
    
}
