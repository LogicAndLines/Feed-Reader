//
//  NewsAPIError.swift
//  Feed Reader
//
//  Created by Zeynep Turnalı on 31.07.2025.
//

import Foundation

/// Custom error enum for handling NewsAPI related errors
enum NewsAPIError: LocalizedError, Equatable {
    case invalidURL
    case invalidResponse
    case decodingError(String)
    case networkError(String)
    case apiError(String, Int)
    case noData
    case rateLimitExceeded
    case apiKeyInvalid
    case serverError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL provided"
        case .invalidResponse:
            return "Invalid response from server"
        case .decodingError(let message):
            return "Failed to decode response: \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        case .apiError(let message, let code):
            return "API Error (\(code)): \(message)"
        case .noData:
            return "No data received from server"
        case .rateLimitExceeded:
            return "Rate limit exceeded. Please try again later."
        case .apiKeyInvalid:
            return "Invalid API key. Please check your configuration."
        case .serverError:
            return "Server error occurred. Please try again later."
        }
    }
    
    var failureReason: String? {
        switch self {
        case .invalidURL:
            return "The URL could not be constructed properly"
        case .invalidResponse:
            return "The server response was not in the expected format"
        case .decodingError:
            return "The response data could not be parsed into the expected model"
        case .networkError:
            return "A network connectivity issue occurred"
        case .apiError:
            return "The NewsAPI returned an error response"
        case .noData:
            return "The server returned an empty response"
        case .rateLimitExceeded:
            return "Too many requests made to the API"
        case .apiKeyInvalid:
            return "The provided API key is not valid"
        case .serverError:
            return "An internal server error occurred"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .invalidURL:
            return "Check the API endpoint configuration"
        case .invalidResponse:
            return "Verify the API is responding correctly"
        case .decodingError:
            return "Check if the API response format has changed"
        case .networkError:
            return "Check your internet connection and try again"
        case .apiError:
            return "Review the API documentation for error details"
        case .noData:
            return "Try adjusting your search parameters"
        case .rateLimitExceeded:
            return "Wait a few minutes before making another request"
        case .apiKeyInvalid:
            return "Verify your API key is correct and active"
        case .serverError:
            return "Try again in a few moments"
        }
    }
}

// MARK: - HTTP Status Code Extensions
extension HTTPURLResponse {
    var isSuccessful: Bool {
        return statusCode >= 200 && statusCode < 300
    }
    
    var isClientError: Bool {
        return statusCode >= 400 && statusCode < 500
    }
    
    var isServerError: Bool {
        return statusCode >= 500 && statusCode < 600
    }
} 