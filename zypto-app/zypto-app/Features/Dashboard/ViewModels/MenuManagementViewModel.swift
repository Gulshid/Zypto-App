//
//  MenuManagementViewModel.swift
//  FoodDeliveryApp
//
//  New in Phase 7. Backs the dashboard's Menu tab: loads every item for
//  the owner's restaurant (unlike RestaurantDetailViewModel's customer-
//  facing fetchAvailableMenuItems, this includes items toggled off), and
//  handles delete + availability-toggle actions from the list.
//  Add/edit itself is handled by MenuItemFormViewModel in a presented sheet.
//
//  Location in project: Features/Dashboard/ViewModels/MenuManagementViewModel.swift
//

import Foundation

@MainActor
final class MenuManagementViewModel: ObservableObject {

    @Published private(set) var menuItems: [MenuItem] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    let restaurantId: String
    private let menuRepository: MenuRepositoryProtocol

    init(restaurantId: String, menuRepository: MenuRepositoryProtocol) {
        self.restaurantId = restaurantId
        self.menuRepository = menuRepository
    }

    /// Same grouped-by-category shape as RestaurantDetailViewModel.menuSections,
    /// so the dashboard list reads in the same order customers see items in.
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
            menuItems = try await menuRepository.fetchAllMenuItems(restaurantId: restaurantId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleAvailability(_ item: MenuItem) async {
        guard let index = menuItems.firstIndex(where: { $0.id == item.id }) else { return }
        let newValue = !item.isAvailable
        menuItems[index].isAvailable = newValue // optimistic

        do {
            try await menuRepository.setAvailability(restaurantId: restaurantId, itemId: item.id, isAvailable: newValue)
        } catch {
            menuItems[index].isAvailable = !newValue // roll back
            errorMessage = error.localizedDescription
        }
    }

    func delete(_ item: MenuItem) async {
        let previous = menuItems
        menuItems.removeAll { $0.id == item.id } // optimistic

        do {
            try await menuRepository.deleteMenuItem(restaurantId: restaurantId, itemId: item.id)
        } catch {
            menuItems = previous // roll back
            errorMessage = error.localizedDescription
        }
    }

    /// Called after MenuItemFormView creates or updates an item, so the
    /// list reflects it immediately without a full re-fetch.
    func applyUpsertedItem(_ item: MenuItem) {
        if let index = menuItems.firstIndex(where: { $0.id == item.id }) {
            menuItems[index] = item
        } else {
            menuItems.append(item)
        }
    }
}
