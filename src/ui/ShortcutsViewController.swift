import Cocoa

// MARK: - Table Row Model

private enum ShortcutTableRow {
    case category(String)
    case shortcut(Int)  // config index into ConfigManager.shared.config.shortcuts

    var isCategory: Bool {
        if case .category = self { return true }
        return false
    }

    var configIndex: Int? {
        if case .shortcut(let index) = self { return index }
        return nil
    }
}

// MARK: - Shortcuts View Controller

class ShortcutsViewController: NSViewController {

    // MARK: - UI Elements

    private var tableView: NSTableView!
    private var addButton: NSButton!
    private var editButton: NSButton!
    private var removeButton: NSButton!

    // MARK: - Data

    private var rows: [ShortcutTableRow] = []

    // MARK: - Column resize debounce

    private var columnResizeWorkItem: DispatchWorkItem?

    // MARK: - Identifiers

    private static let toggleColumnID = NSUserInterfaceItemIdentifier("toggleColumn")
    private static let shortcutColumnID = NSUserInterfaceItemIdentifier("shortcutColumn")
    private static let actionColumnID = NSUserInterfaceItemIdentifier("actionColumn")
    private static let commandColumnID = NSUserInterfaceItemIdentifier("commandColumn")
    private static let workdirColumnID = NSUserInterfaceItemIdentifier("workdirColumn")

    private static let groupCellID = NSUserInterfaceItemIdentifier("GroupCell")
    private static let toggleCellID = NSUserInterfaceItemIdentifier("ToggleCell")
    private static let textCellID = NSUserInterfaceItemIdentifier("TextCell")

    // Column menu item tags
    private static let shortcutColumnTag = 1
    private static let actionColumnTag = 2
    private static let commandColumnTag = 3
    private static let workdirColumnTag = 4

    // MARK: - Lifecycle

    override func loadView() {
        view = NSView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        buildRows()
        setupUI()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(columnDidResize(_:)),
            name: NSTableView.columnDidResizeNotification,
            object: tableView
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        columnResizeWorkItem?.cancel()
    }

    // MARK: - Data

    private func buildRows() {
        rows.removeAll()
        let shortcuts = ConfigManager.shared.config.shortcuts

        var categorized: [String: [Int]] = [:]
        var uncategorized: [Int] = []

        for (index, shortcut) in shortcuts.enumerated() {
            if shortcut.category.isEmpty {
                uncategorized.append(index)
            } else {
                categorized[shortcut.category, default: []].append(index)
            }
        }

        // Sorted categories first
        for category in categorized.keys.sorted() {
            rows.append(.category(category))
            for configIndex in categorized[category]! {
                rows.append(.shortcut(configIndex))
            }
        }

        // "No Category" last
        if !uncategorized.isEmpty {
            rows.append(.category("No Category"))
            for configIndex in uncategorized {
                rows.append(.shortcut(configIndex))
            }
        }
    }

    // MARK: - UI Setup

    private func setupUI() {
        let container = view

        // ── Table View ──

        tableView = NSTableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.style = .plain
        tableView.usesAlternatingRowBackgroundColors = true
        tableView.allowsMultipleSelection = false
        tableView.columnAutoresizingStyle = .lastColumnOnlyAutoresizingStyle
        tableView.rowSizeStyle = .default
        tableView.autoresizingMask = [.width]
        tableView.allowsColumnReordering = false
        tableView.floatsGroupRows = false

        let tableConfig = ConfigManager.shared.config.window.shortcutsTable

        let toggleColumn = NSTableColumn(identifier: Self.toggleColumnID)
        toggleColumn.title = "State"
        toggleColumn.width = 40
        toggleColumn.minWidth = 40
        toggleColumn.maxWidth = 40
        toggleColumn.resizingMask = []

        let shortcutColumn = NSTableColumn(identifier: Self.shortcutColumnID)
        shortcutColumn.width = CGFloat(tableConfig.shortcutColumnWidth)
        shortcutColumn.title = "Shortcut"
        shortcutColumn.isHidden = !tableConfig.shortcutColumn
        shortcutColumn.resizingMask = [.userResizingMask, .autoresizingMask]

        let actionColumn = NSTableColumn(identifier: Self.actionColumnID)
        actionColumn.width = CGFloat(tableConfig.actionColumnWidth)
        actionColumn.title = "Action"
        actionColumn.isHidden = !tableConfig.actionColumn
        actionColumn.resizingMask = [.userResizingMask, .autoresizingMask]

        let commandColumn = NSTableColumn(identifier: Self.commandColumnID)
        commandColumn.width = CGFloat(tableConfig.commandColumnWidth)
        commandColumn.title = "Command"
        commandColumn.isHidden = !tableConfig.commandColumn
        commandColumn.resizingMask = [.userResizingMask, .autoresizingMask]

        let workdirColumn = NSTableColumn(identifier: Self.workdirColumnID)
        workdirColumn.width = CGFloat(tableConfig.workdirColumnWidth)
        workdirColumn.title = "Workdir"
        workdirColumn.isHidden = !tableConfig.workdirColumn
        workdirColumn.resizingMask = [.userResizingMask, .autoresizingMask]

        tableView.addTableColumn(toggleColumn)
        tableView.addTableColumn(shortcutColumn)
        tableView.addTableColumn(actionColumn)
        tableView.addTableColumn(commandColumn)
        tableView.addTableColumn(workdirColumn)

        // ── Column Header Context Menu ──

        let headerMenu = NSMenu()
        headerMenu.delegate = self

        let shortcutMenuItem = NSMenuItem(title: "Shortcut", action: #selector(toggleColumnVisibility(_:)), keyEquivalent: "")
        shortcutMenuItem.tag = Self.shortcutColumnTag
        shortcutMenuItem.target = self
        headerMenu.addItem(shortcutMenuItem)

        let actionMenuItem = NSMenuItem(title: "Action", action: #selector(toggleColumnVisibility(_:)), keyEquivalent: "")
        actionMenuItem.tag = Self.actionColumnTag
        actionMenuItem.target = self
        headerMenu.addItem(actionMenuItem)

        let commandMenuItem = NSMenuItem(title: "Command", action: #selector(toggleColumnVisibility(_:)), keyEquivalent: "")
        commandMenuItem.tag = Self.commandColumnTag
        commandMenuItem.target = self
        headerMenu.addItem(commandMenuItem)

        let workdirMenuItem = NSMenuItem(title: "Workdir", action: #selector(toggleColumnVisibility(_:)), keyEquivalent: "")
        workdirMenuItem.tag = Self.workdirColumnTag
        workdirMenuItem.target = self
        headerMenu.addItem(workdirMenuItem)

        tableView.headerView?.menu = headerMenu

        // ── Scroll View ──

        let scrollView = NSScrollView()
        scrollView.documentView = tableView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        // ── Buttons ──

        addButton = makeIconButton(imageName: "bx-plus-circle", toolTip: "Add new shortcut")
        editButton = makeIconButton(imageName: "bx-pencil-circle", toolTip: "Edit selected shortcut")
        removeButton = makeIconButton(imageName: "bx-x-circle", toolTip: "Remove selected shortcut")

        editButton.isEnabled = false
        removeButton.isEnabled = false

        let buttonStack = NSStackView()
        buttonStack.orientation = .horizontal
        buttonStack.spacing = 8
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        buttonStack.addView(addButton, in: .center)
        buttonStack.addView(editButton, in: .center)
        buttonStack.addView(removeButton, in: .center)

        // ── Layout ──

        container.addSubview(scrollView)
        container.addSubview(buttonStack)

        NSLayoutConstraint.activate([
            // Scroll view fills the area above the buttons
            scrollView.topAnchor.constraint(equalTo: container.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: buttonStack.topAnchor, constant: -8),

            // Button stack at the bottom-center
            buttonStack.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            buttonStack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12),
        ])
    }

    // MARK: - Helpers

    private func makeIconButton(imageName: String, toolTip: String) -> NSButton {
        let button = NSButton(frame: .zero)
        let originalImage = NSImage(named: imageName)
        let image = (originalImage?.copy() as? NSImage) ?? originalImage!
        image.isTemplate = true
        image.size = NSSize(width: 24, height: 24)
        button.image = image
        button.isBordered = false
        button.imagePosition = .imageOnly
        button.toolTip = toolTip
        button.contentTintColor = .labelColor
        button.bezelStyle = .inline
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }

    private func updateButtonStates() {
        let selectedRow = tableView.selectedRow
        let hasValidSelection = selectedRow >= 0 && rows[selectedRow].isCategory == false
        editButton.isEnabled = hasValidSelection
        removeButton.isEnabled = hasValidSelection
    }

    private var appDelegate: AppDelegate? {
        NSApp.delegate as? AppDelegate
    }

    // MARK: - Toggle Shortcut

    @objc private func toggleClicked(_ sender: NSButton) {
        let configIndex = sender.tag
        guard configIndex >= 0 && configIndex < ConfigManager.shared.config.shortcuts.count else { return }

        let shortcut = ConfigManager.shared.config.shortcuts[configIndex]
        let newEnabled = !shortcut.enabled
        ConfigManager.shared.config.shortcuts[configIndex].enabled = newEnabled

        if newEnabled {
            _ = appDelegate?.registerShortcut(at: configIndex)
        } else {
            appDelegate?.unregisterShortcut(at: configIndex)
        }

        // Save config
        ConfigManager.shared.save()

        // Rebuild menu (enabled shortcuts appear in the status bar menu)
        appDelegate?.rebuildMenu()

        // Reload the toggle cell for this row
        if let row = rows.firstIndex(where: { $0.configIndex == configIndex }) {
            tableView.reloadData(forRowIndexes: IndexSet(integer: row), columnIndexes: IndexSet(integer: 0))
        }
    }

    // MARK: - Column Visibility

    @objc private func toggleColumnVisibility(_ sender: NSMenuItem) {
        switch sender.tag {
        case Self.shortcutColumnTag:
            ConfigManager.shared.config.window.shortcutsTable.shortcutColumn.toggle()
            let newValue = ConfigManager.shared.config.window.shortcutsTable.shortcutColumn
            tableView.tableColumn(withIdentifier: Self.shortcutColumnID)?.isHidden = !newValue
        case Self.actionColumnTag:
            ConfigManager.shared.config.window.shortcutsTable.actionColumn.toggle()
            let newValue = ConfigManager.shared.config.window.shortcutsTable.actionColumn
            tableView.tableColumn(withIdentifier: Self.actionColumnID)?.isHidden = !newValue
        case Self.commandColumnTag:
            ConfigManager.shared.config.window.shortcutsTable.commandColumn.toggle()
            let newValue = ConfigManager.shared.config.window.shortcutsTable.commandColumn
            tableView.tableColumn(withIdentifier: Self.commandColumnID)?.isHidden = !newValue
        case Self.workdirColumnTag:
            ConfigManager.shared.config.window.shortcutsTable.workdirColumn.toggle()
            let newValue = ConfigManager.shared.config.window.shortcutsTable.workdirColumn
            tableView.tableColumn(withIdentifier: Self.workdirColumnID)?.isHidden = !newValue
        default:
            break
        }

        ConfigManager.shared.save()
    }

    // MARK: - Column Resize Persistence

    @objc private func columnDidResize(_ notification: Notification) {
        if let column = tableView.tableColumn(withIdentifier: Self.shortcutColumnID) {
            ConfigManager.shared.config.window.shortcutsTable.shortcutColumnWidth = Int(column.width)
        }
        if let column = tableView.tableColumn(withIdentifier: Self.actionColumnID) {
            ConfigManager.shared.config.window.shortcutsTable.actionColumnWidth = Int(column.width)
        }
        if let column = tableView.tableColumn(withIdentifier: Self.commandColumnID) {
            ConfigManager.shared.config.window.shortcutsTable.commandColumnWidth = Int(column.width)
        }
        if let column = tableView.tableColumn(withIdentifier: Self.workdirColumnID) {
            ConfigManager.shared.config.window.shortcutsTable.workdirColumnWidth = Int(column.width)
        }

        // Ensure the last visible column shrinks if total column width exceeds table width,
        // preventing horizontal scrolling
        ensureLastColumnFits()

        // Debounce the config save to avoid excessive disk writes during drag
        columnResizeWorkItem?.cancel()
        let workItem = DispatchWorkItem {
            ConfigManager.shared.save()
        }
        columnResizeWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: workItem)
    }

    /// Ensure the last visible data column is sized so that total column width
    /// does not exceed the table's visible width, preventing horizontal scrolling.
    private func ensureLastColumnFits() {
        let tableWidth = tableView.bounds.width
        let totalColumnWidth = tableView.tableColumns.reduce(0.0) { $0 + $1.width }
        if totalColumnWidth > tableWidth {
            let overflow = totalColumnWidth - tableWidth
            // Find the last visible data column and shrink it
            let dataColumnIDs = [Self.shortcutColumnID, Self.actionColumnID, Self.commandColumnID, Self.workdirColumnID]
            for columnID in dataColumnIDs.reversed() {
                if let column = tableView.tableColumn(withIdentifier: columnID), !column.isHidden {
                    let newWidth = max(column.minWidth, column.width - overflow)
                    column.width = newWidth
                    break
                }
            }
        }
    }
}

// MARK: - NSTableViewDataSource

extension ShortcutsViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return rows.count
    }
}

// MARK: - NSTableViewDelegate

extension ShortcutsViewController: NSTableViewDelegate {

    func tableView(_ tableView: NSTableView, isGroupRow row: Int) -> Bool {
        guard row >= 0 && row < rows.count else { return false }
        return rows[row].isCategory
    }

    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        guard row >= 0 && row < rows.count else { return false }
        return !rows[row].isCategory
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard row >= 0 && row < rows.count else { return nil }

        let item = rows[row]

        if item.isCategory {
            // Group row: return a cell with textField set — isGroupRow merges it across the row
            let cellIdentifier = Self.groupCellID
            var cellView = tableView.makeView(withIdentifier: cellIdentifier, owner: self) as? NSTableCellView

            if cellView == nil {
                cellView = NSTableCellView()
                cellView!.identifier = cellIdentifier
                cellView!.clipsToBounds = false

                let textField = NSTextField(labelWithString: "")
                textField.font = NSFont.systemFont(ofSize: NSFont.systemFontSize, weight: .semibold)
                textField.textColor = .secondaryLabelColor
                textField.translatesAutoresizingMaskIntoConstraints = false
                cellView!.addSubview(textField)
                // CRITICAL: set the textField outlet so NSTableView can use it for group row rendering
                cellView!.textField = textField

                NSLayoutConstraint.activate([
                    textField.leadingAnchor.constraint(equalTo: cellView!.leadingAnchor, constant: 4),
                    textField.trailingAnchor.constraint(lessThanOrEqualTo: cellView!.trailingAnchor, constant: -4),
                    textField.centerYAnchor.constraint(equalTo: cellView!.centerYAnchor),
                ])
            }

            if case .category(let name) = item {
                cellView!.textField?.stringValue = name
            }

            return cellView
        }

        // Shortcut row
        guard let configIndex = item.configIndex else { return nil }
        guard configIndex < ConfigManager.shared.config.shortcuts.count else { return nil }
        let shortcutConfig = ConfigManager.shared.config.shortcuts[configIndex]

        switch tableColumn?.identifier {
        case Self.toggleColumnID:
            return makeToggleCell(for: shortcutConfig, configIndex: configIndex)
        case Self.shortcutColumnID:
            return makeTextCell(text: shortcutConfig.shortcut)
        case Self.actionColumnID:
            return makeTextCell(text: shortcutConfig.action)
        case Self.commandColumnID:
            return makeTextCell(text: shortcutConfig.command)
        case Self.workdirColumnID:
            return makeTextCell(text: shortcutConfig.workdir)
        default:
            return nil
        }
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        updateButtonStates()
    }

    // MARK: - Cell Factories

    private func makeToggleCell(for shortcut: ShortcutConfig, configIndex: Int) -> NSTableCellView {
        let cellIdentifier = Self.toggleCellID
        var cellView = tableView.makeView(withIdentifier: cellIdentifier, owner: self) as? NSTableCellView

        if cellView == nil {
            cellView = NSTableCellView()
            cellView!.identifier = cellIdentifier

            let button = NSButton(frame: .zero)
            button.isBordered = false
            button.imagePosition = .imageOnly
            button.bezelStyle = .inline
            button.target = self
            button.action = #selector(ShortcutsViewController.toggleClicked(_:))
            button.translatesAutoresizingMaskIntoConstraints = false
            cellView!.addSubview(button)

            NSLayoutConstraint.activate([
                button.widthAnchor.constraint(equalToConstant: 24),
                button.heightAnchor.constraint(equalToConstant: 13),
                button.centerXAnchor.constraint(equalTo: cellView!.centerXAnchor),
                button.centerYAnchor.constraint(equalTo: cellView!.centerYAnchor),
            ])
        }

        if let button = cellView?.subviews.first as? NSButton {
            let imageName = shortcut.enabled ? "bx-toggle-right" : "bx-toggle-left"
            let image = (NSImage(named: imageName)?.copy() as? NSImage) ?? NSImage(named: imageName)!
            image.isTemplate = true
            image.size = NSSize(width: 24, height: 13)
            button.image = image
            button.tag = configIndex

            let registrationFailed = appDelegate?.isRegistrationFailed(at: configIndex) ?? false

            if shortcut.enabled && registrationFailed {
                button.contentTintColor = .systemRed
            } else if shortcut.enabled {
                button.contentTintColor = .systemGreen
            } else {
                button.contentTintColor = .tertiaryLabelColor
            }
        }

        return cellView!
    }

    private func makeTextCell(text: String) -> NSTableCellView {
        let cellIdentifier = Self.textCellID
        var cellView = tableView.makeView(withIdentifier: cellIdentifier, owner: self) as? NSTableCellView

        if cellView == nil {
            cellView = NSTableCellView()
            cellView!.identifier = cellIdentifier

            let textField = NSTextField(labelWithString: "")
            textField.translatesAutoresizingMaskIntoConstraints = false
            textField.lineBreakMode = .byTruncatingTail
            textField.font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
            cellView!.addSubview(textField)
            cellView!.textField = textField

            NSLayoutConstraint.activate([
                textField.leadingAnchor.constraint(equalTo: cellView!.leadingAnchor, constant: 4),
                textField.trailingAnchor.constraint(equalTo: cellView!.trailingAnchor, constant: -4),
                textField.centerYAnchor.constraint(equalTo: cellView!.centerYAnchor),
            ])
        }

        cellView!.textField?.stringValue = text
        return cellView!
    }
}

// MARK: - NSMenuDelegate (Column Header Menu)

extension ShortcutsViewController: NSMenuDelegate {
    func menuNeedsUpdate(_ menu: NSMenu) {
        let tableConfig = ConfigManager.shared.config.window.shortcutsTable

        for item in menu.items {
            switch item.tag {
            case Self.shortcutColumnTag:
                item.state = tableConfig.shortcutColumn ? .on : .off
            case Self.actionColumnTag:
                item.state = tableConfig.actionColumn ? .on : .off
            case Self.commandColumnTag:
                item.state = tableConfig.commandColumn ? .on : .off
            case Self.workdirColumnTag:
                item.state = tableConfig.workdirColumn ? .on : .off
            default:
                break
            }
        }
    }
}
