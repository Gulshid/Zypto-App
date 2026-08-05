//
//  UserRepository.swift
//  FoodDeliveryApp
//
//  Business-logic-facing access to the Firestore `users` collection.
//  AuthViewModel calls this after a successful sign-up/sign-in to
//  create or fetch the app-level profile (which holds the user's role).
//
//  Location in project: Core/Repositories/UserRepository.swift
//

import Foundation

protocol UserRepositoryProtocol {
    func createUserProfile(_ user: AppUser) async throws
    func fetchUserProfile(uid: String) async throws -> AppUser?
    func updateRole(uid: String, role: String) async throws
}

final class UserRepository: UserRepositoryProtocol {
    private let firestoreService: FirestoreServiceProtocol

    init(firestoreService: FirestoreServiceProtocol) {
        self.firestoreService = firestoreService
    }

    func createUserProfile(_ user: AppUser) async throws {
        try await firestoreService.setDocument(
            user, collection: Constants.Collections.users, documentId: user.id
        )
    }

    func fetchUserProfile(uid: String) async throws -> AppUser? {
        try await firestoreService.getDocument(
            AppUser.self, collection: Constants.Collections.users, documentId: uid
        )
    }

    func updateRole(uid: String, role: String) async throws {
        try await firestoreService.updateFields(
            ["role": role], collection: Constants.Collections.users, documentId: uid
        )
    }
}
