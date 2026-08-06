//
//  ImagePickerButton.swift
//  FoodDeliveryApp
//
//  New in Phase 7. A tappable photo preview backed by PhotosUI's
//  PhotosPicker (iOS 16+, no third-party dependency needed). Used by
//  the Restaurant Owner dashboard wherever a cover/menu-item photo can
//  be picked and uploaded to Cloudinary — RestaurantProfileView and
//  MenuItemFormView.
//
//  Deliberately dumb: it only knows how to let the user pick a photo
//  and hand back the resulting JPEG Data. Uploading that Data to
//  Cloudinary (and knowing the existing imageURL to show while nothing
//  new has been picked) is the caller's job — this view has no
//  dependency on CloudinaryService itself, so it stays trivial to preview.
//
//  Location in project: Features/Shared/Views/ImagePickerButton.swift
//

import SwiftUI
import PhotosUI

struct ImagePickerButton: View {
    /// Existing remote photo (e.g. Restaurant.imageURL), shown until the
    /// user picks a replacement. Pass the already-optimized URL.
    let existingImageURL: URL?
    /// JPEG data of the newly-picked photo, if any. Set by this view;
    /// the caller reads it to know a new upload is pending on save.
    @Binding var pickedImageData: Data?

    @State private var selection: PhotosPickerItem?
    @State private var isLoadingSelection = false

    var body: some View {
        PhotosPicker(selection: $selection, matching: .images) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.secondarySystemBackground))

                if let pickedImageData, let uiImage = UIImage(data: pickedImageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else if let existingImageURL {
                    CachedAsyncImage(url: existingImageURL)
                        .aspectRatio(contentMode: .fill)
                } else {
                    VStack(spacing: 6) {
                        Image(systemName: "camera.fill")
                            .font(.title2)
                        Text("Add Photo")
                            .font(.caption.bold())
                    }
                    .foregroundStyle(.secondary)
                }

                if isLoadingSelection {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(.black.opacity(0.25))
                }
            }
            .frame(height: 160)
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(alignment: .bottomTrailing) {
                Image(systemName: "pencil.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.white, .orange)
                    .padding(8)
            }
        }
        .buttonStyle(.plain)
        .onChange(of: selection) { _, newValue in
            guard let newValue else { return }
            Task { await loadImage(from: newValue) }
        }
    }

    @MainActor
    private func loadImage(from item: PhotosPickerItem) async {
        isLoadingSelection = true
        defer { isLoadingSelection = false }

        // Load as Data (not Image/UIImage directly via loadTransferable)
        // and re-encode through UIImage.jpegData so HEIC photos from the
        // library still upload as a JPEG Cloudinary/most viewers expect.
        guard let data = try? await item.loadTransferable(type: Data.self),
              let uiImage = UIImage(data: data),
              let jpegData = uiImage.jpegData(compressionQuality: 0.8) else {
            return
        }
        pickedImageData = jpegData
    }
}

#Preview {
    ImagePickerButton(existingImageURL: nil, pickedImageData: .constant(nil))
        .padding()
}
