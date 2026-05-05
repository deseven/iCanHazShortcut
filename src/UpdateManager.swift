import AppKit
import Foundation
import Security

// MARK: - Semantic Version

struct SemVer: Comparable {
    let major: Int
    let minor: Int
    let patch: Int

    init(_ string: String) {
        let parts = string.split(separator: ".").compactMap { Int($0) }
        major = parts.count > 0 ? parts[0] : 0
        minor = parts.count > 1 ? parts[1] : 0
        patch = parts.count > 2 ? parts[2] : 0
    }

    static func < (lhs: SemVer, rhs: SemVer) -> Bool {
        if lhs.major != rhs.major { return lhs.major < rhs.major }
        if lhs.minor != rhs.minor { return lhs.minor < rhs.minor }
        return lhs.patch < rhs.patch
    }
}

// MARK: - GitHub API Models

struct GitHubRelease: Decodable {
    let tagName: String
    let name: String?
    let body: String?
    let prerelease: Bool
    let assets: [GitHubAsset]

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case name, body, prerelease, assets
    }

    /// Extract version from release title (format: "iCHS x.x.x text")
    var parsedVersion: String? {
        guard let name else { return nil }
        let pattern = #"iCHS\s+(\d+\.\d+\.\d+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: name, range: NSRange(name.startIndex..., in: name)),
              let range = Range(match.range(at: 1), in: name) else {
            return nil
        }
        return String(name[range])
    }
}

struct GitHubAsset: Decodable {
    let name: String
    let browserDownloadURL: URL
    let contentType: String

    enum CodingKeys: String, CodingKey {
        case name
        case browserDownloadURL = "browser_download_url"
        case contentType = "content_type"
    }
}

// MARK: - Update Info

struct UpdateInfo {
    let version: String
    let releaseTitle: String
    let changelog: String
    let downloadURL: URL
}

// MARK: - Update Error

enum UpdateError: LocalizedError {
    case invalidGitHubResponse
    case invalidDownloadedBundle
    case invalidArchiveEntry(String)
    case missingCodeSigningInfo
    case mismatchedCodeSigningInfo
    case processFailed(URL, Int32)

    var errorDescription: String? {
        switch self {
        case .invalidGitHubResponse:
            return "GitHub returned an invalid response."
        case .invalidDownloadedBundle:
            return "The downloaded update does not contain a valid app bundle."
        case .invalidArchiveEntry(let entry):
            return "The downloaded archive contains an unsafe entry: \(entry)"
        case .missingCodeSigningInfo:
            return "A bundle is missing required code-signing information."
        case .mismatchedCodeSigningInfo:
            return "The downloaded app was signed by a different identity."
        case .processFailed(let url, let status):
            return "\(url.path) failed with status \(status)"
        }
    }
}

// MARK: - Update Manager

class UpdateManager {
    static let shared = UpdateManager()

    private let owner = "deseven"
    private let repo = "iCanHazShortcut"
    private let session = URLSession.shared

    /// Interval between automatic update checks.
    static let checkInterval: TimeInterval = 24 * 60 * 60

    private var updateCheckTimer: Timer?
    private var _isChecking = false

    /// Whether an update check is currently in progress.
    var isChecking: Bool { _isChecking }

    /// Called on the main thread when an update is found during an automatic check.
    var onAutomaticUpdateFound: ((UpdateInfo) -> Void)?

    private init() {}

    // MARK: - Periodic Checks

    /// Start the periodic update check timer.
    /// The timer always runs; the `checkForUpdates` config setting is evaluated
    /// at check time so that toggling the preference takes effect immediately.
    func startPeriodicChecks() {
        stopPeriodicChecks()
        // First automatic check fires after the check interval
        updateCheckTimer = Timer.scheduledTimer(
            withTimeInterval: Self.checkInterval,
            repeats: true
        ) { [weak self] _ in
            self?.performAutomaticCheck()
        }
    }

    func stopPeriodicChecks() {
        updateCheckTimer?.invalidate()
        updateCheckTimer = nil
    }

    // MARK: - Automatic Check

    private func performAutomaticCheck() {
        guard !_isChecking else { return }

        // Respect the "check for updates" preference at check time
        guard ConfigManager.shared.config.checkForUpdates else { return }

        checkForUpdates(manual: false) { result in
            if case .success(let updateInfo) = result, let updateInfo = updateInfo {
                self.onAutomaticUpdateFound?(updateInfo)
            }
        }
    }

    // MARK: - Check for Updates

    /// Check GitHub releases for a newer version.
    /// - Parameter manual: `true` for user-initiated checks (ignores skipped version).
    /// - Parameter completion: Called on the main thread with `.success(SomeInfo)` if an update
    ///   is available, `.success(nil)` if up to date, or `.failure` on error.
    /// - Returns: `true` if the check was started, `false` if one is already in progress.
    @discardableResult
    func checkForUpdates(manual: Bool, completion: @escaping (Result<UpdateInfo?, Error>) -> Void) -> Bool {
        guard !_isChecking else { return false }
        _isChecking = true

        Log.info("checking for updates (\(manual ? "manual" : "automatic"))")

        Task {
            do {
                let releases = try await fetchReleases()
                let currentVersion = Self.currentAppVersion

                // Find the latest non-prerelease release that has a valid version and ichs.zip
                let latestRelease = releases
                    .filter { $0.parsedVersion != nil && !$0.prerelease }
                    .sorted { SemVer($0.parsedVersion!) > SemVer($1.parsedVersion!) }
                    .first { release in
                        release.assets.contains(where: { $0.name == "ichs.zip" })
                    }

                guard let release = latestRelease, let version = release.parsedVersion else {
                    Log.info("no update available")
                    await MainActor.run {
                        _isChecking = false
                        completion(.success(nil))
                    }
                    return
                }

                guard SemVer(version) > SemVer(currentVersion) else {
                    Log.info("no update available (current: v\(currentVersion), latest: v\(version))")
                    await MainActor.run {
                        _isChecking = false
                        completion(.success(nil))
                    }
                    return
                }

                // For automatic checks, respect the skipped version setting
                if !manual && ConfigManager.shared.config.skippedUpdate == version {
                    Log.info("update v\(version) skipped by user")
                    await MainActor.run {
                        _isChecking = false
                        completion(.success(nil))
                    }
                    return
                }

                let asset = release.assets.first(where: { $0.name == "ichs.zip" })!
                let updateInfo = UpdateInfo(
                    version: version,
                    releaseTitle: release.name ?? version,
                    changelog: release.body ?? "No changelog available.",
                    downloadURL: asset.browserDownloadURL
                )

                Log.info("update available: v\(version)")
                await MainActor.run {
                    _isChecking = false
                    completion(.success(updateInfo))
                }
            } catch {
                Log.info("update check failed: \(error.localizedDescription)")
                await MainActor.run {
                    _isChecking = false
                    completion(.failure(error))
                }
            }
        }

        return true
    }

    // MARK: - GitHub API

    private func fetchReleases() async throws -> [GitHubRelease] {
        let url = URL(string: "https://api.github.com/repos/\(owner)/\(repo)/releases")!
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              200..<300 ~= httpResponse.statusCode else {
            throw UpdateError.invalidGitHubResponse
        }

        return try JSONDecoder().decode([GitHubRelease].self, from: data)
    }

    // MARK: - Download & Install

    func downloadAndInstall(_ updateInfo: UpdateInfo) async throws {
        // Create temp directory for staging
        let tmpdir = try FileManager.default.url(
            for: .itemReplacementDirectory,
            in: .userDomainMask,
            appropriateFor: Bundle.main.bundleURL,
            create: true
        )

        // Download zip
        let downloadURL = tmpdir.appendingPathComponent("ichs.zip")
        let (downloadedURL, _) = try await session.download(from: updateInfo.downloadURL)
        try FileManager.default.moveItem(at: downloadedURL, to: downloadURL)

        // Validate zip entries
        let entries = try await listZipEntries(at: downloadURL)
        try validateZipEntries(entries)

        // Extract
        let extractionDir = tmpdir.appendingPathComponent("extracted", isDirectory: true)
        try FileManager.default.createDirectory(at: extractionDir, withIntermediateDirectories: true)
        _ = try await runProcess(
            URL(fileURLWithPath: "/usr/bin/ditto"),
            arguments: ["-x", "-k", downloadURL.path, extractionDir.path]
        )

        // Find .app bundle
        let appBundleURL = try findAppBundle(in: extractionDir)

        // Verify code signature
        guard let downloadedBundle = Bundle(url: appBundleURL) else {
            throw UpdateError.invalidDownloadedBundle
        }
        try verifyCodeSignature(current: .main, candidate: downloadedBundle)

        // Prepare installer
        let installedBundle = Bundle.main.bundleURL
        guard let executableURL = downloadedBundle.executableURL else {
            throw UpdateError.invalidDownloadedBundle
        }
        let relativeExecutablePath = executableURL.path.replacingOccurrences(
            of: downloadedBundle.bundleURL.path + "/",
            with: ""
        )
        let finalExecutableURL = installedBundle.appendingPathComponent(relativeExecutablePath)

        let scriptURL = try writeInstallerScript(in: tmpdir)
        try launchInstaller(
            scriptURL: scriptURL,
            pid: getpid(),
            stagedBundle: appBundleURL,
            installedBundle: installedBundle,
            executable: finalExecutableURL,
            stagingDir: tmpdir
        )

        NSApp.terminate(nil)
    }

    // MARK: - Helpers

    static var currentAppVersion: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "0.0.0"
    }

    private func listZipEntries(at url: URL) async throws -> [String] {
        let output = try await runProcess(
            URL(fileURLWithPath: "/usr/bin/unzip"),
            arguments: ["-Z", "-1", url.path]
        )
        return output.split(whereSeparator: \.isNewline).map(String.init)
    }

    private func validateZipEntries(_ entries: [String]) throws {
        guard !entries.isEmpty else {
            throw UpdateError.invalidDownloadedBundle
        }
        for entry in entries {
            let path = entry.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            let components = path.split(separator: "/").map(String.init)
            guard !entry.hasPrefix("/"), !components.contains("..") else {
                throw UpdateError.invalidArchiveEntry(entry)
            }
        }
    }

    private func findAppBundle(in directory: URL) throws -> URL {
        let contents = try FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )
        let apps = try contents.filter { url in
            guard url.pathExtension == "app" else { return false }
            return try url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory == true
        }
        guard apps.count == 1, let app = apps.first else {
            throw UpdateError.invalidDownloadedBundle
        }
        return app
    }

    // MARK: - Code Signature Verification

    private func verifyCodeSignature(current: Bundle, candidate: Bundle) throws {
        let currentCode = try staticCode(for: current)
        let candidateCode = try staticCode(for: candidate)

        // Validate current bundle signature
        var error: Unmanaged<CFError>?
        let strictFlags = SecCSFlags(
            rawValue: kSecCSStrictValidate | kSecCSCheckAllArchitectures | kSecCSCheckNestedCode
        )
        guard SecStaticCodeCheckValidityWithErrors(currentCode, strictFlags, nil, &error) == errSecSuccess else {
            _ = error?.takeRetainedValue()
            throw UpdateError.missingCodeSigningInfo
        }

        // Get designated requirement from current bundle
        var requirement: SecRequirement?
        let status = SecCodeCopyDesignatedRequirement(currentCode, SecCSFlags(), &requirement)
        guard status == errSecSuccess, let requirement else {
            throw UpdateError.missingCodeSigningInfo
        }

        // Validate candidate against current's requirement
        guard SecStaticCodeCheckValidityWithErrors(candidateCode, strictFlags, requirement, &error) == errSecSuccess else {
            _ = error?.takeRetainedValue()
            throw UpdateError.mismatchedCodeSigningInfo
        }
    }

    private func staticCode(for bundle: Bundle) throws -> SecStaticCode {
        var staticCode: SecStaticCode?
        let status = SecStaticCodeCreateWithPath(bundle.bundleURL as CFURL, SecCSFlags(), &staticCode)
        guard status == errSecSuccess, let staticCode else {
            throw UpdateError.missingCodeSigningInfo
        }
        return staticCode
    }

    // MARK: - Installer Script

    private func writeInstallerScript(in directory: URL) throws -> URL {
        let script = """
        #!/bin/sh
        set -eu

        pid="$1"
        staged_bundle="$2"
        installed_bundle="$3"
        executable="$4"
        staging_directory="$5"
        deadline=$(( $(date +%s) + 300 ))

        while kill -0 "$pid" 2>/dev/null; do
            if [ "$(date +%s)" -ge "$deadline" ]; then
                rm -rf "$staging_directory"
                exit 1
            fi
            sleep 0.2
        done

        rm -rf "$installed_bundle"
        mv "$staged_bundle" "$installed_bundle"

        if [ -x "$executable" ]; then
            "$executable" >/dev/null 2>&1 &
        else
            /usr/bin/open "$installed_bundle"
        fi

        rm -rf "$staging_directory"
        """
        let scriptURL = directory.appendingPathComponent("install-update.sh")
        try script.write(to: scriptURL, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o700],
            ofItemAtPath: scriptURL.path
        )
        return scriptURL
    }

    private func launchInstaller(
        scriptURL: URL,
        pid: pid_t,
        stagedBundle: URL,
        installedBundle: URL,
        executable: URL,
        stagingDir: URL
    ) throws {
        let process = Process()
        process.executableURL = scriptURL
        process.arguments = [
            "\(pid)",
            stagedBundle.path,
            installedBundle.path,
            executable.path,
            stagingDir.path,
        ]
        try process.run()
    }

    // MARK: - Process Runner

    private func runProcess(_ executableURL: URL, arguments: [String]) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            let stdout = Pipe()

            process.executableURL = executableURL
            process.arguments = arguments
            process.standardOutput = stdout
            process.standardError = FileHandle.nullDevice
            process.terminationHandler = { process in
                let data = stdout.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8) ?? ""
                guard process.terminationStatus == 0 else {
                    continuation.resume(throwing: UpdateError.processFailed(executableURL, process.terminationStatus))
                    return
                }
                continuation.resume(returning: output)
            }
            do {
                try process.run()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}
