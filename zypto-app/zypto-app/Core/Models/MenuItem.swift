//
//  MenuItem.swift
//  FoodDeliveryApp
//
//  New in Phase 3. Firestore document shape for the `menuItems`
//  subcollection nested under each restaurant document:
//  restaurants/{restaurantId}/menuItems/{menuItemId}
//
//  A subcollection (rather than a top-level collection with a
//  restaurantId field) keeps menu browsing to a single, cheap query —
//  no composite index needed to list "all items for restaurant X".
//
//  Location in project: Core/Models/MenuItem.swift
//

import Foundation

struct MenuItem: Codable, Identifiable, Equatable {
    /// Firestore document ID (within the parent restaurant's menuItems subcollection)
    var id: String
    /// Denormalized back-reference — handy when a MenuItem is passed around
    /// on its own (e.g. in a cart or search result) without its parent restaurant.
    var restaurantId: String

    var name: String
    var description: String
    var price: Double
    var imageURL: String?

    /// e.g. "Starters", "Mains", "Desserts", "Drinks" — used for Phase 9 filters
    var category: String

    /// Restaurant Owner can 86 an item from the dashboard (Phase 7) without deleting it
    var isAvailable: Bool

    /// Free-form add-ons/extras a customer can toggle at checkout (Phase 5),
    /// e.g. "Extra cheese", "No onions". Kept optional + simple for now —
    /// each string is just a label with no separate pricing in this phase.
    var extras: [String]

    var createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, restaurantId, name, description, price, imageURL
        case category, isAvailable, extras, createdAt
    }
}

extension MenuItem {
    static func new(id: String, restaurantId: String, name: String, description: String, price: Double, category: String, extras: [String] = []) -> MenuItem {
        MenuItem(
            id: id,
            restaurantId: restaurantId,
            name: name,
            description: description,
            price: price,
            imageURL: nil,
            category: category,
            isAvailable: true,
            extras: extras,
            createdAt: Date()
        )
    }
}
