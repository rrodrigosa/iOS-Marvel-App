//
//  FooterView.swift
//  MarvelHeroes
//
//  Created by RodrigoSA on 12/15/20.
//

import UIKit

class FooterView: UIView {
    @IBOutlet var footerContentView: UIView!
    @IBOutlet weak var footerLabel: UILabel!
    
    let nibName = "Footer"
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    func commonInit() {
        guard let view = loadViewFromNib() else { return }
        view.frame = self.bounds
        self.addSubview(view)
        footerContentView = view
    }
    
    func loadViewFromNib() -> UIView? {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: nibName, bundle: bundle)
        return nib.instantiate(withOwner: self, options: nil).first as? UIView
    }
    
    func updateFooterLabelText(marvelAttributionText: String) {
        footerLabel.text = marvelAttributionText
    }
}
