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

import SwiftUI

struct IncomingOrdersView: View {
    @StateObject private var viewModel: IncomingOrdersViewModel

    init(restaurantId: String, orderRepository: OrderRepositoryProtocol) {
        _viewModel = StateObject(wrappedValue: IncomingOrdersViewModel(
            restaurantId: restaurantId,
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
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if viewModel.filteredOrders.isEmpty {
            emptyState
        } else {
            List(viewModel.filteredOrders) { order in
                IncomingOrderRowView(
                    order: order,
                    nextStatusLabel: viewModel.nextStatus(after: order.status).map(OrderStatusDisplay.label(for:)),
                    onAdvance: { Task { await viewModel.advanceStatus(order) } },
                    onCancel: { Task { await viewModel.cancelOrder(order) } }
                )
            }
            .listStyle(.plain)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "bag")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text(viewModel.filter == .active ? "No active orders" : "No orders yet")
                .foregroundStyle(.secondary)
            Text("New orders from customers will show up here in real time.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
