//
//  MainTabView.swift
//  FoodDeliveryApp
//
//  The Customer's bottom tab bar: Home, Orders, Favorites, Account.
//  Replaces the old arrangement where HomeView was pushed directly
//  from RootView and Orders/Sign-Out were buried in its toolbar (see
//  App/FoodDeliveryApp.swift).
//
//  This view — not HomeView — now owns CartViewModel and
//  OrderHistoryViewModel, since both need to live for as long as the
//  Customer is anywhere in the app (the order-status listener drives
//  toasts/badges from any tab, and the cart has to survive switching
//  away from Home and back). They're injected down as environment
//  objects / explicit params so every tab sees the same instances.
//
//  Location in project: Features/Home/Views/MainTabView.swift
//

import SwiftUI

struct MainTabView: View {
    @StateObject private var cartViewModel: CartViewModel
    @StateObject private var orderHistoryViewModel: OrderHistoryViewModel

    private let currentUser: AppUser
    private let appEnvironment: AppEnvironment

    init(currentUser: AppUser, appEnvironment: AppEnvironment) {
        self.currentUser = currentUser
        self.appEnvironment = appEnvironment
        _cartViewModel = StateObject(wrappedValue: CartViewModel(
            uid: currentUser.id,
            cartRepository: appEnvironment.cartRepository,
            restaurantRepository: appEnvironment.restaurantRepository
        ))
        _orderHistoryViewModel = StateObject(wrappedValue: OrderHistoryViewModel(
            uid: currentUser.id,
            orderRepository: appEnvironment.orderRepository,
            notificationService: appEnvironment.notificationService,
            toastCenter: appEnvironment.toastCenter
        ))
    }

    var body: some View {
        TabView {
            HomeView(
                currentUser: currentUser,
                appEnvironment: appEnvironment,
                cartViewModel: cartViewModel
            )
            .tabItem { Label("Home", systemImage: "house.fill") }

            NavigationStack {
                OrderHistoryView(viewModel: orderHistoryViewModel, orderRepository: appEnvironment.orderRepository)
            }
            .badge(orderHistoryViewModel.activeOrderCount)
            .tabItem { Label("Orders", systemImage: "receipt.fill") }

            NavigationStack {
                FavoritesView(currentUser: currentUser, appEnvironment: appEnvironment)
            }
            .tabItem { Label("Favorites", systemImage: "heart.fill") }

            NavigationStack {
                AccountView(currentUser: currentUser)
            }
            .tabItem { Label("Account", systemImage: "person.crop.circle.fill") }
        }
        .tint(.orange)
        .environmentObject(cartViewModel)
        .task { await cartViewModel.loadCart() }
        // Never returns (a live Firestore listener) — its own task so
        // it doesn't block the cart load above.
        .task { await orderHistoryViewModel.listen() }
    }
}
