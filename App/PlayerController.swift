import AppKit
import Lottie
import Observation

/// Owns one `LottieAnimationView` and exposes playback state to SwiftUI.
@MainActor
@Observable
final class PlayerController {
    let info: AnimationInfo
    @ObservationIgnored let animationView: LottieAnimationView

    private(set) var isPlaying = false
    private(set) var currentFrame: Double

    var loops = true {
        didSet { animationView.loopMode = loops ? .loop : .playOnce }
    }

    var speed: Double = 1 {
        didSet { animationView.animationSpeed = CGFloat(speed) }
    }

    @ObservationIgnored private var ticker: Timer?
    @ObservationIgnored private var resumeAfterScrub = false

    init(loaded: LoadedLottie) {
        info = loaded.info
        animationView = loaded.makeView()
        currentFrame = loaded.info.inPoint
    }

    var startFrame: Double { info.inPoint }
    var endFrame: Double { max(info.outPoint, info.inPoint + 1) }

    /// Slider binding target: reads the playhead, writes seek.
    var scrubFrame: Double {
        get { currentFrame }
        set { seek(to: newValue) }
    }

    /// Frame number relative to the in point, for display.
    var displayFrame: Int { Int((currentFrame - startFrame).rounded(.down)) }

    // MARK: Transport

    func play() {
        if !loops, currentFrame >= endFrame - 0.5 {
            seek(to: startFrame)
        }
        animationView.play()
        isPlaying = true
        startTicker()
    }

    func pause() {
        animationView.pause()
        isPlaying = false
        stopTicker()
        currentFrame = Double(animationView.currentFrame)
    }

    func togglePlayback() {
        isPlaying ? pause() : play()
    }

    func seek(to frame: Double) {
        let clamped = min(max(frame, startFrame), endFrame)
        animationView.currentFrame = AnimationFrameTime(clamped)
        currentFrame = clamped
    }

    func step(_ frames: Int) {
        if isPlaying { pause() }
        seek(to: currentFrame.rounded() + Double(frames))
    }

    func goToStart() {
        if isPlaying { pause() }
        seek(to: startFrame)
    }

    func goToEnd() {
        if isPlaying { pause() }
        seek(to: endFrame)
    }

    func toggleLoop() { loops.toggle() }

    // MARK: Scrubbing

    func beginScrub() {
        resumeAfterScrub = isPlaying
        if isPlaying { pause() }
    }

    func endScrub() {
        if resumeAfterScrub { play() }
        resumeAfterScrub = false
    }

    func tearDown() {
        stopTicker()
        animationView.stop()
    }

    // MARK: Frame ticker

    private func startTicker() {
        guard ticker == nil else { return }
        let timer = Timer(timeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
        RunLoop.main.add(timer, forMode: .common)
        ticker = timer
    }

    private func stopTicker() {
        ticker?.invalidate()
        ticker = nil
    }

    private func tick() {
        currentFrame = Double(animationView.realtimeAnimationFrame)
        // Looping playback never ends on its own; play-once ends when the view stops at the out point.
        // (Checking the frame avoids misreading a play that's queued until the view joins a window.)
        if !loops, !animationView.isAnimationPlaying, currentFrame >= endFrame - 0.5 {
            isPlaying = false
            stopTicker()
            currentFrame = Double(animationView.currentFrame)
        }
    }
}
