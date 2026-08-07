//
//  RestaurantDetailViewModel.swift
//  FoodDeliveryApp
//
//  New in Phase 4. Loads a restaurant's menu and manages its favorite
//  state for the Restaurant Detail screen.
//
//  Location in project: Features/RestaurantDetail/ViewModels/RestaurantDetailViewModel.swift
//
//  UPDATED IN PHASE 9: added client-side search, category, and price
//  filtering over the loaded menu (mirrors the pattern HomeViewModel
//  already uses for restaurants — see that file's comment for why this
//  stays client-side rather than a Firestore query: a single
//  restaurant's menu is small enough that filtering the in-memory
//  array is simpler and just as fast as round-tripping to Firestore,
//  and Firestore has no native substring search anyway).
//
//  Also now tracks the restaurant's average rating / review count as
//  local @Published state (seeded from `restaurant`, the value from
//  Firestore) rather than reading `restaurant.averageRating` directly,
//  so the header can update in place the moment a new review is
//  submitted (see ReviewsViewModel.onAggregateChanged) without a
//  refetch of the restaurant document.
//

import Foundation

/// Coarse price bucket for the Phase 9 price filter. Kept as a small
/// fixed set of tiers (rather than a min/max range slider) since a
/// single restaurant's menu rarely spans more than a few price points —
/// tiers are faster to scan and tap than dragging a slider.
enum PriceFilter: CaseIterable, Identifiable {
    case all
    case under10
    case tenToTwentyFive
    case over25

    var id: Self { self }

    var label: String {
        switch self {
        case .all: return "All"
        case .under10: return "Under $10"
        case .tenToTwentyFive: return "$10–$25"
        case .over25: return "$25+"
        }
    }

    func matches(_ price: Double) -> Bool {
        switch self {
        case .all: return true
        case .under10: return price < 10
        case .tenToTwentyFive: return price >= 10 && price <= 25
        case .over25: return price > 25
        }
    }
}

@MainActor
final class RestaurantDetailViewModel: ObservableObject {

    @Published var menuItems: [MenuItem] = []
    @Published private(set) var isFavorite: Bool
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Phase 9: menu search / category / price filters
    @Published var searchText: String = ""
    @Published var selectedCategory: String?
    @Published var selectedPriceFilter: PriceFilter = .all

    // MARK: - Phase 9: live rating display (seeded from `restaurant`,
    // updated in place after a review is submitted)
    @Published private(set) var averageRating: Double
    @Published private(set) var reviewCount: Int

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
        self.averageRating = restaurant.averageRating
        self.reviewCount = restaurant.reviewCount
    }

    /// Menu items grouped by category, in a stable order (first-seen
    /// category order) so sections don't jump around between loads.
    /// Now built from `filteredMenuItems` rather than the raw
    /// `menuItems`, so search/category/price filters apply here too.
    var menuSections: [(category: String, items: [MenuItem])] {
        var order: [String] = []
        var grouped: [String: [MenuItem]] = [:]
        for item in filteredMenuItems {
            if grouped[item.category] == nil {
                order.append(item.category)
            }
            grouped[item.category, default: []].append(item)
        }
        return order.map { ($0, grouped[$0] ?? []) }
    }

    /// Every category present on this restaurant's menu, for the
    /// filter chip row. Recomputed from `menuItems` so it never drifts
    /// out of sync with what's actually on the menu.
    var availableCategories: [String] {
        Array(Set(menuItems.map(\.category))).sorted()
    }

    /// `menuItems` narrowed by search text, selected category, and
    /// selected price tier — applied together so all three filters can
    /// be combined (e.g. "under $10" within "Mains" matching "chicken").
    var filteredMenuItems: [MenuItem] {
        menuItems.filter { item in
            matchesSearch(item) && matchesCategory(item) && selectedPriceFilter.matches(item.price)
        }
    }

    var isFiltering: Bool {
        !searchText.trimmingCharacters(in: .whitespaces).isEmpty
            || selectedCategory != nil
            || selectedPriceFilter != .all
    }

    private func matchesSearch(_ item: MenuItem) -> Bool {
        let needle = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        guard !needle.isEmpty else { return true }
        return item.name.lowercased().contains(needle)
            || item.description.lowercased().contains(needle)
            || item.category.lowercased().contains(needle)
    }

    private func matchesCategory(_ item: MenuItem) -> Bool {
        guard let selectedCategory else { return true }
        return item.category == selectedCategory
    }

    func selectCategory(_ category: String?) {
        selectedCategory = (selectedCategory == category) ? nil : category
    }

    func clearFilters() {
        searchText = ""
        selectedCategory = nil
        selectedPriceFilter = .all
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

    /// Wired to ReviewsViewModel.onAggregateChanged so the header's
    /// star rating updates the instant a review is submitted, without
    /// waiting on a refetch of the restaurant document.
    func applyAggregateChange(averageRating: Double, reviewCount: Int) {
        self.averageRating = averageRating
        self.reviewCount = reviewCount
    }
}
