//
//  NewsArticle.swift
//  Feed Reader
//
//  Created by Zeynep Turnalı on 31.07.2025.
//

import Foundation

// MARK: - NewsAPI Response Models
struct NewsAPIResponse: Codable {
    let status: String
    let totalResults: Int
    let articles: [NewsArticle]
}

struct NewsArticle: Codable, Identifiable {
    let id = UUID() // Custom ID for SwiftUI
    let source: Source
    let author: String?
    let title: String
    let description: String?
    let url: String
    let urlToImage: String?
    let publishedAt: String
    let content: String?
    
    // Custom coding keys to handle optional fields
    enum CodingKeys: String, CodingKey {
        case source, author, title, description, url, urlToImage, publishedAt, content
    }
    
    // Custom initializer to handle optional fields gracefully
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        source = try container.decode(Source.self, forKey: .source)
        author = try container.decodeIfPresent(String.self, forKey: .author)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        url = try container.decode(String.self, forKey: .url)
        urlToImage = try container.decodeIfPresent(String.self, forKey: .urlToImage)
        publishedAt = try container.decode(String.self, forKey: .publishedAt)
        content = try container.decodeIfPresent(String.self, forKey: .content)
    }
    
    // Computed properties for better UX
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        
        if let date = formatter.date(from: publishedAt) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: date)
        }
        
        return publishedAt
    }
    
    var displayAuthor: String {
        return author ?? "Unknown Author"
    }
    
    var displayDescription: String {
        return description ?? "No description available"
    }
}

struct Source: Codable {
    let id: String?
    let name: String
}

// MARK: - Preview Support
extension NewsArticle {
    static func preview() -> NewsArticle {
        return NewsArticle(
            source: Source(id: "techcrunch", name: "TechCrunch"),
            author: "John Doe",
            title: "Apple Announces New iPhone with Revolutionary Features",
            description: "Apple has unveiled its latest iPhone model featuring breakthrough technology and innovative design.",
            url: "https://example.com/article",
            urlToImage: "https://example.com/image.jpg",
            publishedAt: "2025-08-04T10:30:00Z",
            content: "This is a preview article content that demonstrates the structure of news articles in our app."
        )
    }
    
    init(source: Source, author: String?, title: String, description: String?, url: String, urlToImage: String?, publishedAt: String, content: String?) {
        self.source = source
        self.author = author
        self.title = title
        self.description = description
        self.url = url
        self.urlToImage = urlToImage
        self.publishedAt = publishedAt
        self.content = content
    }
}

// MARK: - API Request Parameters
struct NewsAPIRequest {
    let query: String
    let from: String
    let sortBy: String
    let page: Int
    let pageSize: Int
    
    init(query: String = "Apple", 
         from: String = "2025-08-04", 
         sortBy: String = "popularity", 
         page: Int = 1, 
         pageSize: Int = 20) {
        self.query = query
        self.from = from
        self.sortBy = sortBy
        self.page = page
        self.pageSize = pageSize
    }
    
    var queryItems: [URLQueryItem] {
        return [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "from", value: from),
            URLQueryItem(name: "sortBy", value: sortBy),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "pageSize", value: String(pageSize)),
            URLQueryItem(name: "apiKey", value: APIConfiguration.apiKey)
        ]
    }
} 