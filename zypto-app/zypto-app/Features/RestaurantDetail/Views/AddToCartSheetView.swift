//
//  AddToCartSheetView.swift
//  FoodDeliveryApp
//
//  New in Phase 5. Presented when a customer taps a menu item on the
//  Restaurant Detail screen — lets them pick a quantity, toggle any
//  free-form extras the item defines, and leave a note before adding
//  it to the cart.
//
//  Location in project: Features/RestaurantDetail/Views/AddToCartSheetView.swift
//

import SwiftUI

struct AddToCartSheetView: View {
    let item: MenuItem
    let cloudinaryService: CloudinaryServiceProtocol
    /// Called with the user's selections when they tap "Add to Cart".
    /// The sheet itself doesn't know about CartViewModel — keeping it
    /// dumb makes it reusable and trivial to preview.
    let onAdd: (_ quantity: Int, _ extras: [String], _ note: String?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var quantity = 1
    @State private var selectedExtras: Set<String> = []
    @State private var note = ""

    private var lineTotal: Double { item.price * Double(quantity) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header

                    if !item.extras.isEmpty {
                        extrasSection
                    }

                    noteSection
                }
                .padding()
            }
            .navigationTitle("Add to Cart")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                addButton
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            CachedAsyncImage(
                url: cloudinaryService.optimizedURL(from: item.imageURL, width: 200)
            )
            .aspectRatio(1, contentMode: .fill)
            .frame(width: 64, height: 64)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                Text(item.name).font(.headline)
                if !item.description.isEmpty {
                    Text(item.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text(item.price, format: .currency(code: "USD"))
                    .font(.subheadline.bold())
                    .foregroundStyle(.orange)
            }

            Spacer()

            Stepper(value: $quantity, in: 1...20) {
                Text("\(quantity)")
                    .font(.subheadline.bold())
                    .frame(minWidth: 20)
            }
            .fixedSize()
        }
    }

    private var extrasSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Extras").font(.subheadline.bold())

            ForEach(item.extras, id: \.self) { extra in
                Button {
                    if selectedExtras.contains(extra) {
                        selectedExtras.remove(extra)
                    } else {
                        selectedExtras.insert(extra)
                    }
                } label: {
                    HStack {
                        Text(extra)
                        Spacer()
                        Image(systemName: selectedExtras.contains(extra) ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(selectedExtras.contains(extra) ? .orange : .secondary)
                    }
                    .contentShape(Rectangle())
                    .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
                Divider()
            }
        }
    }

    private var noteSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Note (optional)").font(.subheadline.bold())
            TextField("e.g. no onions, extra napkins", text: $note, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(2...4)
        }
    }

    private var addButton: some View {
        Button {
            onAdd(quantity, Array(selectedExtras), note)
            dismiss()
        } label: {
            Text("Add to Cart — \(lineTotal, format: .currency(code: "USD"))")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.orange)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding()
        .background(.ultraThinMaterial)
    }
}

#Preview {
    AddToCartSheetView(
        item: MenuItem.new(
            id: "1", restaurantId: "r1", name: "Kung Pao Chicken",
            description: "Wok-fried chicken, peanuts, dried chilies",
            price: 12.99, category: "Mains", extras: ["Extra spicy", "No peanuts"]
        ),
        cloudinaryService: CloudinaryServiceLive(),
        onAdd: { _, _, _ in }
    )
}
