//
//  EditListingView.swift
//  RogersOfflineMarketPlace
//
//  Created by Indu Pandey on 31/08/26.
//
import SwiftUI
import SwiftData
import PhotosUI

struct EditListingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    var listing: Listing?
    
    @State private var title: String = ""
    @State private var priceString: String = ""
    @State private var itemDescription: String = ""
    @State private var image: UIImage? = nil
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    
    var body: some View {
        Form {
            Section(header: Text("Image")) {
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                } else if let listing = listing {
                    CachedAsyncImage(urlString: listing.imageUrl, localImagePath: listing.localImagePath)
                        .frame(height: 200)
                }
                
                PhotosPicker("Select Photo", selection: $selectedPhotoItem, matching: .images)
                    .onChange(of: selectedPhotoItem) { oldValue, newValue in
                        // 1: detached so image decoding never touches the main thread
                        Task.detached(priority: .userInitiated) {
                            guard let data = try? await newValue?.loadTransferable(type: Data.self),
                                  let rawImage = UIImage(data: data) else { return }
                            // 2: downsample BEFORE jumping to main thread
                            let thumbnail = await rawImage.byPreparingThumbnail(ofSize: CGSize(width: 600, height: 600))
                            await MainActor.run {
                                self.image = thumbnail ?? rawImage
                            }
                        }
                    }
            }
            
            Section(header: Text("Details")) {
                TextField("Title", text: $title)
                TextField("Price", text: $priceString)
                    .keyboardType(.decimalPad)
                TextEditor(text: $itemDescription)
                    .frame(height: 100)
            }
        }
        .navigationTitle(listing == nil ? "New Listing" : "Edit Listing")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") { save() }
                    .disabled(title.isEmpty || priceString.isEmpty)
            }
        }
        .onAppear {
            if let listing = listing {
                title = listing.title
                priceString = String(format: "%.2f", listing.price)
                itemDescription = listing.itemDescription
            }
        }
    }
    
    private func save() {
        guard let price = Double(priceString) else { return }
        
        var localPath: String? = listing?.localImagePath
        
        if let image = image {
            let key = UUID().uuidString
            Task {
                await ImageCache.shared.insertImage(image, for: key)
            }
            localPath = key
        }
        
        if let listing = listing {
            listing.title = title
            listing.price = price
            listing.itemDescription = itemDescription
            if let localPath = localPath {
                listing.localImagePath = localPath
            }
            listing.updatedAt = Date()
            listing.isPendingSync = true
        } else {
            let newListing = Listing(
                title: title,
                itemDescription: itemDescription,
                price: price,
                localImagePath: localPath,
                isPendingSync: true
            )
            modelContext.insert(newListing)
        }
        
        try? modelContext.save()
        
        let container = modelContext.container
        Task {
            let engine = SyncEngine(modelContainer: container)
            await engine.syncPendingListings()
        }
        
        dismiss()
    }
}

