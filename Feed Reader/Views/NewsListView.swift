//
//  NewsListView.swift
//  Feed Reader
//
//  Created by Zeynep Turnalı on 31.07.2025.
//

import SwiftUI

/// Main view for displaying news articles
struct NewsListView: View {
    
    // MARK: - Properties
    @StateObject private var viewModel = NewsViewModel()
    @State private var searchText = ""
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            VStack {
                // Search bar
                searchBar
                
                // Content
                if viewModel.isLoading && viewModel.articles.isEmpty {
                    loadingView
                } else if viewModel.hasError && viewModel.articles.isEmpty {
                    errorView
                } else if viewModel.articles.isEmpty && !searchText.isEmpty {
                    noSearchResultsView
                } else if viewModel.articles.isEmpty {
                    emptyStateView
                } else {
                    newsList
                }
            }
            .navigationTitle("News Reader")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Clear Cache") {
                        viewModel.clearAllCache()
                    }
                    .foregroundColor(.orange)
                    .font(.caption)
                }
            }
            .refreshable {
                await viewModel.forceRefreshNews()
            }
        }
        .task {
            await viewModel.loadNews()
        }
    }
    
    // MARK: - Subviews
    
    private var searchBar: some View {
        HStack {
            
            TextField("\(Image(systemName: "magnifyingglass")) Search news...", text: $searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onSubmit {
                    Task {
                        await viewModel.searchNews(query: searchText)
                    }
                }
            
            if !searchText.isEmpty {
                Button("Clear") {
                    searchText = ""
                    Task {
                        await viewModel.searchNews(query: "Apple")
                    }
                }
                .foregroundColor(.blue)
                
                Button("Refresh") {
                    Task {
                        await viewModel.forceRefreshNews()
                    }
                }
                .foregroundColor(.green)
            }
        }
        .padding(.horizontal)
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Loading news...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var errorView: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.red)
            
            Text("Error")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(viewModel.displayErrorMessage)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            Button("Try Again") {
                Task {
                    await viewModel.refreshNews()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "newspaper")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No Articles Found")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Try adjusting your search or check your connection")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var noSearchResultsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No content is available")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("No articles found for '\(searchText)'. Try a different search term.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            Button("Clear Search") {
                searchText = ""
                Task {
                    await viewModel.searchNews(query: "Apple")
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var newsList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.articles) { article in
                    NewsArticleRow(article: article)
                        .onAppear {
                            // Load more articles when reaching the end
                            if article.id == viewModel.articles.last?.id {
                                Task {
                                    await viewModel.loadNextPage()
                                }
                            }
                        }
                }
                
                // Loading indicator for pagination
                if viewModel.isLoading && !viewModel.articles.isEmpty {
                    HStack {
                        Spacer()
                        ProgressView()
                            .padding()
                        Spacer()
                    }
                }
            }
            .padding(.horizontal)
        }
        .scrollIndicators(.hidden)
    }
}

// MARK: - News Article Row
struct NewsArticleRow: View {
    let article: NewsArticle
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Image and content row
            HStack(alignment: .top, spacing: 12) {
                // Article image
                if let imageUrl = article.urlToImage {
                    CachedAsyncImage(url: imageUrl) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    }
                    .frame(width: 80, height: 80)
                    .clipped()
                    .cornerRadius(8)
                } else {
                    // Placeholder when no image
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 80, height: 80)
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(.gray)
                        )
                        .cornerRadius(8)
                }
                
                // Article content
                VStack(alignment: .leading, spacing: 8) {
                    // Title
                    Text(article.title)
                        .font(.headline)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                    
                    // Description
                    if let description = article.description {
                        Text(description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(3)
                            .multilineTextAlignment(.leading)
                    }
                    
                    // Source and date
                    HStack {
                        Link(article.source.name, destination: URL(string: article.url)!)
                            .font(.caption)
                            .foregroundStyle(.purple)
                            .lineLimit(1)

                        Spacer()
                        
                        Text(article.formattedDate)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Preview
struct NewsListView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Normal state
            NewsListView()
                .previewDisplayName("Normal State")
            
            // Empty state
            NewsListView()
                .environmentObject(NewsViewModel.previewEmpty())
                .previewDisplayName("Empty State")
            
            // Error state
            NewsListView()
                .previewDisplayName("Error State")
        }
    }
} 
