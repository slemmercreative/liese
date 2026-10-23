import Cocoa
import Lottie
import Quartz

/// Quick Look preview for Lottie JSON and dotLottie files.
///
/// The extension registers for all of `public.json`, so JSON that isn't a Lottie animation
/// falls back to a plain monospaced text view instead of an error.
final class PreviewViewController: NSViewController, QLPreviewingController {
    private let canvas = CanvasView(frame: NSRect(x: 0, y: 0, width: 640, height: 480))
    private var animationView: LottieAnimationView?

    override var nibName: NSNib.Name? { nil }

    override func loadView() {
        canvas.background = .checkerboard
        view = canvas
    }

    func preparePreviewOfFile(at url: URL) async throws {
        let data = try Data(contentsOf: url, options: .mappedIfSafe)
        do {
            let loaded = try await LottieLoader.load(data: data, fileURL: url)
            showAnimation(loaded)
        } catch LieseError.notLottie {
            showText(data)
        } catch where !LottieLoader.isZip(data) {
            // Looked like Lottie but didn't decode: still show the JSON so the preview is useful.
            showText(data, note: error.localizedDescription)
        }
    }

    // MARK: - Animation

    private func showAnimation(_ loaded: LoadedLottie) {
        let lottieView = loaded.makeView()
        canvas.setContent(lottieView)
        addInfoOverlay(loaded.info.summary)
        animationView = lottieView
        lottieView.play()
        preferredContentSize = Self.fittedSize(for: loaded.info.size)
    }

    private func addInfoOverlay(_ text: String) {
        let label = NSTextField(labelWithString: text)
        label.font = .monospacedDigitSystemFont(ofSize: 11, weight: .medium)
        label.textColor = .secondaryLabelColor
        label.translatesAutoresizingMaskIntoConstraints = false

        let pill = NSVisualEffectView()
        pill.material = .hudWindow
        pill.blendingMode = .withinWindow
        pill.state = .active
        pill.wantsLayer = true
        pill.layer?.cornerRadius = 6
        pill.layer?.masksToBounds = true
        pill.translatesAutoresizingMaskIntoConstraints = false

        pill.addSubview(label)
        canvas.addSubview(pill)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: pill.leadingAnchor, constant: 8),
            label.trailingAnchor.constraint(equalTo: pill.trailingAnchor, constant: -8),
            label.topAnchor.constraint(equalTo: pill.topAnchor, constant: 4),
            label.bottomAnchor.constraint(equalTo: pill.bottomAnchor, constant: -4),
            pill.leadingAnchor.constraint(equalTo: canvas.leadingAnchor, constant: 10),
            pill.bottomAnchor.constraint(equalTo: canvas.bottomAnchor, constant: -10),
            pill.trailingAnchor.constraint(lessThanOrEqualTo: canvas.trailingAnchor, constant: -10),
        ])
    }

    /// Fit within 960×720, but scale small animations up so the preview isn't tiny.
    static func fittedSize(for size: CGSize) -> CGSize {
        guard size.width > 0, size.height > 0 else { return CGSize(width: 640, height: 480) }
        var scale = min(960 / size.width, 720 / size.height, 1)
        let longest = max(size.width, size.height) * scale
        if longest < 480 { scale *= 480 / longest }
        return CGSize(width: (size.width * scale).rounded(), height: (size.height * scale).rounded())
    }

    // MARK: - Plain JSON fallback

    private func showText(_ data: Data, note: String? = nil) {
        let scrollView = NSTextView.scrollableTextView()
        guard let textView = scrollView.documentView as? NSTextView else { return }
        textView.isEditable = false
        textView.isRichText = false
        textView.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        textView.textContainerInset = NSSize(width: 10, height: 10)
        textView.string = (note.map { "// \($0)\n\n" } ?? "") + Self.displayText(for: data)
        canvas.setContent(scrollView)
        preferredContentSize = CGSize(width: 800, height: 600)
    }

    private static let textLimit = 4 * 1024 * 1024

    /// Shows the file as-is if it's already formatted; pretty-prints minified JSON.
    static func displayText(for data: Data) -> String {
        let head = String(decoding: data.prefix(4096), as: UTF8.self)
        let alreadyFormatted = head.contains("\n")
        if !alreadyFormatted, data.count <= textLimit,
           let object = try? JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed]),
           let pretty = try? JSONSerialization.data(
               withJSONObject: object,
               options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes, .fragmentsAllowed]
           ) {
            return String(decoding: pretty, as: UTF8.self)
        }
        let text = String(decoding: data.prefix(textLimit), as: UTF8.self)
        return data.count > textLimit ? text + "\n\n… (truncated)" : text
    }
}
