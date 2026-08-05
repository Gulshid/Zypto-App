//
//  Restaurant.swift
//  FoodDeliveryApp
//
//  New in Phase 3. Firestore document shape for the top-level
//  `restaurants` collection. One document per restaurant, owned by
//  the Restaurant Owner user who created it (ownerId == AppUser.id).
//
//  Location in project: Core/Models/Restaurant.swift
//

import Foundation

struct Restaurant: Codable, Identifiable, Equatable {
    /// Firestore document ID
    var id: String
    /// Matches AppUser.id of the Restaurant Owner who manages this restaurant
    var ownerId: String

    var name: String
    var description: String
    /// Cloudinary secure_url for the restaurant's cover image (Phase 4/7 wire this up)
    var imageURL: String?

    var address: String
    /// e.g. "Pizza", "Sushi", "Burgers" — used for browsing filters in Phase 4/9
    var categories: [String]

    /// Denormalized aggregate, recomputed client-side whenever a review is
    /// added (see Review.swift / Phase 9). Avoids reading the whole reviews
    /// subcollection just to show a star rating in a list.
    var averageRating: Double
    var reviewCount: Int

    /// Restaurant Owner can toggle this from the dashboard (Phase 7) to stop
    /// taking new orders without deleting the restaurant.
    var isOpen: Bool

    var createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, ownerId, name, description, imageURL, address, categories
        case averageRating, reviewCount, isOpen, createdAt
    }
}

extension Restaurant {
    /// Sensible defaults for a brand-new restaurant document, before any
    /// reviews exist. Used by the "create restaurant" flow in Phase 7.
    static func new(id: String, ownerId: String, name: String, description: String, address: String, categories: [String]) -> Restaurant {
        Restaurant(
            id: id,
            ownerId: ownerId,
            name: name,
            description: description,
            imageURL: nil,
            address: address,
            categories: categories,
            averageRating: 0,
            reviewCount: 0,
            isOpen: true,
            createdAt: Date()
        )
    }
}
