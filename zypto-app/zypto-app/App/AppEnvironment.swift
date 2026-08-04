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
//  NOTE: Service and Repository types referenced below (AuthService,
//  FirestoreService, CloudinaryService, UserRepository, etc.) are stubs
//  for now — they'll be implemented in Phase 2 and Phase 4 onward.
//  This file is included in Phase 1 purely to establish the DI pattern
//  and folder wiring early, so later phases just "fill in" each service.
//

import Foundation

final class AppEnvironment: ObservableObject {

    // MARK: - Services (thin wrappers around Firebase / Cloudinary SDKs)
    let authService: AuthServiceProtocol
    let firestoreService: FirestoreServiceProtocol
    let cloudinaryService: CloudinaryServiceProtocol

    // MARK: - Repositories (business-logic-facing data access)
    // Uncomment and wire these up as each repository is implemented
    // in its corresponding phase:
    //
    // let userRepository: UserRepository
    // let restaurantRepository: RestaurantRepository
    // let menuRepository: MenuRepository
    // let cartRepository: CartRepository
    // let orderRepository: OrderRepository
    // let reviewRepository: ReviewRepository

    init(
        authService: AuthServiceProtocol = AuthServiceStub(),
        firestoreService: FirestoreServiceProtocol = FirestoreServiceStub(),
        cloudinaryService: CloudinaryServiceProtocol = CloudinaryServiceStub()
    ) {
        self.authService = authService
        self.firestoreService = firestoreService
        self.cloudinaryService = cloudinaryService
    }
}

// MARK: - Protocols (defined now so ViewModels can be built against
// an interface, not a concrete Firebase type — makes unit testing possible)

protocol AuthServiceProtocol {}
protocol FirestoreServiceProtocol {}
protocol CloudinaryServiceProtocol {}

// MARK: - Temporary stub implementations
// These will be replaced with real Firebase/Cloudinary-backed
// implementations in Phase 2 (Auth) and Phase 4 (data + media).

struct AuthServiceStub: AuthServiceProtocol {}
struct FirestoreServiceStub: FirestoreServiceProtocol {}
struct CloudinaryServiceStub: CloudinaryServiceProtocol {}
