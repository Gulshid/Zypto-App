//
//  Review.swift
//  FoodDeliveryApp
//
//  New in Phase 3. Firestore document shape for the top-level `reviews`
//  collection. Kept top-level (not a restaurant subcollection) so a
//  customer's own review history could be queried by customerId alone
//  in a later phase without a collection-group query.
//
//  Location in project: Core/Models/Review.swift
//

import Foundation

struct Review: Codable, Identifiable, Equatable {
    /// Firestore document ID
    var id: String

    var restaurantId: String
    var customerId: String
    /// Denormalized so the reviews list (Phase 9) can render a name without
    /// a per-review lookup into `users`.
    var customerName: String

    /// 1...5
    var rating: Int
    var comment: String

    var createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, restaurantId, customerId, customerName, rating, comment, createdAt
    }
}

extension Review {
    static func new(id: String, restaurantId: String, customerId: String, customerName: String, rating: Int, comment: String) -> Review {
        Review(
            id: id,
            restaurantId: restaurantId,
            customerId: customerId,
            customerName: customerName,
            rating: max(1, min(5, rating)),
            comment: comment,
            createdAt: Date()
        )
    }
}
