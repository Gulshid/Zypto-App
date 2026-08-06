//
//  MenuRepository.swift
//  FoodDeliveryApp
//
//  New in Phase 4. Business-logic-facing access to a restaurant's
//  `menuItems` subcollection (restaurants/{restaurantId}/menuItems).
//
//  Location in project: Core/Repositories/MenuRepository.swift
//
//  UPDATED IN PHASE 7: added the owner-facing side of this subcollection
//  for the dashboard's menu management screen — Restaurant Owners need
//  to see *every* item (including ones toggled unavailable) and create/
//  edit/delete/toggle them.
//

import Foundation

protocol MenuRepositoryProtocol {
    /// Available menu items for a restaurant. Unavailable items
    /// (Restaurant Owner toggled them off in Phase 7) are excluded —
    /// customers browsing in Phase 4 shouldn't see items they can't order.
    func fetchAvailableMenuItems(restaurantId: String) async throws -> [MenuItem]

    /// Every menu item for a restaurant regardless of availability — the
    /// dashboard's menu management list, so the owner can still find and
    /// re-enable an item they 86'd earlier.
    func fetchAllMenuItems(restaurantId: String) async throws -> [MenuItem]

    /// Adds a new item to the restaurant's menuItems subcollection.
    func createMenuItem(_ item: MenuItem) async throws

    /// Saves edits to an existing item (name/price/description/photo/
    /// extras/category/isAvailable) from the dashboard.
    func updateMenuItem(_ item: MenuItem) async throws

    /// Permanently removes an item. Distinct from setting isAvailable to
    /// false, which just hides it from customers without deleting it.
    func deleteMenuItem(restaurantId: String, itemId: String) async throws

    /// Cheap single-field toggle for the dashboard's "86 this item"
    /// switch, so flipping it doesn't require re-encoding the whole item.
    func setAvailability(restaurantId: String, itemId: String, isAvailable: Bool) async throws
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

    func fetchAllMenuItems(restaurantId: String) async throws -> [MenuItem] {
        let path = Constants.Collections.menuItemsPath(restaurantId: restaurantId)
        return try await firestoreService.getDocuments(MenuItem.self, collection: path)
    }

    func createMenuItem(_ item: MenuItem) async throws {
        let path = Constants.Collections.menuItemsPath(restaurantId: item.restaurantId)
        try await firestoreService.setDocument(item, collection: path, documentId: item.id)
    }

    func updateMenuItem(_ item: MenuItem) async throws {
        let path = Constants.Collections.menuItemsPath(restaurantId: item.restaurantId)
        try await firestoreService.setDocument(item, collection: path, documentId: item.id)
    }

    func deleteMenuItem(restaurantId: String, itemId: String) async throws {
        let path = Constants.Collections.menuItemsPath(restaurantId: restaurantId)
        try await firestoreService.deleteDocument(collection: path, documentId: itemId)
    }

    func setAvailability(restaurantId: String, itemId: String, isAvailable: Bool) async throws {
        let path = Constants.Collections.menuItemsPath(restaurantId: restaurantId)
        try await firestoreService.updateFields(["isAvailable": isAvailable], collection: path, documentId: itemId)
    }
}
