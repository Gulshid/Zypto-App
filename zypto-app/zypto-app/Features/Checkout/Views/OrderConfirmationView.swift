//
//  OrderConfirmationView.swift
//  FoodDeliveryApp
//
//  New in Phase 5. Shown in place of the checkout form once
//  CheckoutViewModel.placeOrder() succeeds.
//
//  Location in project: Features/Checkout/Views/OrderConfirmationView.swift
//
//  UPDATED IN PHASE 6: added a "Track Order" link into the new live
//  OrderTrackingView, now that order status updates are backed by a
//  real Firestore listener instead of just a static confirmation.
//

import SwiftUI

struct OrderConfirmationView: View {
    let order: Order
    let orderRepository: OrderRepositoryProtocol
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(.green)

            Text("Order Placed!")
                .font(.title2.bold())

            Text("Your order from \(order.restaurantName) has been confirmed.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            VStack(spacing: 8) {
                row("Order ID", String(order.id.prefix(8)).uppercased())
                row("Delivering to", order.deliveryAddress)
                row("Total", order.total.formatted(.currency(code: "USD")))
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 32)

            Spacer()

            VStack(spacing: 12) {
                NavigationLink {
                    OrderTrackingView(order: order, orderRepository: orderRepository)
                } label: {
                    Text("Track Order")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button(action: onDone) {
                    Text("Back to Restaurants")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding()
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 24)
        }
        .interactiveDismissDisabled()
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(.caption).foregroundStyle(.secondary)
            Spacer()
            Text(value).font(.caption.bold())
        }
    }
}

#Preview {
    NavigationStack {
        OrderConfirmationView(
            order: Order.from(
                cart: Cart(
                    id: "u1", restaurantId: "r1",
                    items: [CartItem(id: "1", menuItemId: "m1", restaurantId: "r1", name: "Pizza", unitPrice: 14.99, quantity: 1, selectedExtras: [], note: nil)],
                    updatedAt: Date()
                ),
                restaurantName: "Tony's Pizzeria",
                deliveryAddress: "123 Main St, Apt 4B",
                deliveryFee: 2.99,
                orderId: UUID().uuidString
            ),
            orderRepository: OrderRepository(firestoreService: FirestoreServiceLive()),
            onDone: {}
        )
    }
}
