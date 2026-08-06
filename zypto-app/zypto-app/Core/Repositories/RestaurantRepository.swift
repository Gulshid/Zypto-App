//
//  RestaurantRepository.swift
//  FoodDeliveryApp
//
//  New in Phase 4. Business-logic-facing access to the top-level
//  `restaurants` collection. HomeViewModel and RestaurantDetailViewModel
//  call this instead of touching Firestore directly.
//
//  Location in project: Core/Repositories/RestaurantRepository.swift
//
//  UPDATED IN PHASE 7: added the owner-facing side of this collection
//  for the Restaurant/Admin dashboard — looking up the restaurant a
//  given owner manages, creating it the first time they sign in, and
//  saving edits (name/description/photo/isOpen) from the dashboard.
//

import Foundation

protocol RestaurantRepositoryProtocol {
    /// All restaurants, alphabetical — the default home feed browse order.
    func fetchAllRestaurants() async throws -> [Restaurant]

    /// Restaurants tagged with `category`, sorted by rating (highest
    /// first). Uses the categories(array-contains) + averageRating(desc)
    /// composite index deployed in Phase 3.
    func fetchRestaurants(category: String) async throws -> [Restaurant]

    func fetchRestaurant(id: String) async throws -> Restaurant?

    /// The single restaurant owned by `ownerId`, if they've created one
    /// yet. This project keeps the dashboard scoped to one restaurant
    /// per Restaurant Owner account, so `limit(to: 1)` is safe here.
    func fetchRestaurant(ownerId: String) async throws -> Restaurant?

    /// Writes a brand-new restaurant document (see Restaurant.new(...)),
    /// used the first time a Restaurant Owner sets up their dashboard.
    func createRestaurant(_ restaurant: Restaurant) async throws

    /// Saves edits to an existing restaurant (profile info, cover photo,
    /// isOpen) from the dashboard.
    func updateRestaurant(_ restaurant: Restaurant) async throws

    /// Cheap single-field update for the dashboard's open/closed toggle,
    /// so flipping it doesn't require re-encoding the whole document.
    func setOpen(restaurantId: String, isOpen: Bool) async throws
}

final class RestaurantRepository: RestaurantRepositoryProtocol {
    private let firestoreService: FirestoreServiceProtocol

    init(firestoreService: FirestoreServiceProtocol) {
        self.firestoreService = firestoreService
    }

    func fetchAllRestaurants() async throws -> [Restaurant] {
        try await firestoreService.getDocuments(Restaurant.self, collection: Constants.Collections.restaurants) { query in
            query.order(by: "name")
        }
    }

    func fetchRestaurants(category: String) async throws -> [Restaurant] {
        try await firestoreService.getDocuments(Restaurant.self, collection: Constants.Collections.restaurants) { query in
            query
                .whereField("categories", arrayContains: category)
                .order(by: "averageRating", descending: true)
        }
    }

    func fetchRestaurant(id: String) async throws -> Restaurant? {
        try await firestoreService.getDocument(
            Restaurant.self, collection: Constants.Collections.restaurants, documentId: id
        )
    }

    func fetchRestaurant(ownerId: String) async throws -> Restaurant? {
        let results = try await firestoreService.getDocuments(Restaurant.self, collection: Constants.Collections.restaurants) { query in
            query.whereField("ownerId", isEqualTo: ownerId).limit(to: 1)
        }
        return results.first
    }

    func createRestaurant(_ restaurant: Restaurant) async throws {
        try await firestoreService.setDocument(
            restaurant, collection: Constants.Collections.restaurants, documentId: restaurant.id
        )
    }

    func updateRestaurant(_ restaurant: Restaurant) async throws {
        try await firestoreService.setDocument(
            restaurant, collection: Constants.Collections.restaurants, documentId: restaurant.id
        )
    }

    func setOpen(restaurantId: String, isOpen: Bool) async throws {
        try await firestoreService.updateFields(
            ["isOpen": isOpen], collection: Constants.Collections.restaurants, documentId: restaurantId
        )
    }
}
