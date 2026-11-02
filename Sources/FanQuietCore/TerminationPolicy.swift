import Foundation

public enum TerminationDecision: Equatable {
    case allowed
    case protected(reason: String)
}

public enum TerminationPolicy {
    private static let protectedNames: Set<String> = [
        "windowserver", "loginwindow", "launchd", "kernel_task", "finder", "dock",
        "systemuiserver", "coreaudiod", "powerd"
    ]
    private static let protectedRoots = ["/System", "/usr", "/bin", "/sbin", "/private"]

    public static func decision(for process: ProcessSnapshot, currentUID: UInt32) -> TerminationDecision {
        if process.pid <= 1 { return .protected(reason: "系统进程 PID 不可结束") }
        if process.userID == 0 { return .protected(reason: "root 用户进程不可结束") }
        if process.userID != currentUID { return .protected(reason: "其他用户的进程不可结束") }
        let path = URL(fileURLWithPath: process.executablePath).standardizedFileURL.path
        if path.isEmpty || !path.hasPrefix("/") { return .protected(reason: "进程路径无法验证") }
        for root in protectedRoots where path == root || path.hasPrefix(root + "/") {
            return .protected(reason: "系统目录中的进程不可结束")
        }
        let name = URL(fileURLWithPath: path).lastPathComponent.lowercased()
        if protectedNames.contains(name) { return .protected(reason: "系统关键进程不可结束") }
        return .allowed
    }
}
