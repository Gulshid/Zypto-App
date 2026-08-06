//
//  CartItemRowView.swift
//  FoodDeliveryApp
//
//  New in Phase 5. A single line item on the Cart screen: name, chosen
//  extras/note, a quantity stepper, and the line total.
//
//  Location in project: Features/Cart/Views/CartItemRowView.swift
//

import SwiftUI

struct CartItemRowView: View {
    let item: CartItem
    let onQuantityChange: (Int) -> Void
    let onRemove: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.subheadline.bold())

                if !item.selectedExtras.isEmpty {
                    Text(item.selectedExtras.joined(separator: ", "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let note = item.note, !note.isEmpty {
                    Text("Note: \(note)")
                        .font(.caption)
                        .italic()
                        .foregroundStyle(.secondary)
                }

                Text(item.unitPrice, format: .currency(code: "USD"))
                    .font(.caption.bold())
                    .foregroundStyle(.orange)

                stepper
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 8) {
                Text(item.lineTotal, format: .currency(code: "USD"))
                    .font(.subheadline.bold())

                Button(role: .destructive, action: onRemove) {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        }
        .padding(.vertical, 8)
    }

    private var stepper: some View {
        HStack(spacing: 12) {
            Button {
                onQuantityChange(item.quantity - 1)
            } label: {
                Image(systemName: "minus.circle")
            }

            Text("\(item.quantity)")
                .font(.subheadline.bold())
                .frame(minWidth: 16)

            Button {
                onQuantityChange(item.quantity + 1)
            } label: {
                Image(systemName: "plus.circle")
            }
        }
        .foregroundStyle(.orange)
        .padding(.top, 4)
    }
}

#Preview {
    CartItemRowView(
        item: CartItem(
            id: "1", menuItemId: "m1", restaurantId: "r1", name: "Kung Pao Chicken",
            unitPrice: 12.99, quantity: 2, selectedExtras: ["Extra spicy"], note: "No peanuts please"
        ),
        onQuantityChange: { _ in },
        onRemove: {}
    )
    .padding()
}
