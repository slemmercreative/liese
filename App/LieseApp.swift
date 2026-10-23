import AppKit
import SwiftUI

@main
struct LieseApp: App {
    var body: some Scene {
        DocumentGroup(viewing: LottieDocument.self) { file in
            DocumentView(document: file.document, fileURL: file.fileURL)
        }
        .defaultSize(width: 720, height: 640)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About Liese") { AboutPanel.show() }
            }
            PlaybackCommands()
        }
    }
}

/// Standard About panel, plus the git commit the build came from (set by scripts/install.sh).
enum AboutPanel {
    static func show() {
        let commit = Bundle.main.object(forInfoDictionaryKey: "LieseGitCommit") as? String ?? "dev"
        let credits = NSAttributedString(
            string: "Lightweight Lottie viewer\nCommit \(commit)",
            attributes: [
                .font: NSFont.systemFont(ofSize: 11),
                .foregroundColor: NSColor.secondaryLabelColor,
            ]
        )
        NSApp.orderFrontStandardAboutPanel(options: [.credits: credits])
        NSApp.activate()
    }
}
