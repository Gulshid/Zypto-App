//
//  MenuItemRowView.swift
//  FoodDeliveryApp
//
//  New in Phase 4. A single menu item row on the Restaurant Detail
//  screen.
//
//  Location in project: Features/RestaurantDetail/Views/MenuItemRowView.swift
//
//  UPDATED IN PHASE 5: the row is now tappable — it presents
//  AddToCartSheetView so the customer can pick a quantity/extras/note
//  and add the item to their cart.
//

import SwiftUI

struct MenuItemRowView: View {
    let item: MenuItem
    let cloudinaryService: CloudinaryServiceProtocol
    /// Forwarded straight from AddToCartSheetView's onAdd closure — see
    /// RestaurantDetailView, which wires this to CartViewModel.addToCart.
    let onAdd: (_ quantity: Int, _ extras: [String], _ note: String?) -> Void

    @State private var showingAddSheet = false

    var body: some View {
        Button {
            showingAddSheet = true
        } label: {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.subheadline.bold())
                        .foregroundStyle(.primary)

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
                .overlay(alignment: .bottomTrailing) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.white, .orange)
                        .background(Circle().fill(.white))
                        .offset(x: 4, y: 4)
                }
            }
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingAddSheet) {
            AddToCartSheetView(item: item, cloudinaryService: cloudinaryService, onAdd: onAdd)
        }
    }
}

#Preview {
    MenuItemRowView(
        item: MenuItem.new(
            id: "1", restaurantId: "r1", name: "Kung Pao Chicken",
            description: "Wok-fried chicken, peanuts, dried chilies",
            price: 12.99, category: "Mains"
        ),
        cloudinaryService: CloudinaryServiceLive(),
        onAdd: { _, _, _ in }
    )
    .padding()
}
