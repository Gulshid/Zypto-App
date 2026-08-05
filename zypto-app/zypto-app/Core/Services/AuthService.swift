//
//  AuthService.swift
//  FoodDeliveryApp
//
//  Thin wrapper around FirebaseAuth + GoogleSignIn. ViewModels never
//  import FirebaseAuth directly — they talk to AuthServiceProtocol,
//  which keeps auth SDK details out of the UI layer and makes it
//  possible to swap in a fake implementation for previews/tests.
//
//  Location in project: Core/Services/AuthService.swift
//

import Foundation
import FirebaseAuth
import GoogleSignIn
import UIKit

protocol AuthServiceProtocol {
    var currentUserId: String? { get }
    var currentUserEmail: String? { get }

    func signUp(email: String, password: String) async throws -> String
    func signIn(email: String, password: String) async throws -> String
    func signOut() throws
    func sendPasswordReset(email: String) async throws
    func signInWithGoogle() async throws -> (uid: String, email: String?, fullName: String?, isNewUser: Bool)

    @discardableResult
    func addAuthStateListener(_ handler: @escaping (String?) -> Void) -> AuthStateDidChangeListenerHandle
    func removeAuthStateListener(_ handle: AuthStateDidChangeListenerHandle)
}

enum AuthError: LocalizedError {
    case noPresentingViewController
    case missingIDToken

    var errorDescription: String? {
        switch self {
        case .noPresentingViewController:
            return "Couldn't find a screen to present Google Sign-In from."
        case .missingIDToken:
            return "Google Sign-In didn't return an ID token. Please try again."
        }
    }
}

final class AuthServiceFirebase: AuthServiceProtocol {

    var currentUserId: String? { Auth.auth().currentUser?.uid }
    var currentUserEmail: String? { Auth.auth().currentUser?.email }

    // MARK: - Email / Password

    func signUp(email: String, password: String) async throws -> String {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        return result.user.uid
    }

    func signIn(email: String, password: String) async throws -> String {
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        return result.user.uid
    }

    func signOut() throws {
        try Auth.auth().signOut()
    }

    func sendPasswordReset(email: String) async throws {
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }

    // MARK: - Google Sign-In

    @MainActor
    func signInWithGoogle() async throws -> (uid: String, email: String?, fullName: String?, isNewUser: Bool) {
        guard let presentingVC = Self.topViewController() else {
            throw AuthError.noPresentingViewController
        }

        let googleResult = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingVC)

        guard let idToken = googleResult.user.idToken?.tokenString else {
            throw AuthError.missingIDToken
        }

        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: googleResult.user.accessToken.tokenString
        )

        let authResult = try await Auth.auth().signIn(with: credential)
        let isNewUser = authResult.additionalUserInfo?.isNewUser ?? false
        let fullName = googleResult.user.profile?.name

        return (authResult.user.uid, authResult.user.email, fullName, isNewUser)
    }

    // MARK: - Session listener

    @discardableResult
    func addAuthStateListener(_ handler: @escaping (String?) -> Void) -> AuthStateDidChangeListenerHandle {
        Auth.auth().addStateDidChangeListener { _, user in
            handler(user?.uid)
        }
    }

    func removeAuthStateListener(_ handle: AuthStateDidChangeListenerHandle) {
        Auth.auth().removeStateDidChangeListener(handle)
    }

    // MARK: - Helpers

    /// Walks the active scene's window hierarchy to find the top-most
    /// presented view controller, which Google Sign-In needs to present from.
    private static func topViewController(
        base: UIViewController? = UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }
            .first?.rootViewController
    ) -> UIViewController? {
        if let nav = base as? UINavigationController {
            return topViewController(base: nav.visibleViewController)
        }
        if let tab = base as? UITabBarController, let selected = tab.selectedViewController {
            return topViewController(base: selected)
        }
        if let presented = base?.presentedViewController {
            return topViewController(base: presented)
        }
        return base
    }
}
