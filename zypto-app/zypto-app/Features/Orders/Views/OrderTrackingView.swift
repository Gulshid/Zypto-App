//
//  OrderTrackingView.swift
//  FoodDeliveryApp
//
//  New in Phase 6. Shows one order's items, delivery address, and a
//  live status timeline (pending -> confirmed -> preparing -> out for
//  delivery -> delivered) that updates in real time via
//  OrderTrackingViewModel's Firestore listener. Reached from Order
//  History, or directly from the post-checkout confirmation screen.
//
//  Location in project: Features/Orders/Views/OrderTrackingView.swift
//

import SwiftUI

struct OrderTrackingView: View {
    @StateObject private var viewModel: OrderTrackingViewModel

    init(order: Order, orderRepository: OrderRepositoryProtocol) {
        _viewModel = StateObject(wrappedValue: OrderTrackingViewModel(order: order, orderRepository: orderRepository))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header

                if viewModel.isCancelled {
                    cancelledBanner
                } else {
                    statusTimeline
                }

                itemsSection
                deliverySection
            }
            .padding()
        }
        .navigationTitle("Order Status")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.listen() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(viewModel.order.restaurantName)
                .font(.title3.bold())
            Text("Order #\(viewModel.order.id.prefix(8).uppercased())")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var cancelledBanner: some View {
        HStack {
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(.red)
            Text("This order was cancelled.")
                .font(.subheadline.bold())
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.red.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var statusTimeline: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(Constants.OrderStatus.ordered.enumerated()), id: \.offset) { index, status in
                timelineRow(status: status, index: index, isLast: index == Constants.OrderStatus.ordered.count - 1)
            }
        }
    }

    private func timelineRow(status: String, index: Int, isLast: Bool) -> some View {
        let isComplete = index <= viewModel.statusIndex
        let isCurrent = index == viewModel.statusIndex

        return HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(isComplete ? Color.orange : Color(.systemGray4))
                        .frame(width: 24, height: 24)
                    if isComplete {
                        Image(systemName: "checkmark")
                            .font(.caption2.bold())
                            .foregroundStyle(.white)
                    }
                }
                if !isLast {
                    Rectangle()
                        .fill(index < viewModel.statusIndex ? Color.orange : Color(.systemGray4))
                        .frame(width: 2)
                        .frame(minHeight: 32)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(OrderStatusDisplay.label(for: status))
                    .font(isCurrent ? .subheadline.bold() : .subheadline)
                    .foregroundStyle(isComplete ? .primary : .secondary)
                if isCurrent {
                    Text("Current status")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
            }
            .padding(.top, 2)

            Spacer()
        }
        .padding(.bottom, isLast ? 0 : 4)
    }

    private var itemsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Items").font(.headline)
            VStack(spacing: 6) {
                ForEach(viewModel.order.items) { item in
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(item.quantity)× \(item.name)")
                                .font(.subheadline)
                            if !item.selectedExtras.isEmpty {
                                Text(item.selectedExtras.joined(separator: ", "))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        Text(item.lineTotal, format: .currency(code: "USD"))
                            .font(.subheadline)
                    }
                }
                Divider()
                HStack {
                    Text("Total").font(.subheadline.bold())
                    Spacer()
                    Text(viewModel.order.total, format: .currency(code: "USD"))
                        .font(.subheadline.bold())
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var deliverySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Delivering To").font(.headline)
            Label(viewModel.order.deliveryAddress, systemImage: "mappin.and.ellipse")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}
