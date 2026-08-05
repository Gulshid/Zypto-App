//
//  FirestoreService.swift
//  FoodDeliveryApp
//
//  Generic, type-erased Firestore read/write wrapper. Repositories
//  (UserRepository now, RestaurantRepository/OrderRepository/etc.
//  from Phase 3 onward) sit on top of this instead of talking to
//  the Firestore SDK directly.
//
//  Location in project: Core/Services/FirestoreService.swift
//

import Foundation
import FirebaseFirestore

protocol FirestoreServiceProtocol {
    func setDocument<T: Encodable>(_ value: T, collection: String, documentId: String) async throws
    func getDocument<T: Decodable>(_ type: T.Type, collection: String, documentId: String) async throws -> T?
    func updateFields(_ fields: [String: Any], collection: String, documentId: String) async throws
}

final class FirestoreServiceLive: FirestoreServiceProtocol {
    private let db = Firestore.firestore()

    func setDocument<T: Encodable>(_ value: T, collection: String, documentId: String) async throws {
        try db.collection(collection).document(documentId).setData(from: value, merge: true)
    }

    func getDocument<T: Decodable>(_ type: T.Type, collection: String, documentId: String) async throws -> T? {
        let snapshot = try await db.collection(collection).document(documentId).getDocument()
        guard snapshot.exists else { return nil }
        return try snapshot.data(as: T.self)
    }

    func updateFields(_ fields: [String: Any], collection: String, documentId: String) async throws {
        try await db.collection(collection).document(documentId).updateData(fields)
    }
}
