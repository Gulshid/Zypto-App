//
//  CartViewModel.swift
//  FoodDeliveryApp
//
//  New in Phase 5. Owns the signed-in customer's cart for the lifetime
//  of their session. Created once in HomeView (like HomeViewModel) and
//  shared down the navigation stack via .environmentObject so the
//  Restaurant Detail screen (adding items) and the Cart screen
//  (editing/checking out) always see the same state.
//
//  Location in project: Features/Cart/ViewModels/CartViewModel.swift
//

import Foundation

/// An add-to-cart request that would clear items from a different
/// restaurant. Held here until the user confirms via an alert, since a
/// cart can only contain items from one restaurant at a time.
struct PendingCartReplacement {
    let menuItem: MenuItem
    let restaurantName: String
    let quantity: Int
    let selectedExtras: [String]
    let note: String?
}

@MainActor
final class CartViewModel: ObservableObject {

    @Published private(set) var cart: Cart
    /// Denormalized display name for the restaurant the cart currently
    /// belongs to. Not stored on Cart itself (see Core/Models/Cart.swift —
    /// it only keeps restaurantId), so it's fetched alongside the cart
    /// and cached here for the lifetime of the session.
    @Published private(set) var restaurantName: String?
    @Published var pendingReplacement: PendingCartReplacement?
    @Published var isLoading = false
    @Published var errorMessage: String?

    let uid: String
    private let cartRepository: CartRepositoryProtocol
    private let restaurantRepository: RestaurantRepositoryProtocol

    init(
        uid: String,
        cartRepository: CartRepositoryProtocol,
        restaurantRepository: RestaurantRepositoryProtocol
    ) {
        self.uid = uid
        self.cartRepository = cartRepository
        self.restaurantRepository = restaurantRepository
        self.cart = .empty(uid: uid)
    }

    var itemCount: Int { cart.items.reduce(0) { $0 + $1.quantity } }
    var subtotal: Double { cart.subtotal }
    var deliveryFee: Double { cart.isEmpty ? 0 : Constants.Checkout.deliveryFee }
    var total: Double { subtotal + deliveryFee }

    // MARK: - Loading

    /// Called once when the home feed appears, and again after checkout
    /// clears the cart server-side, to pick up the latest state.
    func loadCart() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            cart = try await cartRepository.fetchCart(uid: uid)
            await refreshRestaurantNameIfNeeded()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func refreshRestaurantNameIfNeeded() async {
        guard let restaurantId = cart.restaurantId, !cart.isEmpty else {
            restaurantName = nil
            return
        }
        // Skip the read if we already have it (e.g. just set it locally
        // in addToCart) — avoids an extra Firestore read on every load.
        guard restaurantName == nil else { return }
        restaurantName = try? await restaurantRepository.fetchRestaurant(id: restaurantId)?.name
    }

    // MARK: - Mutations

    /// Adds `quantity` of `menuItem` to the cart. If the cart already
    /// holds items from a *different* restaurant, this stops short of
    /// mutating anything and instead populates `pendingReplacement` so
    /// the view can confirm with the user first.
    func addToCart(
        menuItem: MenuItem,
        restaurantName: String,
        quantity: Int,
        selectedExtras: [String],
        note: String?
    ) async {
        if let currentRestaurantId = cart.restaurantId, currentRestaurantId != menuItem.restaurantId, !cart.isEmpty {
            pendingReplacement = PendingCartReplacement(
                menuItem: menuItem,
                restaurantName: restaurantName,
                quantity: quantity,
                selectedExtras: selectedExtras,
                note: note
            )
            return
        }

        await performAdd(
            menuItem: menuItem,
            restaurantName: restaurantName,
            quantity: quantity,
            selectedExtras: selectedExtras,
            note: note
        )
    }

    /// User confirmed "start a new cart" from the replacement alert.
    func confirmReplacement() async {
        guard let pending = pendingReplacement else { return }
        pendingReplacement = nil
        cart = .empty(uid: uid)
        await performAdd(
            menuItem: pending.menuItem,
            restaurantName: pending.restaurantName,
            quantity: pending.quantity,
            selectedExtras: pending.selectedExtras,
            note: pending.note
        )
    }

    func cancelReplacement() {
        pendingReplacement = nil
    }

    private func performAdd(
        menuItem: MenuItem,
        restaurantName: String,
        quantity: Int,
        selectedExtras: [String],
        note: String?
    ) async {
        let newItem = CartItem(
            id: UUID().uuidString,
            menuItemId: menuItem.id,
            restaurantId: menuItem.restaurantId,
            name: menuItem.name,
            unitPrice: menuItem.price,
            quantity: quantity,
            selectedExtras: selectedExtras,
            note: (note?.trimmingCharacters(in: .whitespacesAndNewlines)).flatMap { $0.isEmpty ? nil : $0 }
        )

        var updated = cart
        updated.restaurantId = menuItem.restaurantId
        updated.items.append(newItem)

        await save(updated)
        self.restaurantName = restaurantName
    }

    func updateQuantity(itemId: String, quantity: Int) async {
        guard quantity >= 1 else {
            await removeItem(itemId: itemId)
            return
        }
        var updated = cart
        guard let index = updated.items.firstIndex(where: { $0.id == itemId }) else { return }
        updated.items[index].quantity = quantity
        await save(updated)
    }

    func removeItem(itemId: String) async {
        var updated = cart
        updated.items.removeAll { $0.id == itemId }
        if updated.items.isEmpty {
            updated.restaurantId = nil
            restaurantName = nil
        }
        await save(updated)
    }

    /// Called after a successful checkout, and available for the user to
    /// trigger manually (e.g. a "Clear Cart" button).
    func clearCart() async {
        do {
            try await cartRepository.clearCart(uid: uid)
            cart = .empty(uid: uid)
            restaurantName = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func save(_ updated: Cart) async {
        let previous = cart
        cart = updated // optimistic
        do {
            try await cartRepository.saveCart(updated)
        } catch {
            cart = previous // roll back
            errorMessage = error.localizedDescription
        }
    }
}
