import Foundation

public enum ProcessSnapshotParser {
    private static let rowPattern = #"^\s*(\d+)\s+(\d+)\s+([0-9]+(?:\.[0-9]+)?)\s+([0-9]+(?:\.[0-9]+)?)\s+(\S+)\s+([A-Za-z]{3}\s+[A-Za-z]{3}\s+\d{1,2}\s+\d{2}:\d{2}:\d{2}\s+\d{4})\s+(.+?)\s*$"#

    public static func parse(_ output: String) -> [ProcessSnapshot] {
        guard let expression = try? NSRegularExpression(pattern: rowPattern) else { return [] }
        return output.components(separatedBy: .newlines).compactMap { line in
            let range = NSRange(line.startIndex..<line.endIndex, in: line)
            guard let match = expression.firstMatch(in: line, range: range), match.numberOfRanges == 8,
                  let pidText = capture(1, match, line), let pid = Int32(pidText),
                  let uidText = capture(2, match, line), let uid = UInt32(uidText),
                  let cpuText = capture(3, match, line), let cpu = Double(cpuText),
                  let memoryText = capture(4, match, line), let memory = Double(memoryText),
                  let elapsed = capture(5, match, line),
                  let started = capture(6, match, line),
                  let path = capture(7, match, line), !path.isEmpty else { return nil }
            return ProcessSnapshot(pid: pid, userID: uid, cpuPercent: cpu, memoryPercent: memory,
                                   elapsedTime: elapsed, startedAt: started, executablePath: path,
                                   displayName: URL(fileURLWithPath: path).lastPathComponent)
        }
    }

    private static func capture(_ index: Int, _ match: NSTextCheckingResult, _ text: String) -> String? {
        guard let range = Range(match.range(at: index), in: text) else { return nil }
        return String(text[range])
    }
}
