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
        
        self.setup()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        
        self.photoDataSource.clearCache()
    }
    
    // MARK: - Private
    private func setup() {
        
        self.photoDataSource = PhotoDataSource()
        self.photoDataSource.delegate = self
        self.photoDataSource.dataSource = self
        
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
        cell.photoIdentifier = self.photoDataSource.photoIdentifier(for: indexPath.item)
        return cell
    }

    // MARK: - UICollectionViewDelegate methods

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
    }
    
    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let photoCell = cell as! PhotoCell

        self.photoDataSource.requestImageFor(index: indexPath.item) { (photo) in
            // check to see if the image requested cell still has the same id or if it has been reused, if reused, don't set image
            guard photoCell.photoIdentifier == self.photoDataSource.photoIdentifier(for: indexPath.item) else { return }
            photoCell.photoImageView.image = photo
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        self.photoDataSource.cancelImageRequest(at: indexPath.item)
    }
    
    // MARK: - UICollectionViewDataSourcePrefetching methods
    
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        self.shouldCacheImages(true, for: indexPaths)
    }
    
    func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        self.shouldCacheImages(false, for: indexPaths)
    }
}

// MARK: - UICollectionViewDelegateFlowLayout methods

extension PhotoCollectionViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = self.view.bounds.size.width / 3.1
        return CGSize(width: width, height: width)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 5.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 5.0
    }
}

// MARK: - PhotoDataSourceDelegate methods

extension PhotoCollectionViewController: PhotoDataSourceDelegate {
    func photoDataSourceDidupdate() {
        self.collectionView?.performBatchUpdates({ [weak self] in
            self?.collectionView?.reloadSections(IndexSet(integer: 0))
        }, completion: nil)
    }
}

// MARK: - PhotoDataSourceDataSource methods

extension PhotoCollectionViewController: PhotoDataSourceDataSource {
    func photoDataSourceTargetSize() -> CGSize {
        let scale = UIScreen.main.scale
        let cellSize = (self.collectionViewLayout as! UICollectionViewFlowLayout).itemSize
        return CGSize(width: cellSize.width * scale, height: cellSize.height * scale)
    }
}
