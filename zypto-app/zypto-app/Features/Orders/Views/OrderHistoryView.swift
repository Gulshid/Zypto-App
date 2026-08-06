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
//  just while this screen happens to be on screen. See HomeView.
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
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.orders.isEmpty {
                emptyState
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

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "receipt")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text("No orders yet")
                .foregroundStyle(.secondary)
            Text("Your order history and live status will show up here.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
