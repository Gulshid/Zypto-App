//
//  DashboardView.swift
//  FoodDeliveryApp
//
//  New in Phase 7. Restaurant Owner entry point, routed from RootView
//  (see App/FoodDeliveryApp.swift) in place of HomePlaceholderView.
//
//  DashboardViewModel first checks whether this owner has already
//  created their restaurant:
//   - No restaurant yet -> full-screen RestaurantProfileView (first-run
//     setup), matching the roadmap's "Add/edit/delete menu items" step
//     needing a restaurant to attach items to first.
//   - Restaurant exists -> a TabView across Menu management, Incoming
//     Orders, Analytics, and the restaurant's own Profile/settings.
//
//  Location in project: Features/Dashboard/Views/DashboardView.swift
//
//  UPDATED IN PHASE 8: added a second `.task(id:)` that (re)starts
//  DashboardViewModel's order listener whenever the restaurant's id
//  becomes known/changes — covers both the normal case (restaurant
//  already existed when the dashboard opened) and first-run (restaurant
//  is created *during* this session via RestaurantProfileView, which
//  flows into applyUpdatedRestaurant). The Orders tab now also shows a
//  badge of in-progress orders, driven by that same listener.
//

import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @StateObject private var viewModel: DashboardViewModel
    private let appEnvironment: AppEnvironment
    private let currentUser: AppUser

    @State private var isPresentingEditProfile = false

    init(user: AppUser, appEnvironment: AppEnvironment) {
        self.currentUser = user
        self.appEnvironment = appEnvironment
        _viewModel = StateObject(wrappedValue: DashboardViewModel(
            ownerId: user.id,
            restaurantRepository: appEnvironment.restaurantRepository,
            orderRepository: appEnvironment.orderRepository,
            notificationService: appEnvironment.notificationService,
            toastCenter: appEnvironment.toastCenter
        ))
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let restaurant = viewModel.restaurant {
                tabs(for: restaurant)
            } else {
                RestaurantProfileView(
                    ownerId: currentUser.id,
                    existingRestaurant: nil,
                    appEnvironment: appEnvironment,
                    onSaved: { viewModel.applyUpdatedRestaurant($0) }
                )
            }
        }
        .task { await viewModel.loadRestaurant() }
        // Restarts (fresh badge/notification state) any time the
        // restaurant's id changes — including going from nil (first-run
        // setup) to a real id the moment RestaurantProfileView saves.
        .task(id: viewModel.restaurant?.id) {
            guard let restaurantId = viewModel.restaurant?.id else { return }
            await viewModel.listenForOrders(restaurantId: restaurantId)
        }
    }

    private func tabs(for restaurant: Restaurant) -> some View {
        TabView {
            MenuManagementView(restaurantId: restaurant.id, appEnvironment: appEnvironment)
                .tabItem { Label("Menu", systemImage: "fork.knife") }

            IncomingOrdersView(restaurantId: restaurant.id, orderRepository: appEnvironment.orderRepository)
                .tabItem { Label("Orders", systemImage: "bag") }
                .badge(viewModel.activeOrderCount)

            AnalyticsView(restaurantId: restaurant.id, orderRepository: appEnvironment.orderRepository)
                .tabItem { Label("Analytics", systemImage: "chart.bar") }

            profileTab(for: restaurant)
                .tabItem { Label("Profile", systemImage: "storefront") }
        }
        .tint(.orange)
    }

    private func profileTab(for restaurant: Restaurant) -> some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(restaurant.name).font(.headline)
                            Text(restaurant.address)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }

                    HStack {
                        Text("Accepting Orders")
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { restaurant.isOpen },
                            set: { _ in Task { await viewModel.toggleOpen() } }
                        ))
                        .labelsHidden()
                    }
                }

                Section {
                    Button("Edit Restaurant Info") {
                        isPresentingEditProfile = true
                    }
                }

                Section {
                    Button("Sign Out", role: .destructive) {
                        authViewModel.signOut()
                    }
                }
            }
            .navigationTitle("Profile")
            .sheet(isPresented: $isPresentingEditProfile) {
                RestaurantProfileView(
                    ownerId: currentUser.id,
                    existingRestaurant: restaurant,
                    appEnvironment: appEnvironment,
                    onSaved: { viewModel.applyUpdatedRestaurant($0) }
                )
            }
        }
    }
}
