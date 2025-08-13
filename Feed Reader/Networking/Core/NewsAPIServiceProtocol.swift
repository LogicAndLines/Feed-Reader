import Foundation

/// Protocol for news API service to enable testing and dependency injection
protocol NewsAPIServiceProtocol {
    /// Fetches news articles with pagination support
    /// - Parameters:
    ///   - query: Search query
    ///   - page: Page number (1-based)
    ///   - pageSize: Number of articles per page
    /// - Returns: A NewsAPIResponse containing the articles
    func fetchNews(query: String, page: Int, pageSize: Int) async throws -> NewsAPIResponse
    func fetchNewsForceRefresh(query: String, page: Int, pageSize: Int) async throws -> NewsAPIResponse
}

// MARK: - APIService Conformance
extension APIService: NewsAPIServiceProtocol {
    // APIService already implements the required method
}

// MARK: - MockAPIService Conformance
extension MockAPIService {
    // MockAPIService already implements the required method
}
