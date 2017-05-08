//
//  PhotoCollectionViewController.swift
//  PhotosAppViewer
//
//  Created by Praveen Sitaraman on 5/7/17.
//  Copyright © 2017 Praveen Sitaraman. All rights reserved.
//

import UIKit

final class PhotoCollectionViewController: UICollectionViewController, UICollectionViewDataSourcePrefetching {
    
    // MARK: - Properties
    
    fileprivate var photoDataSource: PhotoDataSource!
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Register cell classes
        //self.collectionView!.register(UICollectionViewCell.self, forCellWithReuseIdentifier: PhotoCell.reuseId)

        self.setup()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Private
    private func setup() {
        
        self.photoDataSource = PhotoDataSource()
        self.photoDataSource.delegate = self
        
        self.photoDataSource.requestPhotoAuthorization {[weak self] (isAuthorized) in
            guard isAuthorized else { return }
            self?.loadData()
        }
    }
    
    private func loadData() {
        self.photoDataSource.loadPhotoData()
    }
    
    private func shouldCacheImages(_ shouldCacheImages:Bool, for indexPaths: [IndexPath]) {
        let indices = indexPaths.flatMap({ $0.item })
        self.photoDataSource.cacheImagesAt(indices: indices, shouldStopCaching: !shouldCacheImages)
    }

    // MARK: - UICollectionViewDataSource methods

    override func numberOfSections(in collectionView: UICollectionView) -> Int { return 1 }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.photoDataSource.photoCount()
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotoCell.reuseId, for: indexPath) as! PhotoCell
    
        // Configure the cell
        self.photoDataSource.requestImage(for: indexPath.item) { (photo) in
            cell.photoImageView.image = photo
        }
    
        return cell
    }

    // MARK: - UICollectionViewDelegate methods

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
    }
    
    // MARK: - UICollectionViewDataSourcePrefetching methods
    
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        self.shouldCacheImages(true, for: indexPaths)
    }
    
    func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        self.shouldCacheImages(false, for: indexPaths)
    }
}

// MARK: - PhotoDataSourceDelegate methods

extension PhotoCollectionViewController: PhotoDataSourceDelegate {
    func photoDataSourceDidupdate() {
        self.collectionView?.reloadData()
    }
}
