import SwiftUI

struct InfoPanel: View {
    let info: AnimationInfo

    var body: some View {
        Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 14, verticalSpacing: 6) {
            row("Name", info.name ?? "—")
            row("Size", info.dimensions)
            row("Frame rate", info.frameRateText)
            row("Frames", "\(info.frameCount)  (\(AnimationInfo.trimmed(info.inPoint))–\(AnimationInfo.trimmed(info.outPoint)))")
            row("Duration", info.durationText)
            if let layers = info.layerCount { row("Layers", "\(layers)") }
            if let assets = info.assetCount {
                row("Assets", "\(assets)" + ((info.imageCount ?? 0) > 0 ? "  (\(info.imageCount!) images)" : ""))
            }
            if !info.markerNames.isEmpty { row("Markers", info.markerNames.joined(separator: ", ")) }
            if let version = info.bodymovinVersion { row("Bodymovin", version) }
            row("Format", info.formatText)
            row("File size", info.fileSizeText)
        }
        .font(.callout)
        .textSelection(.enabled)
        .padding(14)
        .frame(minWidth: 260, alignment: .leading)
    }

    private func row(_ label: String, _ value: String) -> some View {
        GridRow {
            Text(label)
                .foregroundStyle(.secondary)
                .gridColumnAlignment(.trailing)
            Text(value)
                .monospacedDigit()
                .lineLimit(3)
        }
    }
}
