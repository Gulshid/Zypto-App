//
//  OrderTrackingViewModel.swift
//  FoodDeliveryApp
//
//  New in Phase 6. Tracks one order's live status via a Firestore
//  snapshot listener. Seeded with the order the caller already has
//  (from Order History or a fresh checkout) so the screen has
//  something to show instantly, then keeps it in sync as `status`
//  changes server-side — e.g. once the Phase 7 Restaurant dashboard
//  starts updating it.
//
//  Location in project: Features/Orders/ViewModels/OrderTrackingViewModel.swift
//

import Foundation

@MainActor
final class OrderTrackingViewModel: ObservableObject {

    @Published private(set) var order: Order

    private let orderRepository: OrderRepositoryProtocol

    init(order: Order, orderRepository: OrderRepositoryProtocol) {
        self.order = order
        self.orderRepository = orderRepository
    }

    /// Position of the current status within the normal progression
    /// (pending -> confirmed -> preparing -> out_for_delivery ->
    /// delivered), for driving the timeline UI. Cancelled orders are
    /// handled separately by the view via `isCancelled`.
    var statusIndex: Int {
        Constants.OrderStatus.ordered.firstIndex(of: order.status) ?? 0
    }

    var isCancelled: Bool { order.status == Constants.OrderStatus.cancelled }
    var isDelivered: Bool { order.status == Constants.OrderStatus.delivered }

    /// See OrderHistoryViewModel.listen() — same pattern, paired with
    /// `.task { await viewModel.listen() }` in the view.
    func listen() async {
        for await updatedOrder in orderRepository.listenToOrder(orderId: order.id) {
            if let updatedOrder {
                order = updatedOrder
            }
        }
    }
}
