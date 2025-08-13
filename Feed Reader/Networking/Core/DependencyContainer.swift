import Foundation

/// Dependency injection container for managing app dependencies
class DependencyContainer {
    static let shared = DependencyContainer()
    
    private init() {}
    
    // MARK: - Services
    
    /// Returns the appropriate API service based on configuration
    var apiService: NewsAPIServiceProtocol {
        #if DEBUG
        // Use mock data in debug builds when environment variable is set
        if ProcessInfo.processInfo.environment["USE_MOCK_DATA"] == "true" {
            return MockAPIService()
        }
        #endif
        
        return APIService()
    }
    
    /// Returns the image cache service
    var imageCache: ImageCache {
        return ImageCache.shared
    }
    
    /// Returns the cache manager for search results
    var cacheManager: CacheManager {
        return CacheManager.shared
    }
    
    // MARK: - ViewModels
    
    /// Creates a NewsViewModel with proper dependencies
    @MainActor
    func makeNewsViewModel() -> NewsViewModel {
        return NewsViewModel(apiService: apiService)
    }
    
    // MARK: - Configuration
    
    /// Returns whether to use mock data
    var useMockData: Bool {
        #if DEBUG
        return ProcessInfo.processInfo.environment["USE_MOCK_DATA"] == "true"
        #else
        return false
        #endif
    }
    
    /// Returns the current environment
    var environment: Environment {
        return Environment.current
    }
}

// MARK: - Environment Configuration
extension DependencyContainer {
    
    /// Sets up the environment for testing
    func setupForTesting() {
        #if DEBUG
        // Set environment variable for testing
        setenv("USE_MOCK_DATA", "true", 1)
        #endif
    }
    
    /// Resets the environment to production
    func resetToProduction() {
        #if DEBUG
        // Remove environment variable
        unsetenv("USE_MOCK_DATA")
        #endif
    }
}
