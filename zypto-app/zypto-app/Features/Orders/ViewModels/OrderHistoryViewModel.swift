//
//  OrderHistoryViewModel.swift
//  FoodDeliveryApp
//
//  New in Phase 6. Drives the Order History screen with a live
//  Firestore listener (OrderRepository.listenToOrders) rather than a
//  one-shot fetch — new orders and status changes appear immediately.
//
//  Location in project: Features/Orders/ViewModels/OrderHistoryViewModel.swift
//
//  UPDATED IN PHASE 8: this is now the customer-side home for
//  real-time UX. It's the same live listener either way, so rather
//  than adding a second one just for notifications, this instance is
//  lifted up and owned by HomeView (instead of OrderHistoryView
//  creating its own) so it keeps running — and can notify — for as
//  long as the customer is anywhere in the app, not just while the
//  Order History screen itself is on screen. See HomeView.
//
//  Added:
//   - notificationService/toastCenter: fired when a *known* order's
//     status changes between snapshots (never on the snapshot an order
//     first appears in — the customer just placed it, they don't need
//     telling).
//   - activeOrderCount: drives the badge on HomeView's Order History
//     toolbar button.
//

import Foundation

@MainActor
final class OrderHistoryViewModel: ObservableObject {

    @Published private(set) var orders: [Order] = []
    @Published private(set) var isLoading = true

    private let uid: String
    private let orderRepository: OrderRepositoryProtocol
    private let notificationService: NotificationServiceProtocol
    private let toastCenter: ToastCenter

    /// Snapshot of each known order's status as of the last update,
    /// used to detect a *change* (as opposed to an order simply
    /// existing) between one listener emission and the next.
    private var lastKnownStatuses: [String: String] = [:]

    init(
        uid: String,
        orderRepository: OrderRepositoryProtocol,
        notificationService: NotificationServiceProtocol,
        toastCenter: ToastCenter
    ) {
        self.uid = uid
        self.orderRepository = orderRepository
        self.notificationService = notificationService
        self.toastCenter = toastCenter
    }

    /// Orders still in progress (not delivered/cancelled) — the number
    /// shown on HomeView's Order History toolbar badge.
    var activeOrderCount: Int {
        orders.filter {
            $0.status != Constants.OrderStatus.delivered && $0.status != Constants.OrderStatus.cancelled
        }.count
    }

    /// Runs for as long as the calling Task stays alive — pair with
    /// `.task { await viewModel.listen() }` in the view, which cancels
    /// this (and detaches the underlying Firestore listener) the moment
    /// Order History disappears. Never returns on its own since
    /// Firestore listeners don't naturally complete.
    func listen() async {
        for await updatedOrders in orderRepository.listenToOrders(customerId: uid) {
            notifyStatusChanges(updatedOrders)
            orders = updatedOrders
            isLoading = false
        }
    }

    /// Compares each order's status against `lastKnownStatuses` and
    /// fires a notification + toast for anything that actually
    /// changed. Skipped entirely on the very first snapshot (isLoading
    /// is still true at that point) — otherwise every pre-existing
    /// order would "notify" the instant the listener attaches.
    private func notifyStatusChanges(_ updatedOrders: [Order]) {
        guard !isLoading else {
            for order in updatedOrders {
                lastKnownStatuses[order.id] = order.status
            }
            return
        }

        for order in updatedOrders {
            let previousStatus = lastKnownStatuses[order.id]
            if let previousStatus, previousStatus != order.status {
                notificationService.scheduleOrderStatusNotification(
                    orderId: order.id,
                    restaurantName: order.restaurantName,
                    status: order.status
                )
                toastCenter.showStatusUpdate(restaurantName: order.restaurantName, status: order.status)
            }
            lastKnownStatuses[order.id] = order.status
        }
    }
}
