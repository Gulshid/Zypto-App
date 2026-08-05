//
//  CloudinaryService.swift
//  FoodDeliveryApp
//
//  New in Phase 4. Turns a raw Cloudinary secure_url (the kind stored
//  verbatim in Restaurant.imageURL / MenuItem.imageURL) into an
//  optimized delivery URL, by inserting a Cloudinary transformation
//  string into the path. This is what actually gets requested by
//  CachedAsyncImage.
//
//  Upload (turning a picked photo into a secure_url in the first
//  place) isn't needed until the Restaurant Owner dashboard in
//  Phase 7, so this service only handles the read side for now.
//
//  Location in project: Core/Services/CloudinaryService.swift
//

import Foundation

protocol CloudinaryServiceProtocol {
    /// - Parameters:
    ///   - urlString: a raw Cloudinary secure_url, or nil/empty if the
    ///     restaurant/menu item has no photo yet.
    ///   - width: if provided, requests an image downscaled to roughly
    ///     this pixel width (`c_limit`, so it never upscales past the
    ///     original). Pass nil to let Cloudinary pick automatically.
    /// - Returns: a transformed URL, or nil if `urlString` was nil/empty.
    ///   If `urlString` doesn't look like a Cloudinary upload URL, it's
    ///   returned unchanged rather than mangled.
    func optimizedURL(from urlString: String?, width: Int?) -> URL?
}

final class CloudinaryServiceLive: CloudinaryServiceProtocol {

    func optimizedURL(from urlString: String?, width: Int? = nil) -> URL? {
        guard let urlString, !urlString.isEmpty else { return nil }

        // Cloudinary delivery URLs always contain "/upload/" right before
        // the version/public-id segment — that's where transformation
        // flags get inserted. e.g.
        //   .../image/upload/v1699999999/zypto/restaurants/abc.jpg
        //     -> .../image/upload/f_auto,q_auto,w_600,c_limit/v1699999999/...
        guard let uploadRange = urlString.range(of: "/upload/") else {
            // Not a recognizable Cloudinary URL (e.g. a placeholder or a
            // URL from somewhere else entirely) — hand it back as-is
            // rather than guessing.
            return URL(string: urlString)
        }

        // f_auto: serve WebP/AVIF automatically where the client supports it
        // q_auto: Cloudinary picks a quality level that balances size/clarity
        var transform = "f_auto,q_auto"
        if let width {
            transform += ",w_\(width),c_limit"
        }

        let transformed = urlString.replacingCharacters(in: uploadRange, with: "/upload/\(transform)/")
        return URL(string: transformed)
    }
}
