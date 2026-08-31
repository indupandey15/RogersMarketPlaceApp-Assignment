//
//  ListingListViewModelTests.swift
//  RogersMarketPlace
//
//  Created by Indu Pandey on 31/08/26.
//

import XCTest
import SwiftData
@testable import RogersOfflineMarketPlace

@MainActor
final class ListingListViewModelTests: XCTestCase {

    var container: ModelContainer!
    var viewModel: ListingListViewModel!

    override func setUpWithError() throws {
        container = try ModelContainer(
            for: Listing.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        viewModel = ListingListViewModel()
    }

    // ==========================================
    // TEST 1: ViewModel starts with correct default state
    // ==========================================
    func testInitialStateIsNotSyncing() {

        // ASSERT: isSyncing must be false before anything happens
        XCTAssertFalse(viewModel.isSyncing, "ViewModel should not be syncing on initialization.")
    }

    // ==========================================
    // TEST 2: setup() only creates the SyncEngine once
    // ==========================================
    func testSetupOnlyInitializesSyncEngineOnce() {

        // ACT: Call setup twice with the same container
        viewModel.setup(modelContainer: container)
        let firstEngine = viewModel.syncEngine

        viewModel.setup(modelContainer: container)
        let secondEngine = viewModel.syncEngine

        // ASSERT: The engine reference should be the exact same object both times
        XCTAssertTrue(firstEngine === secondEngine, "SyncEngine should only be created once, not replaced on repeated setup() calls.")
    }

    // ==========================================
    // TEST 3: isSyncing resets to false after sync completes
    // ==========================================
    func testIsSyncingResetsToFalseAfterSyncCompletes() async {

        // ARRANGE
        viewModel.setup(modelContainer: container)

        // ACT: Run a full sync cycle
        await viewModel.sync()

        // ASSERT: After sync finishes, isSyncing must return to false
        XCTAssertFalse(viewModel.isSyncing, "isSyncing should be false after sync completes.")
    }

    // ==========================================
    // TEST 4: sync() does not run if already syncing
    // ==========================================
    func testSyncDoesNotRunIfAlreadySyncing() async {

        // ARRANGE: Manually force the syncing state to true
        viewModel.setup(modelContainer: container)
        viewModel.isSyncing = true

        // ACT: Try to trigger another sync while one is "in progress"
        await viewModel.sync()

        // ASSERT: isSyncing should still be true because the guard exits early
        // If guard didn't work, sync() would set isSyncing=false after finishing
        XCTAssertTrue(viewModel.isSyncing, "sync() should exit early and not reset isSyncing when a sync is already in progress.")
    }
}
