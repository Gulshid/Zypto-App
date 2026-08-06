//
//  OrderRepository.swift
//  FoodDeliveryApp
//
//  New in Phase 5. Business-logic-facing access to the top-level
//  `orders` collection. Checkout (Phase 5) only needs to create an
//  order; fetching a customer's order history and listening for
//  real-time status changes are Phase 6 additions to this same file.
//
//  Location in project: Core/Repositories/OrderRepository.swift
//

import Foundation

protocol OrderRepositoryProtocol {
    /// Writes a fully-formed order (built via Order.from(cart:...), see
    /// Core/Models/Order.swift) as a new document keyed by order.id.
    func createOrder(_ order: Order) async throws
}

final class OrderRepository: OrderRepositoryProtocol {
    private let firestoreService: FirestoreServiceProtocol

    init(firestoreService: FirestoreServiceProtocol) {
        self.firestoreService = firestoreService
    }

    func createOrder(_ order: Order) async throws {
        try await firestoreService.setDocument(order, collection: Constants.Collections.orders, documentId: order.id)
    }
}
