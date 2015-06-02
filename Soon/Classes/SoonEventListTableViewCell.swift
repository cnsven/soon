//
//  SoonEventListTableViewCell.swift
//  Soon
//
//  Created by Ben Sandofsky on 5/6/15.
//  Copyright (c) 2015 Chroma Noir. All rights reserved.
//

import UIKit
import SoonPlatform

protocol SoonEventListTableViewCellDelegate: class {
    func didTapFavoriteButtonOnCell(cell:SoonEventListTableViewCell)
}

class SoonEventListTableViewCell: UITableViewCell {
    weak var delegate:SoonEventListTableViewCellDelegate?
    @IBOutlet weak var previewImageView: UIImageView!
    @IBOutlet weak var eventTitleLabel: UILabel!
    @IBOutlet weak var eventSubtitleLabel: UILabel!
    @IBOutlet weak var favoriteButton: UIButton!

    @IBAction func didTapFavoriteButton(sender: AnyObject) {
        delegate?.didTapFavoriteButtonOnCell(self)
    }

    func updateWithEvent(event:SoonEvent){
        eventTitleLabel.text = event.name
        eventSubtitleLabel.text = event.generateFormattedDate()
        previewImageView.image = event.image ?? UIImage(named: "default_poster")
        let imageName = event.isFavorite ? "favorite_on" : "favorite_off"
        self.favoriteButton.setImage(UIImage(named: imageName)!, forState: .Normal)
    }
}
