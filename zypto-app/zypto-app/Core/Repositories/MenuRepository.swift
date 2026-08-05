//
//  MenuRepository.swift
//  FoodDeliveryApp
//
//  New in Phase 4. Business-logic-facing access to a restaurant's
//  `menuItems` subcollection (restaurants/{restaurantId}/menuItems).
//
//  Location in project: Core/Repositories/MenuRepository.swift
//

import Foundation

protocol MenuRepositoryProtocol {
    /// Available menu items for a restaurant. Unavailable items
    /// (Restaurant Owner toggled them off in Phase 7) are excluded —
    /// customers browsing in Phase 4 shouldn't see items they can't order.
    func fetchAvailableMenuItems(restaurantId: String) async throws -> [MenuItem]
}

final class MenuRepository: MenuRepositoryProtocol {
    private let firestoreService: FirestoreServiceProtocol

    init(firestoreService: FirestoreServiceProtocol) {
        self.firestoreService = firestoreService
    }

    func fetchAvailableMenuItems(restaurantId: String) async throws -> [MenuItem] {
        let path = Constants.Collections.menuItemsPath(restaurantId: restaurantId)
        return try await firestoreService.getDocuments(MenuItem.self, collection: path) { query in
            query.whereField("isAvailable", isEqualTo: true)
        }
    }
}
