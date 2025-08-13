# Feed Reader

A modern, feature-rich news reader app built with SwiftUI that fetches news from the NewsAPI.

## Features

### 🚀 Core Functionality
- **Real-time News Fetching**: Get the latest news from NewsAPI
- **Search & Filter**: Search through articles with real-time results
- **Pagination**: Smooth loading of additional articles
- **Pull-to-Refresh**: Refresh the news feed with a simple gesture

### 🎨 Enhanced User Experience
- **Async Image Loading**: Images load asynchronously with placeholder support
- **Smooth Scrolling**: Lazy loading and smooth scrolling for better performance
- **Empty States**: Beautiful empty state views for different scenarios
- **Error Handling**: Comprehensive error handling with user-friendly messages

### 💾 Smart Caching
- **Image Caching**: Images are cached with TTL-based invalidation (24 hours)
- **Search Results Caching**: Search results cached for 1 hour to reduce API calls
- **Memory & Disk Storage**: Efficient caching using both memory and disk storage

### 🧪 Development & Testing
- **Mock Data Service**: Comprehensive mock data for development and testing
- **Dependency Injection**: Clean architecture with proper dependency management
- **Environment Configuration**: Easy switching between mock and real data

### 📱 Modern UI/UX
- **Card-based Design**: Beautiful card layout for news articles
- **Responsive Layout**: Adapts to different screen sizes
- **Loading States**: Skeleton loaders and progress indicators
- **Accessibility**: Built with accessibility in mind

## Architecture

The app follows clean architecture principles with clear separation of concerns:

```
Feed Reader/
├── Models/           # Data models and structures
├── Views/            # SwiftUI views and UI components
├── ViewModels/       # Business logic and state management
├── Networking/       # API services and network layer
└── Tests/            # Unit and UI tests
```

### Key Components

- **NewsViewModel**: Manages news data and API interactions
- **APIService**: Handles network requests with caching
- **ImageCache**: Manages image caching with TTL
- **CacheManager**: Handles search results caching
- **DependencyContainer**: Manages dependencies and configuration

## Setup

### Prerequisites
- Xcode 15.0+
- iOS 17.0+
- Swift 5.9+

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/Feed-Reader.git
cd Feed-Reader
```

2. Open `Feed Reader.xcodeproj` in Xcode

3. Configure your NewsAPI key in `APIConfiguration.swift`:
```swift
static let apiKey: String = "YOUR_API_KEY_HERE"
```

4. Build and run the project

### Using Mock Data for Development

To use mock data during development, set the environment variable:

```bash
export USE_MOCK_DATA=true
```

Or in Xcode:
1. Edit Scheme → Run → Arguments → Environment Variables
2. Add `USE_MOCK_DATA` with value `true`

## API Configuration

The app is configured to:
- Fetch news from the last 24 hours (dynamically calculated)
- Use pagination with 20 articles per page
- Sort by popularity
- Handle rate limiting (5 requests per minute)

## Caching Strategy

### Images
- **Memory Cache**: 100 images, 50MB limit
- **Disk Cache**: Persistent storage with TTL of 24 hours
- **Automatic Cleanup**: Expired images are automatically removed

### Search Results
- **Memory Cache**: 50 search results, 25MB limit
- **Disk Cache**: Persistent storage with TTL of 1 hour
- **Query-based Keys**: Separate cache for each search query and page

## Testing

The app includes comprehensive testing support:

- **Unit Tests**: Test business logic and networking
- **Mock Services**: Simulate API responses and errors
- **Preview Support**: SwiftUI previews for all UI states

### Running Tests

```bash
# Run all tests
xcodebuild test -scheme "Feed Reader" -destination 'platform=iOS Simulator,name=iPhone 15'

# Run specific test target
xcodebuild test -scheme "Feed Reader" -target "Feed ReaderTests"
```

## Performance Features

- **Lazy Loading**: Images and content load only when needed
- **Memory Management**: Efficient memory usage with automatic cleanup
- **Network Optimization**: Reduced API calls through smart caching
- **Smooth Scrolling**: Optimized scrolling performance with LazyVStack

## Error Handling

The app handles various error scenarios gracefully:

- **Network Errors**: Connection issues, timeouts, server errors
- **API Errors**: Invalid API keys, rate limiting, bad requests
- **Data Errors**: Invalid responses, parsing failures
- **User Feedback**: Clear error messages with recovery suggestions

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Commit your changes: `git commit -m 'Add amazing feature'`
4. Push to the branch: `git push origin feature/amazing-feature`
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [NewsAPI](https://newsapi.org/) for providing the news data
- [SwiftUI](https://developer.apple.com/xcode/swiftui/) for the modern UI framework
- [Unsplash](https://unsplash.com/) for placeholder images in mock data

## Support

If you encounter any issues or have questions:

1. Check the [Issues](https://github.com/yourusername/Feed-Reader/issues) page
2. Create a new issue with detailed information
3. Include device, iOS version, and steps to reproduce

---

Built with ❤️ using SwiftUI 
