//
//  SyncEngineTests.swift
//  RogersMarketPlace
//
//  Created by Indu Pandey on 31/08/26.
//

import XCTest
import SwiftData
@testable import RogersOfflineMarketPlace

@MainActor
final class SyncEngineTests: XCTestCase {
    
    func testSyncEngineUploadsPendingItemToServer() async throws {
        
        // ==========================================
        // 1. ARRANGE (Set up the environment)
        // ==========================================
        
        // Create a temporary, in-memory database just for this test
        let container = try ModelContainer(for: Listing.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = container.mainContext
        
        // Create a fake API client with no artificial delay
        let mockAPI = MockAPIClient(simulateDelay: false)
        
        // Add a single item to the local database that is marked as "needs syncing"
        let localItem = Listing(title: "Test Camera", itemDescription: "Test", price: 10.0, isPendingSync: true)
        context.insert(localItem)
        try context.save()
        
        
        // ==========================================
        // 2. ACT (Run the logic we are testing)
        // ==========================================
        
        // Start the sync engine
        let engine = SyncEngine(modelContainer: container, apiClient: mockAPI)
        await engine.syncPendingListings()
        
        
        // ==========================================
        // 3. ASSERT (Verify the results)
        // ==========================================
        
        // Check Server: Did the mock API receive the item?
        let serverItems = try await mockAPI.fetchListings()
        let wasUploaded = serverItems.contains(where: { $0.title == "Test Camera" })
        XCTAssertTrue(wasUploaded, "The SyncEngine should have uploaded the local item to the server.")
        
        // Check Local DB: Did the sync engine un-mark the item as pending?
        let fetchedItems = try context.fetch(FetchDescriptor<Listing>())
        let updatedLocalItem = fetchedItems.first(where: { $0.title == "Test Camera" })
        XCTAssertEqual(updatedLocalItem?.isPendingSync, false, "The SyncEngine should mark the local item as synced (false).")
    }
}
