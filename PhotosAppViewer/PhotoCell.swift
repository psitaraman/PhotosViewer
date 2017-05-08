//
//  PhotoCell.swift
//  PhotosAppViewer
//
//  Created by Praveen Sitaraman on 5/7/17.
//  Copyright © 2017 Praveen Sitaraman. All rights reserved.
//

import UIKit

final class PhotoCell: UICollectionViewCell {
    
    // MARK: - Properties
    static let reuseId = String(describing: PhotoCell.self)
    var photoIdentifier: String!
    
    // MARK: - IBOutlets
    @IBOutlet weak var photoImageView: UIImageView!
    
    // MARK: - Lifecycle
    override func prepareForReuse() {
        super.prepareForReuse()
        self.photoImageView.image = nil
    }
}
