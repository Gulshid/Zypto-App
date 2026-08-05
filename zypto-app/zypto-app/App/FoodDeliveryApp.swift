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
//  UPDATED IN PHASE 2: RootView now routes between the auth flow,
//  role selection, and a temporary home screen based on AuthViewModel's
//  published session state, instead of always showing a static placeholder.
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

/// Routes between the auth flow, role selection, and a temporary home
/// screen based on AuthViewModel's published session state. The real
/// Customer/Restaurant destinations replace HomePlaceholderView in
/// Phase 4 and Phase 7.
struct RootView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel

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
                HomePlaceholderView(user: user)
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
