//
//  ReviewsViewModel.swift
//  FoodDeliveryApp
//
//  New in Phase 9. Loads a restaurant's reviews and handles submitting
//  a new one. Kept separate from RestaurantDetailViewModel (which owns
//  the menu) the same way Dashboard splits menu management / incoming
//  orders / analytics into their own view models — one screen, several
//  independently-loadable sections.
//
//  Location in project: Features/RestaurantDetail/ViewModels/ReviewsViewModel.swift
//

import Foundation

@MainActor
final class ReviewsViewModel: ObservableObject {

    @Published var reviews: [Review] = []
    @Published var isLoading = false
    @Published var isSubmitting = false
    @Published var errorMessage: String?
    /// True once `uid` has a review on this restaurant — hides/disables
    /// the "Write a Review" button so nobody leaves a second one (the
    /// Firestore rules don't enforce this; it's a UI-level courtesy).
    @Published private(set) var hasReviewed = false

    let restaurantId: String
    private let uid: String
    private let customerName: String
    private let reviewRepository: ReviewRepositoryProtocol

    /// Fires after a successful submit with the freshly-recomputed
    /// average/count, so RestaurantDetailViewModel can update the
    /// header's star rating in place without re-fetching the whole
    /// restaurant document.
    var onAggregateChanged: ((_ averageRating: Double, _ reviewCount: Int) -> Void)?

    init(
        restaurantId: String,
        uid: String,
        customerName: String,
        reviewRepository: ReviewRepositoryProtocol
    ) {
        self.restaurantId = restaurantId
        self.uid = uid
        self.customerName = customerName
        self.reviewRepository = reviewRepository
    }

    func loadReviews() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            reviews = try await reviewRepository.fetchReviews(restaurantId: restaurantId)
            hasReviewed = reviews.contains { $0.customerId == uid }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Returns true on success so the write-review sheet knows to
    /// dismiss itself.
    @discardableResult
    func submitReview(rating: Int, comment: String) async -> Bool {
        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }

        do {
            let review = try await reviewRepository.submitReview(
                restaurantId: restaurantId,
                customerId: uid,
                customerName: customerName,
                rating: rating,
                comment: comment.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            reviews.insert(review, at: 0)
            hasReviewed = true

            let count = reviews.count
            let average = Double(reviews.reduce(0) { $0 + $1.rating }) / Double(count)
            onAggregateChanged?(average, count)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
