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
        }
        .modelContainer(sharedModelContainer)
    }
}
