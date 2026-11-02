import Foundation
import Darwin

enum ProcessTerminatorTests {
    static let cases = [
        SelfTestCase("ProcessTerminatorTests", "rejects a missing PID", testMissing),
        SelfTestCase("ProcessTerminatorTests", "rejects a changed identity", testChangedIdentity),
        SelfTestCase("ProcessTerminatorTests", "rechecks protected status", testProtectedRecheck),
        SelfTestCase("ProcessTerminatorTests", "sends only SIGTERM after confirmation path", testSendsSIGTERM)
    ]
    static func testMissing() throws {
        var sent = false
        let terminator = ProcessTerminator(currentUID: 501, snapshotLoader: { [] }, signalSender: { _, _ in sent = true; return 0 })
        do { try terminator.terminate(TerminationPolicyTests.snapshot()); throw SelfTestFailure(description: "expected missing error") }
        catch is ProcessTerminationError { }
        try expectTrue(!sent)
    }
    static func testChangedIdentity() throws {
        var sent = false
        let old = TerminationPolicyTests.snapshot()
        let changed = ProcessSnapshot(pid: old.pid, userID: old.userID, cpuPercent: 2, memoryPercent: 1, elapsedTime: old.elapsedTime, startedAt: "later", executablePath: old.executablePath, displayName: old.displayName)
        let terminator = ProcessTerminator(currentUID: 501, snapshotLoader: { [changed] }, signalSender: { _, _ in sent = true; return 0 })
        do { try terminator.terminate(old); throw SelfTestFailure(description: "expected identity error") }
        catch is ProcessTerminationError { }
        try expectTrue(!sent)
    }
    static func testProtectedRecheck() throws {
        var sent = false
        let old = TerminationPolicyTests.snapshot()
        let changed = ProcessSnapshot(pid: old.pid, userID: old.userID, cpuPercent: 2, memoryPercent: 1, elapsedTime: old.elapsedTime, startedAt: old.startedAt, executablePath: "/usr/bin/launchd", displayName: "launchd")
        let terminator = ProcessTerminator(currentUID: 501, snapshotLoader: { [changed] }, signalSender: { _, _ in sent = true; return 0 })
        do { try terminator.terminate(old); throw SelfTestFailure(description: "expected protected error") }
        catch is ProcessTerminationError { }
        try expectTrue(!sent)
    }
    static func testSendsSIGTERM() throws {
        var received: (Int32, Int32)?
        let expected = TerminationPolicyTests.snapshot()
        let terminator = ProcessTerminator(currentUID: 501, snapshotLoader: { [expected] }, signalSender: { pid, signal in received = (pid, signal); return 0 })
        try terminator.terminate(expected)
        try expectEqual(received?.0, expected.pid)
        try expectEqual(received?.1, SIGTERM)
    }
}
