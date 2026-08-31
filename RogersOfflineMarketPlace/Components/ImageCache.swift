//
//  ImageCache.swift
//  RogersOfflineMarketPlace
//
//  Created by Indu Pandey on 31/08/26.
//

import SwiftUI
import Foundation

actor ImageCache {
    static let shared = ImageCache()
    
    private let memoryCache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    
    private init() {
        memoryCache.countLimit = 100 // limit memory usage
        let urls = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        cacheDirectory = urls[0].appendingPathComponent("ImageCache")
        
        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        }
    }
    
    func image(for key: String) -> UIImage? {
        // Check memory
        if let image = memoryCache.object(forKey: key as NSString) {
            return image
        }
        // Check disk
        let fileURL = cacheDirectory.appendingPathComponent(sanitize(key))
        if let data = try? Data(contentsOf: fileURL), let image = UIImage(data: data) {
            memoryCache.setObject(image, forKey: key as NSString)
            return image
        }
        return nil
    }
    
    func insertImage(_ image: UIImage, for key: String) {
        // Generate Thumbnail to save memory
        let size = CGSize(width: 300, height: 300)
        let thumbnail = image.preparingThumbnail(of: size) ?? image
        
        memoryCache.setObject(thumbnail, forKey: key as NSString)
        
        let fileURL = cacheDirectory.appendingPathComponent(sanitize(key))
        if let data = thumbnail.jpegData(compressionQuality: 0.8) {
            try? data.write(to: fileURL)
        }
    }
    
    private func sanitize(_ key: String) -> String {
        return key.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? UUID().uuidString
    }
}
