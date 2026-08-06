//
//  OrderRowView.swift
//  FoodDeliveryApp
//
//  New in Phase 6. A single row on the Order History screen —
//  restaurant, date, item count, total, and a status badge.
//
//  Location in project: Features/Orders/Views/OrderRowView.swift
//

import SwiftUI

struct OrderRowView: View {
    let order: Order

    private var itemCount: Int { order.items.reduce(0) { $0 + $1.quantity } }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(order.restaurantName)
                    .font(.subheadline.bold())
                Spacer()
                OrderStatusBadge(status: order.status)
            }

            Text("\(itemCount) item\(itemCount == 1 ? "" : "s") · \(order.total, format: .currency(code: "USD"))")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(order.createdAt, format: .dateTime.month().day().hour().minute())
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)
    }
}

#Preview {
    OrderRowView(order: Order.from(
        cart: Cart(
            id: "u1", restaurantId: "r1",
            items: [CartItem(id: "1", menuItemId: "m1", restaurantId: "r1", name: "Pizza", unitPrice: 14.99, quantity: 2, selectedExtras: [], note: nil)],
            updatedAt: Date()
        ),
        restaurantName: "Tony's Pizzeria",
        deliveryAddress: "123 Main St",
        deliveryFee: 2.99,
        orderId: UUID().uuidString
    ))
    .padding()
}
