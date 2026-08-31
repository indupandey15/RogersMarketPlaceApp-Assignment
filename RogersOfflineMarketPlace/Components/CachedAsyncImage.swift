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
    @State private var isLoading: Bool = false
    @State private var hasFailed: Bool = false

    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if hasFailed {
                // Shows clean icon instead of eternal spinner
                ZStack {
                    Color.gray.opacity(0.15)
                    Image(systemName: "photo")
                        .font(.largeTitle)
                        .foregroundColor(.gray.opacity(0.4))
                }
            } else {
                ZStack {
                    Color.gray.opacity(0.15)
                    ProgressView()
                }
            }
        }
        // id: means this task only restarts if the URL actually changes
        // NOT when SwiftData triggers a list re-render
        .task(id: urlString ?? localImagePath ?? "empty") {
            // Don't reload if we already have an image
            guard image == nil else { return }
            await loadImage()
        }
    }

    private func loadImage() async {
        // 1. Check local cache first (user-picked photo from PhotosPicker)
        if let local = localImagePath,
           let cached = await ImageCache.shared.image(for: local) {
            self.image = cached
            return
        }

        guard let urlString = urlString,
              let url = URL(string: urlString) else {
            self.hasFailed = true
            return
        }

        // 2. Check memory/disk cache before any network call
        if let cached = await ImageCache.shared.image(for: urlString) {
            self.image = cached
            return
        }

        // 3. Download from network with a timeout
        isLoading = true

        do {
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = 10  // ✅ 10 second timeout
            config.timeoutIntervalForResource = 15
            let session = URLSession(configuration: config)

            let (data, response) = try await session.data(from: url)

            // Check it's actually a valid HTTP 200 response
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                self.hasFailed = true
                return
            }

            guard let downloaded = UIImage(data: data) else {
                self.hasFailed = true
                return
            }

            // Save to cache so next load is instant
            await ImageCache.shared.insertImage(downloaded, for: urlString)
            self.image = downloaded

        } catch {
            // Network failed — show placeholder icon, don't loop
            self.hasFailed = true
        }

        isLoading = false
    }
}
