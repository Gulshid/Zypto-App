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

import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @StateObject private var viewModel: HomeViewModel

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
                }
                .task { await viewModel.loadInitial() }
                .refreshable { await viewModel.loadInitial() }
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
