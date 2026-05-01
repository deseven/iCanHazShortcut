import Foundation

// MARK: - Command Result

/// Result of a command execution in test mode.
struct CommandResult {
    let stdout: String
    let stderr: String
    let exitCode: Int32
}

// MARK: - Command Runner

/// Runs commands asynchronously with support for "run and forget" and "test" modes.
///
/// Uses `Process` (NSTask) under the hood.
///
/// In "run and forget" mode (default, `test = false`), the process is launched and
/// detached — no output is captured and no completion callback is invoked.
///
/// In "test" mode (`test = true`), stdout and stderr are captured and delivered via
/// a completion handler on the main thread when the process finishes. The running
/// process can be killed pre-emptively by calling `kill()`.
class CommandRunner {

    /// The currently running process (only tracked in test mode).
    private var process: Process?

    // MARK: - Public API

    /// Run a command asynchronously.
    ///
    /// - Parameters:
    ///   - test: If `false` (default), runs in "fire and forget" mode. If `true`,
    ///     captures stdout/stderr and calls `completion` on the main thread when done.
    ///   - workingDirectory: Optional working directory. If it starts with `~`, the tilde
    ///     is expanded using `NSString.expandingTildeInPath`.
    ///   - shell: Optional shell path with optional arguments (e.g. `/bin/zsh -l`).
    ///     If provided, the shell is spawned and `command` is written to its stdin.
    ///     If empty, `command` is launched directly as an executable path with arguments.
    ///   - command: The command to execute. If `shell` is set, this string is written to
    ///     the shell's stdin. Otherwise, it's parsed into an executable path and arguments.
    ///   - completion: Called on the main thread with a `CommandResult` when the process
    ///     finishes (test mode only). Not called in "run and forget" mode.
    func run(
        test: Bool = false,
        workingDirectory: String = "",
        shell: String = "",
        command: String,
        completion: ((CommandResult) -> Void)? = nil
    ) {
        guard !command.isEmpty else {
            if test {
                completion?(CommandResult(stdout: "", stderr: "", exitCode: -1))
            }
            return
        }

        let task = Process()

        // Resolve working directory (expand ~ if present)
        if !workingDirectory.isEmpty {
            let resolved = (workingDirectory as NSString).expandingTildeInPath
            task.currentDirectoryURL = URL(fileURLWithPath: resolved)
        }

        let useShell = !shell.isEmpty

        if useShell {
            // Shell mode: spawn shell, write command to its stdin
            let parts = splitRespectingQuotes(shell)
            guard !parts.isEmpty else {
                if test {
                    completion?(CommandResult(stdout: "", stderr: "Invalid shell: \(shell)", exitCode: -1))
                }
                return
            }
            task.executableURL = URL(fileURLWithPath: parts[0])
            task.arguments = Array(parts.dropFirst())

            let stdinPipe = Pipe()
            task.standardInput = stdinPipe
        } else {
            // Direct mode: launch command as executable with arguments
            let parts = splitRespectingQuotes(command)
            guard !parts.isEmpty else {
                if test {
                    completion?(CommandResult(stdout: "", stderr: "Empty command", exitCode: -1))
                }
                return
            }
            task.executableURL = URL(fileURLWithPath: parts[0])
            task.arguments = Array(parts.dropFirst())
        }

        if test {
            runTestMode(task: task, useShell: useShell, command: command, completion: completion)
        } else {
            runAndForgetTimeMode(task: task, useShell: useShell, command: command)
        }
    }

    /// Kill the currently running process (only meaningful in test mode).
    /// Has no effect if no process is running or if the process was launched in
    /// "run and forget" mode.
    func kill() {
        process?.terminate()
        process = nil
    }

    // MARK: - Run Modes

    private func runAndForgetTimeMode(task: Process, useShell: Bool, command: String) {
        // Redirect all I/O to /dev/null
        task.standardOutput = FileHandle.nullDevice
        task.standardError = FileHandle.nullDevice

        if !useShell {
            task.standardInput = FileHandle.nullDevice
        }

        do {
            try task.run()

            if useShell, let stdinPipe = task.standardInput as? Pipe {
                writeAndCloseStdin(stdinPipe, command: command)
            }
        } catch {
            // Silently fail in run-and-forget mode
        }
    }

    private func runTestMode(task: Process, useShell: Bool, command: String,
                              completion: ((CommandResult) -> Void)?) {
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        task.standardOutput = stdoutPipe
        task.standardError = stderrPipe

        if !useShell {
            task.standardInput = FileHandle.nullDevice
        }

        self.process = task

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                try task.run()

                if useShell, let stdinPipe = task.standardInput as? Pipe {
                    self?.writeAndCloseStdin(stdinPipe, command: command)
                }

                // Read stdout and stderr concurrently to avoid deadlocks
                // when the process produces large output
                var stdoutData = Data()
                var stderrData = Data()

                let readGroup = DispatchGroup()

                readGroup.enter()
                DispatchQueue.global(qos: .userInitiated).async {
                    stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
                    readGroup.leave()
                }

                readGroup.enter()
                DispatchQueue.global(qos: .userInitiated).async {
                    stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
                    readGroup.leave()
                }

                task.waitUntilExit()
                readGroup.wait()

                let result = CommandResult(
                    stdout: String(data: stdoutData, encoding: .utf8) ?? "",
                    stderr: String(data: stderrData, encoding: .utf8) ?? "",
                    exitCode: task.terminationStatus
                )

                DispatchQueue.main.async {
                    completion?(result)
                }
            } catch {
                let result = CommandResult(
                    stdout: "",
                    stderr: error.localizedDescription,
                    exitCode: -1
                )
                DispatchQueue.main.async {
                    completion?(result)
                }
            }

            self?.process = nil
        }
    }

    // MARK: - Private Helpers

    /// Write a command string to the shell's stdin pipe and close it.
    private func writeAndCloseStdin(_ pipe: Pipe, command: String) {
        if let data = (command + "\n").data(using: .utf8) {
            pipe.fileHandleForWriting.write(data)
        }
        try? pipe.fileHandleForWriting.close()
    }

    /// Split a string into tokens, respecting single and double quotes.
    private func splitRespectingQuotes(_ string: String) -> [String] {
        var result: [String] = []
        var current = ""
        var inSingleQuote = false
        var inDoubleQuote = false

        for char in string {
            if char == "'" && !inDoubleQuote {
                inSingleQuote = !inSingleQuote
            } else if char == "\"" && !inSingleQuote {
                inDoubleQuote = !inDoubleQuote
            } else if char == " " && !inSingleQuote && !inDoubleQuote {
                if !current.isEmpty {
                    result.append(current)
                    current = ""
                }
            } else {
                current.append(char)
            }
        }

        if !current.isEmpty {
            result.append(current)
        }

        return result
    }
}
