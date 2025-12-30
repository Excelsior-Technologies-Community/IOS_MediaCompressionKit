//
//  ContentView.swift
//  MediaCompressionKit
//
//  Created by Noman belim on 30/12/25.
//
 
import SwiftUI
import SwiftUI
import PDFKit
import AVKit
struct ContentView: View {

    @State private var savedImage: UIImage?
    @State private var savedVideoURL: URL?

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                ImageCompressionView(
                    onImageCompressed: { image in
                        savedImage = image
                    },
                    onVideoCompressed: { url in
                        savedVideoURL = url
                    }
                )
                if let image = savedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 150)
                }

                if let videoURL = savedVideoURL {
                    VideoPlayer(player: AVPlayer(url: videoURL))
                        .frame(height: 150)
                }
  
            }
            .padding()
        }
    }
}

#Preview {
    ContentView()
}
