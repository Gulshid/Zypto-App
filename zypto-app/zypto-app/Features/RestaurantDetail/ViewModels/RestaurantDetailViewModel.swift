//
//  RestaurantDetailViewModel.swift
//  FoodDeliveryApp
//
//  New in Phase 4. Loads a restaurant's menu and manages its favorite
//  state for the Restaurant Detail screen.
//
//  Location in project: Features/RestaurantDetail/ViewModels/RestaurantDetailViewModel.swift
//

import Foundation

@MainActor
final class RestaurantDetailViewModel: ObservableObject {

    @Published var menuItems: [MenuItem] = []
    @Published private(set) var isFavorite: Bool
    @Published var isLoading = false
    @Published var errorMessage: String?

    let restaurant: Restaurant

    private let uid: String
    private let menuRepository: MenuRepositoryProtocol
    private let favoritesRepository: FavoritesRepositoryProtocol

    /// Notifies whoever pushed this screen (the home feed) that the
    /// favorite state changed, so its heart icon can update without a
    /// redundant Firestore read. See HomeViewModel.applyExternalFavoriteChange.
    var onFavoriteChanged: ((String, Bool) -> Void)?

    init(
        restaurant: Restaurant,
        uid: String,
        isFavorite: Bool,
        menuRepository: MenuRepositoryProtocol,
        favoritesRepository: FavoritesRepositoryProtocol
    ) {
        self.restaurant = restaurant
        self.uid = uid
        self.isFavorite = isFavorite
        self.menuRepository = menuRepository
        self.favoritesRepository = favoritesRepository
    }

    /// Menu items grouped by category, in a stable order (first-seen
    /// category order) so sections don't jump around between loads.
    var menuSections: [(category: String, items: [MenuItem])] {
        var order: [String] = []
        var grouped: [String: [MenuItem]] = [:]
        for item in menuItems {
            if grouped[item.category] == nil {
                order.append(item.category)
            }
            grouped[item.category, default: []].append(item)
        }
        return order.map { ($0, grouped[$0] ?? []) }
    }

    func loadMenu() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            menuItems = try await menuRepository.fetchAvailableMenuItems(restaurantId: restaurant.id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleFavorite() async {
        let newValue = !isFavorite
        isFavorite = newValue // optimistic

        do {
            var current = try await favoritesRepository.fetchFavoriteIds(uid: uid)
            if newValue {
                current.insert(restaurant.id)
            } else {
                current.remove(restaurant.id)
            }
            try await favoritesRepository.setFavoriteIds(uid: uid, restaurantIds: current)
            onFavoriteChanged?(restaurant.id, newValue)
        } catch {
            isFavorite = !newValue // roll back
            errorMessage = error.localizedDescription
        }
    }
}
