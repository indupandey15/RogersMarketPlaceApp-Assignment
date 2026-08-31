//
//  SyncEngine.swift
//  RogersOfflineMarketPlace
//
//  Created by Indu Pandey on 31/08/26.
//

import Foundation
import SwiftData
import os

// 1. Manually conform to ModelActor instead of using the @ModelActor macro
actor SyncEngine: ModelActor {
    // 2. Explicitly declare the required properties
    let modelContainer: ModelContainer
    let modelExecutor: any ModelExecutor
    
    private let apiClient: APIClientType
    private let logger = Logger(subsystem: "com.RogersOfflineMarketPlace", category: "SyncEngine")
    
    init(modelContainer: ModelContainer, apiClient: APIClientType = MockAPIClient()) {
        self.modelContainer = modelContainer
        let context = ModelContext(modelContainer)
        self.modelExecutor = DefaultSerialModelExecutor(modelContext: context)
        self.apiClient = apiClient
    }
    
    func syncPendingListings() async {
        logger.info("Starting sync for pending listings...")
        
        let fetchDescriptor = FetchDescriptor<Listing>(predicate: #Predicate { $0.isPendingSync })
        
        do {
            // modelContext is a computed property automatically provided by the ModelActor protocol
            let pendingListings = try modelContext.fetch(fetchDescriptor)
            logger.info("Found \(pendingListings.count) pending listings.")
            
            for listing in pendingListings {
                let dto = ListingDTO(
                    id: listing.id,
                    title: listing.title,
                    itemDescription: listing.itemDescription,
                    price: listing.price,
                    imageUrl: listing.imageUrl,
                    createdAt: listing.createdAt,
                    updatedAt: listing.updatedAt
                )
                
                do {
                    let syncedDTO = try await apiClient.syncListing(dto)
                    
                    // Last write wins is handled by the server (mock API).
                    // Update local listing with server result
                    listing.title = syncedDTO.title
                    listing.itemDescription = syncedDTO.itemDescription
                    listing.price = syncedDTO.price
                    listing.imageUrl = syncedDTO.imageUrl
                    listing.updatedAt = syncedDTO.updatedAt
                    listing.isPendingSync = false
                    logger.info("Successfully synced listing \(listing.id)")
                } catch {
                    logger.error("Failed to sync listing \(listing.id): \(error.localizedDescription)")
                    // It stays pending
                }
            }
            try modelContext.save()
        } catch {
            logger.error("Failed to fetch pending listings: \(error.localizedDescription)")
        }
    }
    
    func fetchRemoteListings() async {
        do {
            let remoteListings = try await apiClient.fetchListings()
            for dto in remoteListings {
                let id = dto.id
                let fetchDescriptor = FetchDescriptor<Listing>(predicate: #Predicate { $0.id == id })
                let existing = try? modelContext.fetch(fetchDescriptor).first
                
                if let existing = existing {
                    // Last-write wins
                    if dto.updatedAt > existing.updatedAt && !existing.isPendingSync {
                        existing.title = dto.title
                        existing.itemDescription = dto.itemDescription
                        existing.price = dto.price
                        existing.imageUrl = dto.imageUrl
                        existing.updatedAt = dto.updatedAt
                    }
                } else {
                    let newListing = Listing(
                        id: dto.id,
                        title: dto.title,
                        itemDescription: dto.itemDescription,
                        price: dto.price,
                        imageUrl: dto.imageUrl,
                        createdAt: dto.createdAt,
                        updatedAt: dto.updatedAt,
                        isPendingSync: false
                    )
                    modelContext.insert(newListing)
                }
            }
            try modelContext.save()
        } catch {
            logger.error("Failed to fetch remote listings: \(error.localizedDescription)")
        }
    }
}
