//
//  RestaurantDetailView.swift
//  FoodDeliveryApp
//
//  New in Phase 4. Cover photo, restaurant info, and menu grouped by
//  category. Pushed from the home feed via NavigationLink.
//
//  Location in project: Features/RestaurantDetail/Views/RestaurantDetailView.swift
//

import SwiftUI

struct RestaurantDetailView: View {
    @StateObject private var viewModel: RestaurantDetailViewModel
    private let cloudinaryService: CloudinaryServiceProtocol

    init(
        restaurant: Restaurant,
        uid: String,
        isFavorite: Bool,
        appEnvironment: AppEnvironment,
        onFavoriteChanged: ((String, Bool) -> Void)? = nil
    ) {
        self.cloudinaryService = appEnvironment.cloudinaryService
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
        }
        .navigationTitle(viewModel.restaurant.name)
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.loadMenu() }
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
                            MenuItemRowView(item: item, cloudinaryService: cloudinaryService)
                                .padding(.horizontal)
                            Divider().padding(.leading)
                        }
                    }
                }
            }
            .padding(.bottom, 24)
        }
    }
}
