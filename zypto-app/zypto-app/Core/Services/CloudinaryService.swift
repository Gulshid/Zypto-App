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
//  UPDATED IN PHASE 7: added uploadImage(data:) — the Restaurant Owner
//  dashboard needs to turn a picked photo (restaurant cover image or
//  menu item photo) into a secure_url in the first place. Uses the
//  unsigned upload preset configured in Constants.Cloudinary — no
//  Cloudinary API secret ever lives in the app, matching the free-tier
//  "unsigned upload preset" design from the roadmap's Phase 1 setup.
//
//  Location in project: Core/Services/CloudinaryService.swift
//

import Foundation

enum CloudinaryError: LocalizedError {
    case invalidResponse
    case uploadFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Cloudinary returned an unexpected response."
        case .uploadFailed(let message):
            return "Image upload failed: \(message)"
        }
    }
}

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

    /// New in Phase 7. Uploads raw JPEG/PNG image data via Cloudinary's
    /// unsigned upload endpoint (Constants.Cloudinary.uploadURL +
    /// uploadPreset) and returns the resulting secure_url, which gets
    /// stored verbatim on Restaurant.imageURL / MenuItem.imageURL.
    func uploadImage(data: Data) async throws -> String
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

    func uploadImage(data: Data) async throws -> String {
        var request = URLRequest(url: Constants.Cloudinary.uploadURL)
        request.httpMethod = "POST"

        // Cloudinary's unsigned upload endpoint expects a standard
        // multipart/form-data body — the file bytes plus the
        // upload_preset field that authorizes an unsigned (no API
        // secret) upload. Built by hand here rather than pulling in a
        // networking dependency for one endpoint.
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()

        func appendField(name: String, value: String) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }

        appendField(name: "upload_preset", value: Constants.Cloudinary.uploadPreset)

        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"upload.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(data)
        body.append("\r\n".data(using: .utf8)!)

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        let (responseData, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw CloudinaryError.invalidResponse
        }

        // Parse just enough JSON to pull out secure_url / an error
        // message, without adding a Codable model for Cloudinary's full
        // (much larger) response shape.
        let json = (try? JSONSerialization.jsonObject(with: responseData)) as? [String: Any]

        guard httpResponse.statusCode == 200, let secureURL = json?["secure_url"] as? String else {
            let message = (json?["error"] as? [String: Any])?["message"] as? String
            throw CloudinaryError.uploadFailed(message ?? "Unknown error (HTTP \(httpResponse.statusCode))")
        }

        return secureURL
    }
}
