import Foundation

enum ProcessListViewStateTests {
    static let cases = [
        SelfTestCase("ProcessListViewStateTests", "non-loaded states have no actionable rows", testNoRows),
        SelfTestCase("ProcessListViewStateTests", "hides protected and other-user processes", testHidesProtectedRows),
        SelfTestCase("ProcessListViewStateTests", "filters before capping and sorts by CPU", testFiltersBeforeLimit)
    ]

    static func testNoRows() throws {
        for state in [ProcessListViewState.loading, .empty, .failed("error")] {
            try expectTrue(state.visibleRows(currentUID: 501).isEmpty)
        }
    }

    static func testHidesProtectedRows() throws {
        let allowed = snapshot(pid: 10, uid: 501, cpu: 20, path: "/Applications/Example")
        let system = snapshot(pid: 11, uid: 501, cpu: 99, path: "/System/Library/WindowServer")
        let otherUser = snapshot(pid: 12, uid: 502, cpu: 90, path: "/Applications/Other")
        let state = ProcessListViewState.loaded([system, otherUser, allowed])
        let rows = state.visibleRows(currentUID: 501)
        try expectEqual(rows.map { $0.pid }, [10])
        try expectEqual(state.topProcess(currentUID: 501)?.pid, 10)
    }

    static func testFiltersBeforeLimit() throws {
        var snapshots = (1...20).map { index in
            snapshot(pid: Int32(index), uid: 501, cpu: Double(index), path: "/Applications/App\(index)")
        }
        snapshots.append(snapshot(pid: 999, uid: 501, cpu: 999, path: "/System/Library/WindowServer"))
        let rows = ProcessListViewState.loaded(snapshots).visibleRows(currentUID: 501)
        try expectEqual(rows.count, 15)
        try expectEqual(rows.first?.pid, 20)
        try expectEqual(rows.last?.pid, 6)
    }

    private static func snapshot(pid: Int32, uid: UInt32, cpu: Double, path: String) -> ProcessSnapshot {
        ProcessSnapshot(pid: pid, userID: uid, cpuPercent: cpu, memoryPercent: 0,
                        elapsedTime: "00:01", startedAt: "start", executablePath: path,
                        displayName: URL(fileURLWithPath: path).lastPathComponent)
    }
}
