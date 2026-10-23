import SwiftUI

/// Decodes the document off the main thread, then shows the player or an error.
struct DocumentView: View {
    let document: LottieDocument
    let fileURL: URL?

    @State private var phase: Phase = .loading

    private enum Phase {
        case loading
        case ready(PlayerController)
        case failed(String)
    }

    var body: some View {
        Group {
            switch phase {
            case .loading:
                ProgressView()
                    .controlSize(.small)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .ready(let player):
                PlayerScreen(player: player)
            case .failed(let message):
                ContentUnavailableView(
                    "Can't Play This File",
                    systemImage: "exclamationmark.triangle",
                    description: Text(message)
                )
            }
        }
        .frame(minWidth: 420, minHeight: 320)
        .task { await load() }
    }

    @MainActor
    private func load() async {
        guard case .loading = phase else { return }
        do {
            let loaded = try await LottieLoader.load(data: document.data, fileURL: fileURL)
            phase = .ready(PlayerController(loaded: loaded))
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }
}
