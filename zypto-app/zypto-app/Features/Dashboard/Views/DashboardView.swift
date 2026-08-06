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
            restaurantRepository: appEnvironment.restaurantRepository
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
    }

    private func tabs(for restaurant: Restaurant) -> some View {
        TabView {
            MenuManagementView(restaurantId: restaurant.id, appEnvironment: appEnvironment)
                .tabItem { Label("Menu", systemImage: "fork.knife") }

            IncomingOrdersView(restaurantId: restaurant.id, orderRepository: appEnvironment.orderRepository)
                .tabItem { Label("Orders", systemImage: "bag") }

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
