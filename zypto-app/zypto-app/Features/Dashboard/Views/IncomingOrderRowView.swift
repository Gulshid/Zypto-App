//
//  IncomingOrderRowView.swift
//  FoodDeliveryApp
//
//  New in Phase 7. A single row on the dashboard's Orders tab —
//  order items, delivery address, status badge, and the action button
//  that advances (or a menu that cancels) the order.
//
//  Location in project: Features/Dashboard/Views/IncomingOrderRowView.swift
//

import SwiftUI

struct IncomingOrderRowView: View {
    let order: Order
    /// Display label for the status one step ahead of the order's
    /// current one, or nil if it's already in a terminal state
    /// (delivered/cancelled) — drives whether the advance button shows.
    let nextStatusLabel: String?
    let onAdvance: () -> Void
    let onCancel: () -> Void

    private var itemCount: Int { order.items.reduce(0) { $0 + $1.quantity } }
    private var isTerminal: Bool {
        order.status == Constants.OrderStatus.delivered || order.status == Constants.OrderStatus.cancelled
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Order #\(order.id.prefix(8).uppercased())")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                OrderStatusBadge(status: order.status)
            }

            VStack(alignment: .leading, spacing: 2) {
                ForEach(order.items) { item in
                    Text("\(item.quantity)× \(item.name)")
                        .font(.subheadline)
                }
            }

            Label(order.deliveryAddress, systemImage: "mappin.and.ellipse")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            HStack {
                Text(order.total, format: .currency(code: "USD"))
                    .font(.subheadline.bold())

                Spacer()

                if !isTerminal {
                    Button(role: .destructive) {
                        onCancel()
                    } label: {
                        Text("Cancel")
                            .font(.caption.bold())
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                }

                if let nextStatusLabel {
                    Button {
                        onAdvance()
                    } label: {
                        Text("Mark \(nextStatusLabel)")
                            .font(.caption.bold())
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                }
            }
        }
        .padding(.vertical, 6)
    }
}

#Preview {
    IncomingOrderRowView(
        order: Order.from(
            cart: Cart(
                id: "u1", restaurantId: "r1",
                items: [CartItem(id: "1", menuItemId: "m1", restaurantId: "r1", name: "Pizza", unitPrice: 14.99, quantity: 2, selectedExtras: [], note: nil)],
                updatedAt: Date()
            ),
            restaurantName: "Tony's Pizzeria",
            deliveryAddress: "123 Main St, Apt 4B",
            deliveryFee: 2.99,
            orderId: UUID().uuidString
        ),
        nextStatusLabel: "Preparing",
        onAdvance: {},
        onCancel: {}
    )
    .padding()
}
