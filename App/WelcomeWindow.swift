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
        NotificationCenter.default.addObserver(
            forName: NSWindow.didBecomeKeyNotification, object: nil, queue: .main
        ) { note in
            guard let w = note.object as? NSWindow,
                  NSDocumentController.shared.document(for: w) != nil
            else { return }
            MainActor.assumeIsolated { WelcomeWindow.close() }
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
        Button(action: openPanel) {
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
        }
        .buttonStyle(.plain)
        .padding(24)
        .frame(minWidth: 400, minHeight: 300)
        .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
            for provider in providers {
                _ = provider.loadObject(ofClass: URL.self) { url, _ in
                    guard let url else { return }
                    DispatchQueue.main.async { open(url) }
                }
            }
            return !providers.isEmpty
        }
    }

    private func openPanel() {
        NSDocumentController.shared.openDocument(nil)
    }

    private func open(_ url: URL) {
        NSDocumentController.shared.openDocument(withContentsOf: url, display: true) { _, _, error in
            if let error { NSApp.presentError(error) }
        }
    }
}
