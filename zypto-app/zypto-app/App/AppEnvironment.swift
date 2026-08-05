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
//  UPDATED IN PHASE 2: authService and firestoreService are now backed
//  by real Firebase implementations (AuthServiceFirebase, FirestoreServiceLive
//  — see Core/Services/), and userRepository is wired up. cloudinaryService
//  stays a stub until Phase 4.
//

import Foundation

final class AppEnvironment: ObservableObject {

    // MARK: - Services (thin wrappers around Firebase / Cloudinary SDKs)
    let authService: AuthServiceProtocol
    let firestoreService: FirestoreServiceProtocol
    let cloudinaryService: CloudinaryServiceProtocol

    // MARK: - Repositories (business-logic-facing data access)
    let userRepository: UserRepositoryProtocol

    // Uncomment and wire these up as each repository is implemented
    // in its corresponding phase:
    //
    // let restaurantRepository: RestaurantRepository
    // let menuRepository: MenuRepository
    // let cartRepository: CartRepository
    // let orderRepository: OrderRepository
    // let reviewRepository: ReviewRepository

    init(
        authService: AuthServiceProtocol = AuthServiceFirebase(),
        firestoreService: FirestoreServiceProtocol = FirestoreServiceLive(),
        cloudinaryService: CloudinaryServiceProtocol = CloudinaryServiceStub()
    ) {
        self.authService = authService
        self.firestoreService = firestoreService
        self.cloudinaryService = cloudinaryService
        self.userRepository = UserRepository(firestoreService: firestoreService)
    }
}

// MARK: - Protocols not yet implemented

// AuthServiceProtocol now lives in Core/Services/AuthService.swift
// FirestoreServiceProtocol now lives in Core/Services/FirestoreService.swift

/// Cloudinary image upload comes online in Phase 4; this stub keeps
/// AppEnvironment compiling until then.
protocol CloudinaryServiceProtocol {}
struct CloudinaryServiceStub: CloudinaryServiceProtocol {}
