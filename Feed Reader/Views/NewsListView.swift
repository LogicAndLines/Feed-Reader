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
                } else if viewModel.articles.isEmpty {
                    emptyStateView
                } else {
                    newsList
                }
            }
            .navigationTitle("News Reader")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await viewModel.refreshNews()
            }
        }
        .task {
            await viewModel.loadNews()
        }
    }
    
    // MARK: - Subviews
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search news...", text: $searchText)
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
    
    private var newsList: some View {
        List {
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
        .listStyle(PlainListStyle())
    }
}

// MARK: - News Article Row
struct NewsArticleRow: View {
    let article: NewsArticle
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title
            Text(article.title)
                .font(.headline)
                .lineLimit(2)
            
            // Description
            if let description = article.description {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }
            
            // Meta information
            HStack {
                Text(article.source.name)
                    .font(.caption)
                    .foregroundColor(.blue)
                
                Spacer()
                
                Text(article.formattedDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview
struct NewsListView_Previews: PreviewProvider {
    static var previews: some View {
        NewsListView()
    }
} 