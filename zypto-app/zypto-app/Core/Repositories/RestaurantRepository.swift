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

import Foundation

protocol RestaurantRepositoryProtocol {
    /// All restaurants, alphabetical — the default home feed browse order.
    func fetchAllRestaurants() async throws -> [Restaurant]

    /// Restaurants tagged with `category`, sorted by rating (highest
    /// first). Uses the categories(array-contains) + averageRating(desc)
    /// composite index deployed in Phase 3.
    func fetchRestaurants(category: String) async throws -> [Restaurant]

    func fetchRestaurant(id: String) async throws -> Restaurant?
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
}
