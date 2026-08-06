//
//  AnalyticsView.swift
//  FoodDeliveryApp
//
//  New in Phase 7. The dashboard's Analytics tab — a grid of stat cards
//  plus a per-status order-count breakdown, all computed client-side
//  by AnalyticsViewModel from a single Firestore fetch.
//
//  Location in project: Features/Dashboard/Views/AnalyticsView.swift
//

import SwiftUI

struct AnalyticsView: View {
    @StateObject private var viewModel: AnalyticsViewModel

    init(restaurantId: String, orderRepository: OrderRepositoryProtocol) {
        _viewModel = StateObject(wrappedValue: AnalyticsViewModel(
            restaurantId: restaurantId,
            orderRepository: orderRepository
        ))
    }

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Analytics")
                .task { await viewModel.load() }
                .refreshable { await viewModel.load() }
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    LazyVGrid(columns: columns, spacing: 12) {
                        statCard(title: "Orders Today", value: "\(viewModel.ordersToday)", icon: "bag.fill")
                        statCard(title: "Revenue Today", value: viewModel.revenueToday.formatted(.currency(code: "USD")), icon: "dollarsign.circle.fill")
                        statCard(title: "Total Orders", value: "\(viewModel.totalOrders)", icon: "shippingbox.fill")
                        statCard(title: "Total Revenue", value: viewModel.totalRevenue.formatted(.currency(code: "USD")), icon: "chart.line.uptrend.xyaxis")
                    }

                    statCard(title: "Average Order Value", value: viewModel.averageOrderValue.formatted(.currency(code: "USD")), icon: "equal.circle.fill", fullWidth: true)

                    statusBreakdownSection
                }
                .padding()
            }
        }
    }

    private func statCard(title: String, value: String, icon: String, fullWidth: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(.orange)
                Spacer()
            }
            Text(value)
                .font(.title2.bold())
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var statusBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Orders by Status").font(.headline)

            VStack(spacing: 0) {
                ForEach(Array(viewModel.statusBreakdown.enumerated()), id: \.offset) { index, entry in
                    HStack {
                        Circle()
                            .fill(OrderStatusDisplay.color(for: entry.status))
                            .frame(width: 8, height: 8)
                        Text(OrderStatusDisplay.label(for: entry.status))
                            .font(.subheadline)
                        Spacer()
                        Text("\(entry.count)")
                            .font(.subheadline.bold())
                    }
                    .padding(.vertical, 8)

                    if index < viewModel.statusBreakdown.count - 1 {
                        Divider()
                    }
                }
            }
            .padding(.horizontal)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
}
