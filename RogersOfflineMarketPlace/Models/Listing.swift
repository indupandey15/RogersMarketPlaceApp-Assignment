//
//  Listing.swift
//  RogersOfflineMarketPlace
//
//  Created by Indu Pandey on 31/08/26.
//

import Foundation
import SwiftData

@Model
final class Listing: Identifiable {
    @Attribute(.unique) var id: String
    var title: String
    var itemDescription: String
    var price: Double
    var imageUrl: String?
    var localImagePath: String?
    var createdAt: Date
    var updatedAt: Date
    var isPendingSync: Bool

    init(id: String = UUID().uuidString, title: String, itemDescription: String, price: Double, imageUrl: String? = nil, localImagePath: String? = nil, createdAt: Date = Date(), updatedAt: Date = Date(), isPendingSync: Bool = false) {
        self.id = id
        self.title = title
        self.itemDescription = itemDescription
        self.price = price
        self.imageUrl = imageUrl
        self.localImagePath = localImagePath
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isPendingSync = isPendingSync
    }
}
