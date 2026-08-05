//
//  CachedAsyncImage.swift
//  FoodDeliveryApp
//
//  New in Phase 4. A minimal caching image loader — the roadmap's
//  "custom AsyncImage wrapper" alternative to pulling in Kingfisher as
//  a dependency. SwiftUI's built-in AsyncImage re-downloads every time
//  a view re-appears (e.g. scrolling a restaurant list up and down),
//  which is wasteful and causes visible flicker; this caches decoded
//  UIImages in memory per session so a restaurant's photo only loads
//  once.
//
//  Location in project: Features/Shared/Views/CachedAsyncImage.swift
//

import SwiftUI

/// Process-lifetime in-memory image cache, keyed by URL string.
/// Deliberately simple: no disk cache, no expiry — this is a portfolio
/// project on the Firebase free tier, not a production CDN client.
/// NSCache automatically evicts under memory pressure, so this can't
/// grow unbounded.
final class ImageCache {
    static let shared = ImageCache()
    private let cache = NSCache<NSString, UIImage>()

    private init() {
        cache.countLimit = 300
    }

    func image(for key: String) -> UIImage? {
        cache.object(forKey: key as NSString)
    }

    func insert(_ image: UIImage, for key: String) {
        cache.setObject(image, forKey: key as NSString)
    }
}

/// Drop-in replacement for SwiftUI's AsyncImage that checks ImageCache
/// before hitting the network, and populates it after a successful load.
///
/// Usage:
///   CachedAsyncImage(url: cloudinaryService.optimizedURL(from: restaurant.imageURL, width: 400)) {
///       Color(.secondarySystemBackground) // placeholder while loading / on failure
///   }
///   .aspectRatio(16/9, contentMode: .fill)
struct CachedAsyncImage<Placeholder: View>: View {
    let url: URL?
    @ViewBuilder var placeholder: () -> Placeholder

    @State private var uiImage: UIImage?

    var body: some View {
        Group {
            if let uiImage {
                Image(uiImage: uiImage)
                    .resizable()
            } else {
                placeholder()
            }
        }
        // task(id:) re-runs whenever `url` changes (e.g. a recycled List
        // row scrolling onto a different restaurant) and is automatically
        // cancelled if the view disappears mid-load.
        .task(id: url) {
            await load()
        }
    }

    private func load() async {
        guard let url else {
            uiImage = nil
            return
        }

        let key = url.absoluteString
        if let cached = ImageCache.shared.image(for: key) {
            uiImage = cached
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard !Task.isCancelled, let image = UIImage(data: data) else { return }
            ImageCache.shared.insert(image, for: key)
            uiImage = image
        } catch {
            // A broken/slow restaurant photo shouldn't block browsing —
            // fall back to the placeholder silently.
        }
    }
}

extension CachedAsyncImage where Placeholder == Color {
    /// Convenience initializer with a neutral gray placeholder, for the
    /// common case where a custom skeleton isn't needed.
    init(url: URL?) {
        self.init(url: url) { Color(.secondarySystemBackground) }
    }
}
