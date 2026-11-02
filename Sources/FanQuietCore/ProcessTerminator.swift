import Foundation
import Darwin

public enum ProcessTerminationError: Error, CustomStringConvertible {
    case processNotFound
    case identityChanged
    case protected(String)
    case signalFailed(Int32)

    public var description: String {
        switch self {
        case .processNotFound: return "进程已退出"
        case .identityChanged: return "进程身份已变化，请刷新后重试"
        case .protected(let reason): return reason
        case .signalFailed(let code): return "发送 SIGTERM 失败（错误码 \(code)）"
        }
    }
}

public struct ProcessTerminator {
    private let snapshotLoader: () throws -> [ProcessSnapshot]
    private let signalSender: (Int32, Int32) -> Int32
    private let currentUID: UInt32

    public init(currentUID: UInt32, snapshotLoader: @escaping () throws -> [ProcessSnapshot], signalSender: @escaping (Int32, Int32) -> Int32 = kill) {
        self.currentUID = currentUID
        self.snapshotLoader = snapshotLoader
        self.signalSender = signalSender
    }

    public func terminate(_ expected: ProcessSnapshot) throws {
        let initialDecision = TerminationPolicy.decision(for: expected, currentUID: currentUID)
        guard initialDecision == .allowed else {
            if case .protected(let reason) = initialDecision {
                throw ProcessTerminationError.protected(reason)
            }
            throw ProcessTerminationError.identityChanged
        }
        let rows = try snapshotLoader()
        guard let current = rows.first(where: { $0.pid == expected.pid }) else { throw ProcessTerminationError.processNotFound }
        guard current.userID == expected.userID,
              current.executablePath == expected.executablePath,
              current.startedAt == expected.startedAt else { throw ProcessTerminationError.identityChanged }
        if case .protected(let reason) = TerminationPolicy.decision(for: current, currentUID: currentUID) {
            throw ProcessTerminationError.protected(reason)
        }
        let result = signalSender(expected.pid, SIGTERM)
        guard result == 0 else { throw ProcessTerminationError.signalFailed(errno) }
    }
}
