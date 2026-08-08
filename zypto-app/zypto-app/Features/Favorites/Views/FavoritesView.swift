//
//  FavoritesView.swift
//  FoodDeliveryApp
//
//  New in Phase 11. The Favorites tab: every restaurant the signed-in
//  customer has saved, reusing RestaurantCardView (Features/Home/Views/RestaurantCardView.swift)
//  so a favorited card looks identical to the one on the home feed.
//
//  Location in project: Features/Favorites/Views/FavoritesView.swift
//

import SwiftUI

struct FavoritesView: View {
    @StateObject private var viewModel: FavoritesViewModel
    @Namespace private var heroNamespace

    private let currentUser: AppUser
    private let appEnvironment: AppEnvironment

    init(currentUser: AppUser, appEnvironment: AppEnvironment) {
        self.currentUser = currentUser
        self.appEnvironment = appEnvironment
        _viewModel = StateObject(wrappedValue: FavoritesViewModel(
            uid: currentUser.id,
            restaurantRepository: appEnvironment.restaurantRepository,
            favoritesRepository: appEnvironment.favoritesRepository
        ))
    }

    var body: some View {
        content
            .navigationTitle("Favorites")
            .task { await viewModel.load() }
            .refreshable { await viewModel.load() }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.restaurants.isEmpty {
            ScrollView {
                LazyVStack(spacing: 20) {
                    ForEach(0..<3, id: \.self) { _ in
                        RestaurantCardSkeleton()
                    }
                }
                .padding(.horizontal)
            }
        } else if let errorMessage = viewModel.errorMessage, viewModel.restaurants.isEmpty {
            ErrorStateView(message: errorMessage) {
                Task { await viewModel.load() }
            }
        } else if viewModel.restaurants.isEmpty {
            EmptyStateView(
                systemImage: "heart",
                title: "No favorites yet",
                message: "Tap the heart on any restaurant to save it here."
            )
        } else {
            ScrollView {
                LazyVStack(spacing: 20) {
                    ForEach(viewModel.restaurants) { restaurant in
                        NavigationLink {
                            RestaurantDetailView(
                                restaurant: restaurant,
                                currentUser: currentUser,
                                isFavorite: true,
                                appEnvironment: appEnvironment,
                                heroNamespace: heroNamespace,
                                onFavoriteChanged: { id, isFavorite in
                                    guard !isFavorite, id == restaurant.id else { return }
                                    Task { await viewModel.removeFavorite(restaurant) }
                                }
                            )
                        } label: {
                            RestaurantCardView(
                                restaurant: restaurant,
                                isFavorite: true,
                                cloudinaryService: appEnvironment.cloudinaryService,
                                onToggleFavorite: {
                                    Task { await viewModel.removeFavorite(restaurant) }
                                }
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .animation(.default, value: viewModel.restaurants.map(\.id))
        }
    }
}
