//
//  APIClient.swift
//  RogersOfflineMarketPlace
//
//  Created by Indu Pandey on 31/08/26.
//
import Foundation

enum APIError: Error {
    case networkError
    case invalidResponse
    case notFound
}

protocol APIClientType {
    func fetchListings() async throws -> [ListingDTO]
    func syncListing(_ listing: ListingDTO) async throws -> ListingDTO
}

// DTO for Network
struct ListingDTO: Codable {
    let id: String
    let title: String
    let itemDescription: String
    let price: Double
    let imageUrl: String?
    let createdAt: Date
    let updatedAt: Date
}

class MockAPIClient: APIClientType {
    // 1. Made static so the "server" state persists across screen navigations
    private static var serverListings: [String: ListingDTO] = {
        // 2. Hardcoded ID instead of a random UUID so SwiftData knows it's the same item
        let seedId = "seed-vintage-camera-123"
        return [
            seedId: ListingDTO(
                id: seedId,
                title: "Vintage Camera",
                itemDescription: "A cool vintage camera.",
                price: 150.0,
                imageUrl: "https://picsum.photos/seed/watch/200/200",
                createdAt: Date().addingTimeInterval(-86400),
                updatedAt: Date().addingTimeInterval(-86400)
            )
        ]
    }()
    
    private let simulateDelay: Bool
    
    init(simulateDelay: Bool = true) {
        self.simulateDelay = simulateDelay
    }
    
    func fetchListings() async throws -> [ListingDTO] {
        if simulateDelay {
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
        }
        return Array(MockAPIClient.serverListings.values).sorted(by: { $0.updatedAt > $1.updatedAt })
    }
    
    func syncListing(_ listing: ListingDTO) async throws -> ListingDTO {
        if simulateDelay {
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 sec delay
        }
        
        // Last-write-wins conflict resolution on the server
        if let existing = MockAPIClient.serverListings[listing.id] {
            if listing.updatedAt > existing.updatedAt {
                MockAPIClient.serverListings[listing.id] = listing
            }
        } else {
            MockAPIClient.serverListings[listing.id] = listing
        }
        
        return MockAPIClient.serverListings[listing.id]!
    }
}
