import Foundation

/// Metadata shown in the app's info popover and the Quick Look overlay.
struct AnimationInfo {
    var name: String?
    var bodymovinVersion: String?
    var size: CGSize
    var frameRate: Double
    var inPoint: Double
    var outPoint: Double
    var layerCount: Int?
    var assetCount: Int?
    var imageCount: Int?
    var markerNames: [String]
    /// Greater than 1 only for multi-animation dotLottie files (Liese plays the first).
    var animationCount: Int
    var fileSize: Int
    var isDotLottie: Bool

    var frameCount: Int { max(0, Int((outPoint - inPoint).rounded())) }
    var duration: TimeInterval { frameRate > 0 ? (outPoint - inPoint) / frameRate : 0 }

    var dimensions: String { "\(Int(size.width))×\(Int(size.height))" }
    var frameRateText: String { "\(Self.trimmed(frameRate)) fps" }
    var durationText: String { String(format: "%.2fs", duration) }
    var fileSizeText: String { ByteCountFormatter.string(fromByteCount: Int64(fileSize), countStyle: .file) }
    var formatText: String {
        guard isDotLottie else { return "Lottie JSON" }
        return animationCount > 1 ? "dotLottie (\(animationCount) animations)" : "dotLottie"
    }

    /// One-line summary, e.g. "512×512 · 60 fps · 2.00s · 120 frames".
    var summary: String {
        var parts = [dimensions, frameRateText, durationText, "\(frameCount) frames"]
        if isDotLottie { parts.append(formatText) }
        return parts.joined(separator: " · ")
    }

    static func trimmed(_ value: Double) -> String {
        value.rounded() == value ? String(Int(value)) : String(format: "%.2f", value)
    }
}
