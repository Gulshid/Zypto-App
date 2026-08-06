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
//  UPDATED IN PHASE 6: added listenToDocument/listenToDocuments —
//  live-updating counterparts to getDocument/getDocuments, backed by
//  Firestore's addSnapshotListener instead of a one-shot getDocument()
//  call. Returned as AsyncStream so call sites consume them with plain
//  `for await` inside a SwiftUI `.task { }` — no Combine needed, and
//  the listener is torn down automatically (via onTermination) when
//  that task is cancelled, e.g. the view disappearing.
//
//  UPDATED IN PHASE 7: added deleteDocument(collection:documentId:) —
//  the Restaurant/Admin dashboard's menu management screen needs a
//  real delete for removing a menu item entirely, not just flipping
//  its isAvailable flag off.
//

import Foundation
import FirebaseFirestore

protocol FirestoreServiceProtocol {
    func setDocument<T: Encodable>(_ value: T, collection: String, documentId: String) async throws
    func getDocument<T: Decodable>(_ type: T.Type, collection: String, documentId: String) async throws -> T?
    func updateFields(_ fields: [String: Any], collection: String, documentId: String) async throws

    /// New in Phase 7. Restaurant Owners can permanently remove a menu
    /// item from the dashboard (as opposed to just toggling `isAvailable`
    /// off) — needed a real delete, which nothing before Phase 7 did.
    func deleteDocument(collection: String, documentId: String) async throws

    /// Fetches every document in `collection`, optionally shaped by
    /// `queryBuilder` (add whereField/order(by:)/limit calls to the
    /// passed-in Query). `collection` also accepts subcollection paths,
    /// e.g. "restaurants/abc123/menuItems".
    func getDocuments<T: Decodable>(
        _ type: T.Type,
        collection: String,
        queryBuilder: ((Query) -> Query)?
    ) async throws -> [T]

    /// Live updates for a single document — e.g. an order's `status`
    /// field changing as a restaurant updates it. Yields `nil` if the
    /// document doesn't exist (or is deleted) instead of throwing, since
    /// "no document yet" is a normal state to render, not an error.
    func listenToDocument<T: Decodable>(
        _ type: T.Type,
        collection: String,
        documentId: String
    ) -> AsyncStream<T?>

    /// Live updates for a collection query — e.g. a customer's order
    /// history refreshing the instant a new order is created or an
    /// existing one's status changes, with no manual refresh/polling.
    func listenToDocuments<T: Decodable>(
        _ type: T.Type,
        collection: String,
        queryBuilder: ((Query) -> Query)?
    ) -> AsyncStream<[T]>
}

extension FirestoreServiceProtocol {
    /// Convenience overload for the common case of "give me everything
    /// in this collection, no filtering" — most call sites don't need
    /// to pass `nil` explicitly.
    func getDocuments<T: Decodable>(_ type: T.Type, collection: String) async throws -> [T] {
        try await getDocuments(type, collection: collection, queryBuilder: nil)
    }

    func listenToDocuments<T: Decodable>(_ type: T.Type, collection: String) -> AsyncStream<[T]> {
        listenToDocuments(type, collection: collection, queryBuilder: nil)
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

    func deleteDocument(collection: String, documentId: String) async throws {
        try await db.collection(collection).document(documentId).delete()
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

    func listenToDocument<T: Decodable>(
        _ type: T.Type,
        collection: String,
        documentId: String
    ) -> AsyncStream<T?> {
        AsyncStream { continuation in
            let registration = db.collection(collection).document(documentId)
                .addSnapshotListener { snapshot, _ in
                    guard let snapshot, snapshot.exists else {
                        continuation.yield(nil)
                        return
                    }
                    continuation.yield(try? snapshot.data(as: T.self))
                }
            // Fires when the consuming Task is cancelled (e.g. the
            // SwiftUI view stops observing) — detaches the Firestore
            // listener so it doesn't keep running (and billing reads)
            // in the background.
            continuation.onTermination = { _ in
                registration.remove()
            }
        }
    }

    func listenToDocuments<T: Decodable>(
        _ type: T.Type,
        collection: String,
        queryBuilder: ((Query) -> Query)? = nil
    ) -> AsyncStream<[T]> {
        AsyncStream { continuation in
            var query: Query = db.collection(collection)
            if let queryBuilder {
                query = queryBuilder(query)
            }
            let registration = query.addSnapshotListener { snapshot, _ in
                guard let snapshot else {
                    continuation.yield([])
                    return
                }
                continuation.yield(snapshot.documents.compactMap { try? $0.data(as: T.self) })
            }
            continuation.onTermination = { _ in
                registration.remove()
            }
        }
    }
}
