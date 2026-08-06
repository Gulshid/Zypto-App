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
//  NOTE: fetchOrders/listenToOrders filter on `customerId` (or, since
//  Phase 7, `restaurantId`) and sort by `createdAt`. The first time
//  either runs against a real project, Firestore will throw an error
//  containing a console link to create the required composite index
//  (equality + orderBy on different fields always needs one) — click
//  it once and the query works from then on. Same situation as the
//  categories/averageRating index noted in Phase 3/RestaurantRepository.
//
//  UPDATED IN PHASE 7: added the restaurant-side counterparts to the
//  customer-side methods above — the dashboard's Incoming Orders screen
//  needs the same one-shot-fetch + live-listener pair, just filtered by
//  `restaurantId` instead of `customerId`, plus updateStatus(...) so
//  the owner can actually advance an order (Pending -> Preparing ->
//  Out for Delivery -> Delivered).
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

    /// One-shot fetch of every order placed at a restaurant, most recent
    /// first. Used by the dashboard's Analytics screen, and to populate
    /// Incoming Orders before its live listener attaches.
    func fetchOrders(restaurantId: String) async throws -> [Order]

    /// Live updates for a restaurant's full order list — the dashboard's
    /// Incoming Orders screen, so a newly-placed order shows up the
    /// instant a customer checks out, no manual refresh required.
    func listenToOrders(restaurantId: String) -> AsyncStream<[Order]>

    /// Advances (or cancels) an order's status from the dashboard.
    /// A cheap single-field update, matching the pattern used by
    /// Order.status's doc comment (see Core/Models/Order.swift).
    func updateStatus(orderId: String, status: String) async throws
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

    func fetchOrders(restaurantId: String) async throws -> [Order] {
        try await firestoreService.getDocuments(Order.self, collection: Constants.Collections.orders) { query in
            query
                .whereField("restaurantId", isEqualTo: restaurantId)
                .order(by: "createdAt", descending: true)
        }
    }

    func listenToOrders(restaurantId: String) -> AsyncStream<[Order]> {
        firestoreService.listenToDocuments(Order.self, collection: Constants.Collections.orders) { query in
            query
                .whereField("restaurantId", isEqualTo: restaurantId)
                .order(by: "createdAt", descending: true)
        }
    }

    func updateStatus(orderId: String, status: String) async throws {
        try await firestoreService.updateFields(
            ["status": status, "updatedAt": Date()],
            collection: Constants.Collections.orders,
            documentId: orderId
        )
    }
}
