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

import Foundation

@MainActor
final class OrderHistoryViewModel: ObservableObject {

    @Published private(set) var orders: [Order] = []
    @Published private(set) var isLoading = true

    private let uid: String
    private let orderRepository: OrderRepositoryProtocol

    init(uid: String, orderRepository: OrderRepositoryProtocol) {
        self.uid = uid
        self.orderRepository = orderRepository
    }

    /// Runs for as long as the calling Task stays alive — pair with
    /// `.task { await viewModel.listen() }` in the view, which cancels
    /// this (and detaches the underlying Firestore listener) the moment
    /// Order History disappears. Never returns on its own since
    /// Firestore listeners don't naturally complete.
    func listen() async {
        for await updatedOrders in orderRepository.listenToOrders(customerId: uid) {
            orders = updatedOrders
            isLoading = false
        }
    }
}
