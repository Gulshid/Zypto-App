//
//  HomeViewModel.swift
//  FoodDeliveryApp
//
//  New in Phase 4. Drives the customer home feed: loads restaurants +
//  the signed-in user's favorites, and exposes search/category
//  filtering over the in-memory list.
//
//  Search is intentionally client-side (filter the already-fetched
//  `restaurants` array) rather than a Firestore text query — Firestore
//  has no native substring search, and building one (e.g. a separate
//  search-index collection) is overkill for a restaurant list this
//  small. Category filtering DOES go back to Firestore (see
//  RestaurantRepository.fetchRestaurants(category:)) since it can use
//  the composite index from Phase 3 and keeps the "browse by category"
//  path scalable even if the dataset grows.
//
//  Location in project: Features/Home/ViewModels/HomeViewModel.swift
//

import Foundation

@MainActor
final class HomeViewModel: ObservableObject {

    @Published var restaurants: [Restaurant] = []
    @Published var favoriteIds: Set<String> = []
    @Published var searchText: String = ""
    @Published var selectedCategory: String?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let uid: String
    private let restaurantRepository: RestaurantRepositoryProtocol
    private let favoritesRepository: FavoritesRepositoryProtocol

    init(
        uid: String,
        restaurantRepository: RestaurantRepositoryProtocol,
        favoritesRepository: FavoritesRepositoryProtocol
    ) {
        self.uid = uid
        self.restaurantRepository = restaurantRepository
        self.favoritesRepository = favoritesRepository
    }

    /// Every category across the currently-loaded restaurants, for the
    /// filter chip row. Recomputed from `restaurants`, not stored
    /// separately, so it can never drift out of sync with what's on screen.
    var availableCategories: [String] {
        Array(Set(restaurants.flatMap(\.categories))).sorted()
    }

    /// The list the view should actually render: category filter (if any)
    /// applied first — though that filtering already happened server-side
    /// when `selectedCategory` triggered a refetch — then the client-side
    /// search text on top.
    var filteredRestaurants: [Restaurant] {
        guard !searchText.trimmingCharacters(in: .whitespaces).isEmpty else { return restaurants }
        let needle = searchText.lowercased()
        return restaurants.filter { restaurant in
            restaurant.name.lowercased().contains(needle)
                || restaurant.categories.contains { $0.lowercased().contains(needle) }
        }
    }

    func isFavorite(_ restaurantId: String) -> Bool {
        favoriteIds.contains(restaurantId)
    }

    // MARK: - Loading

    func loadInitial() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            async let restaurantsTask = fetchRestaurants(category: selectedCategory)
            async let favoritesTask = favoritesRepository.fetchFavoriteIds(uid: uid)
            let (loadedRestaurants, loadedFavoriteIds) = try await (restaurantsTask, favoritesTask)
            restaurants = loadedRestaurants
            favoriteIds = loadedFavoriteIds
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Called when the user taps a category chip. Refetches from
    /// Firestore with the new filter rather than filtering client-side,
    /// so this stays correct even if not every restaurant is loaded
    /// into memory (e.g. after pagination is added later).
    func selectCategory(_ category: String?) async {
        guard category != selectedCategory else { return }
        selectedCategory = category
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            restaurants = try await fetchRestaurants(category: category)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func fetchRestaurants(category: String?) async throws -> [Restaurant] {
        if let category {
            return try await restaurantRepository.fetchRestaurants(category: category)
        }
        return try await restaurantRepository.fetchAllRestaurants()
    }

    // MARK: - Favorites

    func toggleFavorite(_ restaurantId: String) async {
        let wasFavorite = favoriteIds.contains(restaurantId)
        // Optimistic UI update — the heart flips instantly, then persists.
        if wasFavorite {
            favoriteIds.remove(restaurantId)
        } else {
            favoriteIds.insert(restaurantId)
        }

        do {
            try await favoritesRepository.setFavoriteIds(uid: uid, restaurantIds: favoriteIds)
        } catch {
            // Roll back on failure so the UI doesn't lie about saved state.
            if wasFavorite {
                favoriteIds.insert(restaurantId)
            } else {
                favoriteIds.remove(restaurantId)
            }
            errorMessage = error.localizedDescription
        }
    }

    /// Applies a favorite change that already happened (and was already
    /// persisted) elsewhere — e.g. the user toggled the heart on the
    /// Restaurant Detail screen. Keeps the home feed's hearts in sync
    /// without a redundant Firestore write.
    func applyExternalFavoriteChange(restaurantId: String, isFavorite: Bool) {
        if isFavorite {
            favoriteIds.insert(restaurantId)
        } else {
            favoriteIds.remove(restaurantId)
        }
    }
}
