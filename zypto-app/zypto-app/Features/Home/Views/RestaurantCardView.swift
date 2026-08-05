//
//  RestaurantCardView.swift
//  FoodDeliveryApp
//
//  New in Phase 4. A single restaurant row/card for the home feed:
//  cover photo, name, categories, rating, and a favorite toggle.
//
//  Location in project: Features/Home/Views/RestaurantCardView.swift
//

import SwiftUI

struct RestaurantCardView: View {
    let restaurant: Restaurant
    let isFavorite: Bool
    let cloudinaryService: CloudinaryServiceProtocol
    let onToggleFavorite: () -> Void

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
        }
    }

    private var ratingText: String {
        restaurant.reviewCount > 0 ? String(format: "%.1f", restaurant.averageRating) : "New"
    }

    private var favoriteButton: some View {
        Button(action: onToggleFavorite) {
            Image(systemName: isFavorite ? "heart.fill" : "heart")
                .font(.subheadline.bold())
                .foregroundStyle(isFavorite ? .red : .white)
                .padding(8)
                .background(.black.opacity(0.35), in: Circle())
        }
        .buttonStyle(.plain)
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
