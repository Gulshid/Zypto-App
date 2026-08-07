//
//  ReviewRowView.swift
//  FoodDeliveryApp
//
//  New in Phase 9. A single review row: reviewer name, star rating,
//  relative date, and comment. Used both in RestaurantDetailView's
//  "recent reviews" preview and the full AllReviewsView list.
//
//  Location in project: Features/RestaurantDetail/Views/ReviewRowView.swift
//

import SwiftUI

struct ReviewRowView: View {
    let review: Review

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(review.customerName)
                    .font(.subheadline.bold())
                Spacer()
                Text(review.createdAt, format: .relative(presentation: .named))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            StarRatingView(rating: Double(review.rating), font: .caption)

            if !review.comment.isEmpty {
                Text(review.comment)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
            }
        }
        .padding(.vertical, 6)
    }
}

#Preview {
    ReviewRowView(review: Review.new(
        id: "1", restaurantId: "r1", customerId: "u1", customerName: "Jordan P.",
        rating: 4, comment: "Great flavors, delivery was a little slow but worth the wait."
    ))
    .padding()
}
