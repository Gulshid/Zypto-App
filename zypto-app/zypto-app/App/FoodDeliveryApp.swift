//
//  FoodDeliveryApp.swift
//  FoodDeliveryApp
//
//  App entry point — configures Firebase and Google Sign-In on launch,
//  and injects AppEnvironment (DI container) + AuthViewModel (session
//  state) into the view tree.
//
//  Location in project: App/FoodDeliveryApp.swift
//
//  UPDATED IN PHASE 4: RootView now routes signed-in Customers to the
//  real home feed (HomeView, restaurant browsing). Restaurant Owners
//  still land on HomePlaceholderView until their dashboard ships in
//  Phase 7.
//
//  UPDATED IN PHASE 7: Restaurant Owners now route to DashboardView —
//  first-run restaurant setup, then Menu/Orders/Analytics/Profile tabs.
//
//  UPDATED IN PHASE 8: RootView now (1) requests notification
//  authorization and clears any stale app-icon badge the moment a
//  session becomes signed-in, and (2) overlays ToastCenter's banner
//  (Features/Shared/Views/ToastView.swift) above the whole app so a
//  toast can appear regardless of which screen is on top.
//
//  UPDATED IN PHASE 10: RootView now also (1) starts
//  AppEnvironment.networkMonitor once, on first appearance, and (2)
//  pins an offline banner above the whole app whenever connectivity
//  drops (Features/Shared/Views/EmptyStateView.swift), the same
//  "applied once at the root" treatment as the toast overlay above.
//
//  UPDATED IN PHASE 11:
//   - The plain icon+spinner splash is now the branded animated
//     SplashScreenView (App/SplashScreenView.swift), shown for a
//     minimum duration so it never just flashes on a fast connection.
//   - Signed-in Customers now route to MainTabView (Features/Home/Views/MainTabView.swift),
//     a bottom tab bar across Home/Orders/Favorites/Account, instead of
//     HomeView directly.
//

import SwiftUI
import FirebaseCore
import GoogleSignIn

final class AppDelegate: NSObject, UIApplicationDelegate {
    // NOTE: FirebaseApp.configure() intentionally is NOT called here.
    // SwiftUI does not guarantee this delegate callback runs before the
    // App struct's own init() — so any @StateObject that touches Firebase
    // (like AppEnvironment, which builds Firestore.firestore()) could run
    // first and crash with SIGABRT ("Firebase not configured"). Instead,
    // FirebaseApp.configure() is called explicitly at the top of
    // FoodDeliveryApp.init() below, guaranteeing correct ordering.
    // Calling it in both places would also crash ("default app already exists").

    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        // Required so Google Sign-In can complete its auth redirect back into the app
        return GIDSignIn.sharedInstance.handle(url)
    }
}

@main
struct FoodDeliveryApp: App {
    // Bridges the classic UIApplicationDelegate into SwiftUI's App lifecycle
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    // Single shared instance of our DI container, created once for the app's lifetime
    @StateObject private var appEnvironment: AppEnvironment
    // Session state, built on top of appEnvironment's services
    @StateObject private var authViewModel: AuthViewModel

    init() {
        // Must run before anything touches Firebase (Auth, Firestore) —
        // AppEnvironment below builds Firestore.firestore() immediately,
        // so this has to come first. See note on AppDelegate above.
        FirebaseApp.configure()

        // Google Sign-In needs a client ID. Since this project uses an
        // auto-generated Info.plist (no static file to add a GIDClientID
        // key to), we configure it in code instead, reusing the client ID
        // Firebase already loaded from GoogleService-Info.plist. Without
        // this, Google Sign-In crashes with "No active configuration.
        // Make sure GIDClientID is set in Info.plist."
        if let clientID = FirebaseApp.app()?.options.clientID {
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        }

        let environment = AppEnvironment()
        _appEnvironment = StateObject(wrappedValue: environment)
        _authViewModel = StateObject(wrappedValue: AuthViewModel(
            authService: environment.authService,
            userRepository: environment.userRepository
        ))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appEnvironment)
                .environmentObject(authViewModel)
                // Respect the system's preferred appearance (Light/Dark/
                // Auto) rather than forcing one — every color used across
                // the app is already a semantic/system color (.primary,
                // .secondary, Color(.secondarySystemBackground), etc.)
                // rather than a hardcoded white/black, so both appearances
                // fall out of that "for free" without a dedicated theme
                // file. Intentionally NOT calling .preferredColorScheme(_:)
                // here — that would override the person's iOS setting.
        }
    }
}

/// Routes between the auth flow, role selection, and each role's home
/// screen based on AuthViewModel's published session state.
struct RootView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var appEnvironment: AppEnvironment

    // The branded splash (App/SplashScreenView.swift) is shown for at
    // least this long, even once auth has already resolved, so it
    // never just flashes for a frame on a fast/cached sign-in — a
    // half-second brand moment reads as "loading", not as a glitch.
    @State private var minimumSplashElapsed = false

    var body: some View {
        Group {
            switch authViewModel.sessionState {
            case .loading:
                SplashScreenView()
            case .signedOut:
                if minimumSplashElapsed {
                    AuthContainerView()
                } else {
                    SplashScreenView()
                }
            case .needsRoleSelection(let uid, let email, let fullName):
                RoleSelectionView(uid: uid, email: email, fullName: fullName)
            case .signedIn(let user):
                if !minimumSplashElapsed {
                    SplashScreenView()
                } else if user.isCustomer {
                    MainTabView(currentUser: user, appEnvironment: appEnvironment)
                } else {
                    DashboardView(user: user, appEnvironment: appEnvironment)
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: minimumSplashElapsed)
        .task {
            try? await Task.sleep(nanoseconds: 900_000_000)
            minimumSplashElapsed = true
        }
        // New in Phase 8. Keyed on isSignedIn rather than firing once
        // in .onAppear: re-runs (and re-prompts nothing, since iOS only
        // ever shows the permission dialog once) each time a session
        // transitions into .signedIn — e.g. after a sign-out/sign-in
        // with a different account — so the badge always starts fresh
        // for whoever is now signed in.
        .task(id: isSignedIn) {
            guard isSignedIn else { return }
            await appEnvironment.notificationService.requestAuthorization()
            await appEnvironment.notificationService.clearBadge()
        }
        // New in Phase 10. Runs once, ever — start() itself is
        // idempotent (see NetworkMonitor), but there's no need to even
        // call it more than once from here.
        .onAppear { appEnvironment.networkMonitor.start() }
        .offlineBanner(isOffline: !appEnvironment.networkMonitor.isConnected)
        .toastOverlay(appEnvironment.toastCenter)
    }

    private var isSignedIn: Bool {
        if case .signedIn = authViewModel.sessionState {
            return true
        }
        return false
    }
}
