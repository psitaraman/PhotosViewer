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
    func photoDataSourceTargetSize() -> CGSize
    func photoDataSourceCacheInfo() -> CacheInfo
}

// default implementation
extension PhotoDataSourceDataSource {
    func photoDataSourceCacheInfo() -> CacheInfo {
        return CacheInfo(contentMode: .aspectFit, options: nil)
    }
}

struct CacheInfo {
    let contentMode: PHImageContentMode
    let options: PHImageRequestOptions?
}

final class PhotoDataSource: NSObject {
    
    // MARK: - Properties
    
    weak var delegate: PhotoDataSourceDelegate?
    weak var dataSource: PhotoDataSourceDataSource?
    
    fileprivate var requestIdLookup = [Int : PHImageRequestID]()
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
        
        //register photo library change observer
        PHPhotoLibrary.shared().register(self)
    }
    
    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
    
    // MARK: - Public
    
    func loadPhotoData() {
        
        self.cacheManager.allowsCachingHighQualityImages = true
        
        let options = PHFetchOptions()
        
        // sort newest photos first
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
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
        guard let cacheInfo = self.dataSource?.photoDataSourceCacheInfo(), let size = self.dataSource?.photoDataSourceTargetSize() else { return }
        
        guard  shouldStopCaching else {
            self.cacheManager.startCachingImages(for: assets, targetSize: size, contentMode: cacheInfo.contentMode, options: cacheInfo.options)
            return
        }
        self.cacheManager.stopCachingImages(for: assets, targetSize: size, contentMode: cacheInfo.contentMode, options: cacheInfo.options)
    }
    
    func requestImageFor(index: Int, completion: @escaping (UIImage) -> ()) {
        guard let asset = self.requestAsset(for: index), let cacheInfo = self.dataSource?.photoDataSourceCacheInfo(), let size = self.dataSource?.photoDataSourceTargetSize() else { return }

        let requestId = self.cacheManager.requestImage(for: asset, targetSize: size, contentMode: cacheInfo.contentMode, options: cacheInfo.options) {[weak self] (image, _) in
            
            defer {
                // cleanup
                self?.requestIdLookup.removeValue(forKey: index)
            }
            
            // only return completion if image is non nil otherwise ignore request
            guard let cachedImage = image else { return }
            Thread.executeOnMainThread { completion(cachedImage) }
        }
        
        // save request Id so that it can be canceled if needed
        self.requestIdLookup[index] = requestId
    }
    
    func cancelImageRequest(at index: Int) {
        
        defer {
            // cleanup
            self.requestIdLookup.removeValue(forKey: index)
        }
        
        guard let identifier = self.requestIdLookup[index] else { return }
        self.cacheManager.cancelImageRequest(identifier)
    }
    
    func photoCount() -> Int {
        return self.mediaAssets?.count ?? 0
    }
    
    func photoIdentifier(for index: Int) -> String {
        return self.requestAsset(for: index)?.localIdentifier ?? ""
    }
    
    func clearCache() {
        self.cacheManager.stopCachingImagesForAllAssets()
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
