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

// MARK: - Reorderable Table View

private class ReorderableTableView: NSTableView {
    var dragColumnIdentifier: NSUserInterfaceItemIdentifier?
    var onDeleteKeyPressed: (() -> Void)?
    private(set) var isDragFromHandle = false
    private var didPushGrabCursor = false

    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        let row = row(at: point)
        let column = column(at: point)

        // Reset from any previous interaction, then set if clicking drag handle
        isDragFromHandle = false
        if row >= 0 && column >= 0 && column < tableColumns.count,
           let dragID = dragColumnIdentifier,
           tableColumns[column].identifier == dragID {
            isDragFromHandle = true
        }

        super.mouseDown(with: event)

        // Don't reset isDragFromHandle here — draggingSession callbacks fire after mouseDown returns
    }

    override func mouseUp(with event: NSEvent) {
        isDragFromHandle = false
        super.mouseUp(with: event)
    }

    // Show closed hand cursor during drag from handle
    override func draggingSession(_ session: NSDraggingSession, willBeginAt screenPoint: NSPoint) {
        if isDragFromHandle {
            NSCursor.closedHand.push()
            didPushGrabCursor = true
        }
    }

    override func draggingSession(_ session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
        if didPushGrabCursor {
            NSCursor.pop()
            didPushGrabCursor = false
        }
        isDragFromHandle = false
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 0x33 || event.keyCode == 0x75 {  // Delete or Forward Delete
            onDeleteKeyPressed?()
        } else {
            super.keyDown(with: event)
        }
    }
}

// MARK: - Button with Pointer Cursor

private class PointerButton: NSButton {
    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .pointingHand)
    }
}

// MARK: - Image View with Grab Cursor

private class GrabImageView: NSImageView {
    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .openHand)
    }
}

// MARK: - Shortcuts View Controller

class ShortcutsViewController: NSViewController {

    // MARK: - UI Elements

    private var tableView: ReorderableTableView!
    private var addButton: NSButton!
    private var editButton: NSButton!
    private var removeButton: NSButton!

    // MARK: - Data

    private var rows: [ShortcutTableRow] = []

    // MARK: - Editor

    private var editorWindowController: ShortcutEditorWindowController?

    // MARK: - Column resize debounce

    private var columnResizeWorkItem: DispatchWorkItem?

    // MARK: - Identifiers

    private static let dragColumnID = NSUserInterfaceItemIdentifier("dragColumn")
    private static let toggleColumnID = NSUserInterfaceItemIdentifier("toggleColumn")
    private static let shortcutColumnID = NSUserInterfaceItemIdentifier("shortcutColumn")
    private static let actionColumnID = NSUserInterfaceItemIdentifier("actionColumn")
    private static let commandColumnID = NSUserInterfaceItemIdentifier("commandColumn")
    private static let workdirColumnID = NSUserInterfaceItemIdentifier("workdirColumn")

    private static let groupCellID = NSUserInterfaceItemIdentifier("GroupCell")
    private static let dragCellID = NSUserInterfaceItemIdentifier("DragCell")
    private static let toggleCellID = NSUserInterfaceItemIdentifier("ToggleCell")
    private static let textCellID = NSUserInterfaceItemIdentifier("TextCell")

    private static let shortcutPasteboardType = NSPasteboard.PasteboardType("com.ichs.shortcut-row")

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

        tableView = ReorderableTableView()
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
        tableView.dragColumnIdentifier = Self.dragColumnID
        tableView.registerForDraggedTypes([Self.shortcutPasteboardType])
        tableView.doubleAction = #selector(tableViewDoubleClicked(_:))
        tableView.target = self
        tableView.onDeleteKeyPressed = { [weak self] in
            self?.deleteSelectedShortcut()
        }

        let tableConfig = ConfigManager.shared.config.window.shortcutsTable

        let dragColumn = NSTableColumn(identifier: Self.dragColumnID)
        dragColumn.title = ""
        dragColumn.width = 14
        dragColumn.minWidth = 14
        dragColumn.maxWidth = 14
        dragColumn.resizingMask = []

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

        tableView.addTableColumn(dragColumn)
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
        removeButton = makeIconButton(imageName: "bx-minus-circle", toolTip: "Remove selected shortcut")

        addButton.target = self
        addButton.action = #selector(addClicked(_:))
        editButton.target = self
        editButton.action = #selector(editClicked(_:))
        removeButton.target = self
        removeButton.action = #selector(removeClicked(_:))

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

    // MARK: - Drag-and-Drop Helpers

    /// Determine the target category and position within that category for a drop at the given row.
    /// The `excludingConfigIndex` is the config index of the shortcut being dragged (to exclude it from position counting).
    private func categoryAndPosition(forInsertionAt row: Int, excludingConfigIndex: Int) -> (category: String, position: Int)? {
        // Determine the scan start row
        let scanFrom: Int
        if row >= rows.count {
            scanFrom = rows.count - 1
        } else if rows[row].isCategory {
            // Inserting above a category row = end of previous category
            scanFrom = row - 1
        } else {
            // Inserting above a shortcut row
            scanFrom = row
        }

        // Scan upward to find the category row
        var categoryRow = -1
        for i in stride(from: scanFrom, through: 0, by: -1) {
            if rows[i].isCategory {
                categoryRow = i
                break
            }
        }

        guard categoryRow >= 0 else { return nil }

        let categoryName: String
        if case .category(let name) = rows[categoryRow] {
            categoryName = name == "No Category" ? "" : name
        } else {
            return nil
        }

        // Count shortcuts between category row and insertion point, excluding the source
        let countUpTo = min(row, rows.count)
        var position = 0
        for i in (categoryRow + 1)..<countUpTo {
            if case .shortcut(let configIndex) = rows[i] {
                if configIndex != excludingConfigIndex {
                    position += 1
                }
            }
        }

        return (categoryName, position)
    }

    /// Get the current category and position within that category for a shortcut at the given config index.
    private func currentPositionInCategory(for configIndex: Int) -> (category: String, position: Int)? {
        guard configIndex >= 0 && configIndex < ConfigManager.shared.config.shortcuts.count else { return nil }
        let category = ConfigManager.shared.config.shortcuts[configIndex].category

        var position = 0
        for i in 0..<configIndex {
            if ConfigManager.shared.config.shortcuts[i].category == category {
                position += 1
            }
        }

        return (category, position)
    }

    /// Move a shortcut from its current position in the config array to a new category and position.
    private func moveShortcut(from sourceConfigIndex: Int, toCategory: String, positionInCategory: Int) {
        var shortcuts = ConfigManager.shared.config.shortcuts
        var shortcut = shortcuts.remove(at: sourceConfigIndex)
        shortcut.category = toCategory

        // Find insertion point: before the positionInCategory-th shortcut in toCategory
        var insertIndex = shortcuts.count  // default: end of array
        var countInCategory = 0
        var lastInCategoryIndex = -1
        var foundExactPosition = false

        for (index, s) in shortcuts.enumerated() {
            if s.category == toCategory {
                lastInCategoryIndex = index
                if countInCategory == positionInCategory {
                    insertIndex = index
                    foundExactPosition = true
                    break
                }
                countInCategory += 1
            }
        }

        if !foundExactPosition && lastInCategoryIndex >= 0 {
            insertIndex = lastInCategoryIndex + 1
        }

        shortcuts.insert(shortcut, at: insertIndex)
        ConfigManager.shared.config.shortcuts = shortcuts
    }

    private var appDelegate: AppDelegate? {
        NSApp.delegate as? AppDelegate
    }

    // MARK: - Button Actions

    @objc private func addClicked(_ sender: NSButton) {
        openEditor(mode: .add)
    }

    @objc private func editClicked(_ sender: NSButton) {
        let selectedRow = tableView.selectedRow
        guard selectedRow >= 0 && selectedRow < rows.count else { return }
        guard !rows[selectedRow].isCategory, let configIndex = rows[selectedRow].configIndex else { return }
        openEditor(mode: .edit(configIndex: configIndex))
    }

    @objc private func tableViewDoubleClicked(_ sender: NSTableView) {
        let clickedRow = tableView.clickedRow
        guard clickedRow >= 0 && clickedRow < rows.count else { return }
        guard !rows[clickedRow].isCategory, let configIndex = rows[clickedRow].configIndex else { return }
        openEditor(mode: .edit(configIndex: configIndex))
    }

    private func openEditor(mode: ShortcutEditorWindowController.Mode) {
        guard let window = view.window else { return }

        let editor = ShortcutEditorWindowController(mode: mode)
        editor.onSave = { [weak self] in
            guard let self else { return }
            self.buildRows()
            self.tableView.reloadData()
            self.appDelegate?.reregisterAllShortcuts()
            self.appDelegate?.rebuildMenu()
            ConfigManager.shared.save()
        }
        editor.onClose = { [weak self] in
            self?.editorWindowController = nil
        }
        editorWindowController = editor
        editor.showOnParent(window)
    }

    @objc private func removeClicked(_ sender: NSButton) {
        deleteSelectedShortcut()
    }

    // MARK: - Delete Shortcut

    private func deleteSelectedShortcut() {
        let selectedRow = tableView.selectedRow
        guard selectedRow >= 0 && selectedRow < rows.count else { return }
        guard !rows[selectedRow].isCategory, let configIndex = rows[selectedRow].configIndex else { return }

        let shortcut = ConfigManager.shared.config.shortcuts[configIndex]
        let displayName = shortcut.action.isEmpty ? shortcut.command : shortcut.action

        let alert = NSAlert()
        alert.messageText = "Are you sure you want to delete this shortcut?"
        alert.informativeText = "\"\(displayName)\" will be permanently removed."
        alert.addButton(withTitle: "Yes")
        alert.addButton(withTitle: "No")
        alert.alertStyle = .warning
        alert.window.initialFirstResponder = alert.buttons.first

        guard let window = view.window else { return }
        alert.beginSheetModal(for: window) { response in
            if response == .alertFirstButtonReturn {
                ConfigManager.shared.config.shortcuts.remove(at: configIndex)
                self.buildRows()
                self.tableView.reloadData()
                self.appDelegate?.reregisterAllShortcuts()
                self.appDelegate?.rebuildMenu()
                ConfigManager.shared.save()
            }
        }
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
        if let row = rows.firstIndex(where: { $0.configIndex == configIndex }),
           let toggleColumnIndex = tableView.tableColumns.firstIndex(where: { $0.identifier == Self.toggleColumnID }) {
            tableView.reloadData(forRowIndexes: IndexSet(integer: row), columnIndexes: IndexSet(integer: toggleColumnIndex))
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

    func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {
        guard let reorderableTableView = tableView as? ReorderableTableView,
              reorderableTableView.isDragFromHandle else {
            return nil
        }

        guard row >= 0 && row < rows.count else { return nil }
        let item = rows[row]
        guard !item.isCategory, let configIndex = item.configIndex else { return nil }

        let pasteboardItem = NSPasteboardItem()
        pasteboardItem.setString(String(configIndex), forType: Self.shortcutPasteboardType)
        return pasteboardItem
    }

    func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation operation: NSTableView.DropOperation) -> NSDragOperation {
        // Only allow .above drop operation (insert before the row)
        if operation == .on {
            tableView.setDropRow(row, dropOperation: .above)
        }

        // Don't allow dropping before the first row (which is always a category)
        if row <= 0 {
            return []
        }

        // Don't allow dropping at the very end if the last row is a category
        // (would be ambiguous — no category context below)
        if row >= rows.count && rows.last?.isCategory == true {
            return []
        }

        return .move
    }

    func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool {
        guard let pasteboardItem = info.draggingPasteboard.pasteboardItems?.first else { return false }
        guard let indexString = pasteboardItem.string(forType: Self.shortcutPasteboardType),
              let sourceConfigIndex = Int(indexString) else { return false }

        guard sourceConfigIndex >= 0 && sourceConfigIndex < ConfigManager.shared.config.shortcuts.count else { return false }

        guard let target = categoryAndPosition(forInsertionAt: row, excludingConfigIndex: sourceConfigIndex) else { return false }

        // Check if dropping at the same position
        let current = currentPositionInCategory(for: sourceConfigIndex)
        if current?.category == target.category && current?.position == target.position {
            return false
        }

        moveShortcut(from: sourceConfigIndex, toCategory: target.category, positionInCategory: target.position)

        // Rebuild, save, re-register
        buildRows()
        tableView.reloadData()
        appDelegate?.reregisterAllShortcuts()
        appDelegate?.rebuildMenu()
        ConfigManager.shared.save()

        return true
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
        case Self.dragColumnID:
            return makeDragHandleCell()
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

            let button = PointerButton(frame: .zero)
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

        if let button = cellView?.subviews.first as? PointerButton {
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

    private func makeDragHandleCell() -> NSTableCellView {
        let cellIdentifier = Self.dragCellID
        var cellView = tableView.makeView(withIdentifier: cellIdentifier, owner: self) as? NSTableCellView

        if cellView == nil {
            cellView = NSTableCellView()
            cellView!.identifier = cellIdentifier

            let imageView = GrabImageView()
            if let dragImage = NSImage(systemSymbolName: "line.3.horizontal", accessibilityDescription: "Drag")?.copy() as? NSImage {
                dragImage.isTemplate = true
                imageView.image = dragImage
            }
            imageView.contentTintColor = .tertiaryLabelColor
            imageView.translatesAutoresizingMaskIntoConstraints = false
            cellView!.addSubview(imageView)

            NSLayoutConstraint.activate([
                imageView.widthAnchor.constraint(equalToConstant: 16),
                imageView.heightAnchor.constraint(equalToConstant: 16),
                imageView.centerXAnchor.constraint(equalTo: cellView!.centerXAnchor),
                imageView.centerYAnchor.constraint(equalTo: cellView!.centerYAnchor),
            ])
        }

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
