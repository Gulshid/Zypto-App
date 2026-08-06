//
//  CartRepository.swift
//  FoodDeliveryApp
//
//  New in Phase 5. Business-logic-facing access to the `carts`
//  collection (one document per user, id == uid — see Core/Models/Cart.swift
//  for why this is a single document rather than a subcollection).
//
//  Location in project: Core/Repositories/CartRepository.swift
//

import Foundation

protocol CartRepositoryProtocol {
    /// The user's cart, or an empty cart if they've never added anything
    /// yet (Firestore has no document for them). Never returns nil so
    /// call sites don't have to special-case "no cart" vs "empty cart".
    func fetchCart(uid: String) async throws -> Cart

    /// Overwrites the whole cart document. Cart is small and always
    /// edited as a unit (add/remove/quantity change), so there's no
    /// benefit to a more granular field-level update here.
    func saveCart(_ cart: Cart) async throws

    /// Resets the cart to empty after a successful checkout, or when the
    /// user explicitly starts over with a different restaurant.
    func clearCart(uid: String) async throws
}

final class CartRepository: CartRepositoryProtocol {
    private let firestoreService: FirestoreServiceProtocol

    init(firestoreService: FirestoreServiceProtocol) {
        self.firestoreService = firestoreService
    }

    func fetchCart(uid: String) async throws -> Cart {
        let cart = try await firestoreService.getDocument(
            Cart.self, collection: Constants.Collections.carts, documentId: uid
        )
        return cart ?? .empty(uid: uid)
    }

    func saveCart(_ cart: Cart) async throws {
        var toSave = cart
        toSave.updatedAt = Date()
        try await firestoreService.setDocument(toSave, collection: Constants.Collections.carts, documentId: cart.id)
    }

    func clearCart(uid: String) async throws {
        try await saveCart(.empty(uid: uid))
    }
}
