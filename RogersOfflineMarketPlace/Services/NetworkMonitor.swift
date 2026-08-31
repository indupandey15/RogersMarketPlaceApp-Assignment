//
//  NetworkMonitor.swift
//  RogersOfflineMarketPlace
//
//  Created by Indu Pandey on 31/08/26.
//
import Foundation
import Network
import SwiftData
import os

@MainActor
class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    private let logger = Logger(subsystem: "com.RogersOfflineMarketPlace", category: "Network")
    
    @Published var isConnected = true
    private var modelContainer: ModelContainer?
    
    private init() {}
    
    func startMonitoring(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        
        monitor.pathUpdateHandler = { [weak self] path in
            let connected = path.status == .satisfied
            
            DispatchQueue.main.async {
                let wasOffline = !(self?.isConnected ?? true)
                self?.isConnected = connected
                
                // If we just regained connectivity, trigger the background upload!
                if wasOffline && connected {
                    self?.logger.info("Connectivity returned! Triggering background sync...")
                    self?.triggerSyncWhenOnline()
                }
            }
        }
        monitor.start(queue: queue)
    }
    
    private func triggerSyncWhenOnline() {
        guard let container = modelContainer else { return }
        Task {
            let engine = SyncEngine(modelContainer: container)
            await engine.syncPendingListings()
        }
    }
}

