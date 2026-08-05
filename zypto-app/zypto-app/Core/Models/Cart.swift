//
//  Cart.swift
//  FoodDeliveryApp
//
//  New in Phase 3. Firestore document shape for the `carts` collection.
//
//  Design choice: one cart DOCUMENT per user, with cart lines embedded
//  as an array field, rather than a `carts/{uid}/items/{itemId}`
//  subcollection. A cart is small (a handful of line items), always
//  read/written as a whole on the Cart screen, and never queried by
//  its contents — so a single document means one read + one write per
//  cart interaction instead of N. Document ID == AppUser.id, so there
//  is at most one cart per user by construction.
//
//  Location in project: Core/Models/Cart.swift
//

import Foundation

/// A single line in the cart: one menu item, a quantity, chosen extras,
/// and an optional note (e.g. "no onions, extra napkins").
struct CartItem: Codable, Identifiable, Equatable {
    /// Locally-generated ID (UUID) — NOT the MenuItem's Firestore ID, since
    /// the same menu item can appear twice with different customizations
    /// (e.g. two orders of the same burger, one with extra cheese, one without).
    var id: String
    var menuItemId: String
    var restaurantId: String

    var name: String
    var unitPrice: Double
    var quantity: Int
    var selectedExtras: [String]
    var note: String?

    enum CodingKeys: String, CodingKey {
        case id, menuItemId, restaurantId, name, unitPrice, quantity, selectedExtras, note
    }

    var lineTotal: Double { unitPrice * Double(quantity) }
}

/// The cart document itself: `carts/{uid}`.
struct Cart: Codable, Equatable {
    /// Equal to the owning user's uid — set from the document ID, not stored
    /// redundantly as a field, to avoid the two ever drifting out of sync.
    var id: String

    /// A cart can only hold items from one restaurant at a time (standard
    /// food-delivery UX — adding from a different restaurant prompts the
    /// user in Phase 5 to clear the cart first). Nil when the cart is empty.
    var restaurantId: String?
    var items: [CartItem]
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, restaurantId, items, updatedAt
    }
}

extension Cart {
    static func empty(uid: String) -> Cart {
        Cart(id: uid, restaurantId: nil, items: [], updatedAt: Date())
    }

    var subtotal: Double { items.reduce(0) { $0 + $1.lineTotal } }
    var isEmpty: Bool { items.isEmpty }
}
