//
//  NetworkTests.swift
//  Feed ReaderTests
//
//  Created by Zeynep Turnalı on 31.07.2025.
//

import XCTest
@testable import Feed_Reader

final class NetworkTests: XCTestCase {
    
    // MARK: - Mock Data
    let mockNewsResponse = """
    {
        "status": "ok",
        "totalResults": 1,
        "articles": [
            {
                "source": {
                    "id": "techcrunch",
                    "name": "TechCrunch"
                },
                "author": "John Doe",
                "title": "Test Article",
                "description": "This is a test article",
                "url": "https://example.com",
                "urlToImage": "https://example.com/image.jpg",
                "publishedAt": "2025-08-04T10:30:00Z",
                "content": "Test content"
            }
        ]
    }
    """
    
    // MARK: - Test Methods
    
    func testNewsResponseDecoding() throws {
        guard let data = mockNewsResponse.data(using: .utf8) else {
            XCTFail("Failed to create test data")
            return
        }
        
        do {
            let response = try JSONDecoder().decode(NewsAPIResponse.self, from: data)
            
            // Verify response structure
            XCTAssertEqual(response.status, "ok", "Status should be 'ok'")
            XCTAssertEqual(response.totalResults, 1, "Total results should be 1")
            XCTAssertEqual(response.articles.count, 1, "Should have 1 article")
            
            // Verify article structure
            let article = response.articles.first!
            XCTAssertEqual(article.title, "Test Article", "Title should match")
            XCTAssertEqual(article.source.name, "TechCrunch", "Source name should match")
            XCTAssertEqual(article.author, "John Doe", "Author should match")
            
        } catch {
            XCTFail("News response decoding test failed: \(error)")
        }
    }
    
    func testURLConstruction() {
        let request = NewsAPIRequest(
            query: "Apple",
            from: "2025-08-04",
            sortBy: "popularity",
            page: 1,
            pageSize: 20
        )
        
        let url = APIConfiguration.buildURL(
            for: APIConfiguration.everythingEndpoint,
            queryItems: request.queryItems
        )
        
        XCTAssertNotNil(url, "URL should not be nil")
        XCTAssertTrue(url?.absoluteString.contains("q=Apple") == true, "URL should contain query parameter")
        XCTAssertTrue(url?.absoluteString.contains("page=1") == true, "URL should contain page parameter")
    }
    
    func testErrorHandling() {
        let errors: [NewsAPIError] = [
            .invalidURL,
            .networkError("Test error"),
            .apiError("Test API error", 400),
            .rateLimitExceeded
        ]
        
        for error in errors {
            XCTAssertNotNil(error.errorDescription, "Error should have description")
            XCTAssertNotNil(error.failureReason, "Error should have failure reason")
            XCTAssertNotNil(error.recoverySuggestion, "Error should have recovery suggestion")
        }
    }
    
    func testAPIConfiguration() {
        // Test API key validation
        XCTAssertTrue(APIConfiguration.validateAPIKey(APIConfiguration.apiKey), "API key should be valid")
        XCTAssertFalse(APIConfiguration.validateAPIKey(""), "Empty API key should be invalid")
        XCTAssertFalse(APIConfiguration.validateAPIKey("short"), "Short API key should be invalid")
        
        // Test configuration constants
        XCTAssertGreaterThan(APIConfiguration.defaultPageSize, 0, "Default page size should be positive")
        XCTAssertGreaterThan(APIConfiguration.maxPageSize, APIConfiguration.defaultPageSize, "Max page size should be greater than default")
    }
    
    func testNewsArticleComputedProperties() {
        let article = NewsArticle.preview()
        
        // Test computed properties
        XCTAssertFalse(article.displayAuthor.isEmpty, "Display author should not be empty")
        XCTAssertFalse(article.displayDescription.isEmpty, "Display description should not be empty")
        XCTAssertFalse(article.formattedDate.isEmpty, "Formatted date should not be empty")
    }
}

// MARK: - Mock URLSession for Testing
class MockURLSession: URLSession {
    var mockData: Data?
    var mockResponse: URLResponse?
    var mockError: Error?
    
    override func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        if let error = mockError {
            throw error
        }
        return (mockData ?? Data(), mockResponse ?? HTTPURLResponse())
    }
}

// MARK: - APIService Tests
extension NetworkTests {
    
    func testAPIServiceInitialization() {
        let apiService = APIService()
        XCTAssertNotNil(apiService, "APIService should be initialized successfully")
    }
    
    func testAPIServiceWithMockSession() {
        let mockSession = MockURLSession()
        let apiService = APIService(session: mockSession)
        XCTAssertNotNil(apiService, "APIService should be initialized with mock session")
    }
} 