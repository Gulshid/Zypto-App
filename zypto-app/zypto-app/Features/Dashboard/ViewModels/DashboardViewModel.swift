//
//  DashboardViewModel.swift
//  FoodDeliveryApp
//
//  New in Phase 7. Root view model for the Restaurant Owner dashboard.
//  This project scopes one Restaurant Owner account to exactly one
//  restaurant, so the first thing the dashboard needs to know is
//  whether that restaurant already exists (RestaurantProfileView shows
//  the "set up your restaurant" form) or not (the tabbed dashboard —
//  Menu / Orders / Analytics — takes over).
//
//  Location in project: Features/Dashboard/ViewModels/DashboardViewModel.swift
//
//  UPDATED IN PHASE 8: added listenForOrders(restaurantId:) — a
//  lightweight, always-on order listener (paired with
//  DashboardView's `.task(id: viewModel.restaurant?.id)`) separate from
//  IncomingOrdersViewModel's (Phase 7). IncomingOrdersViewModel only
//  runs while the Orders tab itself is selected; this one runs for as
//  long as the dashboard is open on *any* tab, so a new order still
//  triggers a notification/toast while the owner is on Menu or
//  Analytics, and the Orders tab badge (activeOrderCount) stays
//  current no matter which tab is showing.
//

import Foundation

@MainActor
final class DashboardViewModel: ObservableObject {

    @Published private(set) var restaurant: Restaurant?
    @Published private(set) var isLoading = true
    @Published var errorMessage: String?
    /// Orders not yet delivered/cancelled — drives the badge on the
    /// dashboard's Orders tab (see DashboardView.tabs(for:)).
    @Published private(set) var activeOrderCount = 0

    let ownerId: String
    private let restaurantRepository: RestaurantRepositoryProtocol
    private let orderRepository: OrderRepositoryProtocol
    private let notificationService: NotificationServiceProtocol
    private let toastCenter: ToastCenter

    /// Order IDs seen as of the last listener emission, and whether
    /// we've received a first emission yet — same "don't notify about
    /// things that already existed when we started listening" pattern
    /// as OrderHistoryViewModel, just tracking IDs (new orders) instead
    /// of per-order status (see notifyStatusChanges there).
    private var knownOrderIds: Set<String> = []
    private var hasReceivedFirstOrderSnapshot = false

    init(
        ownerId: String,
        restaurantRepository: RestaurantRepositoryProtocol,
        orderRepository: OrderRepositoryProtocol,
        notificationService: NotificationServiceProtocol,
        toastCenter: ToastCenter
    ) {
        self.ownerId = ownerId
        self.restaurantRepository = restaurantRepository
        self.orderRepository = orderRepository
        self.notificationService = notificationService
        self.toastCenter = toastCenter
    }

    func loadRestaurant() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            restaurant = try await restaurantRepository.fetchRestaurant(ownerId: ownerId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Called by RestaurantProfileView after it creates or edits the
    /// restaurant, so the dashboard's local copy stays in sync without
    /// an extra round-trip fetch.
    func applyUpdatedRestaurant(_ updated: Restaurant) {
        restaurant = updated
    }

    func toggleOpen() async {
        guard let restaurant else { return }
        let newValue = !restaurant.isOpen
        self.restaurant?.isOpen = newValue // optimistic

        do {
            try await restaurantRepository.setOpen(restaurantId: restaurant.id, isOpen: newValue)
        } catch {
            self.restaurant?.isOpen = !newValue // roll back
            errorMessage = error.localizedDescription
        }
    }

    /// Runs for as long as the calling Task stays alive — pair with
    /// DashboardView's `.task(id: viewModel.restaurant?.id)`, which
    /// naturally restarts this (fresh `knownOrderIds`) if the
    /// restaurant identity ever changes, and cancels it when the
    /// dashboard disappears. Never returns on its own, same as the
    /// other live-listener view models (OrderHistoryViewModel,
    /// IncomingOrdersViewModel).
    func listenForOrders(restaurantId: String) async {
        knownOrderIds = []
        hasReceivedFirstOrderSnapshot = false

        for await orders in orderRepository.listenToOrders(restaurantId: restaurantId, restaurantOwnerId: ownerId) {
            activeOrderCount = orders.filter {
                $0.status != Constants.OrderStatus.delivered && $0.status != Constants.OrderStatus.cancelled
            }.count

            let currentIds = Set(orders.map(\.id))
            if hasReceivedFirstOrderSnapshot {
                let newOrderIds = currentIds.subtracting(knownOrderIds)
                for order in orders where newOrderIds.contains(order.id) {
                    notifyNewOrder(order)
                }
            } else {
                hasReceivedFirstOrderSnapshot = true
            }
            knownOrderIds = currentIds
        }
    }

    private func notifyNewOrder(_ order: Order) {
        let itemCount = order.items.reduce(0) { $0 + $1.quantity }
        let summary = "\(itemCount) item\(itemCount == 1 ? "" : "s") · \(order.total.formatted(.currency(code: "USD")))"
        notificationService.scheduleNewOrderNotification(orderId: order.id, itemsSummary: summary)
        toastCenter.showNewOrder(summary: summary)
    }
}
