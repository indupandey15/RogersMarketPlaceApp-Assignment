//
//  ListingDetailView.swift
//  RogersOfflineMarketPlace
//
//  Created by Indu Pandey on 31/08/26.
//
import SwiftUI

struct ListingDetailView: View {
    let listing: Listing
    @State private var showingEditView = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                CachedAsyncImage(urlString: listing.imageUrl, localImagePath: listing.localImagePath)
                    .frame(maxWidth: .infinity, minHeight: 300)
                    .clipped()
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(listing.title)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Spacer()
                        if listing.isPendingSync {
                            Label("Syncing...", systemImage: "icloud.and.arrow.up")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    Text("$\(listing.price, specifier: "%.2f")")
                        .font(.title2)
                        .foregroundColor(.green)
                    
                    Divider()
                    
                    Text("Description")
                        .font(.headline)
                    Text(listing.itemDescription)
                        .font(.body)
                }
                .padding()
            }
        }
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    showingEditView = true
                }
            }
        }
        .sheet(isPresented: $showingEditView) {
            NavigationStack {
                EditListingView(listing: listing)
            }
        }
    }
}
