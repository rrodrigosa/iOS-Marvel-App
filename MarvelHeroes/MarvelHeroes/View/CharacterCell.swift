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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
