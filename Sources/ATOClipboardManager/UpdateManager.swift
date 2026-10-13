import AppKit
import Foundation

struct AppRelease: Codable, Identifiable, Equatable {
    let tagName: String
    let name: String
    let publishedAt: Date
    let pageURL: URL
    let releaseNotes: String
    let assets: [ReleaseAsset]

    var id: String { tagName }
    var version: String { VersionNumber.normalized(tagName) }
    var dmgAsset: ReleaseAsset? {
        assets.first { $0.name.lowercased().hasSuffix(".dmg") }
    }
}

struct ReleaseAsset: Codable, Equatable {
    let name: String
    let downloadURL: URL
}

struct VersionNumber: Comparable, Equatable {
    private let components: [Int]

    init(_ value: String) {
        components = Self.normalized(value)
            .split(separator: ".")
            .map { component in
                Int(component.prefix(while: { $0.isNumber })) ?? 0
            }
    }

    static func normalized(_ value: String) -> String {
        var value = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if value.lowercased().hasPrefix("v") { value.removeFirst() }
        return value
    }

    static func < (lhs: VersionNumber, rhs: VersionNumber) -> Bool {
        let count = max(lhs.components.count, rhs.components.count)
        for index in 0..<count {
            let left = index < lhs.components.count ? lhs.components[index] : 0
            let right = index < rhs.components.count ? rhs.components[index] : 0
            if left != right { return left < right }
        }
        return false
    }

    static func == (lhs: VersionNumber, rhs: VersionNumber) -> Bool {
        !(lhs < rhs) && !(rhs < lhs)
    }
}

@MainActor
final class UpdateManager: ObservableObject {
    private enum DefaultsKey {
        static let lastCheck = "updates.lastCheck"
        static let cachedReleases = "updates.cachedReleases"
    }

    private static let releasesURL = URL(string: "https://api.github.com/repos/simonepiteo/ato-clipboard-manager/releases?per_page=30")!
    private static let checkInterval: TimeInterval = 24 * 60 * 60

    @Published private(set) var releases: [AppRelease] = []
    @Published private(set) var isChecking = false
    @Published private(set) var isInstalling = false
    @Published private(set) var lastChecked: Date?
    @Published var errorMessage: String?

    private let defaults: UserDefaults
    private var timer: Timer?

    var currentVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "development"
    }

    var availableUpdate: AppRelease? {
        guard currentVersion != "development" else { return nil }
        let installed = VersionNumber(currentVersion)
        return releases.first { VersionNumber($0.version) > installed && $0.dmgAsset != nil }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        lastChecked = defaults.object(forKey: DefaultsKey.lastCheck) as? Date
        if let data = defaults.data(forKey: DefaultsKey.cachedReleases),
           let cached = try? JSONDecoder().decode([AppRelease].self, from: data) {
            releases = cached
        }
        timer = Timer.scheduledTimer(withTimeInterval: 60 * 60, repeats: true) { [weak self] _ in
            Task { @MainActor in await self?.checkIfNeeded() }
        }
    }

    deinit { timer?.invalidate() }

    func checkIfNeeded(force: Bool = false) async {
        guard !isChecking else { return }
        if !force, let lastChecked, Date().timeIntervalSince(lastChecked) < Self.checkInterval { return }

        isChecking = true
        errorMessage = nil
        defer { isChecking = false }

        do {
            var request = URLRequest(url: Self.releasesURL)
            request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
            request.setValue("ATO-Clipboard-Manager", forHTTPHeaderField: "User-Agent")
            request.timeoutInterval = 30
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                throw UpdateError.serverResponse
            }

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let apiReleases = try decoder.decode([GitHubRelease].self, from: data)
            releases = apiReleases
                .filter { !$0.draft && !$0.prerelease }
                .map(\.appRelease)
                .sorted { VersionNumber($0.version) > VersionNumber($1.version) }
            lastChecked = Date()
            defaults.set(lastChecked, forKey: DefaultsKey.lastCheck)
            defaults.set(try JSONEncoder().encode(releases), forKey: DefaultsKey.cachedReleases)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @discardableResult
    func install(_ release: AppRelease) async -> Bool {
        guard !isInstalling, let asset = release.dmgAsset else {
            errorMessage = UpdateError.missingDMG.localizedDescription
            return false
        }
        isInstalling = true
        errorMessage = nil
        defer { isInstalling = false }

        do {
            let currentAppURL = Bundle.main.bundleURL
            guard currentAppURL.pathExtension == "app" else { throw UpdateError.notRunningFromApp }
            guard FileManager.default.isWritableFile(atPath: currentAppURL.deletingLastPathComponent().path) else {
                throw UpdateError.installationFolderNotWritable
            }

            var request = URLRequest(url: asset.downloadURL)
            request.setValue("ATO-Clipboard-Manager", forHTTPHeaderField: "User-Agent")
            let (temporaryURL, response) = try await URLSession.shared.download(for: request)
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                throw UpdateError.downloadFailed
            }

            let appURL = try await Task.detached(priority: .userInitiated) {
                try UpdateInstaller.prepare(
                    downloadedDMG: temporaryURL,
                    expectedVersion: release.version,
                    currentAppURL: currentAppURL
                )
            }.value
            try UpdateInstaller.launchReplacement(stagedAppURL: appURL, currentAppURL: currentAppURL)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { NSApp.terminate(nil) }
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}

private struct GitHubRelease: Decodable {
    let tagName: String
    let name: String?
    let publishedAt: Date
    let htmlURL: URL
    let body: String?
    let draft: Bool
    let prerelease: Bool
    let assets: [GitHubAsset]

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case name
        case publishedAt = "published_at"
        case htmlURL = "html_url"
        case body, draft, prerelease, assets
    }

    var appRelease: AppRelease {
        AppRelease(
            tagName: tagName,
            name: name?.isEmpty == false ? name! : tagName,
            publishedAt: publishedAt,
            pageURL: htmlURL,
            releaseNotes: body ?? "",
            assets: assets.map { ReleaseAsset(name: $0.name, downloadURL: $0.browserDownloadURL) }
        )
    }
}

private struct GitHubAsset: Decodable {
    let name: String
    let browserDownloadURL: URL

    enum CodingKeys: String, CodingKey {
        case name
        case browserDownloadURL = "browser_download_url"
    }
}

private enum UpdateError: LocalizedError {
    case serverResponse, missingDMG, notRunningFromApp, installationFolderNotWritable
    case downloadFailed, invalidDiskImage, appNotFound, invalidApplication, replacementFailed

    var errorDescription: String? {
        switch self {
        case .serverResponse: "GitHub returned an unexpected response."
        case .missingDMG: "This release does not include a DMG installer."
        case .notRunningFromApp: "Updates can only be installed from the packaged application."
        case .installationFolderNotWritable: "ATO cannot replace the app in its current folder. Move it to a folder you can modify and try again."
        case .downloadFailed: "The update could not be downloaded."
        case .invalidDiskImage: "The downloaded disk image could not be opened."
        case .appNotFound: "The disk image does not contain ATO Clipboard Manager."
        case .invalidApplication: "The downloaded application could not be verified."
        case .replacementFailed: "The update installer could not be started."
        }
    }
}

private enum UpdateInstaller {
    static func prepare(downloadedDMG: URL, expectedVersion: String, currentAppURL: URL) throws -> URL {
        let manager = FileManager.default
        let root = manager.temporaryDirectory.appendingPathComponent("ato-update-\(UUID().uuidString)", isDirectory: true)
        try manager.createDirectory(at: root, withIntermediateDirectories: true)
        let dmgURL = root.appendingPathComponent("update.dmg")
        try manager.moveItem(at: downloadedDMG, to: dmgURL)

        let attach = try run("/usr/bin/hdiutil", ["attach", "-nobrowse", "-readonly", "-plist", dmgURL.path])
        guard attach.status == 0,
              let plist = try PropertyListSerialization.propertyList(from: attach.output, format: nil) as? [String: Any],
              let entities = plist["system-entities"] as? [[String: Any]],
              let mountPath = entities.compactMap({ $0["mount-point"] as? String }).last else {
            throw UpdateError.invalidDiskImage
        }
        defer { _ = try? run("/usr/bin/hdiutil", ["detach", mountPath, "-force"]) }

        let mountedURL = URL(fileURLWithPath: mountPath, isDirectory: true)
        guard let enumerator = manager.enumerator(at: mountedURL, includingPropertiesForKeys: nil),
              let sourceApp = enumerator.compactMap({ $0 as? URL }).first(where: { $0.pathExtension == "app" }) else {
            throw UpdateError.appNotFound
        }

        let stagedApp = root.appendingPathComponent("ATO Clipboard Manager.app", isDirectory: true)
        try manager.copyItem(at: sourceApp, to: stagedApp)
        guard let bundle = Bundle(url: stagedApp),
              bundle.bundleIdentifier == Bundle(url: currentAppURL)?.bundleIdentifier,
              let version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
              VersionNumber(version) == VersionNumber(expectedVersion) else {
            throw UpdateError.invalidApplication
        }
        let verification = try run("/usr/bin/codesign", ["--verify", "--deep", "--strict", stagedApp.path])
        guard verification.status == 0 else { throw UpdateError.invalidApplication }
        return stagedApp
    }

    @MainActor
    static func launchReplacement(stagedAppURL: URL, currentAppURL: URL) throws {
        let scriptURL = stagedAppURL.deletingLastPathComponent().appendingPathComponent("install-update.zsh")
        let script = """
        #!/bin/zsh
        pid="$1"
        staged="$2"
        current="$3"
        incoming="${current}.ato-update-new"
        backup="${current}.ato-update-backup"
        while /bin/kill -0 "$pid" 2>/dev/null; do /bin/sleep 0.2; done
        /bin/rm -rf "$incoming" "$backup"
        if ! /usr/bin/ditto "$staged" "$incoming"; then exit 1; fi
        if ! /bin/mv "$current" "$backup"; then exit 1; fi
        if /bin/mv "$incoming" "$current"; then
          /usr/bin/open "$current"
          /bin/rm -rf "$backup" "${staged:h}"
        else
          /bin/mv "$backup" "$current"
          exit 1
        fi
        """
        try script.write(to: scriptURL, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: scriptURL.path)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = [scriptURL.path, String(ProcessInfo.processInfo.processIdentifier), stagedAppURL.path, currentAppURL.path]
        do { try process.run() } catch { throw UpdateError.replacementFailed }
    }

    private static func run(_ executable: String, _ arguments: [String]) throws -> (status: Int32, output: Data) {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.standardOutput = pipe
        process.standardError = Pipe()
        try process.run()
        let output = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        return (process.terminationStatus, output)
    }
}
