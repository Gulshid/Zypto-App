//
//  RestaurantProfileView.swift
//  FoodDeliveryApp
//
//  New in Phase 7. Two entry points share this one form:
//   1. First-run setup — DashboardView shows this full-screen when
//      DashboardViewModel finds no restaurant yet for the signed-in owner.
//   2. Editing — pushed/presented from the dashboard's Profile tab to
//      update info or swap the cover photo.
//
//  Location in project: Features/Dashboard/Views/RestaurantProfileView.swift
//

import SwiftUI

struct RestaurantProfileView: View {
    @StateObject private var viewModel: RestaurantProfileViewModel
    private let cloudinaryService: CloudinaryServiceProtocol

    @Environment(\.dismiss) private var dismiss
    /// Called with the saved restaurant so the caller can adopt it
    /// (DashboardViewModel.applyUpdatedRestaurant) without a re-fetch.
    let onSaved: (Restaurant) -> Void

    init(ownerId: String, existingRestaurant: Restaurant?, appEnvironment: AppEnvironment, onSaved: @escaping (Restaurant) -> Void) {
        self.cloudinaryService = appEnvironment.cloudinaryService
        self.onSaved = onSaved
        _viewModel = StateObject(wrappedValue: RestaurantProfileViewModel(
            ownerId: ownerId,
            existingRestaurant: existingRestaurant,
            restaurantRepository: appEnvironment.restaurantRepository,
            cloudinaryService: appEnvironment.cloudinaryService
        ))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ImagePickerButton(
                        existingImageURL: cloudinaryService.optimizedURL(from: viewModel.existingImageURLString, width: 600),
                        pickedImageData: $viewModel.pickedImageData
                    )
                    .listRowInsets(EdgeInsets())
                    .padding(.vertical, 4)
                }
                .listRowBackground(Color.clear)

                Section("Restaurant Info") {
                    TextField("Restaurant name", text: $viewModel.name)
                    TextField("Description", text: $viewModel.description, axis: .vertical)
                        .lineLimit(2...4)
                    TextField("Address", text: $viewModel.address)
                }

                Section {
                    TextField("e.g. Pizza, Italian, Vegan", text: $viewModel.categoriesText)
                } header: {
                    Text("Categories")
                } footer: {
                    Text("Separate multiple categories with commas.")
                }

                Section {
                    Toggle("Open for orders", isOn: $viewModel.isOpen)
                }

                if let errorMessage = viewModel.errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .font(.subheadline)
                    }
                }

                Section {
                    saveButton
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }
            .navigationTitle(viewModel.isEditing ? "Edit Restaurant" : "Set Up Your Restaurant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if viewModel.isEditing {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                }
            }
            // First-run setup has nothing to swipe-back to yet, so the
            // interactive dismiss gesture is disabled there to avoid
            // leaving the owner on a screen with no restaurant and no
            // way back in. Editing (presented as a sheet) can dismiss freely.
            .interactiveDismissDisabled(!viewModel.isEditing)
        }
    }

    private var saveButton: some View {
        Button {
            Task {
                if let saved = await viewModel.save() {
                    onSaved(saved)
                    dismiss()
                }
            }
        } label: {
            HStack {
                Spacer()
                if viewModel.isSaving {
                    ProgressView().tint(.white)
                } else {
                    Text(viewModel.isEditing ? "Save Changes" : "Create Restaurant")
                        .font(.headline)
                }
                Spacer()
            }
            .padding()
            .background(viewModel.isValid ? Color.orange : Color.gray)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(!viewModel.isValid || viewModel.isSaving)
        .padding(.horizontal)
        .padding(.top, 4)
    }
}
