//
//  MenuItemFormViewModel.swift
//  FoodDeliveryApp
//
//  New in Phase 7. Backs MenuItemFormView for both adding a brand-new
//  item (MenuItem.new(...)) and editing an existing one — same form,
//  same view model, `existingItem == nil` decides which Firestore call
//  save() makes. Mirrors RestaurantProfileViewModel's create/edit split.
//
//  Location in project: Features/Dashboard/ViewModels/MenuItemFormViewModel.swift
//

import Foundation

@MainActor
final class MenuItemFormViewModel: ObservableObject {

    @Published var name: String
    @Published var description: String
    @Published var priceText: String
    @Published var category: String
    /// Comma-separated in the UI, split into MenuItem.extras on save —
    /// same free-form convention as Restaurant's categories field.
    @Published var extrasText: String
    @Published var isAvailable: Bool

    @Published var pickedImageData: Data?

    @Published private(set) var isSaving = false
    @Published var errorMessage: String?

    private let restaurantId: String
    private let existingItem: MenuItem?
    private let menuRepository: MenuRepositoryProtocol
    private let cloudinaryService: CloudinaryServiceProtocol

    var existingImageURLString: String? { existingItem?.imageURL }
    var isEditing: Bool { existingItem != nil }

    init(
        restaurantId: String,
        existingItem: MenuItem?,
        menuRepository: MenuRepositoryProtocol,
        cloudinaryService: CloudinaryServiceProtocol
    ) {
        self.restaurantId = restaurantId
        self.existingItem = existingItem
        self.menuRepository = menuRepository
        self.cloudinaryService = cloudinaryService

        name = existingItem?.name ?? ""
        description = existingItem?.description ?? ""
        priceText = existingItem.map { String(format: "%.2f", $0.price) } ?? ""
        category = existingItem?.category ?? ""
        extrasText = existingItem?.extras.joined(separator: ", ") ?? ""
        isAvailable = existingItem?.isAvailable ?? true
    }

    var parsedPrice: Double? { Double(priceText) }

    var isValid: Bool {
        Validators.isNonEmpty(name)
            && Validators.isNonEmpty(category)
            && (parsedPrice ?? 0) > 0
    }

    private var parsedExtras: [String] {
        extrasText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    func save() async -> MenuItem? {
        guard isValid, let price = parsedPrice else {
            errorMessage = "Please fill in a name, category, and a price greater than 0."
            return nil
        }

        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        do {
            var imageURL = existingItem?.imageURL
            if let pickedImageData {
                imageURL = try await cloudinaryService.uploadImage(data: pickedImageData)
            }

            let toSave: MenuItem
            if var existing = existingItem {
                existing.name = name
                existing.description = description
                existing.price = price
                existing.category = category
                existing.extras = parsedExtras
                existing.imageURL = imageURL
                existing.isAvailable = isAvailable
                toSave = existing
                try await menuRepository.updateMenuItem(toSave)
            } else {
                var new = MenuItem.new(
                    id: UUID().uuidString,
                    restaurantId: restaurantId,
                    name: name,
                    description: description,
                    price: price,
                    category: category,
                    extras: parsedExtras
                )
                new.imageURL = imageURL
                new.isAvailable = isAvailable
                toSave = new
                try await menuRepository.createMenuItem(toSave)
            }

            return toSave
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
}
