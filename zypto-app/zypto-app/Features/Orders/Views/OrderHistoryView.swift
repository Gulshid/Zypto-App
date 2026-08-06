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

import SwiftUI

struct OrderHistoryView: View {
    @StateObject private var viewModel: OrderHistoryViewModel
    private let orderRepository: OrderRepositoryProtocol

    init(uid: String, appEnvironment: AppEnvironment) {
        self.orderRepository = appEnvironment.orderRepository
        _viewModel = StateObject(wrappedValue: OrderHistoryViewModel(
            uid: uid,
            orderRepository: appEnvironment.orderRepository
        ))
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
        .task { await viewModel.listen() }
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
