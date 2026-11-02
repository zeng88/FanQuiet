import Foundation

enum ProcessSnapshotProviderTests {
    static let cases = [
        SelfTestCase("ProcessSnapshotProviderTests", "accepts empty output", testEmptyOutput),
        SelfTestCase("ProcessSnapshotProviderTests", "propagates runner errors", testRunnerError),
        SelfTestCase("ProcessSnapshotProviderTests", "sorts by CPU descending", testSortsByCPU)
    ]
    static func testEmptyOutput() throws {
        let provider = ProcessSnapshotProvider(commandRunner: { "" })
        let rows = try provider.load()
        try expectTrue(rows.isEmpty)
    }
    static func testRunnerError() throws {
        let provider = ProcessSnapshotProvider(commandRunner: { throw SelfTestFailure(description: "runner failed") })
        do { _ = try provider.load(); throw SelfTestFailure(description: "expected error") } catch let error as SelfTestFailure {
            try expectEqual(error.description, "runner failed")
        }
    }
    static func testSortsByCPU() throws {
        let provider = ProcessSnapshotProvider(commandRunner: {
            "11 501 2.0 1.0 00:10 Mon Nov  2 09:04:31 2026 /Applications/Low\n12 501 88.5 1.0 00:10 Mon Nov  2 09:04:31 2026 /Applications/High"
        })
        let rows = try provider.load()
        try expectEqual(rows.map { $0.pid }, [12, 11])
    }
}
