import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct ClipboardFileMetadata {
    let byteCount: Int64?
    let modifiedAt: Date?
    let kind: String?
    let isDirectory: Bool

    static func read(_ file: ClipboardFile) -> Self {
        let values = try? file.url.resourceValues(forKeys: [
            .fileSizeKey, .isDirectoryKey, .contentModificationDateKey, .contentTypeKey
        ])
        let isDirectory = values?.isDirectory == true
        return Self(
            byteCount: isDirectory ? nil : values?.fileSize.map(Int64.init),
            modifiedAt: values?.contentModificationDate,
            kind: values?.contentType?.localizedDescription
                ?? UTType(filenameExtension: file.url.pathExtension)?.localizedDescription,
            isDirectory: isDirectory
        )
    }
}

struct SingleFileClipboardPreview: View {
    let file: ClipboardFile
    let language: AppLanguage
    let icon: NSImage
    @State private var metadata: ClipboardFileMetadata?

    var body: some View {
        SingleFileDetailsContent(file: file, language: language, icon: icon, metadata: metadata)
            .task(id: file.path) {
                // File URLs may point to external or network volumes; keep I/O off the UI thread.
                let result = await Task.detached(priority: .utility) {
                    ClipboardFileMetadata.read(file)
                }.value
                guard !Task.isCancelled else { return }
                metadata = result
            }
    }
}

struct SingleFileDetailsContent: View {
    let file: ClipboardFile
    let language: AppLanguage
    let icon: NSImage
    let metadata: ClipboardFileMetadata?

    private var unavailable: String { Localizer.text(.fileInfoUnavailable, language: language) }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                Image(nsImage: icon)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(width: 44, height: 44)
                VStack(alignment: .leading, spacing: 3) {
                    Text(file.name)
                        .font(.caption.weight(.semibold))
                        .lineLimit(2)
                        .truncationMode(.middle)
                    Text(metadata?.isDirectory == true
                         ? Localizer.text(.fileFolder, language: language)
                         : metadata?.kind ?? unavailable)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            VStack(spacing: 4) {
                if metadata?.isDirectory != true {
                    detailRow(.fileSize, value: metadata?.byteCount.map {
                        ByteCountFormatter.string(fromByteCount: $0, countStyle: .file)
                    } ?? unavailable)
                }
                detailRow(.fileModified, value: metadata?.modifiedAt.map {
                    $0.formatted(.dateTime.day().month(.abbreviated).year().locale(Locale(identifier: language.rawValue)))
                } ?? unavailable)
            }

            Text(file.url.deletingLastPathComponent().path)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .truncationMode(.middle)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func detailRow(_ title: LocalizedKey, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(Localizer.text(title, language: language))
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
            Text(value)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .font(.caption2)
    }
}
