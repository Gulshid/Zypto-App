//
//  IncomingOrdersView.swift
//  FoodDeliveryApp
//
//  New in Phase 7. The dashboard's Orders tab. Live-updating (via
//  IncomingOrdersViewModel's Firestore listener) list of every order
//  placed at the owner's restaurant, each with controls to advance its
//  status — Pending -> Confirmed -> Preparing -> Out for Delivery ->
//  Delivered — or cancel it. Status changes made here are what the
//  customer's Order Tracking screen (Phase 6) picks up in real time.
//
//  Location in project: Features/Dashboard/Views/IncomingOrdersView.swift
//
//  UPDATED IN PHASE 10: the loading state is now a handful of
//  OrderRowSkeleton shimmer rows (Features/Shared/Views/SkeletonView.swift)
//  instead of a single centered ProgressView, and the empty state now
//  uses the shared EmptyStateView instead of a locally-defined copy.
//  Advancing or cancelling an order now gives a light haptic so the
//  action feels confirmed the instant it's tapped, not only once the
//  Firestore write round-trips.
//

import SwiftUI

struct IncomingOrdersView: View {
    @StateObject private var viewModel: IncomingOrdersViewModel

    init(restaurantId: String, restaurantOwnerId: String, orderRepository: OrderRepositoryProtocol) {
        _viewModel = StateObject(wrappedValue: IncomingOrdersViewModel(
            restaurantId: restaurantId,
            restaurantOwnerId: restaurantOwnerId,
            orderRepository: orderRepository
        ))
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Orders")
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Picker("Filter", selection: $viewModel.filter) {
                            ForEach(IncomingOrdersViewModel.Filter.allCases, id: \.self) { filter in
                                Text(filter.rawValue).tag(filter)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 180)
                    }
                }
                .task { await viewModel.listen() }
                .alert("Error", isPresented: .constant(viewModel.errorMessage != nil), presenting: viewModel.errorMessage) { _ in
                    Button("OK") { viewModel.errorMessage = nil }
                } message: { message in
                    Text(message)
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            List(0..<5, id: \.self) { _ in
                OrderRowSkeleton()
            }
            .listStyle(.plain)
        } else if viewModel.filteredOrders.isEmpty {
            EmptyStateView(
                systemImage: "bag",
                title: viewModel.filter == .active ? "No active orders" : "No orders yet",
                message: "New orders from customers will show up here in real time."
            )
        } else {
            List(viewModel.filteredOrders) { order in
                IncomingOrderRowView(
                    order: order,
                    nextStatusLabel: viewModel.nextStatus(after: order.status).map(OrderStatusDisplay.label(for:)),
                    onAdvance: {
                        Haptics.tap()
                        Task { await viewModel.advanceStatus(order) }
                    },
                    onCancel: {
                        Haptics.warning()
                        Task { await viewModel.cancelOrder(order) }
                    }
                )
            }
            .listStyle(.plain)
        }
    }
}
