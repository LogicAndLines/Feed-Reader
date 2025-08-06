//
//  APIConfiguration.swift
//  Feed Reader
//
//  Created by Zeynep Turnalı on 31.07.2025.
//

import Foundation

/// Configuration class for NewsAPI settings
struct APIConfiguration {
    
    // MARK: - API Constants
    static let baseURL = "https://newsapi.org/v2"
    static let everythingEndpoint = "/everything"
    
    // MARK: - API Key Management
    /// The API key for NewsAPI
    /// 
    /// SECURITY NOTE: In a production app, you should:
    /// 1. Store this in a secure keychain
    /// 2. Use environment variables
    /// 3. Implement API key rotation
    /// 4. Consider using a backend proxy to hide the key
    static let apiKey: String = {
        // For development, we'll use the provided key
        // In production, implement one of the security measures above
        return "03f99f37fbae4c65b87e4bd2ec6f434e"
    }()
    
    // MARK: - Request Configuration
    static let defaultPageSize = 20
    static let maxPageSize = 100
    static let defaultSortBy = "popularity"
    static let defaultFromDate = "2025-08-04"
    
    // MARK: - Rate Limiting
    static let requestsPerDay = 1000 // Free tier limit
    static let requestsPerMinute = 5 // Conservative limit
    
    // MARK: - URL Construction
    static func buildURL(for endpoint: String, queryItems: [URLQueryItem]) -> URL? {
        var components = URLComponents(string: baseURL + endpoint)
        components?.queryItems = queryItems
        return components?.url
    }
    
    // MARK: - Validation
    static func validateAPIKey(_ key: String) -> Bool {
        // Basic validation - check if key is not empty and has expected length
        return !key.isEmpty && key.count >= 32
    }
}

// MARK: - Environment Configuration
enum Environment {
    case development
    case staging
    case production
    
    static var current: Environment {
        #if DEBUG
        return .development
        #else
        return .production
        #endif
    }
    
    var baseURL: String {
        switch self {
        case .development, .staging, .production:
            return APIConfiguration.baseURL
        }
    }
    
    var timeoutInterval: TimeInterval {
        switch self {
        case .development:
            return 30.0
        case .staging:
            return 20.0
        case .production:
            return 15.0
        }
    }
} 