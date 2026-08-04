//
//  Constants.swift
//  FoodDeliveryApp
//
//  Central place for config values, collection names, and app-wide
//  constants — avoids magic strings scattered across the codebase.
//
//  Location in project: Core/Utils/Constants.swift
//

import Foundation

enum Constants {

    // MARK: - Cloudinary
    // Fill these in with the values from your Cloudinary dashboard
    // (see Phase 1 setup steps: Settings → Upload → Upload presets)
    enum Cloudinary {
        static let cloudName = "df0saqabg"
        static let uploadPreset = "zypto_unsigned"

        static var uploadURL: URL {
            URL(string: "https://api.cloudinary.com/v1_1/\(cloudName)/image/upload")!
        }
    }

    // MARK: - Firestore Collection Names
    // Centralizing these avoids typos like "resturants" breaking a query silently
    enum Collections {
        static let users = "users"
        static let restaurants = "restaurants"
        static let menuItems = "menuItems" // subcollection under restaurants
        static let carts = "carts"
        static let orders = "orders"
        static let reviews = "reviews"
    }

    // MARK: - Order Status Values
    // String-based status matching the `status` field in Firestore's
    // `orders` collection (see 02_Firestore_Schema.md)
    enum OrderStatus {
        static let pending = "pending"
        static let confirmed = "confirmed"
        static let preparing = "preparing"
        static let outForDelivery = "out_for_delivery"
        static let delivered = "delivered"
        static let cancelled = "cancelled"
    }

    // MARK: - User Roles
    enum UserRole {
        static let customer = "customer"
        static let restaurantOwner = "restaurant_owner"
    }
}
