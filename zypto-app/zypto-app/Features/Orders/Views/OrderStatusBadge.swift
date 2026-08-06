//
//  OrderStatusBadge.swift
//  FoodDeliveryApp
//
//  New in Phase 6. Maps an Order.status raw string (Constants.OrderStatus)
//  to display text and a color, and wraps that in a small pill badge
//  shared by OrderRowView and OrderTrackingView.
//
//  Location in project: Features/Orders/Views/OrderStatusBadge.swift
//

import SwiftUI

enum OrderStatusDisplay {
    static func label(for status: String) -> String {
        switch status {
        case Constants.OrderStatus.pending: return "Order Placed"
        case Constants.OrderStatus.confirmed: return "Confirmed"
        case Constants.OrderStatus.preparing: return "Preparing"
        case Constants.OrderStatus.outForDelivery: return "Out for Delivery"
        case Constants.OrderStatus.delivered: return "Delivered"
        case Constants.OrderStatus.cancelled: return "Cancelled"
        default: return status.capitalized
        }
    }

    static func color(for status: String) -> Color {
        switch status {
        case Constants.OrderStatus.delivered: return .green
        case Constants.OrderStatus.cancelled: return .red
        case Constants.OrderStatus.pending: return .gray
        default: return .orange
        }
    }
}

struct OrderStatusBadge: View {
    let status: String

    var body: some View {
        Text(OrderStatusDisplay.label(for: status))
            .font(.caption.bold())
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(OrderStatusDisplay.color(for: status).opacity(0.15))
            .foregroundStyle(OrderStatusDisplay.color(for: status))
            .clipShape(Capsule())
    }
}

#Preview {
    VStack(spacing: 12) {
        OrderStatusBadge(status: Constants.OrderStatus.pending)
        OrderStatusBadge(status: Constants.OrderStatus.preparing)
        OrderStatusBadge(status: Constants.OrderStatus.outForDelivery)
        OrderStatusBadge(status: Constants.OrderStatus.delivered)
        OrderStatusBadge(status: Constants.OrderStatus.cancelled)
    }
}
