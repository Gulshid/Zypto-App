//
//  CartView.swift
//  FoodDeliveryApp
//
//  New in Phase 5. Lists the current cart's line items with an order
//  summary, and hands off to CheckoutView for delivery address +
//  payment. Reached from the floating cart bar on Restaurant Detail,
//  or the cart button on the home feed.
//
//  Location in project: Features/Cart/Views/CartView.swift
//

import SwiftUI

struct CartView: View {
    @ObservedObject var cartViewModel: CartViewModel
    let appEnvironment: AppEnvironment

    var body: some View {
        Group {
            if cartViewModel.cart.isEmpty {
                emptyState
            } else {
                cartContent
            }
        }
        .navigationTitle("Your Cart")
        .navigationBarTitleDisplayMode(.inline)
        .task { await cartViewModel.loadCart() }
    }

    private var cartContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let restaurantName = cartViewModel.restaurantName {
                    Text(restaurantName)
                        .font(.headline)
                        .padding(.horizontal)
                        .padding(.top, 12)
                }

                VStack(spacing: 0) {
                    ForEach(cartViewModel.cart.items) { item in
                        CartItemRowView(
                            item: item,
                            onQuantityChange: { newQuantity in
                                Task { await cartViewModel.updateQuantity(itemId: item.id, quantity: newQuantity) }
                            },
                            onRemove: {
                                Task { await cartViewModel.removeItem(itemId: item.id) }
                            }
                        )
                        Divider()
                    }
                }
                .padding(.horizontal)

                summary
                    .padding(.horizontal)
                    .padding(.top, 8)

                if let errorMessage = cartViewModel.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.horizontal)
                }

                NavigationLink {
                    CheckoutView(
                        cart: cartViewModel.cart,
                        restaurantName: cartViewModel.restaurantName ?? "Restaurant",
                        uid: cartViewModel.uid,
                        appEnvironment: appEnvironment,
                        onOrderPlaced: {
                            Task { await cartViewModel.loadCart() }
                        }
                    )
                } label: {
                    Text("Proceed to Checkout")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)
                .padding(.top, 4)
                .padding(.bottom, 24)
            }
        }
    }

    private var summary: some View {
        VStack(spacing: 8) {
            summaryRow("Subtotal", cartViewModel.subtotal)
            summaryRow("Delivery Fee", cartViewModel.deliveryFee)
            Divider()
            summaryRow("Total", cartViewModel.total, bold: true)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func summaryRow(_ label: String, _ amount: Double, bold: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(bold ? .subheadline.bold() : .subheadline)
                .foregroundStyle(bold ? .primary : .secondary)
            Spacer()
            Text(amount, format: .currency(code: "USD"))
                .font(bold ? .subheadline.bold() : .subheadline)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "bag")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text("Your cart is empty")
                .foregroundStyle(.secondary)
            Text("Add items from a restaurant to get started.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 80)
    }
}
