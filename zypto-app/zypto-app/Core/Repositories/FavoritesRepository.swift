//
//  FavoritesRepository.swift
//  FoodDeliveryApp
//
//  New in Phase 4. Business-logic-facing access to the `favorites`
//  collection — one document per user, see Core/Models/Favorites.swift
//  for why it's shaped this way.
//
//  Location in project: Core/Repositories/FavoritesRepository.swift
//

import Foundation

protocol FavoritesRepositoryProtocol {
    func fetchFavoriteIds(uid: String) async throws -> Set<String>
    func setFavoriteIds(uid: String, restaurantIds: Set<String>) async throws
}

final class FavoritesRepository: FavoritesRepositoryProtocol {
    private let firestoreService: FirestoreServiceProtocol

    init(firestoreService: FirestoreServiceProtocol) {
        self.firestoreService = firestoreService
    }

    func fetchFavoriteIds(uid: String) async throws -> Set<String> {
        let doc = try await firestoreService.getDocument(
            FavoritesDocument.self, collection: Constants.Collections.favorites, documentId: uid
        )
        return Set(doc?.restaurantIds ?? [])
    }

    func setFavoriteIds(uid: String, restaurantIds: Set<String>) async throws {
        let doc = FavoritesDocument(id: uid, restaurantIds: Array(restaurantIds))
        try await firestoreService.setDocument(
            doc, collection: Constants.Collections.favorites, documentId: uid
        )
    }
}
