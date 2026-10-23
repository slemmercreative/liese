import Lottie
import SwiftUI

struct PlayerScreen: View {
    @Bindable var player: PlayerController
    @AppStorage("canvasBackground") private var background: CanvasBackground = .checkerboard
    @State private var showInfo = false

    var body: some View {
        VStack(spacing: 0) {
            LottieCanvas(animationView: player.animationView, background: background)
            Divider()
            controlBar
        }
        .focusedSceneValue(\.player, player)
        .onAppear { player.play() }
        .onDisappear { player.tearDown() }
    }

    private static let speeds: [Double] = [0.1, 0.25, 0.5, 1, 1.5, 2]

    private var controlBar: some View {
        HStack(spacing: 10) {
            Button {
                player.togglePlayback()
            } label: {
                Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                    .frame(width: 18)
            }
            .buttonStyle(.borderless)
            .help(player.isPlaying ? "Pause (Space)" : "Play (Space)")

            Slider(
                value: $player.scrubFrame,
                in: player.startFrame...player.endFrame,
                onEditingChanged: { editing in
                    editing ? player.beginScrub() : player.endScrub()
                }
            )
            .controlSize(.small)

            Text("\(player.displayFrame) / \(player.info.frameCount)")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(minWidth: 72, alignment: .trailing)

            Toggle(isOn: $player.loops) {
                Image(systemName: "repeat")
            }
            .toggleStyle(.button)
            .buttonStyle(.borderless)
            .help("Loop (L)")

            Menu {
                Picker("Speed", selection: $player.speed) {
                    ForEach(Self.speeds, id: \.self) { speed in
                        Text("\(AnimationInfo.trimmed(speed))×").tag(speed)
                    }
                }
                .pickerStyle(.inline)
                .labelsHidden()
            } label: {
                Text("\(AnimationInfo.trimmed(player.speed))×")
                    .font(.caption.monospacedDigit())
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
            .help("Playback speed")

            Menu {
                Picker("Background", selection: $background) {
                    ForEach(CanvasBackground.allCases) { option in
                        Text(option.title).tag(option)
                    }
                }
                .pickerStyle(.inline)
                .labelsHidden()
            } label: {
                Image(systemName: "checkerboard.rectangle")
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
            .help("Background")

            Button {
                showInfo.toggle()
            } label: {
                Image(systemName: "info.circle")
            }
            .buttonStyle(.borderless)
            .help("Animation info")
            .popover(isPresented: $showInfo, arrowEdge: .top) {
                InfoPanel(info: player.info)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.bar)
    }
}

/// Hosts the controller's `LottieAnimationView` on a `CanvasView`.
struct LottieCanvas: NSViewRepresentable {
    let animationView: LottieAnimationView
    let background: CanvasBackground

    func makeNSView(context: Context) -> CanvasView {
        let canvas = CanvasView(frame: .zero)
        canvas.background = background
        canvas.setContent(animationView)
        return canvas
    }

    func updateNSView(_ canvas: CanvasView, context: Context) {
        canvas.background = background
        if animationView.superview !== canvas {
            canvas.setContent(animationView)
        }
    }
}
