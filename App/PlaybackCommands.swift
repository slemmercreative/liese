import SwiftUI

struct FocusedPlayerKey: FocusedValueKey {
    typealias Value = PlayerController
}

extension FocusedValues {
    var player: PlayerController? {
        get { self[FocusedPlayerKey.self] }
        set { self[FocusedPlayerKey.self] = newValue }
    }
}

/// "Playback" menu; shortcuts act on the frontmost document window.
struct PlaybackCommands: Commands {
    @FocusedValue(\.player) private var player

    var body: some Commands {
        CommandMenu("Playback") {
            Group {
                Button("Play / Pause") { player?.togglePlayback() }
                    .keyboardShortcut(.space, modifiers: [])

                Divider()

                Button("Next Frame") { player?.step(1) }
                    .keyboardShortcut(.rightArrow, modifiers: [])
                Button("Previous Frame") { player?.step(-1) }
                    .keyboardShortcut(.leftArrow, modifiers: [])
                Button("Forward 10 Frames") { player?.step(10) }
                    .keyboardShortcut(.rightArrow, modifiers: .shift)
                Button("Back 10 Frames") { player?.step(-10) }
                    .keyboardShortcut(.leftArrow, modifiers: .shift)

                Divider()

                Button("Go to Start") { player?.goToStart() }
                    .keyboardShortcut(.leftArrow, modifiers: .command)
                Button("Go to End") { player?.goToEnd() }
                    .keyboardShortcut(.rightArrow, modifiers: .command)

                Divider()

                Button("Toggle Loop") { player?.toggleLoop() }
                    .keyboardShortcut("l", modifiers: [])
            }
            .disabled(player == nil)
        }
    }
}
