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
        }
    }
}

/// Routes between the auth flow, role selection, and each role's home
/// screen based on AuthViewModel's published session state.
struct RootView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var appEnvironment: AppEnvironment

    var body: some View {
        Group {
            switch authViewModel.sessionState {
            case .loading:
                splash
            case .signedOut:
                AuthContainerView()
            case .needsRoleSelection(let uid, let email, let fullName):
                RoleSelectionView(uid: uid, email: email, fullName: fullName)
            case .signedIn(let user):
                if user.isCustomer {
                    HomeView(currentUser: user, appEnvironment: appEnvironment)
                } else {
                    DashboardView(user: user, appEnvironment: appEnvironment)
                }
            }
        }
    }

    private var splash: some View {
        VStack(spacing: 12) {
            Image(systemName: "fork.knife.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.orange)
            ProgressView()
        }
    }
}
