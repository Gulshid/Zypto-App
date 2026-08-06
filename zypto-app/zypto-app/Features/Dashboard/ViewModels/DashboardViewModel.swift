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

import Foundation

@MainActor
final class DashboardViewModel: ObservableObject {

    @Published private(set) var restaurant: Restaurant?
    @Published private(set) var isLoading = true
    @Published var errorMessage: String?

    let ownerId: String
    private let restaurantRepository: RestaurantRepositoryProtocol

    init(ownerId: String, restaurantRepository: RestaurantRepositoryProtocol) {
        self.ownerId = ownerId
        self.restaurantRepository = restaurantRepository
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
}
