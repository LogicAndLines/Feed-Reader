import Foundation

/// Mock API service for testing and development
class MockAPIService: APIService {
    
    override func fetchNews(query: String = "Apple", page: Int = 1, pageSize: Int = APIConfiguration.defaultPageSize) async throws -> NewsAPIResponse {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Simulate random errors for testing
        if Int.random(in: 1...10) == 1 {
            throw NewsAPIError.networkError("Mock network error for testing")
        }
        
        return MockDataService.shared.getMockSearchResults(
            query: query,
            page: page,
            pageSize: pageSize
        )
    }
}
