//
//  NotificationService.swift
//  FoodDeliveryApp
//
//  New in Phase 8. Thin wrapper around UNUserNotificationCenter used to
//  *simulate* push notifications, per the free-tier constraint at the
//  top of the roadmap: real FCM push needs a server to send it, which
//  is out of scope on the Spark plan. Instead, whichever screen is
//  already holding a live Firestore listener (OrderHistoryViewModel for
//  customers, DashboardViewModel for restaurant owners — see Phase 6/7)
//  schedules a local notification the moment it observes a relevant
//  change, so it *feels* like push without needing a backend.
//
//  Location in project: Core/Services/NotificationService.swift
//

import Foundation
import UserNotifications

protocol NotificationServiceProtocol {
    /// Prompts the system permission dialog the first time this is
    /// called; a no-op (returns immediately) on every call after the
    /// person has already answered. Safe to call on every launch.
    func requestAuthorization() async

    /// Fired when a customer's order status advances (e.g. Preparing ->
    /// Out for Delivery). One notification per (orderId, status) pair —
    /// the identifier is derived from both, so re-delivering the same
    /// status (e.g. a listener reconnecting) can't double-notify.
    func scheduleOrderStatusNotification(orderId: String, restaurantName: String, status: String)

    /// Fired on the restaurant owner's device the moment a new order
    /// lands in their `orders` collection.
    func scheduleNewOrderNotification(orderId: String, itemsSummary: String)

    /// Mirrors the in-app badge counts (see DashboardViewModel /
    /// OrderHistoryViewModel's `activeOrderCount`) onto the app icon.
    func setBadgeCount(_ count: Int) async

    /// Called once on sign-in so a fresh session doesn't inherit a
    /// stale badge number left over from the last session.
    func clearBadge() async
}

final class NotificationServiceLive: NSObject, NotificationServiceProtocol, UNUserNotificationCenterDelegate {

    private let center = UNUserNotificationCenter.current()

    override init() {
        super.init()
        // Needed so userNotificationCenter(_:willPresent:...) below gets
        // called at all — without a delegate, UNUserNotificationCenter
        // silently swallows notifications that fire while the app is in
        // the foreground (the common case here, since these are all
        // triggered by a live Firestore listener while some screen is
        // open) instead of showing a banner.
        center.delegate = self
    }

    func requestAuthorization() async {
        do {
            _ = try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            // Notifications are a nice-to-have simulation of push here,
            // not a feature the rest of the app depends on working —
            // the in-app toast (see ToastCenter) covers the same
            // real-time UX even if the person declines the permission
            // prompt, so this is intentionally non-fatal.
            print("NotificationService: authorization request failed — \(error.localizedDescription)")
        }
    }

    func scheduleOrderStatusNotification(orderId: String, restaurantName: String, status: String) {
        let content = UNMutableNotificationContent()
        content.title = restaurantName
        content.body = "Your order is now \(OrderStatusDisplay.label(for: status))."
        content.sound = .default
        content.userInfo = ["orderId": orderId, "type": "orderStatus"]
        schedule(identifier: "order-status-\(orderId)-\(status)", content: content)
    }

    func scheduleNewOrderNotification(orderId: String, itemsSummary: String) {
        let content = UNMutableNotificationContent()
        content.title = "New Order Received"
        content.body = itemsSummary
        content.sound = .default
        content.userInfo = ["orderId": orderId, "type": "newOrder"]
        schedule(identifier: "new-order-\(orderId)", content: content)
    }

    func setBadgeCount(_ count: Int) async {
        try? await center.setBadgeCount(max(0, count))
    }

    func clearBadge() async {
        try? await center.setBadgeCount(0)
    }

    private func schedule(identifier: String, content: UNMutableNotificationContent) {
        // A short delay rather than firing instantly — mirrors how a
        // real push would arrive slightly after the server-side event,
        // and avoids racing the in-app toast for the same change.
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        center.add(request) { error in
            if let error {
                print("NotificationService: failed to schedule \(identifier) — \(error.localizedDescription)")
            }
        }
    }

    /// Without this, iOS suppresses alert/sound entirely for
    /// notifications that fire while the app is frontmost — which is
    /// nearly always true here, since these are all driven by a
    /// currently-open screen's Firestore listener.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }
}
