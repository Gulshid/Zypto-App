//
//  WriteReviewView.swift
//  FoodDeliveryApp
//
//  New in Phase 9. Sheet for leaving a star rating + comment on a
//  restaurant, presented from RestaurantDetailView's "Write a Review"
//  button.
//
//  Location in project: Features/RestaurantDetail/Views/WriteReviewView.swift
//

import SwiftUI

struct WriteReviewView: View {
    @ObservedObject var viewModel: ReviewsViewModel
    let restaurantName: String

    @Environment(\.dismiss) private var dismiss
    @State private var rating = 0
    @State private var comment = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Text(restaurantName)
                            .font(.headline)
                        Text("How was your order?")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        StarRatingPicker(rating: $rating)
                            .padding(.top, 4)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 12)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Comment (optional)")
                            .font(.subheadline.bold())
                        TextField("Tell other customers what you thought…", text: $comment, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(4...8)
                    }

                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
                .padding()
            }
            .navigationTitle("Write a Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                submitButton
            }
        }
    }

    private var submitButton: some View {
        Button {
            Task {
                let success = await viewModel.submitReview(rating: rating, comment: comment)
                if success { dismiss() }
            }
        } label: {
            Group {
                if viewModel.isSubmitting {
                    ProgressView().tint(.white)
                } else {
                    Text("Submit Review")
                }
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding()
            .background(rating > 0 ? Color.orange : Color.gray.opacity(0.4))
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(rating == 0 || viewModel.isSubmitting)
        .padding()
    }
}
