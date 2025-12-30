//
//  Helper.swift
//  MediaCompressionKit
//
//  Created by Noman belim on 30/12/25.
//
import SwiftUI
import PhotosUI
import AVFoundation
import AVKit
import UniformTypeIdentifiers

enum MediaType: String, CaseIterable {
    case image = "Image"
    case video = "Video"
}

struct ImageCompressionView: View {

    // MARK: - CALLBACKS (IMPORTANT)
    let onImageCompressed: (UIImage) -> Void
    let onVideoCompressed: (URL) -> Void

    // MARK: - Image State
    @State private var selectedImage: UIImage?
    @State private var compressedImage: UIImage?
    @State private var compressionQuality: Double = 0.7
    @State private var originalSize: Int64 = 0
    @State private var compressedSize: Int64 = 0

    // MARK: - Video State
    @State private var selectedVideoURL: URL?
    @State private var compressedVideoURL: URL?
    @State private var videoOriginalSize: Int64 = 0
    @State private var videoCompressedSize: Int64 = 0

    // MARK: - UI State
    @State private var showingPicker = false
    @State private var showingSaveAlert = false
    @State private var mediaType: MediaType = .image
    @State private var compressionFormat: CompressionFormat = .jpeg
    @State private var isCompressing = false

    enum CompressionFormat: String, CaseIterable {
        case jpeg = "JPEG"
        case png = "PNG"
        case heic = "HEIC"
    }

    // MARK: - INIT
    init(
        onImageCompressed: @escaping (UIImage) -> Void = { _ in },
        onVideoCompressed: @escaping (URL) -> Void = { _ in }
    ) {
        self.onImageCompressed = onImageCompressed
        self.onVideoCompressed = onVideoCompressed
    }

    // MARK: - UI
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {

                if selectedImage == nil && selectedVideoURL == nil {
                    emptyState
                } else {
                    previewView
                    statsView

                    if mediaType == .image {
                        compressionControls
                    }

                    actionButtons
                }
            }
            .padding()
        }
        
        .sheet(isPresented: $showingPicker) {
            pickerSheet
        }
        .alert("Saved", isPresented: $showingSaveAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Media saved successfully.")
        }
    }
}

// MARK: - UI SECTIONS
extension ImageCompressionView {

    var emptyState: some View {
        VStack(spacing: 20) {
            Picker("Media", selection: $mediaType) {
                ForEach(MediaType.allCases, id: \.self) {
                    Text($0.rawValue)
                }
            }
            .pickerStyle(.segmented)

            Button("Select \(mediaType.rawValue)") {
                showingPicker = true
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }

    var previewView: some View {
        Group {
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 220)
                    .cornerRadius(12)
            }

            if let videoURL = selectedVideoURL {
                VideoPlayer(player: AVPlayer(url: videoURL))
                    .frame(height: 220)
                    .cornerRadius(12)
            }
        }
    }

    var statsView: some View {
        VStack(spacing: 8) {
            if mediaType == .image && compressedSize > 0 {
                statRow("Original", originalSize)
                statRow("Compressed", compressedSize)
            }

            if mediaType == .video && videoCompressedSize > 0 {
                statRow("Original", videoOriginalSize)
                statRow("Compressed", videoCompressedSize)
            }

            if isCompressing {
                ProgressView("Compressing...")
            }
        }
    }

    var compressionControls: some View {
        VStack(spacing: 12) {
            Picker("Format", selection: $compressionFormat) {
                ForEach(CompressionFormat.allCases, id: \.self) {
                    Text($0.rawValue)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: compressionFormat) { _ in
                compressImage()
            }

            if compressionFormat != .png {
                Slider(value: $compressionQuality, in: 0.1...1.0, step: 0.05)
                    .onChange(of: compressionQuality) { _ in
                        compressImage()
                    }
            }
        }
    }

    var actionButtons: some View {
        VStack(spacing: 12) {

            Button("New Media") {
                reset()
                showingPicker = true
            }

            if let image = compressedImage {
                Button("Save Image") {
                    onImageCompressed(image)
                    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                    showingSaveAlert = true
                }
            }

            if let videoURL = compressedVideoURL {
                Button("Save Video") {
                    onVideoCompressed(videoURL)
                    UISaveVideoAtPathToSavedPhotosAlbum(videoURL.path, nil, nil, nil)
                    showingSaveAlert = true
                }
            }
        }
        .buttonStyle(.borderedProminent)
    }

    func statRow(_ title: String, _ bytes: Int64) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file))
        }
    }
}

// MARK: - PICKER
extension ImageCompressionView {

    var pickerSheet: some View {
        ImagePicker(
            mediaType: mediaType,
            onImagePicked: { image in
                selectedImage = image
                originalSize = Int64(image.jpegData(compressionQuality: 1)?.count ?? 0)
                compressImage()
            },
            onVideoPicked: { url in
                selectedVideoURL = url
                videoOriginalSize = fileSize(url)
                isCompressing = true
                compressVideo(url)
            }
        )
    }
}

// MARK: - LOGIC
extension ImageCompressionView {

    func compressImage() {
        guard let image = selectedImage else { return }

        let data: Data?
        switch compressionFormat {
        case .jpeg:
            data = image.jpegData(compressionQuality: compressionQuality)
        case .png:
            data = image.pngData()
        case .heic:
            data = image.heicData(compressionQuality: compressionQuality)
        }

        compressedSize = Int64(data?.count ?? 0)
        compressedImage = data.flatMap { UIImage(data: $0) }
    }

    func compressVideo(_ url: URL) {
        let asset = AVAsset(url: url)
        guard let exporter = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetMediumQuality) else {
            isCompressing = false
            return
        }

        let output = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mp4")

        exporter.outputURL = output
        exporter.outputFileType = .mp4

        exporter.exportAsynchronously {
            DispatchQueue.main.async {
                isCompressing = false
                if exporter.status == .completed {
                    compressedVideoURL = output
                    videoCompressedSize = fileSize(output)
                }
            }
        }
    }

    func fileSize(_ url: URL) -> Int64 {
        (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize.map(Int64.init) ?? 0
    }

    func reset() {
        selectedImage = nil
        compressedImage = nil
        selectedVideoURL = nil
        compressedVideoURL = nil
        originalSize = 0
        compressedSize = 0
        videoOriginalSize = 0
        videoCompressedSize = 0
        isCompressing = false
    }
}

// MARK: - PICKER WRAPPER
struct ImagePicker: UIViewControllerRepresentable {

    let mediaType: MediaType
    let onImagePicked: (UIImage) -> Void
    let onVideoPicked: (URL) -> Void

    @Environment(\.presentationMode) var presentationMode

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.selectionLimit = 1
        config.filter = mediaType == .image ? .images : .videos
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker
        init(_ parent: ImagePicker) { self.parent = parent }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.presentationMode.wrappedValue.dismiss()
            guard let provider = results.first?.itemProvider else { return }

            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, _ in
                    DispatchQueue.main.async {
                        if let image = image as? UIImage {
                            self.parent.onImagePicked(image)
                        }
                    }
                }
            } else if provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
                provider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { url, _ in
                    guard let url else { return }
                    let temp = FileManager.default.temporaryDirectory.appendingPathComponent(url.lastPathComponent)
                    try? FileManager.default.copyItem(at: url, to: temp)
                    DispatchQueue.main.async {
                        self.parent.onVideoPicked(temp)
                    }
                }
            }
        }
    }
}

// MARK: - HEIC
extension UIImage {
    func heicData(compressionQuality: CGFloat) -> Data? {
        guard let cgImage else { return nil }
        let data = NSMutableData()
        guard let dest = CGImageDestinationCreateWithData(
            data, AVFileType.heic as CFString, 1, nil
        ) else { return nil }

        CGImageDestinationAddImage(
            dest,
            cgImage,
            [kCGImageDestinationLossyCompressionQuality: compressionQuality] as CFDictionary
        )
        CGImageDestinationFinalize(dest)
        return data as Data
    }
}
