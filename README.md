# 📦 MediaCompressionKit

**MediaCompressionKit** is a **SwiftUI-based Image & Video Compression module** for iOS that allows developers to easily:

* Pick **images or videos** from the photo library
* Compress them using **native Apple frameworks**
* Preview the compressed media
* Save media to Photos
* Receive the **compressed image or video URL back in the parent view**

It is **iOS 16+ compatible**, **App Store safe**, and designed to be **reusable in any SwiftUI project**.

---

## ✨ Features

* 📸 Image compression (JPEG, PNG, HEIC)
* 🎥 Video compression (MP4 using AVFoundation)
* 🧠 Native compression (no third-party libraries)
* 🧩 Reusable SwiftUI component
* 🔁 Callback-based API for parent views
* 📱 Photo & Video picker using `PHPickerViewController`
* 💾 Save to Photos with permission handling
* 🧪 Safe defaults + extensible design

---

## 🛠 Technologies Used (And Why)

| Technology               | Why It’s Used                                                |
| ------------------------ | ------------------------------------------------------------ |
| **SwiftUI**              | Modern UI framework, easy to embed                           |
| **PhotosUI (PHPicker)**  | Apple-recommended media picker (no full photo access needed) |
| **AVFoundation**         | Video compression using `AVAssetExportSession`               |
| **AVKit**                | Video preview with `VideoPlayer`                             |
| **CoreGraphics**         | HEIC image compression                                       |
| **Closures (Callbacks)** | To return compressed media to parent view                    |

All APIs are **Apple-native**, making this library **future-proof and App Store compliant**.

---

## 📁 Project Structure

```
MediaCompressionKit
│
├── ContentView.swift        // Example usage (Parent / Main file)
├── Helper.swift             // MediaCompressionKit (UI + logic)
├── Info.plist               // Required permissions
└── README.md
```

---

## 🚀 How to Add This to Your Project

### 1️⃣ Copy Files

Add the following files to your project:

* `Helper.swift` (contains `ImageCompressionView`)
* (Optional) `ContentView.swift` as an example

---

### 2️⃣ Add Required Permissions (IMPORTANT)

Open **Info.plist** and add:

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>Select images or videos for compression.</string>

<key>NSPhotoLibraryAddUsageDescription</key>
<string>Save compressed media to your photo library.</string>
```

Without these keys, the app **will crash** when saving media.

---

## 🧩 How to Use MediaCompressionKit

### Basic Usage (Parent View)

```swift
import SwiftUI
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
```

---

## 🔁 How Callbacks Work (Important Concept)

MediaCompressionKit uses **closures** to send data back to the parent.

```swift
onImageCompressed: (UIImage) -> Void
onVideoCompressed: (URL) -> Void
```

### What This Means:

* The compressor **does NOT store data globally**
* Parent view fully controls:

  * where the image/video is stored
  * what happens after compression
* This makes the component **safe, reusable, and testable**

---

## 🎥 Video Compression Explained

* Uses `AVAssetExportSession`
* Preset: `AVAssetExportPresetMediumQuality`
* Output format: **MP4**
* Runs asynchronously (non-blocking UI)
* Shows loading indicator while compressing

Why this approach?

* Apple-recommended
* Hardware accelerated
* Works reliably across devices

---

## 🖼 Image Compression Explained

* JPEG: lossy compression using quality slider
* PNG: lossless (quality slider disabled)
* HEIC: compressed using CoreGraphics
* Real-time preview updates

---

## 🔒 Privacy & App Store Safety

* Uses **PHPicker** → no full photo access
* Requests permission only when saving
* No background tracking
* No private APIs

✅ **Safe for App Store submission**

---

## 🧪 Minimum Requirements

* iOS **16.0+**
* Swift **5.7+**
* Xcode **15+**

---

## 🔮 Possible Extensions

You can easily extend this kit to add:

* Progress percentage for video compression
* Video quality presets (Low / Medium / High)
* Batch media compression
* Share Sheet instead of auto-save
* Swift Package Manager support

---

## 🧠 Who Should Use This?

* iOS developers needing media compression
* SwiftUI projects
* Invoice, document, social, or upload-heavy apps
* Developers who want **clean native solutions**

---
 
