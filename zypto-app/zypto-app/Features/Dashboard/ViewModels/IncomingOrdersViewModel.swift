//
//  IncomingOrdersViewModel.swift
//  FoodDeliveryApp
//
//  New in Phase 7. Mirrors OrderHistoryViewModel's live-listener
//  pattern from Phase 6, but scoped to a restaurant instead of a
//  customer — this is what makes the customer's Order Tracking screen
//  (Phase 6) update in real time: this screen writes the status change
//  that listener picks up.
//
//  Location in project: Features/Dashboard/ViewModels/IncomingOrdersViewModel.swift
//

import Foundation

@MainActor
final class IncomingOrdersViewModel: ObservableObject {

    enum Filter: String, CaseIterable {
        case active = "Active"
        case all = "All"
    }

    @Published private(set) var orders: [Order] = []
    @Published private(set) var isLoading = true
    @Published var filter: Filter = .active
    @Published var errorMessage: String?

    private let restaurantId: String
    private let orderRepository: OrderRepositoryProtocol

    init(restaurantId: String, orderRepository: OrderRepositoryProtocol) {
        self.restaurantId = restaurantId
        self.orderRepository = orderRepository
    }

    /// "Active" hides orders in a terminal state (delivered/cancelled)
    /// so the owner's default view is just what still needs attention.
    var filteredOrders: [Order] {
        switch filter {
        case .all:
            return orders
        case .active:
            return orders.filter {
                $0.status != Constants.OrderStatus.delivered && $0.status != Constants.OrderStatus.cancelled
            }
        }
    }

    /// See OrderHistoryViewModel.listen() — same pattern, scoped to
    /// restaurantId instead of customerId.
    func listen() async {
        for await updatedOrders in orderRepository.listenToOrders(restaurantId: restaurantId) {
            orders = updatedOrders
            isLoading = false
        }
    }

    /// Next status in the normal progression after `current`, or nil if
    /// there isn't one (already delivered, or cancelled).
    func nextStatus(after current: String) -> String? {
        guard let index = Constants.OrderStatus.ordered.firstIndex(of: current),
              index + 1 < Constants.OrderStatus.ordered.count else { return nil }
        return Constants.OrderStatus.ordered[index + 1]
    }

    func advanceStatus(_ order: Order) async {
        guard let next = nextStatus(after: order.status) else { return }
        await setStatus(order, to: next)
    }

    func cancelOrder(_ order: Order) async {
        await setStatus(order, to: Constants.OrderStatus.cancelled)
    }

    private func setStatus(_ order: Order, to status: String) async {
        do {
            try await orderRepository.updateStatus(orderId: order.id, status: status)
            // The live listener will also deliver this update, but
            // applying it locally too avoids a visible flicker back to
            // the old status while waiting on the round-trip.
            if let index = orders.firstIndex(where: { $0.id == order.id }) {
                orders[index].status = status
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
