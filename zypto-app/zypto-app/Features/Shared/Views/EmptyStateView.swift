//
//  EmptyStateView.swift
//  FoodDeliveryApp
//
//  New in Phase 10. Since Phase 4, every list screen (home feed, order
//  history, incoming orders, menu management, cart...) grew its own
//  hand-rolled `emptyState`/`errorState` computed property — all
//  slightly different shapes of the same icon + title + subtitle
//  layout. This file pulls that into two reusable views so new screens
//  don't repeat it a sixth time, and existing ones read the same way
//  everywhere in the app:
//
//   - EmptyStateView   — "there's nothing here yet" (empty list, no
//     search matches). Optional action button for screens where there's
//     something to *do* about it (e.g. "Add Your First Item").
//   - ErrorStateView   — something went wrong loading data, with a
//     Try Again button wired to a retry closure.
//
//  Also home to the Phase 10 offline banner: `OfflineBannerView` plus
//  the `.offlineBanner(isOffline:)` modifier, driven by
//  AppEnvironment.networkMonitor and applied once at the root (see
//  RootView in App/FoodDeliveryApp.swift) so it shows up no matter
//  which screen is on top — the same pattern already used for
//  ToastCenter's `.toastOverlay(_:)` in Features/Shared/Views/ToastView.swift.
//
//  Location in project: Features/Shared/Views/EmptyStateView.swift
//

import SwiftUI

// MARK: - Empty state

struct EmptyStateView: View {
    let systemImage: String
    let title: String
    var message: String?
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            Text(title)
                .foregroundStyle(.secondary)

            if let message {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                }
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        // One VoiceOver announcement ("No orders yet. Your order
        // history...") instead of stepping through the icon, title, and
        // subtitle as three separate stops.
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Error state

struct ErrorStateView: View {
    let message: String
    let retryTitle: String
    let onRetry: () -> Void

    init(message: String, retryTitle: String = "Try Again", onRetry: @escaping () -> Void) {
        self.message = message
        self.retryTitle = retryTitle
        self.onRetry = onRetry
    }

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundStyle(.orange)
                .accessibilityHidden(true)
            Text(message)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button(retryTitle, action: onRetry)
                .buttonStyle(.borderedProminent)
                .tint(.orange)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Offline banner

struct OfflineBannerView: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "wifi.slash")
            Text("You're offline — showing saved data")
                .font(.subheadline.bold())
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray5))
        .foregroundStyle(.primary)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("You're offline. Showing previously saved data.")
    }
}

private struct OfflineBannerModifier: ViewModifier {
    let isOffline: Bool

    func body(content: Content) -> some View {
        content
            .safeAreaInset(edge: .top, spacing: 0) {
                if isOffline {
                    OfflineBannerView()
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.25), value: isOffline)
    }
}

extension View {
    /// Pins an offline banner above this view's content whenever
    /// `isOffline` is true. Applied once at the root in RootView (see
    /// App/FoodDeliveryApp.swift), driven by AppEnvironment.networkMonitor.
    func offlineBanner(isOffline: Bool) -> some View {
        modifier(OfflineBannerModifier(isOffline: isOffline))
    }
}

#Preview {
    VStack(spacing: 0) {
        OfflineBannerView()
        EmptyStateView(
            systemImage: "receipt",
            title: "No orders yet",
            message: "Your order history and live status will show up here."
        )
        Divider()
        ErrorStateView(message: "Couldn't load restaurants. Check your connection.") {}
    }
}
