//
//  APIService.swift
//  Feed Reader
//
//  Created by Zeynep Turnalı on 31.07.2025.
//

import Foundation

/// Main service class for handling NewsAPI requests
class APIService: ObservableObject {
    
    // MARK: - Properties
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private let cacheManager = CacheManager.shared
    
    // MARK: - Rate Limiting
    private var requestCount = 0
    private var lastRequestTime: Date?
    private let rateLimitQueue = DispatchQueue(label: "com.feedreader.ratelimit")
    
    // MARK: - Initialization
    init(session: URLSession = .shared) {
        self.session = session
        
        // Configure JSON decoder
        self.decoder = JSONDecoder()
        self.decoder.keyDecodingStrategy = .useDefaultKeys
        self.decoder.dateDecodingStrategy = .iso8601
        
        // Configure JSON encoder
        self.encoder = JSONEncoder()
        self.encoder.keyEncodingStrategy = .useDefaultKeys
        self.encoder.dateEncodingStrategy = .iso8601
    }
    
    // MARK: - Public Methods
    
    /// Fetches news articles from the NewsAPI
    /// - Parameter request: The request parameters for the API call
    /// - Returns: A NewsAPIResponse containing the articles
    /// - Throws: NewsAPIError for various error conditions
    nonisolated func fetchNews(request: NewsAPIRequest) async throws -> NewsAPIResponse {
        
        // Validate API key
        guard APIConfiguration.validateAPIKey(APIConfiguration.apiKey) else {
            throw NewsAPIError.apiKeyInvalid
        }
        
        // Check rate limiting
        try await checkRateLimit()
        
        // Build URL
        guard let url = APIConfiguration.buildURL(
            for: APIConfiguration.everythingEndpoint,
            queryItems: request.queryItems
        ) else {
            throw NewsAPIError.invalidURL
        }
        
        // Create request
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        urlRequest.timeoutInterval = Environment.current.timeoutInterval
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        urlRequest.setValue("FeedReader/1.0", forHTTPHeaderField: "User-Agent")
        
        do {
            // Perform request
            let (data, response) = try await session.data(for: urlRequest)
            
            // Update rate limiting
            updateRateLimit()
            
            // Validate response
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NewsAPIError.invalidResponse
            }
            
            // Handle HTTP status codes
            try handleHTTPResponse(httpResponse)
            
            // Validate data
            guard !data.isEmpty else {
                throw NewsAPIError.noData
            }
            
            // Decode response
            do {
                let newsResponse = try decoder.decode(NewsAPIResponse.self, from: data)
                return newsResponse
            } catch {
                // Try to decode error response from NewsAPI
                if let errorResponse = try? decoder.decode(NewsAPIErrorResponse.self, from: data) {
                    throw NewsAPIError.apiError(errorResponse.message, httpResponse.statusCode)
                }
                
                // If not an API error, it's a decoding error
                throw NewsAPIError.decodingError(error.localizedDescription)
            }
            
        } catch let error as NewsAPIError {
            // Re-throw our custom errors
            throw error
        } catch {
            // Handle network errors
            if let urlError = error as? URLError {
                switch urlError.code {
                case .notConnectedToInternet, .networkConnectionLost:
                    throw NewsAPIError.networkError("No internet connection")
                case .timedOut:
                    throw NewsAPIError.networkError("Request timed out")
                case .cannotFindHost:
                    throw NewsAPIError.networkError("Cannot reach server")
                default:
                    throw NewsAPIError.networkError(urlError.localizedDescription)
                }
            }
            
            throw NewsAPIError.networkError(error.localizedDescription)
        }
    }
    
    /// Fetches news articles with pagination support
    /// - Parameters:
    ///   - query: Search query
    ///   - page: Page number (1-based)
    ///   - pageSize: Number of articles per page
    /// - Returns: A NewsAPIResponse containing the articles
    nonisolated func fetchNews(query: String = "Apple", 
                   page: Int = 1, 
                   pageSize: Int = APIConfiguration.defaultPageSize) async throws -> NewsAPIResponse {
        
        print("🔍 APIService: Fetching news for query: '\(query)', page: \(page)")
        
        // Check cache first (but don't cache empty results)
        if let cachedResult = cacheManager.getCachedResult(for: query, page: page) {
            print("📦 APIService: Found cached result with \(cachedResult.totalResults) articles")
            // Only return cached result if it has articles
            if cachedResult.totalResults > 0 {
                print("✅ APIService: Returning cached result")
                return cachedResult
            } else {
                print("🗑️ APIService: Clearing cache for empty results")
                // Clear cache for empty results to force fresh API call
                cacheManager.clearCacheForQuery(query)
            }
        } else {
            print("📭 APIService: No cached result found")
        }
        
        print("🌐 APIService: Making fresh API call...")
        let request = NewsAPIRequest(
            query: query,
            from: APIConfiguration.defaultFromDate,
            sortBy: APIConfiguration.defaultSortBy,
            page: page,
            pageSize: min(pageSize, APIConfiguration.maxPageSize)
        )
        
        let response = try await fetchNews(request: request)
        print("📡 APIService: API response received with \(response.totalResults) articles")
        
        // Only cache results that have articles
        if response.totalResults > 0 {
            print("💾 APIService: Caching successful result")
            cacheManager.cacheResult(response, for: query, page: page)
        } else {
            print("⚠️ APIService: Not caching empty result")
        }
        
        return response
    }
    
    // MARK: - Private Methods
    
    /// Handles HTTP response status codes
    private func handleHTTPResponse(_ response: HTTPURLResponse) throws {
        switch response.statusCode {
        case 200...299:
            return // Success
        case 400:
            throw NewsAPIError.apiError("Bad request", response.statusCode)
        case 401:
            throw NewsAPIError.apiKeyInvalid
        case 429:
            throw NewsAPIError.rateLimitExceeded
        case 500...599:
            throw NewsAPIError.serverError
        default:
            throw NewsAPIError.apiError("Unexpected status code: \(response.statusCode)", response.statusCode)
        }
    }
    
    /// Checks rate limiting before making a request
    private nonisolated func checkRateLimit() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            rateLimitQueue.async {
                let now = Date()
                
                // Reset counter if more than a minute has passed
                if let lastRequest = self.lastRequestTime,
                   now.timeIntervalSince(lastRequest) > 60 {
                    self.requestCount = 0
                }
                
                // Check if we're within rate limits
                if self.requestCount >= APIConfiguration.requestsPerMinute {
                    continuation.resume(throwing: NewsAPIError.rateLimitExceeded)
                    return
                }
                
                continuation.resume()
            }
        }
    }
    
    /// Updates rate limiting after a successful request
    private nonisolated func updateRateLimit() {
        rateLimitQueue.async {
            self.requestCount += 1
            self.lastRequestTime = Date()
        }
    }
}

// MARK: - NewsAPI Error Response Model
struct NewsAPIErrorResponse: Codable {
    let status: String
    let code: String?
    let message: String
}

// MARK: - APIService Extensions for Convenience

extension APIService {
    
    /// Convenience method to fetch the latest news
    nonisolated func fetchLatestNews() async throws -> [NewsArticle] {
        let response = try await fetchNews()
        return response.articles
    }
    
    /// Convenience method to search for news with a specific query
    nonisolated func searchNews(query: String) async throws -> [NewsArticle] {
        let response = try await fetchNews(query: query)
        return response.articles
    }
    
    /// Fetches news with cache bypass (force refresh)
    nonisolated func fetchNewsForceRefresh(query: String = "Apple", 
                   page: Int = 1, 
                   pageSize: Int = APIConfiguration.defaultPageSize) async throws -> NewsAPIResponse {
        
        print("🔄 APIService: Force refresh for query: '\(query)', page: \(page)")
        
        // Clear cache for this query to force fresh API call
        cacheManager.clearCacheForQuery(query)
        print("🗑️ APIService: Cache cleared for force refresh")
        
        let request = NewsAPIRequest(
            query: query,
            from: APIConfiguration.defaultFromDate,
            sortBy: APIConfiguration.defaultSortBy,
            page: page,
            pageSize: min(pageSize, APIConfiguration.maxPageSize)
        )
        
        let response = try await fetchNews(request: request)
        print("📡 APIService: Force refresh API response with \(response.totalResults) articles")
        
        // Only cache results that have articles
        if response.totalResults > 0 {
            print("💾 APIService: Caching force refresh result")
            cacheManager.cacheResult(response, for: query, page: page)
        } else {
            print("⚠️ APIService: Not caching empty force refresh result")
        }
        
        return response
    }
    
    /// Convenience method to fetch news with custom parameters
    nonisolated func fetchNews(query: String, 
                   fromDate: String, 
                   sortBy: String, 
                   page: Int = 1) async throws -> NewsAPIResponse {
        
        let request = NewsAPIRequest(
            query: query,
            from: fromDate,
            sortBy: sortBy,
            page: page
        )
        
        return try await fetchNews(request: request)
    }
} 