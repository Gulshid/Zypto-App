//
//  FavoritesViewModel.swift
//  FoodDeliveryApp
//
//  New in Phase 11. Drives the Favorites tab (Features/Favorites/Views/FavoritesView.swift):
//  loads the signed-in customer's saved restaurant IDs (FavoritesRepository,
//  same doc HomeViewModel reads/writes for the heart icons on the home
//  feed) and resolves each ID into a full Restaurant for display.
//
//  Location in project: Features/Favorites/ViewModels/FavoritesViewModel.swift
//

import Foundation

@MainActor
final class FavoritesViewModel: ObservableObject {

    @Published var restaurants: [Restaurant] = []
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

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let favoriteIds = try await favoritesRepository.fetchFavoriteIds(uid: uid)
            // Fetched concurrently — favoriting is usually a handful of
            // restaurants, so N parallel document reads beats N sequential
            // round-trips without needing a batched "get many" API.
            let fetched: [Restaurant] = try await withThrowingTaskGroup(of: Restaurant?.self) { group in
                for id in favoriteIds {
                    group.addTask { try await self.restaurantRepository.fetchRestaurant(id: id) }
                }
                var results: [Restaurant] = []
                for try await restaurant in group {
                    if let restaurant { results.append(restaurant) }
                }
                return results
            }
            restaurants = fetched.sorted { $0.name < $1.name }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Un-favoriting from this screen removes the restaurant from the
    /// list immediately (there's nothing else to show it for here,
    /// unlike the home feed's heart which just flips in place).
    func removeFavorite(_ restaurant: Restaurant) async {
        restaurants.removeAll { $0.id == restaurant.id }
        do {
            let currentIds = try await favoritesRepository.fetchFavoriteIds(uid: uid)
            var updatedIds = currentIds
            updatedIds.remove(restaurant.id)
            try await favoritesRepository.setFavoriteIds(uid: uid, restaurantIds: updatedIds)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
