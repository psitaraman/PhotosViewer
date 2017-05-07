//
//  PhotoDataSource.swift
//  PhotosAppViewer
//
//  Created by Praveen Sitaraman on 5/7/17.
//  Copyright © 2017 Praveen Sitaraman. All rights reserved.
//

import UIKit
import Photos

protocol PhotoDataSourceDelegate: class {
    func photo(dataSource: PhotoDataSource, didFetchPhotos: [AnyObject])
}

final class PhotoDataSource {
    
    // MARK: - Properties
    
    weak var delegate: PhotoDataSourceDelegate?
    
    
    // MARK: - Lifecycle
    
    init() {
        
    }
    
    // MARK: - Public
    
    func loadPhotoData() {
        let options PHFetchOptions()
    }
}
