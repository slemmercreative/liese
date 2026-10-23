import Foundation
import Lottie
import UniformTypeIdentifiers

extension UTType {
    /// dotLottie (`.lottie`): a zip container holding one or more Lottie animations plus their assets.
    /// Declared as an imported type in `App/Info.plist`.
    static let dotLottie = UTType(importedAs: "io.dotlottie.lottie")
}

enum LieseError: LocalizedError {
    /// Valid JSON, but not a Lottie / Bodymovin animation.
    case notLottie
    /// A dotLottie archive that contains no animations.
    case emptyDotLottie
    case decodeFailed(Error)

    var errorDescription: String? {
        switch self {
        case .notLottie:
            return "This JSON file isn't a Lottie animation."
        case .emptyDotLottie:
            return "This .lottie file doesn't contain any animations."
        case .decodeFailed(let error):
            return "Lottie couldn't decode this file: \(error.localizedDescription)"
        }
    }
}

/// A decoded animation, ready to be handed to a `LottieAnimationView`.
struct LoadedLottie: @unchecked Sendable {
    enum Source {
        case json(LottieAnimation, imageDirectory: URL?)
        case dotLottie(DotLottieFile)
    }

    let source: Source
    let info: AnimationInfo

    /// Must be called on the main thread.
    func makeView() -> LottieAnimationView {
        let view: LottieAnimationView
        switch source {
        case .json(let animation, let imageDirectory):
            let imageProvider = imageDirectory.map { FilepathImageProvider(filepath: $0) }
            view = LottieAnimationView(animation: animation, imageProvider: imageProvider)
        case .dotLottie(let file):
            view = LottieAnimationView(dotLottie: file)
        }
        view.loopMode = .loop
        view.backgroundBehavior = .pauseAndRestore
        view.contentMode = .scaleAspectFit
        return view
    }
}

enum LottieLoader {
    /// Decodes on a background thread (dotLottie decoding must not run on the main thread).
    static func load(data: Data, fileURL: URL?) async throws -> LoadedLottie {
        try await Task.detached(priority: .userInitiated) {
            try loadSync(data: data, fileURL: fileURL)
        }.value
    }

    static func loadSync(data: Data, fileURL: URL?) throws -> LoadedLottie {
        isZip(data) ? try loadDotLottie(data: data, fileURL: fileURL) : try loadJSON(data: data, fileURL: fileURL)
    }

    /// Cheap structural check for a Bodymovin export.
    static func looksLikeLottie(_ object: [String: Any]) -> Bool {
        object["layers"] is [Any] && object["op"] != nil && object["fr"] != nil
            && object["w"] != nil && object["h"] != nil
    }

    static func isZip(_ data: Data) -> Bool {
        data.count >= 4 && data.prefix(4).elementsEqual([0x50, 0x4B, 0x03, 0x04])
    }

    // MARK: - JSON

    private static func loadJSON(data: Data, fileURL: URL?) throws -> LoadedLottie {
        guard
            let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            looksLikeLottie(object)
        else { throw LieseError.notLottie }

        let animation: LottieAnimation
        do {
            animation = try LottieAnimation.from(data: data)
        } catch {
            throw LieseError.decodeFailed(error)
        }

        let assets = object["assets"] as? [[String: Any]] ?? []
        // Image assets carry a path ("p"); precomps carry "layers".
        let imageCount = assets.filter { $0["p"] != nil && $0["layers"] == nil }.count

        let info = AnimationInfo(
            name: object["nm"] as? String,
            bodymovinVersion: object["v"] as? String,
            size: animation.size,
            frameRate: animation.framerate,
            inPoint: Double(animation.startFrame),
            outPoint: Double(animation.endFrame),
            layerCount: (object["layers"] as? [Any])?.count,
            assetCount: assets.count,
            imageCount: imageCount,
            markerNames: animation.markerNames,
            animationCount: 1,
            fileSize: data.count,
            isDotLottie: false
        )

        // External (non-embedded) images resolve relative to the JSON file.
        let imageDirectory = imageCount > 0 ? fileURL?.deletingLastPathComponent() : nil
        return LoadedLottie(source: .json(animation, imageDirectory: imageDirectory), info: info)
    }

    // MARK: - dotLottie

    private static func loadDotLottie(data: Data, fileURL: URL?) throws -> LoadedLottie {
        let filename = fileURL?.lastPathComponent ?? "animation.lottie"
        let file: DotLottieFile
        switch DotLottieFile.SynchronouslyBlockingCurrentThread.loadedFrom(data: data, filename: filename) {
        case .success(let loaded): file = loaded
        case .failure(let error): throw LieseError.decodeFailed(error)
        }

        guard let first = file.animations.first else { throw LieseError.emptyDotLottie }
        let animation = first.animation

        let info = AnimationInfo(
            name: first.configuration.id,
            bodymovinVersion: nil,
            size: animation.size,
            frameRate: animation.framerate,
            inPoint: Double(animation.startFrame),
            outPoint: Double(animation.endFrame),
            layerCount: nil,
            assetCount: nil,
            imageCount: nil,
            markerNames: animation.markerNames,
            animationCount: file.animations.count,
            fileSize: data.count,
            isDotLottie: true
        )
        return LoadedLottie(source: .dotLottie(file), info: info)
    }
}
