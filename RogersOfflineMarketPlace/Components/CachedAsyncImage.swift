//
//  CachedAsyncImage.swift
//  RogersOfflineMarketPlace
//
//  Created by Indu Pandey on 31/08/26.
//

import SwiftUI

struct CachedAsyncImage: View {
    let urlString: String?
    let localImagePath: String?
    
    @State private var image: UIImage? = nil
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                ZStack {
                    Color.gray.opacity(0.3)
                    ProgressView()
                }
                .task {
                    await loadImage()
                }
            }
        }
    }
    
    private func loadImage() async {
        if let local = localImagePath, let cached = await ImageCache.shared.image(for: local) {
            self.image = cached
            return
        }
        
        guard let urlString = urlString, let url = URL(string: urlString) else {
            return
        }
        
        if let cached = await ImageCache.shared.image(for: urlString) {
            self.image = cached
            return
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let downloadedImage = UIImage(data: data) {
                await ImageCache.shared.insertImage(downloadedImage, for: urlString)
                self.image = downloadedImage
            }
        } catch {
            print("Failed to load image: \(error)")
        }
    }
}
