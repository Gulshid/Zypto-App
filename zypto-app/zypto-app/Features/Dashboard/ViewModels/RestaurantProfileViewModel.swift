//
//  RestaurantProfileViewModel.swift
//  FoodDeliveryApp
//
//  New in Phase 7. Backs RestaurantProfileView for both flows it
//  supports: setting up a brand-new restaurant (Restaurant.new(...))
//  the first time a Restaurant Owner opens the dashboard, and editing
//  an existing one's info/cover photo afterward. Same form, same view
//  model — `existingRestaurant == nil` is the only thing that changes
//  which Firestore call save() makes at the end.
//
//  Location in project: Features/Dashboard/ViewModels/RestaurantProfileViewModel.swift
//

import Foundation

@MainActor
final class RestaurantProfileViewModel: ObservableObject {

    @Published var name: String
    @Published var description: String
    @Published var address: String
    /// Comma-separated in the UI (matches the free-form style already
    /// used for MenuItem.extras input) — split into Restaurant.categories on save.
    @Published var categoriesText: String
    @Published var isOpen: Bool

    /// Newly-picked cover photo bytes, set by ImagePickerButton. Nil
    /// means "keep whatever photo (if any) is already saved."
    @Published var pickedImageData: Data?

    @Published private(set) var isSaving = false
    @Published var errorMessage: String?

    private let ownerId: String
    private let existingRestaurant: Restaurant?
    private let restaurantRepository: RestaurantRepositoryProtocol
    private let cloudinaryService: CloudinaryServiceProtocol

    var existingImageURLString: String? { existingRestaurant?.imageURL }
    var isEditing: Bool { existingRestaurant != nil }

    init(
        ownerId: String,
        existingRestaurant: Restaurant?,
        restaurantRepository: RestaurantRepositoryProtocol,
        cloudinaryService: CloudinaryServiceProtocol
    ) {
        self.ownerId = ownerId
        self.existingRestaurant = existingRestaurant
        self.restaurantRepository = restaurantRepository
        self.cloudinaryService = cloudinaryService

        name = existingRestaurant?.name ?? ""
        description = existingRestaurant?.description ?? ""
        address = existingRestaurant?.address ?? ""
        categoriesText = existingRestaurant?.categories.joined(separator: ", ") ?? ""
        isOpen = existingRestaurant?.isOpen ?? true
    }

    var isValid: Bool {
        Validators.isNonEmpty(name) && Validators.isNonEmpty(address) && !parsedCategories.isEmpty
    }

    private var parsedCategories: [String] {
        categoriesText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    /// Creates or updates the restaurant, uploading a newly-picked photo
    /// first if there is one. Returns the saved Restaurant on success so
    /// the caller (DashboardView) can adopt it without a re-fetch.
    func save() async -> Restaurant? {
        guard isValid else {
            errorMessage = "Please fill in a name, address, and at least one category."
            return nil
        }

        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        do {
            var imageURL = existingRestaurant?.imageURL
            if let pickedImageData {
                imageURL = try await cloudinaryService.uploadImage(data: pickedImageData)
            }

            let toSave: Restaurant
            if var existing = existingRestaurant {
                existing.name = name
                existing.description = description
                existing.address = address
                existing.categories = parsedCategories
                existing.imageURL = imageURL
                existing.isOpen = isOpen
                toSave = existing
                try await restaurantRepository.updateRestaurant(toSave)
            } else {
                var new = Restaurant.new(
                    id: UUID().uuidString,
                    ownerId: ownerId,
                    name: name,
                    description: description,
                    address: address,
                    categories: parsedCategories
                )
                new.imageURL = imageURL
                new.isOpen = isOpen
                toSave = new
                try await restaurantRepository.createRestaurant(toSave)
            }

            return toSave
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
}
