//
//  CheckoutView.swift
//  FoodDeliveryApp
//
//  New in Phase 5. Delivery address, order summary, and a mock card
//  form. "Place Order" simulates a payment, writes the order to
//  Firestore, and clears the cart — see CheckoutViewModel for the
//  free-tier rationale (no real payment processor).
//
//  Location in project: Features/Checkout/Views/CheckoutView.swift
//

import SwiftUI

struct CheckoutView: View {
    @StateObject private var viewModel: CheckoutViewModel
    @Environment(\.dismiss) private var dismiss
    private let orderRepository: OrderRepositoryProtocol
    /// Lets the presenting CartView refresh once the order is placed and
    /// the cart is cleared server-side.
    private let onOrderPlaced: () -> Void

    init(
        cart: Cart,
        restaurantName: String,
        uid: String,
        appEnvironment: AppEnvironment,
        onOrderPlaced: @escaping () -> Void
    ) {
        self.onOrderPlaced = onOrderPlaced
        self.orderRepository = appEnvironment.orderRepository
        _viewModel = StateObject(wrappedValue: CheckoutViewModel(
            cart: cart,
            restaurantName: restaurantName,
            uid: uid,
            orderRepository: appEnvironment.orderRepository,
            cartRepository: appEnvironment.cartRepository
        ))
    }

    var body: some View {
        Group {
            if let order = viewModel.placedOrder {
                OrderConfirmationView(order: order, orderRepository: orderRepository) {
                    onOrderPlaced()
                    dismiss()
                }
            } else {
                form
            }
        }
        .navigationTitle("Checkout")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(viewModel.isPlacingOrder || viewModel.placedOrder != nil)
    }

    private var form: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                addressSection
                summarySection
                paymentSection

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                placeOrderButton
            }
            .padding()
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var addressSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Delivery Address").font(.headline)
            TextField("Street address, apt/unit, city", text: $viewModel.deliveryAddress, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(2...4)
        }
    }

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Order Summary").font(.headline)

            VStack(spacing: 6) {
                ForEach(viewModel.cart.items) { item in
                    HStack {
                        Text("\(item.quantity)× \(item.name)")
                            .font(.subheadline)
                        Spacer()
                        Text(item.lineTotal, format: .currency(code: "USD"))
                            .font(.subheadline)
                    }
                }
                Divider()
                summaryRow("Subtotal", viewModel.subtotal)
                summaryRow("Delivery Fee", viewModel.deliveryFee)
                summaryRow("Total", viewModel.total, bold: true)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
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

    private var paymentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Payment").font(.headline)
                Spacer()
                Label("Simulated", systemImage: "lock.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            TextField("Name on Card", text: $viewModel.cardholderName)
                .textFieldStyle(.roundedBorder)
                .textContentType(.name)

            TextField("Card Number", text: $viewModel.cardNumber)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.numberPad)
                .onChange(of: viewModel.cardNumber) { _, newValue in
                    viewModel.formatCardNumber(newValue)
                }

            HStack(spacing: 12) {
                TextField("MM/YY", text: $viewModel.expiry)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
                    .onChange(of: viewModel.expiry) { _, newValue in
                        viewModel.formatExpiry(newValue)
                    }

                TextField("CVV", text: $viewModel.cvv)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
            }

            Text("No real payment is processed — this project runs entirely on free-tier services.")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private var placeOrderButton: some View {
        Button {
            Task { await viewModel.placeOrder() }
        } label: {
            Group {
                if viewModel.isPlacingOrder {
                    ProgressView().tint(.white)
                } else {
                    Text("Place Order — \(viewModel.total, format: .currency(code: "USD"))")
                        .font(.headline)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(viewModel.isFormValid ? Color.orange : Color.gray)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(!viewModel.isFormValid || viewModel.isPlacingOrder)
    }
}
