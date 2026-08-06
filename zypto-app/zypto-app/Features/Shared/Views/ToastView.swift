//
//  ToastView.swift
//  FoodDeliveryApp
//
//  New in Phase 8. In-app toast/snackbar alerts — the visible,
//  in-the-moment counterpart to NotificationService's local
//  notifications (Core/Services/NotificationService.swift). A local
//  notification is easy to miss while actively using the app (no
//  banner shows over whatever you're already looking at on some
//  configurations), so real-time events also surface here.
//
//  ToastCenter lives on AppEnvironment (see App/AppEnvironment.swift)
//  and is presented once, at the root of the view tree (see
//  RootView.toastOverlay(_:) in App/FoodDeliveryApp.swift) — any
//  ViewModel can call `appEnvironment.toastCenter.show(...)` from
//  anywhere without needing to be embedded in a particular screen.
//
//  Location in project: Features/Shared/Views/ToastView.swift
//

import SwiftUI

struct ToastMessage: Identifiable, Equatable {
    enum Style {
        case info
        case success
        case error
    }

    let id = UUID()
    let title: String
    let subtitle: String?
    let style: Style
}

/// Plain ObservableObject (not an actor) so it can be constructed
/// directly inside AppEnvironment.init() — every mutation below happens
/// on whichever thread called `show`/`dismiss`, which in practice is
/// always the MainActor-isolated ViewModels that own the Firestore
/// listeners (OrderHistoryViewModel, DashboardViewModel), so the
/// @Published updates land on the main thread SwiftUI expects without
/// needing extra actor plumbing here.
final class ToastCenter: ObservableObject {

    @Published private(set) var current: ToastMessage?

    private var dismissWorkItem: DispatchWorkItem?

    func show(_ message: ToastMessage, duration: TimeInterval = 3.5) {
        dismissWorkItem?.cancel()
        current = message

        let workItem = DispatchWorkItem { [weak self] in self?.current = nil }
        dismissWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: workItem)
    }

    func dismiss() {
        dismissWorkItem?.cancel()
        current = nil
    }

    // MARK: - Convenience factories for the two Phase 8 events

    /// A customer's order advanced to a new status.
    func showStatusUpdate(restaurantName: String, status: String) {
        show(ToastMessage(
            title: restaurantName,
            subtitle: "Order is now \(OrderStatusDisplay.label(for: status))",
            style: .info
        ))
    }

    /// A restaurant owner just received a new order.
    func showNewOrder(summary: String) {
        show(ToastMessage(title: "New Order Received", subtitle: summary, style: .success))
    }
}

struct ToastBannerView: View {
    let message: ToastMessage

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: iconName)
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: 2) {
                Text(message.title)
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                if let subtitle = message.subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.9))
                }
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(backgroundColor, in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.2), radius: 10, y: 4)
        .padding(.horizontal)
    }

    private var iconName: String {
        switch message.style {
        case .info: return "bell.fill"
        case .success: return "checkmark.circle.fill"
        case .error: return "exclamationmark.triangle.fill"
        }
    }

    private var backgroundColor: Color {
        switch message.style {
        case .info: return .orange
        case .success: return .green
        case .error: return .red
        }
    }
}

/// Overlays `toastCenter.current` (if any) at the top of whatever it's
/// attached to, sliding in/out as the published value changes. Applied
/// once at the root — see RootView in App/FoodDeliveryApp.swift.
private struct ToastOverlayModifier: ViewModifier {
    @ObservedObject var toastCenter: ToastCenter

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if let message = toastCenter.current {
                    ToastBannerView(message: message)
                        .padding(.top, 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .onTapGesture { toastCenter.dismiss() }
                        .zIndex(1)
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.85), value: toastCenter.current)
    }
}

extension View {
    func toastOverlay(_ toastCenter: ToastCenter) -> some View {
        modifier(ToastOverlayModifier(toastCenter: toastCenter))
    }
}

#Preview {
    VStack(spacing: 16) {
        ToastBannerView(message: ToastMessage(title: "Tony's Pizzeria", subtitle: "Order is now Out for Delivery", style: .info))
        ToastBannerView(message: ToastMessage(title: "New Order Received", subtitle: "3 items · $27.50", style: .success))
        ToastBannerView(message: ToastMessage(title: "Something went wrong", subtitle: nil, style: .error))
    }
}
