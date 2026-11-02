import Foundation

enum ProcessListViewStateTests {
    static let cases = [
        SelfTestCase("ProcessListViewStateTests", "non-loaded states have no actionable rows", testNoRows),
        SelfTestCase("ProcessListViewStateTests", "loaded rows cap at fifteen and sort by CPU", testLimitAndSort)
    ]
    static func testNoRows() throws {
        for state in [ProcessListViewState.loading, .empty, .failed("error")] {
            try expectTrue(state.rows.isEmpty)
            try expectTrue(state.topProcess == nil)
        }
    }
    static func testLimitAndSort() throws {
        let snapshots = (1...20).map { index in
            ProcessSnapshot(pid: Int32(index), userID: 501, cpuPercent: Double(index), memoryPercent: 0,
                            elapsedTime: "00:01", startedAt: "start", executablePath: "/Applications/App\(index)", displayName: "App\(index)")
        }
        let state = ProcessListViewState.loaded(snapshots)
        try expectEqual(state.rows.count, 15)
        try expectEqual(state.rows.first?.pid, 20)
        try expectEqual(state.rows.last?.pid, 6)
    }
}
