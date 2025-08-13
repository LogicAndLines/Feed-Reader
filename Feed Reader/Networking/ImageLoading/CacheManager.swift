import Foundation

/// Cache manager for search results with TTL-based invalidation
class CacheManager {
    static let shared = CacheManager()
    
    private let cache = NSCache<NSString, CachedSearchResult>()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    private var trackedKeys = Set<String>() // Track keys for cleanup
    
    private init() {
        // Create cache directory in app's documents folder
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        cacheDirectory = documentsPath.appendingPathComponent("SearchCache")
        
        // Create directory if it doesn't exist
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        
        // Set cache limits
        cache.countLimit = 50 // Maximum number of search results in memory
        cache.totalCostLimit = 25 * 1024 * 1024 // 25MB limit
        
        // Clean expired cache on app launch
        cleanExpiredCache()
    }
    
    // MARK: - Public Methods
    
    func getCachedResult(for query: String, page: Int) -> NewsAPIResponse? {
        let key = cacheKey(for: query, page: page)
        
        // Check memory cache first
        if let cachedResult = cache.object(forKey: key) {
            if !cachedResult.isExpired {
                return cachedResult.response
            } else {
                // Remove expired result from memory cache
                cache.removeObject(forKey: key)
            }
        }
        
        // Check disk cache
        if let diskResult = loadResultFromDisk(for: query, page: page) {
            // Add to memory cache
            let cachedResult = CachedSearchResult(response: diskResult, timestamp: Date())
            cache.setObject(cachedResult, forKey: key)
            return diskResult
        }
        
        return nil
    }
    
    func cacheResult(_ response: NewsAPIResponse, for query: String, page: Int) {
        let key = cacheKey(for: query, page: page)
        let cachedResult = CachedSearchResult(response: response, timestamp: Date())
        
        // Store in memory cache
        cache.setObject(cachedResult, forKey: key)
        
        // Track the key for cleanup
        trackedKeys.insert(key as String)
        
        // Store in disk cache
        saveResultToDisk(response, for: query, page: page)
    }
    
    func clearCache() {
        cache.removeAllObjects()
        trackedKeys.removeAll()
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    func clearCacheForQuery(_ query: String) {
        // Use tracked keys instead of cache.allKeys (which doesn't exist)
        let keysToCheck = Array(trackedKeys)
        for keyString in keysToCheck {
            let key = NSString(string: keyString)
            if keyString.contains(query) {
                cache.removeObject(forKey: key)
                trackedKeys.remove(keyString)
            }
        }
        
        // Clear disk cache for this query
        clearDiskCacheForQuery(query)
    }
    
    // MARK: - Private Methods
    
    private func cacheKey(for query: String, page: Int) -> NSString {
        return NSString(string: "\(query)_\(page)")
    }
    
    private func loadResultFromDisk(for query: String, page: Int) -> NewsAPIResponse? {
        let filename = "\(query)_\(page)".addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? "\(query)_\(page)"
        let fileURL = cacheDirectory.appendingPathComponent(filename)
        
        guard let data = try? Data(contentsOf: fileURL) else {
            return nil
        }
        
        do {
            let response = try JSONDecoder().decode(NewsAPIResponse.self, from: data)
            return response
        } catch {
            print("Failed to decode cached search result: \(error)")
            return nil
        }
    }
    
    private func saveResultToDisk(_ response: NewsAPIResponse, for query: String, page: Int) {
        let filename = "\(query)_\(page)".addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? "\(query)_\(page)"
        let fileURL = cacheDirectory.appendingPathComponent(filename)
        
        do {
            let data = try JSONEncoder().encode(response)
            try data.write(to: fileURL)
        } catch {
            print("Failed to save search result to disk: \(error)")
        }
    }
    
    private func clearDiskCacheForQuery(_ query: String) {
        do {
            let contents = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
            for url in contents {
                if url.lastPathComponent.contains(query) {
                    try fileManager.removeItem(at: url)
                }
            }
        } catch {
            print("Failed to clear disk cache for query: \(error)")
        }
    }
    
    private func cleanExpiredCache() {
        // Use tracked keys instead of cache.allKeys (which doesn't exist)
        let keysToCheck = Array(trackedKeys)
        for keyString in keysToCheck {
            let key = NSString(string: keyString)
            if let cachedResult = cache.object(forKey: key), cachedResult.isExpired {
                cache.removeObject(forKey: key)
                trackedKeys.remove(keyString)
            }
        }
    }
}

// MARK: - Cached Search Result Model
private class CachedSearchResult {
    let response: NewsAPIResponse
    let timestamp: Date
    
    var isExpired: Bool {
        // Cache expires after 15 minutes for search results (more responsive)
        return Date().timeIntervalSince(timestamp) > 15 * 60
    }
    
    init(response: NewsAPIResponse, timestamp: Date) {
        self.response = response
        self.timestamp = timestamp
    }
}
