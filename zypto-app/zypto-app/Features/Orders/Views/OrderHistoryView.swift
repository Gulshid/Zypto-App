//
//  OrderHistoryView.swift
//  FoodDeliveryApp
//
//  New in Phase 6. Lists the signed-in customer's past and in-progress
//  orders, live-updating via OrderHistoryViewModel. Reached from a new
//  toolbar button on the home feed (see HomeView).
//
//  Location in project: Features/Orders/Views/OrderHistoryView.swift
//
//  UPDATED IN PHASE 8: now takes an already-running OrderHistoryViewModel
//  instead of constructing its own — HomeView owns the instance so its
//  Firestore listener (and the real-time notifications/toasts it
//  drives) keeps running the whole time a customer is in the app, not
//  just while Order History is on screen. See HomeView.
//
//  UPDATED IN PHASE 10: the loading state is now a handful of
//  OrderRowSkeleton shimmer rows (Features/Shared/Views/SkeletonView.swift)
//  instead of a single centered ProgressView, and the empty state now
//  uses the shared EmptyStateView instead of a locally-defined copy.
//

import SwiftUI

struct OrderHistoryView: View {
    @ObservedObject private var viewModel: OrderHistoryViewModel
    private let orderRepository: OrderRepositoryProtocol

    init(viewModel: OrderHistoryViewModel, orderRepository: OrderRepositoryProtocol) {
        self.viewModel = viewModel
        self.orderRepository = orderRepository
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                List(0..<5, id: \.self) { _ in
                    OrderRowSkeleton()
                }
                .listStyle(.plain)
            } else if viewModel.orders.isEmpty {
                EmptyStateView(
                    systemImage: "receipt",
                    title: "No orders yet",
                    message: "Your order history and live status will show up here."
                )
            } else {
                List(viewModel.orders) { order in
                    NavigationLink {
                        OrderTrackingView(order: order, orderRepository: orderRepository)
                    } label: {
                        OrderRowView(order: order)
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Your Orders")
        .navigationBarTitleDisplayMode(.inline)
        // No .task { await viewModel.listen() } here on purpose — the
        // viewModel passed in is already listening (started by
        // HomeView the moment the customer signs in), so attaching a
        // second listener here would just duplicate Firestore reads
        // and risk double-firing notifications.
    }
}
