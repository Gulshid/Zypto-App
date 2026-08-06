//
//  MenuItemFormView.swift
//  FoodDeliveryApp
//
//  New in Phase 7. Add/edit sheet for a single menu item — presented
//  from MenuManagementView's "+" toolbar button (new item) or a row's
//  edit action (existing item).
//
//  Location in project: Features/Dashboard/Views/MenuItemFormView.swift
//

import SwiftUI

struct MenuItemFormView: View {
    @StateObject private var viewModel: MenuItemFormViewModel
    private let cloudinaryService: CloudinaryServiceProtocol

    @Environment(\.dismiss) private var dismiss
    /// Called with the saved item so MenuManagementViewModel can adopt
    /// it into the list immediately (see applyUpsertedItem).
    let onSaved: (MenuItem) -> Void

    init(restaurantId: String, existingItem: MenuItem?, appEnvironment: AppEnvironment, onSaved: @escaping (MenuItem) -> Void) {
        self.cloudinaryService = appEnvironment.cloudinaryService
        self.onSaved = onSaved
        _viewModel = StateObject(wrappedValue: MenuItemFormViewModel(
            restaurantId: restaurantId,
            existingItem: existingItem,
            menuRepository: appEnvironment.menuRepository,
            cloudinaryService: appEnvironment.cloudinaryService
        ))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ImagePickerButton(
                        existingImageURL: cloudinaryService.optimizedURL(from: viewModel.existingImageURLString, width: 500),
                        pickedImageData: $viewModel.pickedImageData
                    )
                    .listRowInsets(EdgeInsets())
                    .padding(.vertical, 4)
                }
                .listRowBackground(Color.clear)

                Section("Item Info") {
                    TextField("Item name", text: $viewModel.name)
                    TextField("Description", text: $viewModel.description, axis: .vertical)
                        .lineLimit(2...4)
                    HStack {
                        Text("$")
                            .foregroundStyle(.secondary)
                        TextField("Price", text: $viewModel.priceText)
                            .keyboardType(.decimalPad)
                    }
                    TextField("Category (e.g. Mains, Drinks)", text: $viewModel.category)
                }

                Section {
                    TextField("e.g. Extra cheese, No onions", text: $viewModel.extrasText)
                } header: {
                    Text("Extras")
                } footer: {
                    Text("Optional add-ons customers can select. Separate with commas.")
                }

                Section {
                    Toggle("Available to order", isOn: $viewModel.isAvailable)
                }

                if let errorMessage = viewModel.errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .font(.subheadline)
                    }
                }
            }
            .navigationTitle(viewModel.isEditing ? "Edit Item" : "New Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if viewModel.isSaving {
                        ProgressView()
                    } else {
                        Button("Save") {
                            Task {
                                if let saved = await viewModel.save() {
                                    onSaved(saved)
                                    dismiss()
                                }
                            }
                        }
                        .disabled(!viewModel.isValid)
                        .bold()
                    }
                }
            }
        }
    }
}
