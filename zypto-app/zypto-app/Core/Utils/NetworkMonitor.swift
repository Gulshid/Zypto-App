//
//  NetworkMonitor.swift
//  FoodDeliveryApp
//
//  New in Phase 10. Thin wrapper around Apple's Network framework that
//  publishes whether the device currently has internet connectivity.
//  Firestore already has offline persistence enabled by default (reads
//  fall back to its local cache, writes queue and replay automatically),
//  so this doesn't need to do anything clever with retry logic — its
//  only job is to let the UI tell the person "you're offline, showing
//  saved data" instead of silently showing stale content or a
//  confusing error.
//
//  Location in project: Core/Utils/NetworkMonitor.swift
//
//  One instance lives on AppEnvironment (see App/AppEnvironment.swift)
//  and is read by RootView (App/FoodDeliveryApp.swift) to drive the
//  offline banner declared in Features/Shared/Views/EmptyStateView.swift.
//

import Foundation
import Network

@MainActor
final class NetworkMonitor: ObservableObject {

    /// True until the first path update arrives, so the offline banner
    /// never flashes on screen during the split-second before the
    /// monitor reports its first real status.
    @Published private(set) var isConnected = true

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.zypto.networkmonitor")
    private var started = false

    /// Explicitly `nonisolated` so `NetworkMonitor()` can be called from
    /// AppEnvironment's synchronous, non-isolated `init()` (see
    /// App/AppEnvironment.swift) without the compiler having to prove
    /// that call happens on the main actor. Safe because this
    /// initializer only assigns default values to stored properties —
    /// it never touches `isConnected` or any other main-actor-isolated
    /// state, so there's nothing here that actually needs isolation
    /// until `start()` is called.
    nonisolated init() {}

    /// Safe to call more than once (e.g. RootView re-appearing after a
    /// sign-out/sign-in) — only starts the underlying NWPathMonitor once.
    func start() {
        guard !started else { return }
        started = true

        monitor.pathUpdateHandler = { [weak self] path in
            let connected = path.status == .satisfied
            Task { @MainActor in
                self?.isConnected = connected
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}
