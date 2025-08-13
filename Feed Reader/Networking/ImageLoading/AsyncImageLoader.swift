import Foundation
import UIKit
import SwiftUI

/// Service for loading images asynchronously with caching
@MainActor
class AsyncImageLoader: ObservableObject {
    @Published var image: UIImage?
    @Published var isLoading = false
    @Published var hasError = false
    
    private let imageCache = ImageCache.shared
    private var currentTask: Task<Void, Never>?
    
    func loadImage(from urlString: String) {
        // Cancel any existing task
        currentTask?.cancel()
        
        // Check cache first
        if let cachedImage = imageCache.getImage(for: urlString) {
            self.image = cachedImage
            return
        }
        
        // Load from network
        isLoading = true
        hasError = false
        
        currentTask = Task {
            do {
                guard let url = URL(string: urlString) else {
                    throw URLError(.badURL)
                }
                
                let (data, _) = try await URLSession.shared.data(from: url)
                
                // Check if task was cancelled
                if Task.isCancelled { return }
                
                guard let loadedImage = UIImage(data: data) else {
                    throw URLError(.cannotDecodeContentData)
                }
                
                // Cache the image
                imageCache.setImage(loadedImage, for: urlString)
                
                // Update UI on main thread
                await MainActor.run {
                    self.image = loadedImage
                    self.isLoading = false
                }
                
            } catch {
                if !Task.isCancelled {
                    await MainActor.run {
                        self.hasError = true
                        self.isLoading = false
                    }
                }
            }
        }
    }
    
    func cancel() {
        currentTask?.cancel()
        currentTask = nil
    }
    
    deinit {
        // Cancel the task directly - Task.cancel() is not actor-isolated
        currentTask?.cancel()
        currentTask = nil
    }
}

// MARK: - SwiftUI AsyncImage with Caching
struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    let url: String?
    let content: (Image) -> Content
    let placeholder: () -> Placeholder
    
    @StateObject private var imageLoader = AsyncImageLoader()
    
    init(url: String?, @ViewBuilder content: @escaping (Image) -> Content, @ViewBuilder placeholder: @escaping () -> Placeholder) {
        self.url = url
        self.content = content
        self.placeholder = placeholder
    }
    
    var body: some View {
        Group {
            if let image = imageLoader.image {
                content(Image(uiImage: image))
            } else if imageLoader.isLoading {
                placeholder()
            } else if imageLoader.hasError {
                placeholder()
            } else {
                placeholder()
            }
        }
        .onAppear {
            if let url = url, !url.isEmpty {
                imageLoader.loadImage(from: url)
            }
        }
        .onDisappear {
            imageLoader.cancel()
        }
    }
}

// MARK: - Convenience Extensions
extension CachedAsyncImage where Placeholder == AnyView {
    init(url: String?, @ViewBuilder content: @escaping (Image) -> Content) {
        self.init(url: url, content: content) {
            AnyView(
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    )
            )
        }
    }
}
