import Foundation

enum TerminationPolicyTests {
    static let cases = [
        SelfTestCase("TerminationPolicyTests", "protects PID zero and one", testPID),
        SelfTestCase("TerminationPolicyTests", "protects root and other users", testUsers),
        SelfTestCase("TerminationPolicyTests", "protects system paths", testPaths),
        SelfTestCase("TerminationPolicyTests", "protects critical names", testCriticalNames),
        SelfTestCase("TerminationPolicyTests", "allows a normal current-user app", testAllowed)
    ]
    static func testPID() throws {
        for pid: Int32 in [0, 1] { try protected(snapshot(pid: pid), "系统进程 PID 不可结束") }
    }
    static func testUsers() throws {
        try protected(snapshot(uid: 0), "root 用户进程不可结束")
        try protected(snapshot(uid: 502), "其他用户的进程不可结束")
    }
    static func testPaths() throws {
        for path in ["/System/Library/x", "/usr/bin/tool", "/bin/sh", "/sbin/launchd", "/private/var/x"] {
            try protected(snapshot(path: path), "系统目录中的进程不可结束")
        }
    }
    static func testCriticalNames() throws {
        for name in ["WindowServer", "loginwindow", "launchd", "kernel_task", "Finder", "Dock", "SystemUIServer", "coreaudiod", "powerd"] {
            try protected(snapshot(path: "/Applications/\(name)"), "系统关键进程不可结束")
        }
    }
    static func testAllowed() throws {
        try expectEqual(TerminationPolicy.decision(for: snapshot(), currentUID: 501), .allowed)
    }
    private static func protected(_ item: ProcessSnapshot, _ reason: String) throws {
        try expectEqual(TerminationPolicy.decision(for: item, currentUID: 501), .protected(reason: reason))
    }
    static func snapshot(pid: Int32 = 42, uid: UInt32 = 501, path: String = "/Applications/Example.app/Contents/MacOS/Example") -> ProcessSnapshot {
        ProcessSnapshot(pid: pid, userID: uid, cpuPercent: 1, memoryPercent: 1, elapsedTime: "00:10", startedAt: "Mon Nov  2 09:04:31 2026", executablePath: path, displayName: URL(fileURLWithPath: path).lastPathComponent)
    }
}
