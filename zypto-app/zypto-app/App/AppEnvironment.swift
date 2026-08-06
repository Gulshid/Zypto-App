//
//  AppEnvironment.swift
//  FoodDeliveryApp
//
//  Lightweight dependency-injection container. Holds shared service and
//  repository instances so ViewModels never talk to Firebase/Cloudinary
//  SDKs directly — they go through repositories, which are easy to mock
//  in unit tests later (Phase 11).
//
//  Location in project: App/AppEnvironment.swift
//
//  UPDATED IN PHASE 4: cloudinaryService is now backed by a real
//  implementation (CloudinaryServiceLive, see Core/Services/) instead
//  of the Phase 2 stub. Wired up restaurantRepository, menuRepository,
//  and favoritesRepository for the Phase 4 browsing feature.
//
//  UPDATED IN PHASE 5: wired up cartRepository and orderRepository for
//  the Cart & Checkout flow.
//

import Foundation

final class AppEnvironment: ObservableObject {

    // MARK: - Services (thin wrappers around Firebase / Cloudinary SDKs)
    let authService: AuthServiceProtocol
    let firestoreService: FirestoreServiceProtocol
    let cloudinaryService: CloudinaryServiceProtocol

    // MARK: - Repositories (business-logic-facing data access)
    let userRepository: UserRepositoryProtocol
    let restaurantRepository: RestaurantRepositoryProtocol
    let menuRepository: MenuRepositoryProtocol
    let favoritesRepository: FavoritesRepositoryProtocol
    let cartRepository: CartRepositoryProtocol
    let orderRepository: OrderRepositoryProtocol

    // Uncomment and wire this up once Phase 9 lands:
    //
    // let reviewRepository: ReviewRepository

    init(
        authService: AuthServiceProtocol = AuthServiceFirebase(),
        firestoreService: FirestoreServiceProtocol = FirestoreServiceLive(),
        cloudinaryService: CloudinaryServiceProtocol = CloudinaryServiceLive()
    ) {
        self.authService = authService
        self.firestoreService = firestoreService
        self.cloudinaryService = cloudinaryService
        self.userRepository = UserRepository(firestoreService: firestoreService)
        self.restaurantRepository = RestaurantRepository(firestoreService: firestoreService)
        self.menuRepository = MenuRepository(firestoreService: firestoreService)
        self.favoritesRepository = FavoritesRepository(firestoreService: firestoreService)
        self.cartRepository = CartRepository(firestoreService: firestoreService)
        self.orderRepository = OrderRepository(firestoreService: firestoreService)
    }
}

// MARK: - Protocols not yet implemented

// AuthServiceProtocol now lives in Core/Services/AuthService.swift
// FirestoreServiceProtocol now lives in Core/Services/FirestoreService.swift
// CloudinaryServiceProtocol now lives in Core/Services/CloudinaryService.swift
// (upload support arrives in Phase 7 — Phase 4 only needs read-side URL building)
