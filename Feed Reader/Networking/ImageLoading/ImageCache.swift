import Foundation
import UIKit

/// Image cache with TTL-based invalidation
class ImageCache {
    static let shared = ImageCache()
    
    private let cache = NSCache<NSString, CachedImage>()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    private var trackedKeys = Set<String>() // Track keys for cleanup
    
    private init() {
        // Create cache directory in app's documents folder
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        cacheDirectory = documentsPath.appendingPathComponent("ImageCache")
        
        // Create directory if it doesn't exist
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        
        // Set cache limits
        cache.countLimit = 100 // Maximum number of images in memory
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB limit
        
        // Clean expired cache on app launch
        cleanExpiredCache()
    }
    
    // MARK: - Public Methods
    
    func getImage(for url: String) -> UIImage? {
        let key = NSString(string: url)
        
        // Check memory cache first
        if let cachedImage = cache.object(forKey: key) {
            if !cachedImage.isExpired {
                return cachedImage.image
            } else {
                // Remove expired image from memory cache
                cache.removeObject(forKey: key)
            }
        }
        
        // Check disk cache
        if let diskImage = loadImageFromDisk(for: url) {
            // Add to memory cache
            let cachedImage = CachedImage(image: diskImage, timestamp: Date())
            cache.setObject(cachedImage, forKey: key)
            return diskImage
        }
        
        return nil
    }
    
    func setImage(_ image: UIImage, for url: String) {
        let key = NSString(string: url)
        let cachedImage = CachedImage(image: image, timestamp: Date())
        
        // Store in memory cache
        cache.setObject(cachedImage, forKey: key)
        
        // Track the key for cleanup
        trackedKeys.insert(url)
        
        // Store in disk cache
        saveImageToDisk(image, for: url)
    }
    
    func clearCache() {
        cache.removeAllObjects()
        trackedKeys.removeAll()
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    // MARK: - Private Methods
    
    private func loadImageFromDisk(for url: String) -> UIImage? {
        let filename = url.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? url
        let fileURL = cacheDirectory.appendingPathComponent(filename)
        
        guard let data = try? Data(contentsOf: fileURL),
              let image = UIImage(data: data) else {
            return nil
        }
        
        return image
    }
    
    private func saveImageToDisk(_ image: UIImage, for url: String) {
        let filename = url.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? url
        let fileURL = cacheDirectory.appendingPathComponent(filename)
        
        if let data = image.jpegData(compressionQuality: 0.8) {
            try? data.write(to: fileURL)
        }
    }
    
    private func cleanExpiredCache() {
        // Use tracked keys instead of cache.allKeys (which doesn't exist)
        let keysToCheck = Array(trackedKeys)
        for url in keysToCheck {
            let key = NSString(string: url)
            if let cachedImage = cache.object(forKey: key), cachedImage.isExpired {
                cache.removeObject(forKey: key)
                trackedKeys.remove(url)
            }
        }
    }
}

// MARK: - Cached Image Model
private class CachedImage {
    let image: UIImage
    let timestamp: Date
    
    var isExpired: Bool {
        // Cache expires after 24 hours
        return Date().timeIntervalSince(timestamp) > 24 * 60 * 60
    }
    
    init(image: UIImage, timestamp: Date) {
        self.image = image
        self.timestamp = timestamp
    }
}
