//
//  OrderRepository.swift
//  FoodDeliveryApp
//
//  New in Phase 5. Business-logic-facing access to the top-level
//  `orders` collection.
//
//  Location in project: Core/Repositories/OrderRepository.swift
//
//  UPDATED IN PHASE 6: added fetchOrders(customerId:) for the Order
//  History screen, plus listenToOrder/listenToOrders — live variants
//  backed by Firestore snapshot listeners so status changes and new
//  orders show up without a manual refresh.
//
//  NOTE: fetchOrders/listenToOrders filter on `customerId` and sort by
//  `createdAt`. The first time either runs against a real project,
//  Firestore will throw an error containing a console link to create
//  the required composite index (equality + orderBy on different
//  fields always needs one) — click it once and the query works from
//  then on. Same situation as the categories/averageRating index noted
//  in Phase 3/RestaurantRepository.
//

import Foundation

protocol OrderRepositoryProtocol {
    /// Writes a fully-formed order (built via Order.from(cart:...), see
    /// Core/Models/Order.swift) as a new document keyed by order.id.
    func createOrder(_ order: Order) async throws

    /// One-shot fetch of a customer's past orders, most recent first.
    /// Used to populate Order History before the live listener attaches.
    func fetchOrders(customerId: String) async throws -> [Order]

    /// Live updates for a single order — used by the Order Tracking
    /// screen so a status change (e.g. the restaurant marking it
    /// "Preparing") appears instantly without the customer refreshing.
    func listenToOrder(orderId: String) -> AsyncStream<Order?>

    /// Live updates for a customer's full order list — used by Order
    /// History so a newly-placed order or a status change appears in
    /// place, with no pull-to-refresh required.
    func listenToOrders(customerId: String) -> AsyncStream<[Order]>
}

final class OrderRepository: OrderRepositoryProtocol {
    private let firestoreService: FirestoreServiceProtocol

    init(firestoreService: FirestoreServiceProtocol) {
        self.firestoreService = firestoreService
    }

    func createOrder(_ order: Order) async throws {
        try await firestoreService.setDocument(order, collection: Constants.Collections.orders, documentId: order.id)
    }

    func fetchOrders(customerId: String) async throws -> [Order] {
        try await firestoreService.getDocuments(Order.self, collection: Constants.Collections.orders) { query in
            query
                .whereField("customerId", isEqualTo: customerId)
                .order(by: "createdAt", descending: true)
        }
    }

    func listenToOrder(orderId: String) -> AsyncStream<Order?> {
        firestoreService.listenToDocument(Order.self, collection: Constants.Collections.orders, documentId: orderId)
    }

    func listenToOrders(customerId: String) -> AsyncStream<[Order]> {
        firestoreService.listenToDocuments(Order.self, collection: Constants.Collections.orders) { query in
            query
                .whereField("customerId", isEqualTo: customerId)
                .order(by: "createdAt", descending: true)
        }
    }
}
