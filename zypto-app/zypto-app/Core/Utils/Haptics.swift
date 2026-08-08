//
//  Haptics.swift
//  FoodDeliveryApp
//
//  New in Phase 10. One-line wrappers around UIKit's feedback
//  generators so views don't each spin up their own
//  UIImpactFeedbackGenerator instance. Used sparingly, for the same
//  moments that already show a visual confirmation (favoriting a
//  restaurant, adding to cart, an order advancing to its next status)
//  — small physical polish, not decoration for its own sake.
//
//  Location in project: Core/Utils/Haptics.swift
//

import UIKit

enum Haptics {
    /// Light tap — toggles, selections (favorite heart, filter chips).
    static func tap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    /// A positive outcome completed (item added to cart, order placed).
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    /// An order/status genuinely changed in a way worth a slightly
    /// stronger confirmation than `tap()` (order status advanced).
    static func impact() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    /// Something failed (a request errored out).
    static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
}
