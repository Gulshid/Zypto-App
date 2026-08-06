//
//  CheckoutViewModel.swift
//  FoodDeliveryApp
//
//  New in Phase 5. Drives the Checkout screen: delivery address, a
//  mock card-payment form, and order placement. Per the roadmap, this
//  is a *simulated* payment (no real processor/SDK) — placeOrder()
//  just adds an artificial delay so the UI has something to show a
//  spinner for, then always "succeeds" if the form validates.
//
//  Order creation writes straight to the `orders` collection via
//  OrderRepository (added this phase) and clears the cart on success.
//  Real-time status tracking and an order-history list are Phase 6.
//
//  Location in project: Features/Checkout/ViewModels/CheckoutViewModel.swift
//

import Foundation

@MainActor
final class CheckoutViewModel: ObservableObject {

    @Published var deliveryAddress: String = ""
    @Published var cardholderName: String = ""
    @Published var cardNumber: String = ""
    @Published var expiry: String = ""
    @Published var cvv: String = ""

    @Published private(set) var isPlacingOrder = false
    @Published private(set) var placedOrder: Order?
    @Published var errorMessage: String?

    let cart: Cart
    let restaurantName: String
    private let uid: String
    private let orderRepository: OrderRepositoryProtocol
    private let cartRepository: CartRepositoryProtocol

    init(
        cart: Cart,
        restaurantName: String,
        uid: String,
        orderRepository: OrderRepositoryProtocol,
        cartRepository: CartRepositoryProtocol
    ) {
        self.cart = cart
        self.restaurantName = restaurantName
        self.uid = uid
        self.orderRepository = orderRepository
        self.cartRepository = cartRepository
    }

    var subtotal: Double { cart.subtotal }
    var deliveryFee: Double { Constants.Checkout.deliveryFee }
    var total: Double { subtotal + deliveryFee }

    var isFormValid: Bool {
        Validators.isNonEmpty(deliveryAddress)
            && Validators.isNonEmpty(cardholderName)
            && Validators.isValidCardNumber(cardNumber)
            && Validators.isValidExpiry(expiry)
            && Validators.isValidCVV(cvv)
    }

    /// Auto-inserts a space every 4 digits as the user types, mirroring
    /// how real card-entry UIs format the number. Called from the
    /// TextField's onChange in CheckoutView.
    func formatCardNumber(_ raw: String) {
        let digits = raw.filter(\.isNumber).prefix(19)
        var formatted = ""
        for (index, digit) in digits.enumerated() {
            if index != 0 && index % 4 == 0 { formatted += " " }
            formatted.append(digit)
        }
        cardNumber = formatted
    }

    /// Auto-inserts "/" after the month as the user types.
    func formatExpiry(_ raw: String) {
        let digits = raw.filter(\.isNumber).prefix(4)
        if digits.count <= 2 {
            expiry = String(digits)
        } else {
            let month = digits.prefix(2)
            let year = digits.suffix(digits.count - 2)
            expiry = "\(month)/\(year)"
        }
    }

    func placeOrder() async {
        guard isFormValid else {
            errorMessage = "Please fill in a delivery address and valid card details."
            return
        }
        guard !cart.isEmpty else {
            errorMessage = "Your cart is empty."
            return
        }

        isPlacingOrder = true
        errorMessage = nil
        defer { isPlacingOrder = false }

        do {
            // Simulated payment processing delay — there is no real
            // payment gateway behind this project (free-tier constraint,
            // see roadmap). A real integration would call out to a
            // processor's SDK/API here instead.
            try await Task.sleep(nanoseconds: 1_200_000_000)

            let order = Order.from(
                cart: cart,
                restaurantName: restaurantName,
                deliveryAddress: deliveryAddress.trimmingCharacters(in: .whitespacesAndNewlines),
                deliveryFee: deliveryFee,
                orderId: UUID().uuidString
            )
            try await orderRepository.createOrder(order)
            try await cartRepository.clearCart(uid: uid)
            placedOrder = order
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
