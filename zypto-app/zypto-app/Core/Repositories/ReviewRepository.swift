//
//  ReviewRepository.swift
//  FoodDeliveryApp
//
//  New in Phase 9. Business-logic-facing access to the top-level
//  `reviews` collection (see Core/Models/Review.swift for why it's
//  kept top-level rather than a restaurant subcollection).
//
//  Also owns recomputing Restaurant.averageRating/reviewCount after a
//  new review is submitted. There's no Cloud Functions on the Spark
//  plan to keep a running aggregate server-side, so this reads every
//  review for the restaurant and averages client-side, then writes the
//  two denormalized fields back onto the restaurant document. Fine at
//  this project's scale (a portfolio project's worth of reviews per
//  restaurant); a restaurant with thousands of reviews would want a
//  server-side aggregate instead.
//
//  Location in project: Core/Repositories/ReviewRepository.swift
//

import Foundation

protocol ReviewRepositoryProtocol {
    /// All reviews for a restaurant, newest first.
    func fetchReviews(restaurantId: String) async throws -> [Review]

    /// Whether `customerId` has already reviewed this restaurant — used
    /// to hide/disable the "Write a Review" button so nobody can leave
    /// more than one review per restaurant.
    func hasReviewed(restaurantId: String, customerId: String) async throws -> Bool

    /// Creates the review document, then recomputes and saves the
    /// restaurant's averageRating/reviewCount. Returns the created
    /// review so the caller can insert it into an already-loaded list
    /// without a full refetch.
    func submitReview(
        restaurantId: String,
        customerId: String,
        customerName: String,
        rating: Int,
        comment: String
    ) async throws -> Review
}

final class ReviewRepository: ReviewRepositoryProtocol {
    private let firestoreService: FirestoreServiceProtocol

    init(firestoreService: FirestoreServiceProtocol) {
        self.firestoreService = firestoreService
    }

    func fetchReviews(restaurantId: String) async throws -> [Review] {
        try await firestoreService.getDocuments(Review.self, collection: Constants.Collections.reviews) { query in
            query
                .whereField("restaurantId", isEqualTo: restaurantId)
                .order(by: "createdAt", descending: true)
        }
    }

    func hasReviewed(restaurantId: String, customerId: String) async throws -> Bool {
        let results = try await firestoreService.getDocuments(Review.self, collection: Constants.Collections.reviews) { query in
            query
                .whereField("restaurantId", isEqualTo: restaurantId)
                .whereField("customerId", isEqualTo: customerId)
                .limit(to: 1)
        }
        return !results.isEmpty
    }

    func submitReview(
        restaurantId: String,
        customerId: String,
        customerName: String,
        rating: Int,
        comment: String
    ) async throws -> Review {
        let id = UUID().uuidString
        let review = Review.new(
            id: id,
            restaurantId: restaurantId,
            customerId: customerId,
            customerName: customerName,
            rating: rating,
            comment: comment
        )
        try await firestoreService.setDocument(review, collection: Constants.Collections.reviews, documentId: id)
        try await recomputeAggregate(restaurantId: restaurantId)
        return review
    }

    // MARK: - Private

    private func recomputeAggregate(restaurantId: String) async throws {
        let reviews = try await fetchReviews(restaurantId: restaurantId)
        let count = reviews.count
        let average = count > 0
            ? Double(reviews.reduce(0) { $0 + $1.rating }) / Double(count)
            : 0
        try await firestoreService.updateFields(
            ["averageRating": average, "reviewCount": count],
            collection: Constants.Collections.restaurants,
            documentId: restaurantId
        )
    }
}
