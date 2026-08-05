//
//  AuthViewModel.swift
//  FoodDeliveryApp
//
//  Single source of truth for auth/session state, shared across the
//  whole app via @EnvironmentObject. RootView switches its content
//  based on `sessionState`; individual auth screens call this
//  ViewModel's methods and read `errorMessage` / `isPerformingAction`
//  for loading + error UI.
//
//  Location in project: Features/Auth/ViewModels/AuthViewModel.swift
//

import Foundation
import FirebaseAuth

enum AuthSessionState {
    case loading
    case signedOut
    /// Auth account exists (email/password or Google) but the Firestore
    /// `users` profile — and therefore the role — hasn't been created yet.
    case needsRoleSelection(uid: String, email: String, fullName: String)
    case signedIn(AppUser)
}

@MainActor
final class AuthViewModel: ObservableObject {

    @Published private(set) var sessionState: AuthSessionState = .loading
    @Published var errorMessage: String?
    @Published var isPerformingAction = false

    private let authService: AuthServiceProtocol
    private let userRepository: UserRepositoryProtocol
    private var authListenerHandle: AuthStateDidChangeListenerHandle?

    init(authService: AuthServiceProtocol, userRepository: UserRepositoryProtocol) {
        self.authService = authService
        self.userRepository = userRepository
        observeAuthState()
    }

    deinit {
        if let authListenerHandle {
            authService.removeAuthStateListener(authListenerHandle)
        }
    }

    // MARK: - Session bootstrapping

    private func observeAuthState() {
        authListenerHandle = authService.addAuthStateListener { [weak self] uid in
            Task { @MainActor in
                await self?.refreshSession(uid: uid)
            }
        }
    }

    private func refreshSession(uid: String?) async {
        guard let uid else {
            sessionState = .signedOut
            return
        }
        do {
            if let profile = try await userRepository.fetchUserProfile(uid: uid) {
                sessionState = .signedIn(profile)
            } else {
                // Auth account exists but no Firestore profile yet
                // (e.g. signed up but closed the app before picking a role).
                let email = authService.currentUserEmail ?? ""
                sessionState = .needsRoleSelection(uid: uid, email: email, fullName: "")
            }
        } catch {
            errorMessage = error.localizedDescription
            sessionState = .signedOut
        }
    }

    // MARK: - Email / Password

    func signUp(fullName: String, email: String, password: String) async {
        errorMessage = nil
        guard Validators.isValidEmail(email) else {
            errorMessage = "Please enter a valid email address."
            return
        }
        guard Validators.isValidPassword(password) else {
            errorMessage = "Password must be at least 6 characters."
            return
        }

        isPerformingAction = true
        defer { isPerformingAction = false }

        do {
            let uid = try await authService.signUp(email: email, password: password)
            sessionState = .needsRoleSelection(uid: uid, email: email, fullName: fullName)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signIn(email: String, password: String) async {
        errorMessage = nil
        guard Validators.isValidEmail(email) else {
            errorMessage = "Please enter a valid email address."
            return
        }
        guard !password.isEmpty else {
            errorMessage = "Please enter your password."
            return
        }

        isPerformingAction = true
        defer { isPerformingAction = false }

        do {
            let uid = try await authService.signIn(email: email, password: password)
            await refreshSession(uid: uid)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Google Sign-In

    func signInWithGoogle() async {
        errorMessage = nil
        isPerformingAction = true
        defer { isPerformingAction = false }

        do {
            let result = try await authService.signInWithGoogle()
            if result.isNewUser {
                sessionState = .needsRoleSelection(
                    uid: result.uid,
                    email: result.email ?? "",
                    fullName: result.fullName ?? ""
                )
            } else {
                await refreshSession(uid: result.uid)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Forgot password

    @discardableResult
    func sendPasswordReset(email: String) async -> Bool {
        errorMessage = nil
        guard Validators.isValidEmail(email) else {
            errorMessage = "Please enter a valid email address."
            return false
        }
        do {
            try await authService.sendPasswordReset(email: email)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    // MARK: - Role selection (completes profile creation)

    func completeProfile(uid: String, email: String, fullName: String, role: String) async {
        errorMessage = nil
        isPerformingAction = true
        defer { isPerformingAction = false }

        let user = AppUser(id: uid, email: email, fullName: fullName, role: role, createdAt: Date())
        do {
            try await userRepository.createUserProfile(user)
            sessionState = .signedIn(user)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Sign out

    func signOut() {
        do {
            try authService.signOut()
            sessionState = .signedOut
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Preview support

#if DEBUG
extension AuthViewModel {
    /// Lightweight fake-backed instance for SwiftUI previews —
    /// never touches real Firebase.
    static var preview: AuthViewModel {
        AuthViewModel(authService: PreviewAuthService(), userRepository: PreviewUserRepository())
    }
}

private struct PreviewAuthService: AuthServiceProtocol {
    var currentUserId: String? { nil }
    var currentUserEmail: String? { nil }
    func signUp(email: String, password: String) async throws -> String { "" }
    func signIn(email: String, password: String) async throws -> String { "" }
    func signOut() throws {}
    func sendPasswordReset(email: String) async throws {}
    func signInWithGoogle() async throws -> (uid: String, email: String?, fullName: String?, isNewUser: Bool) {
        ("", nil, nil, false)
    }
    func addAuthStateListener(_ handler: @escaping (String?) -> Void) -> AuthStateDidChangeListenerHandle {
        handler(nil)
        return NSObject()
    }
    func removeAuthStateListener(_ handle: AuthStateDidChangeListenerHandle) {}
}

private struct PreviewUserRepository: UserRepositoryProtocol {
    func createUserProfile(_ user: AppUser) async throws {}
    func fetchUserProfile(uid: String) async throws -> AppUser? { nil }
    func updateRole(uid: String, role: String) async throws {}
}
#endif
