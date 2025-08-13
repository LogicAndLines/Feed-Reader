import Foundation

/// Mock data service for development and testing
class MockDataService {
    static let shared = MockDataService()
    
    private init() {}
    
    // MARK: - Mock Articles
    
    func getMockArticles() -> [NewsArticle] {
        return [
            NewsArticle(
                source: Source(id: "techcrunch", name: "TechCrunch"),
                author: "Sarah Johnson",
                title: "Apple Unveils Revolutionary AI-Powered iPhone 16",
                description: "The new iPhone features breakthrough artificial intelligence capabilities that transform how users interact with their devices.",
                url: "https://techcrunch.com/apple-iphone-16-ai",
                urlToImage: "https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=800&h=600&fit=crop",
                publishedAt: "2025-01-15T10:30:00Z",
                content: "Apple has once again redefined the smartphone industry with the introduction of the iPhone 16..."
            ),
            NewsArticle(
                source: Source(id: "theverge", name: "The Verge"),
                author: "Michael Chen",
                title: "Tesla's New Electric Vehicle Breaks Range Records",
                description: "Tesla's latest model achieves unprecedented range while maintaining affordability for the mass market.",
                url: "https://theverge.com/tesla-new-ev-range",
                urlToImage: "https://images.unsplash.com/photo-1549317661-bd32c8ce0db2?w=800&h=600&fit=crop",
                publishedAt: "2025-01-15T09:15:00Z",
                content: "Tesla has announced a new electric vehicle that shatters previous range records..."
            ),
            NewsArticle(
                source: Source(id: "wired", name: "Wired"),
                author: "Emily Rodriguez",
                title: "Quantum Computing Breakthrough Achieved",
                description: "Scientists have achieved quantum supremacy in a landmark experiment that could revolutionize computing.",
                url: "https://wired.com/quantum-computing-breakthrough",
                urlToImage: "https://images.unsplash.com/photo-1635070041078-e363dbe005cb?w=800&h=600&fit=crop",
                publishedAt: "2025-01-15T08:45:00Z",
                content: "A team of researchers has achieved what many thought impossible..."
            ),
            NewsArticle(
                source: Source(id: "ars-technica", name: "Ars Technica"),
                author: "David Kim",
                title: "SpaceX Successfully Lands on Mars",
                description: "In a historic moment, SpaceX has become the first private company to successfully land on the Red Planet.",
                url: "https://arstechnica.com/spacex-mars-landing",
                urlToImage: "https://images.unsplash.com/photo-1446776811953-b23d0bd843e2?w=800&h=600&fit=crop",
                publishedAt: "2025-01-15T07:30:00Z",
                content: "SpaceX has made history by successfully landing its spacecraft on Mars..."
            ),
            NewsArticle(
                source: Source(id: "mit-tech-review", name: "MIT Technology Review"),
                author: "Lisa Wang",
                title: "Breakthrough in Renewable Energy Storage",
                description: "New battery technology promises to solve the intermittency problem of solar and wind power.",
                url: "https://mit-tech-review.com/renewable-energy-storage",
                urlToImage: "https://images.unsplash.com/photo-1509391366360-2e959784a276?w=800&h=600&fit=crop",
                publishedAt: "2025-01-15T06:20:00Z",
                content: "Researchers have developed a revolutionary battery technology..."
            ),
            NewsArticle(
                source: Source(id: "cnn-tech", name: "CNN Tech"),
                author: "Robert Taylor",
                title: "Virtual Reality Goes Mainstream",
                description: "VR technology has finally reached the tipping point for widespread consumer adoption.",
                url: "https://cnn.com/tech/vr-mainstream",
                urlToImage: "https://images.unsplash.com/photo-1593508512255-aaab0b0f8c0f?w=800&h=600&fit=crop",
                publishedAt: "2025-01-15T05:10:00Z",
                content: "Virtual reality has been on the horizon for decades..."
            ),
            NewsArticle(
                source: Source(id: "bbc-tech", name: "BBC Technology"),
                author: "Jennifer Smith",
                title: "5G Networks Transform Healthcare",
                description: "The rollout of 5G technology is enabling revolutionary changes in telemedicine and remote surgery.",
                url: "https://bbc.com/tech/5g-healthcare",
                urlToImage: "https://images.unsplash.com/photo-1559757148-5c350d0d3c56?w=800&h=600&fit=crop",
                publishedAt: "2025-01-15T04:00:00Z",
                content: "5G networks are revolutionizing healthcare delivery..."
            ),
            NewsArticle(
                source: Source(id: "reuters-tech", name: "Reuters Technology"),
                author: "Alex Thompson",
                title: "Artificial Intelligence in Education",
                description: "AI-powered learning platforms are personalizing education for millions of students worldwide.",
                url: "https://reuters.com/tech/ai-education",
                urlToImage: "https://images.unsplash.com/photo-1522202176988-66273c2fd55f?w=800&h=600&fit=crop",
                publishedAt: "2025-01-15T03:30:00Z",
                content: "Artificial intelligence is transforming education..."
            )
        ]
    }
    
    func getMockArticlesForQuery(_ query: String) -> [NewsArticle] {
        let allArticles = getMockArticles()
        
        if query.isEmpty {
            return allArticles
        }
        
        let lowercasedQuery = query.lowercased()
        return allArticles.filter { article in
            article.title.lowercased().contains(lowercasedQuery) ||
            (article.description?.lowercased().contains(lowercasedQuery) ?? false) ||
            article.source.name.lowercased().contains(lowercasedQuery)
        }
    }
    
    func getMockSearchResults(query: String, page: Int, pageSize: Int) -> NewsAPIResponse {
        let filteredArticles = getMockArticlesForQuery(query)
        let totalResults = filteredArticles.count
        let startIndex = (page - 1) * pageSize
        let endIndex = min(startIndex + pageSize, totalResults)
        
        let articles = Array(filteredArticles[startIndex..<endIndex])
        
        return NewsAPIResponse(
            status: "ok",
            totalResults: totalResults,
            articles: articles
        )
    }
    
    // MARK: - Mock Error Responses
    
    func getMockErrorResponse() -> NewsAPIError {
        return NewsAPIError.networkError("Mock network error for testing")
    }
    
    func getMockEmptyResponse() -> NewsAPIResponse {
        return NewsAPIResponse(
            status: "ok",
            totalResults: 0,
            articles: []
        )
    }
}


