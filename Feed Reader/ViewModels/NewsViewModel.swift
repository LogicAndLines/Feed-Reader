//
//  NewsViewModel.swift
//  Feed Reader
//
//  Created by Zeynep Turnalı on 31.07.2025.
//

import Foundation
import SwiftUI

/// ViewModel for managing news data and API interactions
@MainActor
class NewsViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var articles: [NewsArticle] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasError = false
    @Published var currentPage = 1
    @Published var hasMorePages = true
    @Published var searchQuery = "Apple"
    
    // MARK: - Private Properties
    private let apiService: APIService
    private let pageSize = APIConfiguration.defaultPageSize
    private var totalResults = 0
    
    // MARK: - Initialization
    init(apiService: APIService = APIService()) {
        self.apiService = apiService
    }
    
    // MARK: - Public Methods
    
    /// Loads the initial set of news articles
    func loadNews() async {
        await loadNews(page: 1, isRefresh: true)
    }
    
    /// Loads the next page of news articles
    func loadNextPage() async {
        guard hasMorePages && !isLoading else { return }
        await loadNews(page: currentPage + 1, isRefresh: false)
    }
    
    /// Refreshes the news feed
    func refreshNews() async {
        await loadNews(page: 1, isRefresh: true)
    }
    
    /// Searches for news with a specific query
    func searchNews(query: String) async {
        searchQuery = query
        await loadNews(page: 1, isRefresh: true)
    }
    
    /// Clears any error state
    func clearError() {
        hasError = false
        errorMessage = nil
    }
    
    // MARK: - Private Methods
    
    /// Internal method to load news articles
    private func loadNews(page: Int, isRefresh: Bool) async {
        // Prevent multiple simultaneous requests
        guard !isLoading else { return }
        
        isLoading = true
        
        if isRefresh {
            clearError()
        }
        
        do {
            let response = try await apiService.fetchNews(
                query: searchQuery,
                page: page,
                pageSize: pageSize
            )
            
            // Update articles
            if isRefresh {
                articles = response.articles
            } else {
                articles.append(contentsOf: response.articles)
            }
            
            // Update pagination state
            currentPage = page
            totalResults = response.totalResults
            hasMorePages = articles.count < totalResults
            
            // Clear any previous errors
            clearError()
            
        } catch let error as NewsAPIError {
            handleError(error)
        } catch {
            handleError(NewsAPIError.networkError(error.localizedDescription))
        }
        
        isLoading = false
    }
    
    /// Handles errors and updates the UI state
    private func handleError(_ error: NewsAPIError) {
        hasError = true
        errorMessage = error.errorDescription
        
        // Log error for debugging
        print("NewsAPI Error: \(error.errorDescription ?? "Unknown error")")
        if let failureReason = error.failureReason {
            print("Failure Reason: \(failureReason)")
        }
        if let recoverySuggestion = error.recoverySuggestion {
            print("Recovery Suggestion: \(recoverySuggestion)")
        }
    }
}

// MARK: - Convenience Extensions

extension NewsViewModel {
    
    /// Returns a user-friendly error message
    var displayErrorMessage: String {
        return errorMessage ?? "An unknown error occurred"
    }
    
    /// Returns whether there are any articles loaded
    var hasArticles: Bool {
        return !articles.isEmpty
    }
    
    /// Returns the total number of articles available
    var totalArticlesCount: Int {
        return totalResults
    }
    
    /// Returns whether more articles can be loaded
    var canLoadMore: Bool {
        return hasMorePages && !isLoading
    }
    
    /// Returns a formatted string showing the current page and total results
    var paginationInfo: String {
        let loadedCount = articles.count
        let totalCount = totalResults
        
        if totalCount > 0 {
            return "Showing \(loadedCount) of \(totalCount) articles"
        } else {
            return "No articles found"
        }
    }
}

// MARK: - Preview Support

extension NewsViewModel {
    
    /// Creates a preview instance with mock data
    static func preview() -> NewsViewModel {
        let viewModel = NewsViewModel()
        viewModel.articles = [
            NewsArticle.preview(),
            NewsArticle.preview(),
            NewsArticle.preview()
        ]
        return viewModel
    }
} 
