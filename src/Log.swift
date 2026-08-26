import Foundation
import os

/// Unified logging for iCanHazShortcut.
///
/// Messages are written twice:
/// 1. To the unified logging system (`os.Logger`) so they're visible in
///    Console.app even when the app is launched from Finder
///    (`subsystem == "info.deseven.icanhazshortcut"`).
/// 2. To stdout/stderr so they're visible in the terminal when the app is
///    launched from the command line.
///
/// All messages are prefixed with `[iCHS]` for easy grepping.
enum Log {
    private static let logger = Logger(
        subsystem: "info.deseven.icanhazshortcut",
        category: "app"
    )

    /// General informational message.
    static func info(_ message: String) {
        logger.info("[iCHS] \(message, privacy: .public)")
        print("[iCHS] \(message)")
    }

    /// Error message — use for recoverable failures that should be
    /// diagnosable from Console.app or the terminal.
    static func error(_ message: String) {
        logger.error("[iCHS] \(message, privacy: .public)")
        fputs("[iCHS] \(message)\n", stderr)
    }
}
