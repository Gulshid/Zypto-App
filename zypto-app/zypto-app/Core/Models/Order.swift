//
//  Order.swift
//  FoodDeliveryApp
//
//  New in Phase 3. Firestore document shape for the top-level `orders`
//  collection. Created once at checkout (Phase 5/6) from a snapshot of
//  the cart at that moment — orders never reference the cart or live
//  menu items afterward, so editing a menu item's price later can't
//  retroactively change a past order's total.
//
//  Location in project: Core/Models/Order.swift
//

import Foundation

/// A frozen snapshot of a cart line, copied into the order at checkout time.
struct OrderItem: Codable, Identifiable, Equatable {
    var id: String
    var menuItemId: String
    var name: String
    var unitPrice: Double
    var quantity: Int
    var selectedExtras: [String]
    var note: String?

    enum CodingKeys: String, CodingKey {
        case id, menuItemId, name, unitPrice, quantity, selectedExtras, note
    }

    var lineTotal: Double { unitPrice * Double(quantity) }
}

struct Order: Codable, Identifiable, Equatable {
    /// Firestore document ID
    var id: String

    var customerId: String
    var restaurantId: String
    /// Denormalized so order lists/history (Phase 6) don't need a join read
    /// back to the restaurants collection just to show a name.
    var restaurantName: String

    var items: [OrderItem]
    var subtotal: Double
    var deliveryFee: Double
    var total: Double

    var deliveryAddress: String
    /// One of Constants.OrderStatus. Kept as a plain string (not a Swift enum)
    /// so Firestore snapshot listeners in Phase 6/8 can update it with a cheap
    /// updateFields(["status": ...]) call without re-encoding the whole order.
    var status: String

    var createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, customerId, restaurantId, restaurantName, items
        case subtotal, deliveryFee, total, deliveryAddress, status
        case createdAt, updatedAt
    }
}

extension Order {
    static func from(cart: Cart, restaurantName: String, deliveryAddress: String, deliveryFee: Double, orderId: String) -> Order {
        let orderItems = cart.items.map {
            OrderItem(
                id: $0.id,
                menuItemId: $0.menuItemId,
                name: $0.name,
                unitPrice: $0.unitPrice,
                quantity: $0.quantity,
                selectedExtras: $0.selectedExtras,
                note: $0.note
            )
        }
        let subtotal = cart.subtotal
        return Order(
            id: orderId,
            customerId: cart.id,
            restaurantId: cart.restaurantId ?? "",
            restaurantName: restaurantName,
            items: orderItems,
            subtotal: subtotal,
            deliveryFee: deliveryFee,
            total: subtotal + deliveryFee,
            deliveryAddress: deliveryAddress,
            status: Constants.OrderStatus.pending,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}
