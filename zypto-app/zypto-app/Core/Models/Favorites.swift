//
//  Favorites.swift
//  FoodDeliveryApp
//
//  New in Phase 4. Firestore document shape for the `favorites`
//  collection: one document per user (doc ID == uid), holding the
//  set of restaurant IDs they've saved.
//
//  Kept as a single doc per user (like Cart, see Core/Models/Cart.swift)
//  rather than a `favorites/{uid}/restaurants/{id}` subcollection — the
//  whole list is always read/written together (populate the heart icons
//  on the home feed; toggle one on/off), so one doc means one read
//  instead of N.
//
//  Location in project: Core/Models/Favorites.swift
//

import Foundation

struct FavoritesDocument: Codable, Equatable {
    /// Equal to the owning user's uid.
    var id: String
    var restaurantIds: [String]

    enum CodingKeys: String, CodingKey {
        case id, restaurantIds
    }
}

extension FavoritesDocument {
    static func empty(uid: String) -> FavoritesDocument {
        FavoritesDocument(id: uid, restaurantIds: [])
    }
}
