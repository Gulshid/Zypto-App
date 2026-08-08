//
//  RestaurantCardView.swift
//  FoodDeliveryApp
//
//  New in Phase 4. A single restaurant row/card for the home feed:
//  cover photo, name, categories, rating, and a favorite toggle.
//
//  Location in project: Features/Home/Views/RestaurantCardView.swift
//
//  UPDATED IN PHASE 10:
//   - Favoriting now gives a light haptic tap and a small spring "pop"
//     on the heart icon instead of just flipping the SF Symbol.
//   - The photo/name/rating are grouped into a single VoiceOver stop
//     ("Golden Dragon, Chinese, Spicy, 4.3 stars, 128 reviews") separate
//     from the favorite button, which now announces its own state
//     ("Add to favorites" / "Remove from favorites") — previously
//     neither had a label, so VoiceOver read the raw SF Symbol names.
//   - `.matchedTransitionSource(id:in:)` is applied by the call site in
//     HomeView, not here, so this view doesn't need to know about the
//     shared hero namespace.
//

import SwiftUI

struct RestaurantCardView: View {
    let restaurant: Restaurant
    let isFavorite: Bool
    let cloudinaryService: CloudinaryServiceProtocol
    let onToggleFavorite: () -> Void

    @State private var isFavoriteBouncing = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topTrailing) {
                CachedAsyncImage(
                    url: cloudinaryService.optimizedURL(from: restaurant.imageURL, width: 500)
                )
                .aspectRatio(16.0 / 9.0, contentMode: .fill)
                .frame(maxWidth: .infinity)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 14))

                favoriteButton
                    .padding(8)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(restaurant.name)
                        .font(.headline)
                        .lineLimit(1)

                    Spacer()

                    if !restaurant.isOpen {
                        Text("Closed")
                            .font(.caption.bold())
                            .foregroundStyle(.red)
                    }
                }

                if !restaurant.categories.isEmpty {
                    Text(restaurant.categories.joined(separator: " • "))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.orange)
                        .font(.caption)
                    Text(ratingText)
                        .font(.caption.bold())
                    Text("(\(restaurant.reviewCount))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .accessibilityElement(children: .combine)
        }
    }

    private var ratingText: String {
        restaurant.reviewCount > 0 ? String(format: "%.1f", restaurant.averageRating) : "New"
    }

    private var favoriteButton: some View {
        Button {
            Haptics.tap()
            onToggleFavorite()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.4)) {
                isFavoriteBouncing = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                isFavoriteBouncing = false
            }
        } label: {
            Image(systemName: isFavorite ? "heart.fill" : "heart")
                .font(.subheadline.bold())
                .foregroundStyle(isFavorite ? .red : .white)
                .padding(8)
                .background(.black.opacity(0.35), in: Circle())
                .scaleEffect(isFavoriteBouncing ? 1.3 : 1.0)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isFavorite ? "Remove from favorites" : "Add to favorites")
    }
}

#Preview {
    RestaurantCardView(
        restaurant: Restaurant.new(
            id: "1", ownerId: "owner1", name: "Golden Dragon",
            description: "Authentic Sichuan cuisine", address: "123 Main St",
            categories: ["Chinese", "Spicy"]
        ),
        isFavorite: true,
        cloudinaryService: CloudinaryServiceLive(),
        onToggleFavorite: {}
    )
    .padding()
}
