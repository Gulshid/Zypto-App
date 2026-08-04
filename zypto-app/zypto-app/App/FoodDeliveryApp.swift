//
//  FoodDeliveryApp.swift
//  FoodDeliveryApp
//
//  App entry point — configures Firebase and Google Sign-In on launch,
//  and injects the shared AppEnvironment (DI container) into the view tree.
//
//  Location in project: App/FoodDeliveryApp.swift
//

import SwiftUI
import FirebaseCore
import GoogleSignIn

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        return true
    }

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
    @StateObject private var appEnvironment = AppEnvironment()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appEnvironment)
        }
    }
}

/// Placeholder root view — will be replaced in Phase 2 with real
/// auth-state-based routing (Login vs Home).
struct RootView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "fork.knife.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.orange)
            Text("Food Delivery App")
                .font(.title2.bold())
            Text("Phase 1 setup complete ✅")
                .foregroundStyle(.secondary)
        }
    }
}
