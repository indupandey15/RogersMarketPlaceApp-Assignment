//
//  ListingListView.swift
//  RogersOfflineMarketPlace
//
//  Created by Indu Pandey on 31/08/26.
//

import SwiftUI
import SwiftData

struct ListingListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Listing.updatedAt, order: .reverse) private var listings: [Listing]
    
    @StateObject private var viewModel = ListingListViewModel()
    @State private var showingEditView = false
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(listings) { listing in
                    NavigationLink(destination: ListingDetailView(listing: listing)) {
                        ListingRowView(listing: listing)
                    }
                }
            }
            .navigationTitle("Rogers Market place")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingEditView = true }) {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    if viewModel.isSyncing {
                        ProgressView()
                    }
                }
            }
            .sheet(isPresented: $showingEditView) {
                NavigationStack {
                    EditListingView()
                }
            }
            .refreshable {
                await viewModel.sync()
            }
            .onAppear {
                viewModel.setup(modelContainer: modelContext.container)
                Task {
                    await viewModel.sync()
                }
            }
        }
    }
}

struct ListingRowView: View {
    let listing: Listing
    
    var body: some View {
        HStack {
            CachedAsyncImage(urlString: listing.imageUrl, localImagePath: listing.localImagePath)
                .frame(width: 50, height: 50)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading) {
                Text(listing.title)
                    .font(.headline)
                Text("$\(listing.price, specifier: "%.2f")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if listing.isPendingSync {
                Image(systemName: "icloud.and.arrow.up")
                    .foregroundColor(.blue)
                    .font(.caption)
            }
        }
    }
}
