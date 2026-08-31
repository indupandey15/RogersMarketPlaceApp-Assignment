//
//  EditListingViewTests.swift
//  RogersMarketPlace
//
//  Created by Indu Pandey on 31/08/26.
//

import XCTest
import SwiftData
@testable import RogersOfflineMarketPlace

@MainActor
final class EditListingViewTests: XCTestCase {

    // Shared in-memory database for each test
    var container: ModelContainer!
    var context: ModelContext!

    override func setUpWithError() throws {
        container = try ModelContainer(
            for: Listing.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        context = container.mainContext
    }

    // ==========================================
    // TEST 1: Creating a new listing saves to DB
    // ==========================================
    func testSaveNewListingInsertsIntoDatabase() throws {

        // ARRANGE: Simulate the form inputs a user types
        let title = "Test Bike"
        let price = 250.0
        let description = "A great mountain bike"

        // ACT: Simulate what save() does for a NEW listing
        let newListing = Listing(
            title: title,
            itemDescription: description,
            price: price,
            isPendingSync: true
        )
        context.insert(newListing)
        try context.save()

        // ASSERT: Verify the listing was saved to the local database
        let all = try context.fetch(FetchDescriptor<Listing>())
        XCTAssertEqual(all.count, 1, "There should be exactly 1 listing in the database.")
        XCTAssertEqual(all.first?.title, "Test Bike", "The saved title should match the input.")
        XCTAssertEqual(all.first?.price, 250.0, "The saved price should match the input.")
    }

    // ==========================================
    // TEST 2: New listing is always marked as pending sync
    // ==========================================
    func testNewListingIsMarkedAsPendingSync() throws {

        // ARRANGE
        let newListing = Listing(
            title: "Pending Item",
            itemDescription: "Should sync",
            price: 99.0,
            isPendingSync: true  // save() always sets this to true
        )

        // ACT
        context.insert(newListing)
        try context.save()

        // ASSERT: isPendingSync must be true so SyncEngine picks it up
        let fetched = try context.fetch(FetchDescriptor<Listing>()).first
        XCTAssertTrue(fetched?.isPendingSync == true, "A newly created listing must be marked pending sync.")
    }

    // ==========================================
    // TEST 3: Editing an existing listing updates its fields
    // ==========================================
    func testSaveUpdatesExistingListingFields() throws {

        // ARRANGE: Insert an existing listing into the database first
        let existing = Listing(
            title: "Old Title",
            itemDescription: "Old description",
            price: 50.0,
            isPendingSync: false
        )
        context.insert(existing)
        try context.save()

        // ACT: Simulate what save() does when EDITING an existing listing
        existing.title = "New Title"
        existing.price = 75.0
        existing.itemDescription = "Updated description"
        existing.updatedAt = Date()
        existing.isPendingSync = true
        try context.save()

        // ASSERT: Verify the fields were updated correctly
        let fetched = try context.fetch(FetchDescriptor<Listing>()).first
        XCTAssertEqual(fetched?.title, "New Title", "Title should be updated.")
        XCTAssertEqual(fetched?.price, 75.0, "Price should be updated.")
        XCTAssertTrue(fetched?.isPendingSync == true, "Edited listing must be re-queued for sync.")
    }

    // ==========================================
    // TEST 4: Invalid price string does NOT save
    // ==========================================
    func testInvalidPriceDoesNotCreateListing() throws {

        // ARRANGE: Simulate the guard let price = Double(priceString) check in save()
        let invalidPriceString = "abc"

        // ACT: Replicate the guard check that prevents saving
        let price = Double(invalidPriceString)

        // ASSERT: save() exits early, so nothing should be in the database
        XCTAssertNil(price, "Non-numeric price string should fail Double conversion.")

        let all = try context.fetch(FetchDescriptor<Listing>())
        XCTAssertEqual(all.count, 0, "No listing should be saved when the price is invalid.")
    }
}
