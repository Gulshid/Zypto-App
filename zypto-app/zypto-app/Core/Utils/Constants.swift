//
//  Constants.swift
//  FoodDeliveryApp
//
//  Central place for config values, collection names, and app-wide
//  constants — avoids magic strings scattered across the codebase.
//
//  Location in project: Core/Utils/Constants.swift
//
//  UPDATED IN PHASE 3: menuItems is a subcollection under each restaurant
//  document (restaurants/{restaurantId}/menuItems), not a top-level
//  collection — added Collections.menuItemsPath(restaurantId:) so
//  repositories never hand-build that string themselves.
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

        /// Path to a given restaurant's menuItems subcollection, e.g.
        /// "restaurants/abc123/menuItems". Use this instead of concatenating
        /// `restaurants` + id + `menuItems` by hand at call sites.
        static func menuItemsPath(restaurantId: String) -> String {
            "\(restaurants)/\(restaurantId)/\(menuItems)"
        }
    }

    // MARK: - Order Status Values
    // String-based status matching the `status` field in Firestore's
    // `orders` collection (see docs/02_Firestore_Schema.md)
    enum OrderStatus {
        static let pending = "pending"
        static let confirmed = "confirmed"
        static let preparing = "preparing"
        static let outForDelivery = "out_for_delivery"
        static let delivered = "delivered"
        static let cancelled = "cancelled"

        /// Display order for status-tracker UIs (Phase 6/7)
        static let ordered: [String] = [pending, confirmed, preparing, outForDelivery, delivered]
    }

    // MARK: - User Roles
    enum UserRole {
        static let customer = "customer"
        static let restaurantOwner = "restaurant_owner"
    }
}
