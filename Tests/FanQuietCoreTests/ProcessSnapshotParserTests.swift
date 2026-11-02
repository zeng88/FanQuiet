
enum ProcessSnapshotParserTests {
    static let cases: [SelfTestCase] = [
        SelfTestCase("ProcessSnapshotParserTests", "parses path with spaces", testParsesFullExecutablePathContainingSpaces),
        SelfTestCase("ProcessSnapshotParserTests", "skips malformed rows", testSkipsMalformedRows),
        SelfTestCase("ProcessSnapshotParserTests", "preserves CPU percentages", testPreservesFractionalAndAboveOneHundredCPUValues)
    ]

    static func testParsesFullExecutablePathContainingSpaces() throws {
        let output = "321 501 12.5 4.2 03:20:11 Mon Nov  2 09:04:31 2026 /Applications/Fan App/Fan"

        let snapshots = ProcessSnapshotParser.parse(output)

        try expectEqual(snapshots.count, 1)
        try expectEqual(snapshots[0].pid, 321)
        try expectEqual(snapshots[0].userID, 501)
        try expectEqual(snapshots[0].elapsedTime, "03:20:11")
        try expectEqual(snapshots[0].startedAt, "Mon Nov  2 09:04:31 2026")
        try expectEqual(snapshots[0].executablePath, "/Applications/Fan App/Fan")
        try expectEqual(snapshots[0].displayName, "Fan")
    }

    static func testSkipsMalformedRows() throws {
        let output = "bad process row\n22 501 nope 3.0 00:10 Mon Nov  2 09:04:31 2026 /Applications/Bad.app/Bad"

        try expectTrue(ProcessSnapshotParser.parse(output).isEmpty)
    }

    static func testPreservesFractionalAndAboveOneHundredCPUValues() throws {
        let output = "1 501 142.75 8.5 00:10 Mon Nov  2 09:04:31 2026 /Applications/Heavy.app/Heavy\n2 501 0.25 1.0 00:10 Mon Nov  2 09:04:31 2026 /Applications/Light.app/Light"

        let snapshots = ProcessSnapshotParser.parse(output)

        let cpuValues: [Double] = snapshots.map { $0.cpuPercent }
        try expectEqual(cpuValues, [142.75, 0.25])
        let memoryValues: [Double] = snapshots.map { $0.memoryPercent }
        try expectEqual(memoryValues, [8.5, 1.0])
    }
}
