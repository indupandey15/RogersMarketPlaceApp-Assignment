//
//  ListingListViewModel.swift
//  RogersOfflineMarketPlace
//
//  Created by Indu Pandey on 31/08/26.
//
import Foundation
import SwiftData

@MainActor
class ListingListViewModel: ObservableObject {
    @Published var isSyncing: Bool = false
    
    var syncEngine: SyncEngine?
    
    func setup(modelContainer: ModelContainer) {
        // Only set it up if it hasn't been created yet
        if self.syncEngine == nil {
            self.syncEngine = SyncEngine(modelContainer: modelContainer)
        }
    }
    
    func sync() async {
        guard !isSyncing else { return }
        isSyncing = true
        defer { isSyncing = false }
        
        await syncEngine?.syncPendingListings()
        await syncEngine?.fetchRemoteListings()
    }
}
