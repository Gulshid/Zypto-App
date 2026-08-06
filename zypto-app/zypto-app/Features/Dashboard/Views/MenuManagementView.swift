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
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if viewModel.menuItems.isEmpty {
            emptyState
        } else {
            List {
                ForEach(viewModel.menuSections, id: \.category) { section in
                    Section(section.category) {
                        ForEach(section.items) { item in
                            MenuManagementRowView(
                                item: item,
                                cloudinaryService: appEnvironment.cloudinaryService,
                                onToggleAvailability: { Task { await viewModel.toggleAvailability(item) } }
                            )
                            .contentShape(Rectangle())
                            .onTapGesture { editingItem = item }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
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

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "fork.knife.circle")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text("No menu items yet")
                .foregroundStyle(.secondary)
            Button {
                isPresentingNewItem = true
            } label: {
                Text("Add Your First Item")
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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

            Toggle("", isOn: Binding(get: { item.isAvailable }, set: { _ in onToggleAvailability() }))
                .labelsHidden()
        }
        .padding(.vertical, 4)
    }
}
