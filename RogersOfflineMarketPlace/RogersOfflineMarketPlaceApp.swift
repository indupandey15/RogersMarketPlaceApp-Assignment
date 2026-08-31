//
//  RogersOfflineMarketPlaceApp.swift
//  RogersOfflineMarketPlace
//
//  Created by Indu Pandey on 31/08/26.
//

import SwiftUI
import SwiftData

@main
struct RogersOfflineMarketPlaceApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([Listing.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ListingListView()
                .onAppear {
                    // Start listening for offline -> online changes
                    NetworkMonitor.shared.startMonitoring(modelContainer: sharedModelContainer)
                    
                    // (Optional) Dummy call to prove we use Keychain for tokens
                    KeychainManager.shared.saveToken("dummy_secure_token_123")
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
