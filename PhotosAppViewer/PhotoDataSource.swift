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
    func photo(dataSource: PhotoDataSource, didChangePhotos: [AnyObject])
}

protocol PhotoDataSourceDataSource: class {
    func photoDataSourceCacheInfo() -> CacheInfo
}

// default implementation - implementation is optional outside of this class
extension PhotoDataSourceDataSource {
    func photoDataSourceCacheInfo() -> CacheInfo {
        return CacheInfo(targetSize: CGSize(width: 100.0, height: 100.0), contentMode: .aspectFit, options: nil)
    }
}

struct CacheInfo {
    let targetSize: CGSize
    let contentMode: PHImageContentMode
    let options: PHImageRequestOptions?
}

final class PhotoDataSource: NSObject, PhotoDataSourceDataSource {
    
    // MARK: - Properties
    
    weak var delegate: PhotoDataSourceDelegate?
    weak var dataSource: PhotoDataSourceDataSource?

    fileprivate var mediaAssets: PHFetchResult<PHAsset>?
    
    fileprivate lazy var imageCacheManager: PHCachingImageManager  = {
        return PHCachingImageManager()
    }()
    
    // MARK: - Lifecycle
    
    override init() {
        super.init()
        
        self.dataSource = self
    }
    
    // MARK: - Public
    
    func loadPhotoData() {
        let options = PHFetchOptions()
        options.sortDescriptors = [ NSSortDescriptor(key: "creationDate", ascending: true) ]
        /*let videoPredicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.video.rawValue)
        let imagePredicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [videoPredicate, imagePredicate])
        
        options.predicate = predicate*/
        self.mediaAssets = PHAsset.fetchAssets(with: options)
    }
    
    func requestPhotoAuthorization(completion: @escaping (Bool) -> ()) {
        
        PHPhotoLibrary.requestAuthorization { (status) in
            switch status{
            case .authorized:
                Thread.executeOnMainThread { completion(true) }
            case .denied, .restricted, .notDetermined:
                Thread.executeOnMainThread { completion(false) }
            }
        }
    }
    
    func cacheImagesAt(indices: [Int], shouldStopCaching: Bool) {
        let assets = indices.flatMap({ self.requestImage(for: $0) })
        guard let cacheInfo = self.dataSource?.photoDataSourceCacheInfo() else { return }
        
        guard  shouldStopCaching else {
            self.imageCacheManager.startCachingImages(for: assets, targetSize: cacheInfo.targetSize, contentMode: cacheInfo.contentMode, options: cacheInfo.options)
            return
        }
        self.imageCacheManager.stopCachingImages(for: assets, targetSize: cacheInfo.targetSize, contentMode: cacheInfo.contentMode, options: cacheInfo.options)
    }
    
    // MARK: - Private

    private func requestImage(for index: Int) -> PHAsset? {
        // check if requested index is within media assets
        guard index < self.mediaAssets?.count ?? 0 else { return nil }
        return self.mediaAssets?.object(at: index)
    }
}

// MARK: - PHPhotoLibraryChangeObserver protocol methods

extension PhotoDataSource: PHPhotoLibraryChangeObserver {
    
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        
        guard let fetchedAssets = self.mediaAssets, let changeDetails = changeInstance.changeDetails(for: fetchedAssets) else { return }
        
        Thread.executeOnMainThread {
            // Update the cached fetch result.
            self.mediaAssets = changeDetails.fetchResultAfterChanges
            
            self.delegate?.photo(dataSource: self, didFetchPhotos: [])
        }
    }
}
