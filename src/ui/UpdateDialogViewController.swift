import Cocoa

// MARK: - Update Dialog View Controller

class UpdateDialogViewController: NSViewController {

    private let updateInfo: UpdateInfo
    private let onUpdate: () -> Void
    private let onSkip: () -> Void

    // MARK: - Controls

    private let skipButton = NSButton()
    private let laterButton = NSButton()
    private let updateButton = NSButton()

    // MARK: - Init

    init(updateInfo: UpdateInfo, onUpdate: @escaping () -> Void, onSkip: @escaping () -> Void) {
        self.updateInfo = updateInfo
        self.onUpdate = onUpdate
        self.onSkip = onSkip
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func loadView() {
        view = NSView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    // MARK: - UI Setup

    private func setupUI() {
        let container = view

        let appName = ConfigManager.appName

        // Header: "A new version of {appName} was found."
        let headerText = "A new version of \(appName) was found."
        let headerLabel = NSTextField(wrappingLabelWithString: headerText)
        headerLabel.font = NSFont.systemFont(ofSize: NSFont.systemFontSize, weight: .semibold)
        headerLabel.translatesAutoresizingMaskIntoConstraints = false

        // Release title
        let titleLabel = NSTextField(wrappingLabelWithString: updateInfo.releaseTitle)
        titleLabel.font = NSFont.systemFont(ofSize: 16, weight: .bold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        // Changelog text view in scroll view
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
            textView.string = updateInfo.changelog
        }

        // Question label
        let questionLabel = NSTextField(labelWithString: "Would you like to update?")
        questionLabel.font = NSFont.systemFont(ofSize: NSFont.systemFontSize, weight: .medium)
        questionLabel.translatesAutoresizingMaskIntoConstraints = false

        // Buttons
        skipButton.title = "Skip this version"
        skipButton.bezelStyle = .rounded
        skipButton.translatesAutoresizingMaskIntoConstraints = false
        skipButton.target = self
        skipButton.action = #selector(skipClicked)

        laterButton.title = "Later"
        laterButton.bezelStyle = .rounded
        laterButton.translatesAutoresizingMaskIntoConstraints = false
        laterButton.target = self
        laterButton.action = #selector(laterClicked)

        updateButton.title = "Update"
        updateButton.bezelStyle = .rounded
        updateButton.keyEquivalent = "\r" // default button
        updateButton.translatesAutoresizingMaskIntoConstraints = false
        updateButton.target = self
        updateButton.action = #selector(updateClicked)

        let buttonStack = NSStackView()
        buttonStack.orientation = .horizontal
        buttonStack.spacing = 12
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        buttonStack.addView(skipButton, in: .center)
        buttonStack.addView(laterButton, in: .center)
        buttonStack.addView(updateButton, in: .center)

        // Add subviews
        container.addSubview(headerLabel)
        container.addSubview(titleLabel)
        container.addSubview(scrollView)
        container.addSubview(questionLabel)
        container.addSubview(buttonStack)

        let pad: CGFloat = 20
        let spacing: CGFloat = 8
        let changelogHeight: CGFloat = 180

        // Minimum width so the dialog isn't too narrow
        let minWidthConstraint = container.widthAnchor.constraint(greaterThanOrEqualToConstant: 560)
        minWidthConstraint.priority = .required

        NSLayoutConstraint.activate([
            // Min width
            minWidthConstraint,

            // Header
            headerLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: pad),
            headerLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: pad),
            headerLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -pad),

            // Release title
            titleLabel.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: spacing),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: pad),
            titleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -pad),

            // Changelog scroll view
            scrollView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: spacing),
            scrollView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: pad),
            scrollView.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -pad),
            scrollView.heightAnchor.constraint(equalToConstant: changelogHeight),

            // Question
            questionLabel.topAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: spacing + 4),
            questionLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: pad),

            // Buttons
            buttonStack.topAnchor.constraint(equalTo: questionLabel.bottomAnchor, constant: spacing + 4),
            buttonStack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -pad),
            buttonStack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -pad),
        ])
    }

    // MARK: - Actions

    @objc private func skipClicked() {
        onSkip()
        dismissSheet()
    }

    @objc private func laterClicked() {
        dismissSheet()
    }

    @objc private func updateClicked() {
        onUpdate()
        dismissSheet()
    }

    private func dismissSheet() {
        if let sheetWindow = view.window,
           let parentWindow = sheetWindow.sheetParent {
            parentWindow.endSheet(sheetWindow)
        }
    }
}
