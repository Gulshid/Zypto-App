//
//  MenuItemRowView.swift
//  FoodDeliveryApp
//
//  New in Phase 4. A single menu item row on the Restaurant Detail
//  screen. Read-only for now — "Add to Cart" lands in Phase 5.
//
//  Location in project: Features/RestaurantDetail/Views/MenuItemRowView.swift
//

import SwiftUI

struct MenuItemRowView: View {
    let item: MenuItem
    let cloudinaryService: CloudinaryServiceProtocol

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.subheadline.bold())

                if !item.description.isEmpty {
                    Text(item.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Text(item.price, format: .currency(code: "USD"))
                    .font(.subheadline.bold())
                    .foregroundStyle(.orange)
                    .padding(.top, 2)
            }

            Spacer(minLength: 8)

            CachedAsyncImage(
                url: cloudinaryService.optimizedURL(from: item.imageURL, width: 200)
            )
            .aspectRatio(1, contentMode: .fill)
            .frame(width: 72, height: 72)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .padding(.vertical, 6)
    }
}

#Preview {
    MenuItemRowView(
        item: MenuItem.new(
            id: "1", restaurantId: "r1", name: "Kung Pao Chicken",
            description: "Wok-fried chicken, peanuts, dried chilies",
            price: 12.99, category: "Mains"
        ),
        cloudinaryService: CloudinaryServiceLive()
    )
    .padding()
}
