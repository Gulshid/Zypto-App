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
    /// New in Phase 10. Denormalized restaurant-owner UID, populated by
    /// OrderRepository.createOrder(_:) (not by Order.from(...) itself —
    /// callers don't know the owner's UID at checkout time). Lets
    /// firestore.rules check restaurant-owner permissions on the order
    /// doc directly instead of a nested get() to the restaurants
    /// collection, which was failing during real-time listener
    /// re-evaluation and causing orders to disappear from the dashboard.
    var restaurantOwnerId: String

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
        case id, customerId, restaurantId, restaurantName, restaurantOwnerId, items
        case subtotal, deliveryFee, total, deliveryAddress, status
        case createdAt, updatedAt
    }

    init(
        id: String, customerId: String, restaurantId: String, restaurantName: String,
        restaurantOwnerId: String, items: [OrderItem], subtotal: Double, deliveryFee: Double,
        total: Double, deliveryAddress: String, status: String, createdAt: Date, updatedAt: Date
    ) {
        self.id = id
        self.customerId = customerId
        self.restaurantId = restaurantId
        self.restaurantName = restaurantName
        self.restaurantOwnerId = restaurantOwnerId
        self.items = items
        self.subtotal = subtotal
        self.deliveryFee = deliveryFee
        self.total = total
        self.deliveryAddress = deliveryAddress
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// Custom decoder so orders written before restaurantOwnerId existed
    /// (pre-Phase-10) still decode instead of silently disappearing from
    /// history — decodeIfPresent defaults a missing field to "" rather
    /// than throwing.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        customerId = try c.decode(String.self, forKey: .customerId)
        restaurantId = try c.decode(String.self, forKey: .restaurantId)
        restaurantName = try c.decode(String.self, forKey: .restaurantName)
        restaurantOwnerId = try c.decodeIfPresent(String.self, forKey: .restaurantOwnerId) ?? ""
        items = try c.decode([OrderItem].self, forKey: .items)
        subtotal = try c.decode(Double.self, forKey: .subtotal)
        deliveryFee = try c.decode(Double.self, forKey: .deliveryFee)
        total = try c.decode(Double.self, forKey: .total)
        deliveryAddress = try c.decode(String.self, forKey: .deliveryAddress)
        status = try c.decode(String.self, forKey: .status)
        createdAt = try c.decode(Date.self, forKey: .createdAt)
        updatedAt = try c.decode(Date.self, forKey: .updatedAt)
    }
}

extension Order {
    /// restaurantOwnerId is left blank here — CheckoutViewModel only
    /// has the restaurant's name/id at checkout time, not its owner's
    /// UID. OrderRepository.createOrder(_:) looks it up and fills it in
    /// right before writing to Firestore. See restaurantOwnerId's doc
    /// comment above.
    static func from(cart: Cart, restaurantName: String, deliveryAddress: String, deliveryFee: Double, orderId: String, restaurantOwnerId: String = "") -> Order {
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
            restaurantOwnerId: restaurantOwnerId,
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
