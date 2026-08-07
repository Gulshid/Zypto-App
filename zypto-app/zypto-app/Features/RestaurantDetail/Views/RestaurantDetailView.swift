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
//  UPDATED IN PHASE 9:
//   - Menu search bar + category/price filter chips (RestaurantDetailViewModel
//     now filters `menuItems` client-side; see that file). A plain
//     TextField is used instead of `.searchable` because this view is
//     pushed inside HomeView's NavigationStack, which already owns a
//     `.searchable` for restaurant search — a pushed view can't attach
//     a second one.
//   - Ratings & Reviews section: average rating + a short preview of
//     recent reviews, a "See all N reviews" link to AllReviewsView, and
//     a "Write a Review" button (hidden once the signed-in customer has
//     already reviewed this restaurant) that presents WriteReviewView.
//     Backed by the new ReviewsViewModel, owned here the same way
//     RestaurantDetailViewModel owns the menu.
//   - init now takes the full `currentUser: AppUser` (was just `uid:`)
//     since ReviewsViewModel needs the customer's display name to
//     denormalize onto new Review documents.
//

import SwiftUI

struct RestaurantDetailView: View {
    @EnvironmentObject private var cartViewModel: CartViewModel
    @StateObject private var viewModel: RestaurantDetailViewModel
    @StateObject private var reviewsViewModel: ReviewsViewModel
    private let cloudinaryService: CloudinaryServiceProtocol
    private let appEnvironment: AppEnvironment

    @State private var showingWriteReview = false

    init(
        restaurant: Restaurant,
        currentUser: AppUser,
        isFavorite: Bool,
        appEnvironment: AppEnvironment,
        onFavoriteChanged: ((String, Bool) -> Void)? = nil
    ) {
        self.cloudinaryService = appEnvironment.cloudinaryService
        self.appEnvironment = appEnvironment
        let model = RestaurantDetailViewModel(
            restaurant: restaurant,
            uid: currentUser.id,
            isFavorite: isFavorite,
            menuRepository: appEnvironment.menuRepository,
            favoritesRepository: appEnvironment.favoritesRepository
        )
        model.onFavoriteChanged = onFavoriteChanged
        _viewModel = StateObject(wrappedValue: model)
        _reviewsViewModel = StateObject(wrappedValue: ReviewsViewModel(
            restaurantId: restaurant.id,
            uid: currentUser.id,
            customerName: currentUser.fullName,
            reviewRepository: appEnvironment.reviewRepository
        ))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header
                info
                Divider().padding(.vertical, 8)
                menuSearchAndFilters
                menu
                Divider().padding(.vertical, 8)
                reviewsSection
            }
            // Leaves room so the last section isn't hidden behind the
            // floating cart bar.
            .padding(.bottom, cartViewModel.itemCount > 0 ? 72 : 0)
        }
        .navigationTitle(viewModel.restaurant.name)
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.loadMenu() }
        .task { await reviewsViewModel.loadReviews() }
        .onAppear {
            reviewsViewModel.onAggregateChanged = { average, count in
                viewModel.applyAggregateChange(averageRating: average, reviewCount: count)
            }
        }
        .safeAreaInset(edge: .bottom) {
            if cartViewModel.itemCount > 0 {
                viewCartBar
            }
        }
        .sheet(isPresented: $showingWriteReview) {
            WriteReviewView(viewModel: reviewsViewModel, restaurantName: viewModel.restaurant.name)
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
                Text(viewModel.reviewCount > 0
                     ? String(format: "%.1f", viewModel.averageRating)
                     : "New")
                    .bold()
                Text("(\(viewModel.reviewCount) reviews)")
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

    // MARK: - Phase 9: menu search + filters

    private var menuSearchAndFilters: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search this menu", text: $viewModel.searchText)
                    .textFieldStyle(.plain)
                if !viewModel.searchText.isEmpty {
                    Button {
                        viewModel.searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(10)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal)

            if !viewModel.availableCategories.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.availableCategories, id: \.self) { category in
                            filterChip(
                                title: category,
                                isSelected: viewModel.selectedCategory == category
                            ) {
                                viewModel.selectCategory(category)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(PriceFilter.allCases) { tier in
                        filterChip(
                            title: tier.label,
                            isSelected: viewModel.selectedPriceFilter == tier
                        ) {
                            viewModel.selectedPriceFilter = tier
                        }
                    }
                }
                .padding(.horizontal)
            }

            if viewModel.isFiltering {
                Button("Clear Filters") {
                    viewModel.clearFilters()
                }
                .font(.footnote.bold())
                .padding(.horizontal)
            }
        }
        .padding(.bottom, 8)
    }

    private func filterChip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.bold())
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? Color.orange : Color(.secondarySystemBackground))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
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
        } else if viewModel.filteredMenuItems.isEmpty {
            VStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 32))
                    .foregroundStyle(.secondary)
                Text("No menu items match your filters")
                    .foregroundStyle(.secondary)
                Button("Clear Filters") { viewModel.clearFilters() }
                    .font(.subheadline.bold())
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
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

    // MARK: - Phase 9: reviews

    private var reviewsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Ratings & Reviews")
                    .font(.headline)
                Spacer()
                if !reviewsViewModel.hasReviewed {
                    Button("Write a Review") {
                        showingWriteReview = true
                    }
                    .font(.subheadline.bold())
                }
            }
            .padding(.horizontal)

            HStack(spacing: 8) {
                StarRatingView(rating: viewModel.averageRating, font: .subheadline)
                Text(viewModel.reviewCount > 0
                     ? String(format: "%.1f · %d review%@", viewModel.averageRating, viewModel.reviewCount, viewModel.reviewCount == 1 ? "" : "s")
                     : "No reviews yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)

            if reviewsViewModel.isLoading && reviewsViewModel.reviews.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            } else if reviewsViewModel.reviews.isEmpty {
                Text("Be the first to review this restaurant.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(reviewsViewModel.reviews.prefix(3)) { review in
                        ReviewRowView(review: review)
                            .padding(.horizontal)
                        Divider().padding(.leading)
                    }
                }

                if reviewsViewModel.reviews.count > 3 {
                    NavigationLink {
                        AllReviewsView(restaurantName: viewModel.restaurant.name, viewModel: reviewsViewModel)
                    } label: {
                        Text("See all \(reviewsViewModel.reviews.count) reviews")
                            .font(.subheadline.bold())
                    }
                    .padding(.horizontal)
                }
            }

            if let errorMessage = reviewsViewModel.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .padding(.horizontal)
            }
        }
        .padding(.bottom, 24)
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
