import AppKit
import SwiftUI
import UniformTypeIdentifiers

/// Shown when Liese launches (or is reopened) with no document: a blank canvas
/// that accepts a dropped Lottie file or opens one on click.
@MainActor
enum WelcomeWindow {
    private static var window: NSWindow?

    static func show() {
        if window == nil {
            let w = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 720, height: 640),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered,
                defer: false
            )
            w.title = "Liese"
            w.isReleasedWhenClosed = false
            w.contentView = NSHostingView(rootView: WelcomeView())
            w.center()
            window = w
        }
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate()
    }

    static func isWelcome(_ w: NSWindow) -> Bool { w === window }

    static func close() {
        window?.close()
    }
}

final class LieseAppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillFinishLaunching(_ notification: Notification) {
        // Skip the launch-time Open panel; the welcome canvas replaces it.
        UserDefaults.standard.set(false, forKey: "NSShowAppCentricOpenPanelInsteadOfUntitledFile")
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Let any documents passed at launch (Finder, `open`) arrive first.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if NSDocumentController.shared.documents.isEmpty { WelcomeWindow.show() }
        }
        // Close the welcome canvas as soon as any document window appears. SwiftUI
        // document windows aren't reliably tied to their NSDocument when they first
        // show, so check for open documents instead of matching the window.
        for name in [NSWindow.didBecomeMainNotification, NSWindow.didBecomeKeyNotification] {
            NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { note in
                MainActor.assumeIsolated {
                    guard let w = note.object as? NSWindow, !WelcomeWindow.isWelcome(w),
                          !NSDocumentController.shared.documents.isEmpty
                    else { return }
                    WelcomeWindow.close()
                }
            }
        }
        // Bring the welcome canvas back once the last document closes.
        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification, object: nil, queue: .main
        ) { note in
            guard let w = note.object as? NSWindow,
                  NSDocumentController.shared.document(for: w) != nil
            else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                if NSDocumentController.shared.documents.isEmpty { WelcomeWindow.show() }
            }
        }
    }

    func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool { false }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag { WelcomeWindow.show() }
        return false
    }
}

struct WelcomeView: View {
    @State private var isTargeted = false

    var body: some View {
        // Not a Button: a plain-style button fires its action when a drag ends over
        // it, which swallowed drops and showed the Open panel instead.
        VStack(spacing: 12) {
            Image(systemName: "square.and.arrow.down")
                .font(.system(size: 40, weight: .light))
            Text("Drop a Lottie file here")
                .font(.title3)
            Text("or click to open one")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8, 6]))
                .foregroundStyle(isTargeted ? Color.accentColor : Color.secondary.opacity(0.4))
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: openPanel)
        .dropDestination(for: URL.self) { urls, _ in
            let files = urls.filter(\.isFileURL)
            files.forEach(open)
            return !files.isEmpty
        } isTargeted: { isTargeted = $0 }
        .padding(24)
        .frame(minWidth: 400, minHeight: 300)
    }

    private func openPanel() {
        NSDocumentController.shared.openDocument(nil)
    }

    private func open(_ url: URL) {
        NSDocumentController.shared.openDocument(withContentsOf: url, display: true) { document, _, error in
            if let error { NSApp.presentError(error) }
            if document != nil { WelcomeWindow.close() }
        }
    }
}
