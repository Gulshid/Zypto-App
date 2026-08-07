//
//  AllReviewsView.swift
//  FoodDeliveryApp
//
//  New in Phase 9. Full scrollable review list, pushed from
//  RestaurantDetailView's "See all N reviews" link (which otherwise
//  only shows a short preview inline).
//
//  Location in project: Features/RestaurantDetail/Views/AllReviewsView.swift
//

import SwiftUI

struct AllReviewsView: View {
    let restaurantName: String
    @ObservedObject var viewModel: ReviewsViewModel

    var body: some View {
        Group {
            if viewModel.reviews.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "star.bubble")
                        .font(.system(size: 36))
                        .foregroundStyle(.secondary)
                    Text("No reviews yet")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(viewModel.reviews) { review in
                        ReviewRowView(review: review)
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("\(restaurantName) Reviews")
        .navigationBarTitleDisplayMode(.inline)
    }
}
