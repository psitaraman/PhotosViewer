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
    func photoDataSourceDidupdate()
}

protocol PhotoDataSourceDataSource: class {
    func photoDataSourceCacheInfo() -> CacheInfo
}

// default implementation of PhotoDataSourceDataSource - implementation is optional outside of this class
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

    fileprivate var mediaAssets: PHFetchResult<PHAsset>? {
        didSet {
            self.delegate?.photoDataSourceDidupdate()
        }
    }
    
    fileprivate lazy var cacheManager: PHCachingImageManager  = {
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
        
        Thread.executeOnMainThread {
            // Update the cached fetch result.
            self.mediaAssets = PHAsset.fetchAssets(with: options)
        }
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
    
    /// Call this method for an index before calling requestImage(for index: Int, completion: @escaping (UIImage) -> ())
    /// That way cache can load the image leading to faster access and better performance
    func cacheImagesAt(indices: [Int], shouldStopCaching: Bool) {
        let assets = indices.flatMap({ self.requestAsset(for: $0) })
        guard let cacheInfo = self.dataSource?.photoDataSourceCacheInfo() else { return }
        
        guard  shouldStopCaching else {
            self.cacheManager.startCachingImages(for: assets, targetSize: cacheInfo.targetSize, contentMode: cacheInfo.contentMode, options: cacheInfo.options)
            return
        }
        self.cacheManager.stopCachingImages(for: assets, targetSize: cacheInfo.targetSize, contentMode: cacheInfo.contentMode, options: cacheInfo.options)
    }
    
    func requestImage(for index: Int, completion: @escaping (UIImage) -> ()) {
        guard let asset = self.requestAsset(for: index), let cacheInfo = self.dataSource?.photoDataSourceCacheInfo() else { return }

        self.cacheManager.requestImage(for: asset, targetSize: cacheInfo.targetSize, contentMode: cacheInfo.contentMode, options: cacheInfo.options) { (image, _) in
            
            // only return completion if image is non nil otherwise ignore request
            guard let cachedImage = image else { return }
            Thread.executeOnMainThread { completion(cachedImage) }
        }
    }
    
    func photoCount() -> Int {
        return self.mediaAssets?.count ?? 0
    }
    
    // MARK: - Private

    private func requestAsset(for index: Int) -> PHAsset? {
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
        }
    }
}
