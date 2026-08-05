//
//  FirestoreService.swift
//  FoodDeliveryApp
//
//  Generic, type-erased Firestore read/write wrapper. Repositories
//  (UserRepository from Phase 2; RestaurantRepository, MenuRepository,
//  FavoritesRepository from Phase 4 onward) sit on top of this instead
//  of talking to the Firestore SDK directly.
//
//  Location in project: Core/Services/FirestoreService.swift
//
//  UPDATED IN PHASE 4: added getDocuments(_:collection:queryBuilder:) —
//  Phase 2/3 only ever needed single-document reads/writes (one user
//  profile at a time). Browsing restaurants/menus needs *collection*
//  queries (list all restaurants, filter by category, list a
//  restaurant's available menu items), so this wraps Firestore's
//  Query type generically the same way setDocument/getDocument wrap
//  DocumentReference.
//

import Foundation
import FirebaseFirestore

protocol FirestoreServiceProtocol {
    func setDocument<T: Encodable>(_ value: T, collection: String, documentId: String) async throws
    func getDocument<T: Decodable>(_ type: T.Type, collection: String, documentId: String) async throws -> T?
    func updateFields(_ fields: [String: Any], collection: String, documentId: String) async throws

    /// Fetches every document in `collection`, optionally shaped by
    /// `queryBuilder` (add whereField/order(by:)/limit calls to the
    /// passed-in Query). `collection` also accepts subcollection paths,
    /// e.g. "restaurants/abc123/menuItems".
    func getDocuments<T: Decodable>(
        _ type: T.Type,
        collection: String,
        queryBuilder: ((Query) -> Query)?
    ) async throws -> [T]
}

extension FirestoreServiceProtocol {
    /// Convenience overload for the common case of "give me everything
    /// in this collection, no filtering" — most call sites don't need
    /// to pass `nil` explicitly.
    func getDocuments<T: Decodable>(_ type: T.Type, collection: String) async throws -> [T] {
        try await getDocuments(type, collection: collection, queryBuilder: nil)
    }
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

    func getDocuments<T: Decodable>(
        _ type: T.Type,
        collection: String,
        queryBuilder: ((Query) -> Query)? = nil
    ) async throws -> [T] {
        var query: Query = db.collection(collection)
        if let queryBuilder {
            query = queryBuilder(query)
        }
        let snapshot = try await query.getDocuments()
        // compactMap rather than map: silently skips a document that fails
        // to decode (e.g. a stray malformed doc from manual console edits)
        // instead of failing the whole list for every other valid document.
        return snapshot.documents.compactMap { try? $0.data(as: T.self) }
    }
}
