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
//  UPDATED IN PHASE 9: passes the full `currentUser` (was just `uid`)
//  into RestaurantDetailView, which now needs the customer's display
//  name to construct its ReviewsViewModel.
//
//  UPDATED IN PHASE 10:
//   - The initial-load spinner is now a scrollable stack of
//     RestaurantCardSkeleton shimmer placeholders (Features/Shared/Views/SkeletonView.swift)
//     instead of a single centered ProgressView.
//   - Empty/error states now use the shared EmptyStateView/ErrorStateView
//     (Features/Shared/Views/EmptyStateView.swift) instead of a
//     locally-defined copy of the same layout.
//   - Tapping a restaurant now zooms its cover photo into
//     RestaurantDetailView's header using iOS 18's `.navigationTransition(.zoom)`,
//     via a shared `heroNamespace`, instead of the plain push animation.
//   - Category filter changes and list content now carry `.animation(_:value:)`
//     modifiers so the chip highlight and the resulting list update
//     animate together instead of popping.
//   - Toolbar buttons get explicit accessibility labels that speak
//     their live badge counts (a sighted person sees the red "3"; a
//     VoiceOver user now hears "Cart, 3 items" the same way).
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @StateObject private var viewModel: HomeViewModel
    @StateObject private var cartViewModel: CartViewModel
    @StateObject private var orderHistoryViewModel: OrderHistoryViewModel
    @Namespace private var heroNamespace

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
                        .accessibilityHidden(true)
                }
            }
        }
        .accessibilityLabel(cartViewModel.itemCount > 0 ? "Cart, \(cartViewModel.itemCount) item\(cartViewModel.itemCount == 1 ? "" : "s")" : "Cart")
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
                        .accessibilityHidden(true)
                }
            }
        }
        .accessibilityLabel(orderHistoryViewModel.activeOrderCount > 0 ? "Your Orders, \(orderHistoryViewModel.activeOrderCount) active" : "Your Orders")
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.restaurants.isEmpty {
            skeletonList
        } else if let errorMessage = viewModel.errorMessage, viewModel.restaurants.isEmpty {
            ErrorStateView(message: errorMessage) {
                Task { await viewModel.loadInitial() }
            }
        } else {
            ScrollView {
                categoryFilterBar

                if viewModel.filteredRestaurants.isEmpty {
                    EmptyStateView(
                        systemImage: "fork.knife",
                        title: viewModel.searchText.isEmpty ? "No restaurants yet" : "No matches for \"\(viewModel.searchText)\""
                    )
                    .padding(.top, 40)
                } else {
                    LazyVStack(spacing: 20) {
                        ForEach(viewModel.filteredRestaurants) { restaurant in
                            NavigationLink {
                                RestaurantDetailView(
                                    restaurant: restaurant,
                                    currentUser: currentUser,
                                    isFavorite: viewModel.isFavorite(restaurant.id),
                                    appEnvironment: appEnvironment,
                                    heroNamespace: heroNamespace,
                                    onFavoriteChanged: { id, isFavorite in
                                        viewModel.applyExternalFavoriteChange(restaurantId: id, isFavorite: isFavorite)
                                    }
                                )
                                .navigationTransition(.zoom(sourceID: restaurant.id, in: heroNamespace))
                            } label: {
                                RestaurantCardView(
                                    restaurant: restaurant,
                                    isFavorite: viewModel.isFavorite(restaurant.id),
                                    cloudinaryService: appEnvironment.cloudinaryService,
                                    onToggleFavorite: {
                                        Task { await viewModel.toggleFavorite(restaurant.id) }
                                    }
                                )
                                .matchedTransitionSource(id: restaurant.id, in: heroNamespace)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                }
            }
            .animation(.default, value: viewModel.filteredRestaurants.map(\.id))
            .animation(.default, value: viewModel.selectedCategory)
        }
    }

    /// Phase 10: a handful of shimmering RestaurantCardSkeleton rows in
    /// the exact layout real cards will appear in, replacing the old
    /// centered ProgressView.
    private var skeletonList: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                ForEach(0..<4, id: \.self) { _ in
                    RestaurantCardSkeleton()
                }
            }
            .padding(.horizontal)
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
        Button {
            Haptics.tap()
            action()
        } label: {
            Text(title)
                .font(.subheadline.bold())
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? Color.orange : Color(.secondarySystemBackground))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}
