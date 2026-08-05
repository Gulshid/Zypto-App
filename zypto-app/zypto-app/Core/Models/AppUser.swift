//
//  AppUser.swift
//  FoodDeliveryApp
//
//  App-level user profile, stored as a document in the Firestore
//  `users` collection (one doc per Firebase Auth uid). This is
//  separate from FirebaseAuth.User — that type only knows about
//  auth credentials, this one knows about our app's data (role, name).
//
//  Location in project: Core/Models/AppUser.swift
//

import Foundation

struct AppUser: Codable, Identifiable, Equatable {
    /// Matches the Firebase Auth uid — used as the Firestore document ID too.
    var id: String
    var email: String
    var fullName: String
    /// One of Constants.UserRole (customer / restaurant_owner)
    var role: String
    var createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, email, fullName, role, createdAt
    }
}

extension AppUser {
    var isCustomer: Bool { role == Constants.UserRole.customer }
    var isRestaurantOwner: Bool { role == Constants.UserRole.restaurantOwner }
}
