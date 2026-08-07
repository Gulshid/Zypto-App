//
//  StarRatingView.swift
//  FoodDeliveryApp
//
//  New in Phase 9. Two small, reusable star-rating pieces used by the
//  reviews feature:
//   - StarRatingView: read-only stars for displaying an existing rating
//     (whole/half/empty stars from a Double average).
//   - StarRatingPicker: tappable 1...5 stars for WriteReviewView.
//
//  Location in project: Features/Shared/Views/StarRatingView.swift
//

import SwiftUI

/// Read-only star display for an average rating, e.g. 4.3 -> 4 full
/// stars, 1 half star, 0 empty stars.
struct StarRatingView: View {
    let rating: Double
    var maxRating: Int = 5
    var font: Font = .caption

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...maxRating, id: \.self) { position in
                Image(systemName: iconName(for: position))
                    .foregroundStyle(.orange)
                    .font(font)
            }
        }
    }

    private func iconName(for position: Int) -> String {
        let filled = Double(position) <= rating
        let halfFilled = !filled && Double(position) - rating < 1
        if filled { return "star.fill" }
        if halfFilled { return "star.leadinghalf.filled" }
        return "star"
    }
}

/// Tappable star picker for submitting a new 1...5 rating.
struct StarRatingPicker: View {
    @Binding var rating: Int
    var maxRating: Int = 5

    var body: some View {
        HStack(spacing: 8) {
            ForEach(1...maxRating, id: \.self) { star in
                Button {
                    rating = star
                } label: {
                    Image(systemName: star <= rating ? "star.fill" : "star")
                        .font(.title2)
                        .foregroundStyle(.orange)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        StarRatingView(rating: 4.3, font: .title3)
        StarRatingView(rating: 2.0, font: .title3)
        StarRatingPicker(rating: .constant(3))
    }
    .padding()
}
