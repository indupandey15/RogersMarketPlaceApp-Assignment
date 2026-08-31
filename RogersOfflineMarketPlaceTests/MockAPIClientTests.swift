//
//  MockAPIClientTests.swift
//  RogersMarketPlace
//
//  Created by Indu Pandey on 31/08/26.
//

import XCTest
@testable import RogersOfflineMarketPlace

final class MockAPIClientTests: XCTestCase {
    
    func testFetchListingsReturnsInitialSeed() async throws {
        let client = MockAPIClient(simulateDelay: false)
        let listings = try await client.fetchListings()
        XCTAssertEqual(listings.count, 1)
        XCTAssertEqual(listings.first?.title, "Vintage Camera")
    }
    
    func testSyncListingLastWriteWins() async throws {
        let client = MockAPIClient(simulateDelay: false)
        let listings = try await client.fetchListings()
        let existing = listings.first!
        
        let outdatedUpdate = ListingDTO(
            id: existing.id,
            title: "Outdated Title",
            itemDescription: existing.itemDescription,
            price: 100,
            imageUrl: existing.imageUrl,
            createdAt: existing.createdAt,
            updatedAt: existing.updatedAt.addingTimeInterval(-100) // Older timestamp
        )
        
        _ = try await client.syncListing(outdatedUpdate)
        
        let finalServerListings = try await client.fetchListings()
        // Should not have updated the title because timestamp is older
        XCTAssertEqual(finalServerListings.first?.title, "Vintage Camera")
        
        let newUpdate = ListingDTO(
            id: existing.id,
            title: "New Title",
            itemDescription: existing.itemDescription,
            price: 100,
            imageUrl: existing.imageUrl,
            createdAt: existing.createdAt,
            updatedAt: existing.updatedAt.addingTimeInterval(100) // Newer timestamp
        )
        
        _ = try await client.syncListing(newUpdate)
        let newerListings = try await client.fetchListings()
        XCTAssertEqual(newerListings.first?.title, "New Title")
    }
}
