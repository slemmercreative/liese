import SwiftUI
import UniformTypeIdentifiers

/// Read-only document: Liese is a viewer, so it just holds the file's bytes.
struct LottieDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json, .dotLottie] }

    let data: Data

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.data = data
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
