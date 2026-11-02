import Foundation

public enum ProcessSnapshotProviderError: Error, CustomStringConvertible {
    case commandFailed(String)
    case invalidOutputEncoding

    public var description: String {
        switch self {
        case .commandFailed(let message): return message
        case .invalidOutputEncoding: return "ps returned output that is not UTF-8"
        }
    }
}

public struct ProcessSnapshotProvider {
    private let commandRunner: () throws -> String

    public init() { self.commandRunner = ProcessSnapshotProvider.runPS }

    public init(commandRunner: @escaping () throws -> String) {
        self.commandRunner = commandRunner
    }

    public func load() throws -> [ProcessSnapshot] {
        try commandRunner().pipeSort()
    }

    private static func runPS() throws -> String {
        let process = Process()
        let output = Pipe()
        process.launchPath = "/bin/ps"
        process.arguments = ["-Aww", "-o", "pid=,uid=,%cpu=,%mem=,etime=,lstart=,comm="]
        process.standardOutput = output
        process.standardError = Pipe()
        do { try process.run() } catch { throw ProcessSnapshotProviderError.commandFailed(error.localizedDescription) }
        let data = output.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            throw ProcessSnapshotProviderError.commandFailed("ps exited with status \(process.terminationStatus)")
        }
        guard let text = String(data: data, encoding: .utf8) else { throw ProcessSnapshotProviderError.invalidOutputEncoding }
        return text
    }
}

private extension String {
    func pipeSort() -> [ProcessSnapshot] {
        ProcessSnapshotParser.parse(self).sorted { $0.cpuPercent > $1.cpuPercent }
    }
}
