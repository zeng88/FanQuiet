import AppKit
import Darwin

final class MainWindowController: NSWindowController, NSWindowDelegate, NSTableViewDataSource, NSTableViewDelegate {
    private let provider = ProcessSnapshotProvider()
    private var state: ProcessListViewState = .loading
    private var refreshTimer: Timer?
    private var isLoading = false
    private var pendingResult: ProcessListViewState?
    private var visibleRows: [ProcessSnapshot] = []
    private let headline = NSTextField(labelWithString: "正在读取进程…")
    private let detail = NSTextField(labelWithString: "每 5 秒刷新；选中进程时暂停。只显示当前用户可结束的进程。")
    private let status = NSTextField(labelWithString: "")
    private let table = NSTableView()
    private let scroll = NSScrollView()
    private let terminateButton = NSButton(title: "结束进程…", target: nil, action: nil)
    private let refreshButton = NSButton(title: "立即刷新", target: nil, action: nil)

    init() {
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 900, height: 590),
                              styleMask: [.titled, .closable, .miniaturizable, .resizable],
                              backing: .buffered, defer: false)
        window.title = "FanQuiet — CPU 进程检查"
        window.minSize = NSSize(width: 720, height: 460)
        super.init(window: window)
        window.delegate = self
        buildInterface(in: window)
        refresh()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is unsupported") }

    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(automaticRefresh), userInfo: nil, repeats: true)
    }

    func windowWillClose(_ notification: Notification) {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    private func buildInterface(in window: NSWindow) {
        guard let content = window.contentView else { return }
        headline.font = NSFont.systemFont(ofSize: 23, weight: .semibold)
        detail.textColor = .secondaryLabelColor
        status.textColor = .secondaryLabelColor
        refreshButton.target = self
        refreshButton.action = #selector(refreshAction)
        terminateButton.target = self
        terminateButton.action = #selector(terminateSelected)
        for (title, identifier, width) in [("进程", "name", 250.0), ("PID", "pid", 70.0), ("CPU", "cpu", 85.0), ("内存", "memory", 85.0), ("运行时长", "time", 100.0), ("状态", "status", 190.0)] {
            let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(identifier))
            column.title = title
            column.width = CGFloat(width)
            table.addTableColumn(column)
        }
        table.dataSource = self
        table.delegate = self
        table.usesAlternatingRowBackgroundColors = true
        table.allowsEmptySelection = true
        scroll.documentView = table
        table.frame = NSRect(origin: .zero, size: NSSize(width: scroll.contentSize.width, height: 320))
        table.autoresizingMask = [.width]
        scroll.hasVerticalScroller = true
        scroll.borderType = .bezelBorder
        let buttons = NSStackView(views: [status, refreshButton, terminateButton])
        buttons.orientation = .horizontal
        buttons.alignment = .centerY
        buttons.distribution = .fill
        buttons.spacing = 12
        let stack = NSStackView(views: [headline, detail, scroll, buttons])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.distribution = .fill
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(stack)
        scroll.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 22),
            stack.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -22),
            stack.topAnchor.constraint(equalTo: content.topAnchor, constant: 20),
            stack.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -18),
            scroll.widthAnchor.constraint(equalTo: stack.widthAnchor),
            scroll.heightAnchor.constraint(greaterThanOrEqualToConstant: 300),
            status.widthAnchor.constraint(greaterThanOrEqualToConstant: 360)
        ])
    }

    @objc private func automaticRefresh() {
        guard table.selectedRow < 0 else { return }
        refresh()
    }

    @objc private func refreshAction() {
        if table.selectedRow >= 0 { table.deselectAll(nil) }
        if let pending = pendingResult {
            state = pending
            pendingResult = nil
            render()
        }
        refresh()
    }

    @objc private func refresh() {
        guard !isLoading else { return }
        isLoading = true
        switch state {
        case .loaded, .empty, .failed: status.stringValue = "正在刷新；保留当前列表…"
        case .loading: render()
        }
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }
            let result: ProcessListViewState
            do {
                let snapshots = try self.provider.load()
                result = snapshots.isEmpty ? .empty : .loaded(snapshots)
            } catch { result = .failed(error.localizedDescription) }
            DispatchQueue.main.async {
                self.isLoading = false
                if self.table.selectedRow >= 0 {
                    self.pendingResult = result
                    self.status.stringValue = "自动刷新已暂停；点击“恢复并刷新”后应用新数据。"
                    self.updateTerminateButton()
                    return
                }
                self.state = result
                self.render()
            }
        }
    }

    private func render() {
        visibleRows = state.visibleRows(currentUID: UInt32(geteuid()))
        table.reloadData()
        let minimumHeight = max(scroll.contentView.bounds.height, table.rowHeight * CGFloat(max(table.numberOfRows, 1)))
        table.setFrameSize(NSSize(width: scroll.contentSize.width, height: minimumHeight))
        switch state {
        case .loading: headline.stringValue = "正在读取进程…"; status.stringValue = ""
        case .empty: headline.stringValue = "暂时没有可显示的进程"; status.stringValue = ""
        case .failed(let message): headline.stringValue = "读取进程失败"; status.stringValue = message
        case .loaded:
            if let top = state.topProcess(currentUID: UInt32(geteuid())) {
                headline.stringValue = "CPU 最高（可结束）：\(top.displayName)  ·  \(String(format: "%.1f", top.cpuPercent))%  ·  PID \(top.pid)"
                status.stringValue = "显示 \(visibleRows.count) 个可结束进程；结束前会再次核对身份。"
            } else {
                headline.stringValue = "没有可安全结束的当前用户进程"
                status.stringValue = "系统进程和其他用户进程已隐藏。"
            }
        }
        updateTerminateButton()
    }

    func numberOfRows(in tableView: NSTableView) -> Int { visibleRows.count }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let column = tableColumn, row < visibleRows.count else { return nil }
        let process = visibleRows[row]
        let identifier = column.identifier.rawValue
        let text: String
        switch identifier {
        case "name": text = process.displayName
        case "pid": text = String(process.pid)
        case "cpu": text = String(format: "%.1f%%", process.cpuPercent)
        case "memory": text = String(format: "%.1f%%", process.memoryPercent)
        case "time": text = process.elapsedTime
        case "status": text = "可结束（需确认）"
        default: text = ""
        }
        let cellID = NSUserInterfaceItemIdentifier("Cell-\(identifier)")
        let cell = (tableView.makeView(withIdentifier: cellID, owner: self) as? NSTableCellView) ?? NSTableCellView()
        for subview in cell.subviews { subview.removeFromSuperview() }
        let field = NSTextField(labelWithString: text)
        field.lineBreakMode = .byTruncatingTail
        field.frame = NSRect(x: 4, y: 0, width: max(20, column.width - 8), height: 20)
        cell.addSubview(field)
        cell.identifier = cellID
        return cell
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        updateTerminateButton()
        if table.selectedRow >= 0 {
            status.stringValue = "已暂停自动刷新；点击“恢复并刷新”可更新列表。"
        } else if !isLoading, case .loaded = state {
            status.stringValue = "显示 \(visibleRows.count) 个可结束进程；结束前会再次核对身份。"
        }
    }

    private func updateTerminateButton() {
        let hasSelection = table.selectedRow >= 0 && table.selectedRow < visibleRows.count
        refreshButton.title = hasSelection ? "恢复并刷新" : "立即刷新"
        guard hasSelection else {
            terminateButton.isEnabled = false
            return
        }
        terminateButton.isEnabled = TerminationPolicy.decision(for: visibleRows[table.selectedRow], currentUID: geteuid()) == .allowed
    }

    @objc private func terminateSelected() {
        guard table.selectedRow >= 0, table.selectedRow < visibleRows.count else { return }
        let process = visibleRows[table.selectedRow]
        guard TerminationPolicy.decision(for: process, currentUID: geteuid()) == .allowed else { updateTerminateButton(); return }
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "确认结束此进程？"
        alert.informativeText = "\(process.displayName)（PID \(process.pid)）将收到 SIGTERM。未保存的数据可能丢失；FanQuiet 不会强制结束进程。"
        alert.addButton(withTitle: "取消")
        alert.addButton(withTitle: "确认结束")
        guard alert.runModal() == .alertSecondButtonReturn else { return }
        do {
            let terminator = ProcessTerminator(currentUID: geteuid(), snapshotLoader: { try self.provider.load() })
            try terminator.terminate(process)
            status.stringValue = "已向 \(process.displayName) 发送 SIGTERM。"
            table.deselectAll(nil)
            refresh()
        } catch {
            let errorAlert = NSAlert()
            errorAlert.alertStyle = .warning
            errorAlert.messageText = "无法结束进程"
            errorAlert.informativeText = error.localizedDescription
            errorAlert.runModal()
            table.deselectAll(nil)
            refresh()
        }
    }
}
