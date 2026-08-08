//
//  AnalyticsViewModel.swift
//  FoodDeliveryApp
//
//  New in Phase 7. Backs the dashboard's Analytics tab. Per the
//  roadmap's free-tier constraints (no Cloud Functions), "basic
//  analytics" here means fetching the restaurant's orders once and
//  computing everything client-side — no aggregation collection, no
//  scheduled function keeping a running total.
//
//  Location in project: Features/Dashboard/ViewModels/AnalyticsViewModel.swift
//

import Foundation

@MainActor
final class AnalyticsViewModel: ObservableObject {

    @Published private(set) var orders: [Order] = []
    @Published private(set) var isLoading = true
    @Published var errorMessage: String?

    private let restaurantId: String
    private let restaurantOwnerId: String
    private let orderRepository: OrderRepositoryProtocol

    init(restaurantId: String, restaurantOwnerId: String, orderRepository: OrderRepositoryProtocol) {
        self.restaurantId = restaurantId
        self.restaurantOwnerId = restaurantOwnerId
        self.orderRepository = orderRepository
    }

    /// Excludes cancelled orders from every figure below — a cancelled
    /// order was never actually fulfilled, so counting its total as
    /// "revenue" or its existence as an "order today" would be misleading.
    private var countedOrders: [Order] {
        orders.filter { $0.status != Constants.OrderStatus.cancelled }
    }

    private var todaysOrders: [Order] {
        countedOrders.filter { Calendar.current.isDateInToday($0.createdAt) }
    }

    var ordersToday: Int { todaysOrders.count }
    var revenueToday: Double { todaysOrders.reduce(0) { $0 + $1.total } }

    var totalOrders: Int { countedOrders.count }
    var totalRevenue: Double { countedOrders.reduce(0) { $0 + $1.total } }

    var averageOrderValue: Double {
        totalOrders > 0 ? totalRevenue / Double(totalOrders) : 0
    }

    /// Count per status across ALL orders (including cancelled — the
    /// breakdown is meant to show the full picture, unlike the revenue
    /// figures above), in the same display order as the tracking timeline.
    var statusBreakdown: [(status: String, count: Int)] {
        let allStatuses = Constants.OrderStatus.ordered + [Constants.OrderStatus.cancelled]
        return allStatuses.map { status in
            (status, orders.filter { $0.status == status }.count)
        }
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            orders = try await orderRepository.fetchOrders(restaurantId: restaurantId, restaurantOwnerId: restaurantOwnerId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
