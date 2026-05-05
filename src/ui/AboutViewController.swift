import Cocoa

// MARK: - Link Button

/// A borderless button that opens a URL when clicked.
private class LinkButton: NSButton {
    let linkURL: URL?

    init(title: String, url: String) {
        self.linkURL = URL(string: url)
        super.init(frame: .zero)
        self.title = title
        self.isBordered = false
        self.font = NSFont.systemFont(ofSize: NSFont.systemFontSize, weight: .medium)
        self.contentTintColor = .linkColor
        self.alignment = .center
        self.toolTip = url
        self.translatesAutoresizingMaskIntoConstraints = false
        self.target = self
        self.action = #selector(openURL)
    }

    init(image: NSImage, url: String) {
        self.linkURL = URL(string: url)
        super.init(frame: .zero)
        self.image = image
        self.isBordered = false
        self.imagePosition = .imageOnly
        self.contentTintColor = .labelColor
        self.toolTip = url
        self.translatesAutoresizingMaskIntoConstraints = false
        self.target = self
        self.action = #selector(openURL)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func resetCursorRects() {
        if linkURL != nil {
            addCursorRect(bounds, cursor: .pointingHand)
        }
    }

    @objc private func openURL() {
        if let url = linkURL {
            NSWorkspace.shared.open(url)
        }
    }
}

// MARK: - Action Link Button

/// A borderless button that performs an action when clicked (no URL).
private class ActionLinkButton: NSButton {
    init(title: String, target: AnyObject?, action: Selector?) {
        super.init(frame: .zero)
        self.title = title
        self.isBordered = false
        self.font = NSFont.systemFont(ofSize: NSFont.systemFontSize, weight: .medium)
        self.contentTintColor = .linkColor
        self.alignment = .center
        self.translatesAutoresizingMaskIntoConstraints = false
        self.target = target
        self.action = action
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .pointingHand)
    }
}

// MARK: - About View Controller

class AboutViewController: NSViewController {

    private var checkUpdatesButton: ActionLinkButton!

    override func loadView() {
        view = NSView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        let container = view

        // ═══════════════════════════════════════════════════════════
        // Left Panel — App Info
        // ═══════════════════════════════════════════════════════════

        let leftPanel = NSView()
        leftPanel.translatesAutoresizingMaskIntoConstraints = false

        // App icon
        let iconImageView = NSImageView()
        iconImageView.image = NSImage(named: "main")
        iconImageView.imageScaling = .scaleProportionallyUpOrDown
        iconImageView.translatesAutoresizingMaskIntoConstraints = false

        // App name & version
        let appName = Bundle.main.infoDictionary?["CFBundleName"] as? String ?? ConfigManager.appName
        let appVersion = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?.?.?"

        let nameLabel = NSTextField(labelWithString: appName)
        nameLabel.font = NSFont.systemFont(ofSize: 18, weight: .bold)
        nameLabel.alignment = .center
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        let versionLabel = NSTextField(labelWithString: appVersion)
        versionLabel.font = NSFont.systemFont(ofSize: 13, weight: .bold)
        versionLabel.textColor = .secondaryLabelColor
        versionLabel.alignment = .center
        versionLabel.translatesAutoresizingMaskIntoConstraints = false

        // "check for updates" link
        checkUpdatesButton = ActionLinkButton(
            title: "check for updates",
            target: self,
            action: #selector(checkForUpdatesClicked)
        )

        // "created by" section
        let createdByLabel = NSTextField(labelWithString: "created by")
        createdByLabel.font = NSFont.systemFont(ofSize: NSFont.systemFontSize, weight: .bold)
        createdByLabel.textColor = .secondaryLabelColor
        createdByLabel.alignment = .center
        createdByLabel.translatesAutoresizingMaskIntoConstraints = false

        let desevenLink = LinkButton(title: "deseven", url: "https://icanhazapps.d7.wtf")

        // "icons by" section
        let iconsByLabel = NSTextField(labelWithString: "icons by")
        iconsByLabel.font = NSFont.systemFont(ofSize: NSFont.systemFontSize, weight: .bold)
        iconsByLabel.textColor = .secondaryLabelColor
        iconsByLabel.alignment = .center
        iconsByLabel.translatesAutoresizingMaskIntoConstraints = false

        let boxiconsLink = LinkButton(title: "boxicons", url: "https://boxicons.com")

        let denborodaLabel = NSTextField(labelWithString: "denboroda")
        denborodaLabel.font = NSFont.systemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        denborodaLabel.alignment = .center
        denborodaLabel.translatesAutoresizingMaskIntoConstraints = false

        let aescolasticoLabel = NSTextField(labelWithString: "aescolastico")
        aescolasticoLabel.font = NSFont.systemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        aescolasticoLabel.alignment = .center
        aescolasticoLabel.translatesAutoresizingMaskIntoConstraints = false

        // Social link buttons
        let kofiButton = makeIconButton(imageName: "bx-kofi", url: "https://ko-fi.com/deseven")
        let githubButton = makeIconButton(imageName: "bx-github", url: "https://github.com/deseven/iCanHazShortcut")
        let redditButton = makeIconButton(imageName: "bx-reddit", url: "https://www.reddit.com/r/iCanHazApps")
        let telegramButton = makeIconButton(imageName: "bx-telegram", url: "https://t.me/icanhazshortcut")

        let socialStack = NSStackView()
        socialStack.orientation = .horizontal
        socialStack.spacing = 16
        socialStack.translatesAutoresizingMaskIntoConstraints = false
        socialStack.addView(kofiButton, in: .center)
        socialStack.addView(githubButton, in: .center)
        socialStack.addView(redditButton, in: .center)
        socialStack.addView(telegramButton, in: .center)

        // Add all subviews to left panel
        let leftSubviews: [NSView] = [
            iconImageView, nameLabel, versionLabel, checkUpdatesButton,
            createdByLabel, desevenLink,
            iconsByLabel, boxiconsLink, denborodaLabel, aescolasticoLabel,
            socialStack
        ]
        for sv in leftSubviews {
            leftPanel.addSubview(sv)
        }

        // Layout constants
        let iconSize: CGFloat = 96
        let tightGap: CGFloat = 2
        let sectionGap: CGFloat = 14

        NSLayoutConstraint.activate([
            // Icon
            iconImageView.widthAnchor.constraint(equalToConstant: iconSize),
            iconImageView.heightAnchor.constraint(equalToConstant: iconSize),
            iconImageView.topAnchor.constraint(equalTo: leftPanel.topAnchor, constant: 16),
            iconImageView.centerXAnchor.constraint(equalTo: leftPanel.centerXAnchor),

            // App name
            nameLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 6),
            nameLabel.centerXAnchor.constraint(equalTo: leftPanel.centerXAnchor),

            // Version
            versionLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: tightGap),
            versionLabel.centerXAnchor.constraint(equalTo: leftPanel.centerXAnchor),

            // Check for updates
            checkUpdatesButton.topAnchor.constraint(equalTo: versionLabel.bottomAnchor, constant: tightGap),
            checkUpdatesButton.centerXAnchor.constraint(equalTo: leftPanel.centerXAnchor),

            // "created by"
            createdByLabel.topAnchor.constraint(equalTo: checkUpdatesButton.bottomAnchor, constant: sectionGap),
            createdByLabel.centerXAnchor.constraint(equalTo: leftPanel.centerXAnchor),

            // deseven link
            desevenLink.topAnchor.constraint(equalTo: createdByLabel.bottomAnchor, constant: tightGap),
            desevenLink.centerXAnchor.constraint(equalTo: leftPanel.centerXAnchor),

            // "icons by"
            iconsByLabel.topAnchor.constraint(equalTo: desevenLink.bottomAnchor, constant: sectionGap),
            iconsByLabel.centerXAnchor.constraint(equalTo: leftPanel.centerXAnchor),

            // boxicons link
            boxiconsLink.topAnchor.constraint(equalTo: iconsByLabel.bottomAnchor, constant: tightGap),
            boxiconsLink.centerXAnchor.constraint(equalTo: leftPanel.centerXAnchor),

            // denboroda
            denborodaLabel.topAnchor.constraint(equalTo: boxiconsLink.bottomAnchor, constant: tightGap),
            denborodaLabel.centerXAnchor.constraint(equalTo: leftPanel.centerXAnchor),

            // aescolastico
            aescolasticoLabel.topAnchor.constraint(equalTo: denborodaLabel.bottomAnchor, constant: tightGap),
            aescolasticoLabel.centerXAnchor.constraint(equalTo: leftPanel.centerXAnchor),

            // Social icons
            socialStack.topAnchor.constraint(equalTo: aescolasticoLabel.bottomAnchor, constant: sectionGap + 5),
            socialStack.centerXAnchor.constraint(equalTo: leftPanel.centerXAnchor),
            socialStack.bottomAnchor.constraint(lessThanOrEqualTo: leftPanel.bottomAnchor, constant: -16),
        ])

        // ═══════════════════════════════════════════════════════════
        // Separator
        // ═══════════════════════════════════════════════════════════

        let separator = NSBox()
        separator.boxType = .separator
        separator.translatesAutoresizingMaskIntoConstraints = false

        // ═══════════════════════════════════════════════════════════
        // Right Panel — License
        // ═══════════════════════════════════════════════════════════

        let scrollView = NSTextView.scrollableTextView()
        scrollView.borderType = .bezelBorder
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        if let textView = scrollView.documentView as? NSTextView {
            textView.isEditable = false
            textView.isSelectable = true
            textView.isRichText = false
            textView.font = NSFont.monospacedSystemFont(ofSize: NSFont.smallSystemFontSize, weight: .regular)
            textView.textColor = .textColor
            textView.backgroundColor = .textBackgroundColor
            textView.drawsBackground = true
            textView.isAutomaticQuoteSubstitutionEnabled = false
            textView.isAutomaticDashSubstitutionEnabled = false
            textView.isAutomaticTextReplacementEnabled = false
            textView.isAutomaticSpellingCorrectionEnabled = false
            textView.isContinuousSpellCheckingEnabled = false
            textView.isGrammarCheckingEnabled = false
            textView.isHorizontallyResizable = false
            textView.isVerticallyResizable = true
            textView.textContainer?.widthTracksTextView = true
            textView.textContainer?.containerSize = NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude)
            textView.textContainerInset = NSSize(width: 8, height: 8)
            textView.string = Self.loadLicenseText()
        }

        // ═══════════════════════════════════════════════════════════
        // Main Layout
        // ═══════════════════════════════════════════════════════════

        container.addSubview(leftPanel)
        container.addSubview(separator)
        container.addSubview(scrollView)

        let outerPad: CGFloat = 20
        let leftPanelWidth: CGFloat = 200
        let columnGap: CGFloat = 16

        NSLayoutConstraint.activate([
            // Left panel
            leftPanel.topAnchor.constraint(equalTo: container.topAnchor, constant: outerPad),
            leftPanel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: outerPad),
            leftPanel.widthAnchor.constraint(equalToConstant: leftPanelWidth),
            leftPanel.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -outerPad),

            // Separator
            separator.topAnchor.constraint(equalTo: container.topAnchor, constant: outerPad),
            separator.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -outerPad),
            separator.leadingAnchor.constraint(equalTo: leftPanel.trailingAnchor, constant: columnGap),

            // Right panel
            scrollView.topAnchor.constraint(equalTo: container.topAnchor, constant: outerPad),
            scrollView.leadingAnchor.constraint(equalTo: separator.trailingAnchor, constant: columnGap),
            scrollView.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -outerPad),
            scrollView.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -outerPad),
        ])
    }

    // MARK: - Update Check

    @objc private func checkForUpdatesClicked() {
        guard !UpdateManager.shared.isChecking else { return }

        checkUpdatesButton.title = "checking for updates..."
        checkUpdatesButton.isEnabled = false

        UpdateManager.shared.checkForUpdates(manual: true) { [weak self] result in
            guard let self else { return }
            self.checkUpdatesButton.title = "check for updates"
            self.checkUpdatesButton.isEnabled = true

            switch result {
            case .success(let updateInfo):
                if let updateInfo = updateInfo {
                    self.showUpdateDialog(updateInfo: updateInfo)
                } else {
                    let alert = NSAlert()
                    alert.messageText = "You have the latest available version!"
                    alert.alertStyle = .informational
                    alert.addButton(withTitle: "OK")
                    alert.beginSheetModal(for: self.view.window!)
                }
            case .failure(let error):
                let alert = NSAlert()
                alert.messageText = "Failed to check for updates"
                alert.informativeText = error.localizedDescription
                alert.alertStyle = .warning
                alert.addButton(withTitle: "OK")
                alert.beginSheetModal(for: self.view.window!)
            }
        }
    }

    func showUpdateDialog(updateInfo: UpdateInfo) {
        guard let window = view.window else { return }

        let dialogVC = UpdateDialogViewController(
            updateInfo: updateInfo,
            onUpdate: {
                Task {
                    do {
                        try await UpdateManager.shared.downloadAndInstall(updateInfo)
                    } catch {
                        let alert = NSAlert()
                        alert.messageText = "Update failed"
                        alert.informativeText = error.localizedDescription
                        alert.alertStyle = .warning
                        alert.addButton(withTitle: "OK")
                        alert.runModal()
                    }
                }
            },
            onSkip: {
                ConfigManager.shared.config.skippedUpdate = updateInfo.version
                ConfigManager.shared.save()
            }
        )

        let sheetWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 340),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        sheetWindow.isReleasedWhenClosed = false
        sheetWindow.contentViewController = dialogVC
        sheetWindow.title = "Update Available"

        window.beginSheet(sheetWindow)
    }

    // MARK: - Helpers

    private static func loadLicenseText() -> String {
        if let url = Bundle.main.url(forResource: "LICENSE", withExtension: nil),
           let text = try? String(contentsOf: url, encoding: .utf8) {
            return text
        }
        return "License text not available."
    }

    private func makeIconButton(imageName: String, url: String) -> LinkButton {
        let originalImage = NSImage(named: imageName)
        let image = (originalImage?.copy() as? NSImage) ?? originalImage!
        image.isTemplate = true
        image.size = NSSize(width: 24, height: 24)
        return LinkButton(image: image, url: url)
    }
}
