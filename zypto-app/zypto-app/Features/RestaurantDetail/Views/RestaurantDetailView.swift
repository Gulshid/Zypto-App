//
//  RestaurantDetailView.swift
//  FoodDeliveryApp
//
//  New in Phase 4. Cover photo, restaurant info, and menu grouped by
//  category. Pushed from the home feed via NavigationLink.
//
//  Location in project: Features/RestaurantDetail/Views/RestaurantDetailView.swift
//
//  UPDATED IN PHASE 5: menu rows now add to CartViewModel (shared from
//  HomeView via .environmentObject). A floating "View Cart" bar appears
//  once the cart has items, and an alert confirms before replacing a
//  cart that belongs to a different restaurant.
//

import SwiftUI

struct RestaurantDetailView: View {
    @EnvironmentObject private var cartViewModel: CartViewModel
    @StateObject private var viewModel: RestaurantDetailViewModel
    private let cloudinaryService: CloudinaryServiceProtocol
    private let appEnvironment: AppEnvironment

    init(
        restaurant: Restaurant,
        uid: String,
        isFavorite: Bool,
        appEnvironment: AppEnvironment,
        onFavoriteChanged: ((String, Bool) -> Void)? = nil
    ) {
        self.cloudinaryService = appEnvironment.cloudinaryService
        self.appEnvironment = appEnvironment
        let model = RestaurantDetailViewModel(
            restaurant: restaurant,
            uid: uid,
            isFavorite: isFavorite,
            menuRepository: appEnvironment.menuRepository,
            favoritesRepository: appEnvironment.favoritesRepository
        )
        model.onFavoriteChanged = onFavoriteChanged
        _viewModel = StateObject(wrappedValue: model)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header
                info
                Divider().padding(.vertical, 8)
                menu
            }
            // Leaves room so the last menu item isn't hidden behind the
            // floating cart bar.
            .padding(.bottom, cartViewModel.itemCount > 0 ? 72 : 0)
        }
        .navigationTitle(viewModel.restaurant.name)
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.loadMenu() }
        .safeAreaInset(edge: .bottom) {
            if cartViewModel.itemCount > 0 {
                viewCartBar
            }
        }
        .alert(
            "Start a new cart?",
            isPresented: Binding(
                get: { cartViewModel.pendingReplacement != nil },
                set: { if !$0 { cartViewModel.cancelReplacement() } }
            )
        ) {
            Button("Cancel", role: .cancel) { cartViewModel.cancelReplacement() }
            Button("Start New Cart", role: .destructive) {
                Task { await cartViewModel.confirmReplacement() }
            }
        } message: {
            if let pending = cartViewModel.pendingReplacement {
                Text("Your cart has items from \(cartViewModel.restaurantName ?? "another restaurant"). Adding from \(pending.restaurantName) will clear it.")
            }
        }
    }

    private var header: some View {
        ZStack(alignment: .bottomTrailing) {
            CachedAsyncImage(
                url: cloudinaryService.optimizedURL(from: viewModel.restaurant.imageURL, width: 800)
            )
            .aspectRatio(16.0 / 9.0, contentMode: .fill)
            .frame(maxWidth: .infinity)
            .clipped()

            Button {
                Task { await viewModel.toggleFavorite() }
            } label: {
                Image(systemName: viewModel.isFavorite ? "heart.fill" : "heart")
                    .font(.headline)
                    .foregroundStyle(viewModel.isFavorite ? .red : .white)
                    .padding(10)
                    .background(.black.opacity(0.35), in: Circle())
            }
            .padding(12)
        }
    }

    private var info: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(viewModel.restaurant.name)
                .font(.title2.bold())

            if !viewModel.restaurant.description.isEmpty {
                Text(viewModel.restaurant.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 4) {
                Image(systemName: "star.fill").foregroundStyle(.orange)
                Text(viewModel.restaurant.reviewCount > 0
                     ? String(format: "%.1f", viewModel.restaurant.averageRating)
                     : "New")
                    .bold()
                Text("(\(viewModel.restaurant.reviewCount) reviews)")
                    .foregroundStyle(.secondary)
                Spacer()
                if !viewModel.restaurant.isOpen {
                    Text("Closed").font(.caption.bold()).foregroundStyle(.red)
                }
            }
            .font(.subheadline)

            Label(viewModel.restaurant.address, systemImage: "mappin.and.ellipse")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
    }

    @ViewBuilder
    private var menu: some View {
        if viewModel.isLoading {
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(.top, 24)
        } else if let errorMessage = viewModel.errorMessage {
            Text(errorMessage)
                .foregroundStyle(.red)
                .padding()
        } else if viewModel.menuItems.isEmpty {
            Text("This restaurant hasn't added any menu items yet.")
                .foregroundStyle(.secondary)
                .padding()
        } else {
            VStack(alignment: .leading, spacing: 16) {
                ForEach(viewModel.menuSections, id: \.category) { section in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(section.category)
                            .font(.headline)
                            .padding(.horizontal)

                        ForEach(section.items) { item in
                            MenuItemRowView(
                                item: item,
                                cloudinaryService: cloudinaryService,
                                onAdd: { quantity, extras, note in
                                    Task {
                                        await cartViewModel.addToCart(
                                            menuItem: item,
                                            restaurantName: viewModel.restaurant.name,
                                            quantity: quantity,
                                            selectedExtras: extras,
                                            note: note
                                        )
                                    }
                                }
                            )
                            .padding(.horizontal)
                            Divider().padding(.leading)
                        }
                    }
                }
            }
            .padding(.bottom, 24)
        }
    }

    private var viewCartBar: some View {
        NavigationLink {
            CartView(cartViewModel: cartViewModel, appEnvironment: appEnvironment)
        } label: {
            HStack {
                Image(systemName: "bag.fill")
                Text("View Cart · \(cartViewModel.itemCount) item\(cartViewModel.itemCount == 1 ? "" : "s")")
                    .font(.subheadline.bold())
                Spacer()
                Text(cartViewModel.subtotal, format: .currency(code: "USD"))
                    .font(.subheadline.bold())
            }
            .padding()
            .background(Color.orange)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
    }
}
