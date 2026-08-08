//
//  MenuManagementView.swift
//  FoodDeliveryApp
//
//  New in Phase 7. The dashboard's Menu tab. Shows every item for the
//  owner's restaurant grouped by category (including ones toggled
//  unavailable, unlike the customer-facing RestaurantDetailView), with
//  swipe-to-delete, an inline availability toggle, and tap-to-edit.
//
//  Location in project: Features/Dashboard/Views/MenuManagementView.swift
//
//  UPDATED IN PHASE 10: the loading state now shows a handful of
//  shimmering skeleton rows (matching this screen's own 48x48-thumbnail
//  row layout, via the local MenuManagementRowSkeleton below — the
//  shared MenuItemRowSkeleton in Features/Shared/Views/SkeletonView.swift
//  is sized for the customer-facing 72x72 row instead) rather than a
//  single centered ProgressView, and the empty state now uses the
//  shared EmptyStateView.
//

import SwiftUI

struct MenuManagementView: View {
    @StateObject private var viewModel: MenuManagementViewModel
    private let appEnvironment: AppEnvironment
    private let restaurantId: String

    @State private var isPresentingNewItem = false
    @State private var editingItem: MenuItem?

    init(restaurantId: String, appEnvironment: AppEnvironment) {
        self.restaurantId = restaurantId
        self.appEnvironment = appEnvironment
        _viewModel = StateObject(wrappedValue: MenuManagementViewModel(
            restaurantId: restaurantId,
            menuRepository: appEnvironment.menuRepository
        ))
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Menu")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            isPresentingNewItem = true
                        } label: {
                            Image(systemName: "plus")
                        }
                        .accessibilityLabel("Add menu item")
                    }
                }
                .task { await viewModel.loadMenu() }
                .refreshable { await viewModel.loadMenu() }
                .sheet(isPresented: $isPresentingNewItem) {
                    MenuItemFormView(restaurantId: restaurantId, existingItem: nil, appEnvironment: appEnvironment) { saved in
                        viewModel.applyUpsertedItem(saved)
                    }
                }
                .sheet(item: $editingItem) { item in
                    MenuItemFormView(restaurantId: restaurantId, existingItem: item, appEnvironment: appEnvironment) { saved in
                        viewModel.applyUpsertedItem(saved)
                    }
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.menuItems.isEmpty {
            List {
                ForEach(0..<6, id: \.self) { _ in MenuManagementRowSkeleton() }
            }
            .listStyle(.insetGrouped)
        } else if viewModel.menuItems.isEmpty {
            EmptyStateView(
                systemImage: "fork.knife.circle",
                title: "No menu items yet",
                actionTitle: "Add Your First Item",
                action: { isPresentingNewItem = true }
            )
        } else {
            List {
                ForEach(viewModel.menuSections, id: \.category) { section in
                    Section(section.category) {
                        ForEach(section.items) { item in
                            MenuManagementRowView(
                                item: item,
                                cloudinaryService: appEnvironment.cloudinaryService,
                                onToggleAvailability: {
                                    Haptics.tap()
                                    Task { await viewModel.toggleAvailability(item) }
                                }
                            )
                            .contentShape(Rectangle())
                            .onTapGesture { editingItem = item }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    Haptics.warning()
                                    Task { await viewModel.delete(item) }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
    }
}

/// A single row in MenuManagementView's list — thumbnail, name, price,
/// category, and an inline availability toggle.
private struct MenuManagementRowView: View {
    let item: MenuItem
    let cloudinaryService: CloudinaryServiceProtocol
    let onToggleAvailability: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            CachedAsyncImage(url: cloudinaryService.optimizedURL(from: item.imageURL, width: 160))
                .aspectRatio(1, contentMode: .fill)
                .frame(width: 48, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.subheadline.bold())
                    .foregroundStyle(item.isAvailable ? .primary : .secondary)
                Text(item.price, format: .currency(code: "USD"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Toggle(
                "\(item.name) available",
                isOn: Binding(get: { item.isAvailable }, set: { _ in onToggleAvailability() })
            )
            .labelsHidden()
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}

/// New in Phase 10. Mirrors MenuManagementRowView's exact layout (48x48
/// thumbnail + two text lines + trailing toggle) so the loading state
/// doesn't jump around once the real rows arrive.
private struct MenuManagementRowSkeleton: View {
    var body: some View {
        HStack(spacing: 12) {
            SkeletonBox(cornerRadius: 8)
                .frame(width: 48, height: 48)
            VStack(alignment: .leading, spacing: 6) {
                SkeletonBox().frame(width: 120, height: 14)
                SkeletonBox().frame(width: 50, height: 12)
            }
            Spacer()
            SkeletonBox(cornerRadius: 10)
                .frame(width: 40, height: 22)
        }
        .padding(.vertical, 4)
        .accessibilityHidden(true)
    }
}
