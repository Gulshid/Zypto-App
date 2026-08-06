//
//  HomeView.swift
//  FoodDeliveryApp
//
//  New in Phase 4. The Customer home feed: search + category filters
//  over a restaurant list, each row navigating to RestaurantDetailView.
//  Replaces HomePlaceholderView for users with role == customer; the
//  Restaurant Owner still sees HomePlaceholderView until the dashboard
//  in Phase 7.
//
//  Location in project: Features/Home/Views/HomeView.swift
//
//  UPDATED IN PHASE 5: owns the session's CartViewModel and injects it
//  as an environmentObject so RestaurantDetailView (adding items) and
//  CartView (pushed from the new toolbar cart button) share one cart.
//
//  UPDATED IN PHASE 6: added a toolbar button into the new Order
//  History screen (live order list + status tracking).
//
//  UPDATED IN PHASE 8: now also owns the OrderHistoryViewModel itself
//  (rather than OrderHistoryView creating its own) so its Firestore
//  listener — and the real-time notification/toast it drives when a
//  status changes — runs for as long as the customer is anywhere in
//  the app, not just while Order History is on screen. The toolbar
//  button also now shows a badge of in-progress orders, same pattern
//  as the existing cart item-count badge below.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @StateObject private var viewModel: HomeViewModel
    @StateObject private var cartViewModel: CartViewModel
    @StateObject private var orderHistoryViewModel: OrderHistoryViewModel

    private let currentUser: AppUser
    private let appEnvironment: AppEnvironment

    init(currentUser: AppUser, appEnvironment: AppEnvironment) {
        self.currentUser = currentUser
        self.appEnvironment = appEnvironment
        _viewModel = StateObject(wrappedValue: HomeViewModel(
            uid: currentUser.id,
            restaurantRepository: appEnvironment.restaurantRepository,
            favoritesRepository: appEnvironment.favoritesRepository
        ))
        _cartViewModel = StateObject(wrappedValue: CartViewModel(
            uid: currentUser.id,
            cartRepository: appEnvironment.cartRepository,
            restaurantRepository: appEnvironment.restaurantRepository
        ))
        _orderHistoryViewModel = StateObject(wrappedValue: OrderHistoryViewModel(
            uid: currentUser.id,
            orderRepository: appEnvironment.orderRepository,
            notificationService: appEnvironment.notificationService,
            toastCenter: appEnvironment.toastCenter
        ))
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Restaurants")
                .searchable(text: $viewModel.searchText, prompt: "Search restaurants or cuisines")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Sign Out", role: .destructive) {
                            authViewModel.signOut()
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        cartButton
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        orderHistoryButton
                    }
                }
                .task {
                    await viewModel.loadInitial()
                    await cartViewModel.loadCart()
                }
                // Separate .task: listen() never returns (it's a live
                // Firestore listener), so it needs its own task rather
                // than being awaited sequentially above — otherwise it
                // would block loadInitial()/loadCart() from ever running.
                .task { await orderHistoryViewModel.listen() }
                .refreshable { await viewModel.loadInitial() }
        }
        .environmentObject(cartViewModel)
    }

    private var cartButton: some View {
        NavigationLink {
            CartView(cartViewModel: cartViewModel, appEnvironment: appEnvironment)
        } label: {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "bag")
                if cartViewModel.itemCount > 0 {
                    Text("\(cartViewModel.itemCount)")
                        .font(.caption2.bold())
                        .foregroundStyle(.white)
                        .padding(4)
                        .background(Color.orange, in: Circle())
                        .offset(x: 10, y: -10)
                }
            }
        }
    }

    private var orderHistoryButton: some View {
        NavigationLink {
            OrderHistoryView(viewModel: orderHistoryViewModel, orderRepository: appEnvironment.orderRepository)
        } label: {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "receipt")
                if orderHistoryViewModel.activeOrderCount > 0 {
                    Text("\(orderHistoryViewModel.activeOrderCount)")
                        .font(.caption2.bold())
                        .foregroundStyle(.white)
                        .padding(4)
                        .background(Color.orange, in: Circle())
                        .offset(x: 10, y: -10)
                }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.restaurants.isEmpty {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let errorMessage = viewModel.errorMessage, viewModel.restaurants.isEmpty {
            errorState(message: errorMessage)
        } else {
            ScrollView {
                categoryFilterBar

                if viewModel.filteredRestaurants.isEmpty {
                    emptyState
                } else {
                    LazyVStack(spacing: 20) {
                        ForEach(viewModel.filteredRestaurants) { restaurant in
                            NavigationLink {
                                RestaurantDetailView(
                                    restaurant: restaurant,
                                    uid: currentUser.id,
                                    isFavorite: viewModel.isFavorite(restaurant.id),
                                    appEnvironment: appEnvironment,
                                    onFavoriteChanged: { id, isFavorite in
                                        viewModel.applyExternalFavoriteChange(restaurantId: id, isFavorite: isFavorite)
                                    }
                                )
                            } label: {
                                RestaurantCardView(
                                    restaurant: restaurant,
                                    isFavorite: viewModel.isFavorite(restaurant.id),
                                    cloudinaryService: appEnvironment.cloudinaryService,
                                    onToggleFavorite: {
                                        Task { await viewModel.toggleFavorite(restaurant.id) }
                                    }
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                }
            }
        }
    }

    private var categoryFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                categoryChip(title: "All", isSelected: viewModel.selectedCategory == nil) {
                    Task { await viewModel.selectCategory(nil) }
                }
                ForEach(viewModel.availableCategories, id: \.self) { category in
                    categoryChip(title: category, isSelected: viewModel.selectedCategory == category) {
                        Task { await viewModel.selectCategory(category) }
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }

    private func categoryChip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.bold())
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? Color.orange : Color(.secondarySystemBackground))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "fork.knife")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text(viewModel.searchText.isEmpty ? "No restaurants yet" : "No matches for \"\(viewModel.searchText)\"")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }

    private func errorState(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundStyle(.orange)
            Text(message)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button("Try Again") {
                Task { await viewModel.loadInitial() }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
