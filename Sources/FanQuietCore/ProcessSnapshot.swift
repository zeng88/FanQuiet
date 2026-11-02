import Foundation

public struct ProcessSnapshot: Equatable {
    public let pid: Int32
    public let userID: UInt32
    public let cpuPercent: Double
    public let memoryPercent: Double
    public let elapsedTime: String
    public let startedAt: String
    public let executablePath: String
    public let displayName: String

    public init(
        pid: Int32,
        userID: UInt32,
        cpuPercent: Double,
        memoryPercent: Double,
        elapsedTime: String,
        startedAt: String,
        executablePath: String,
        displayName: String
    ) {
        self.pid = pid
        self.userID = userID
        self.cpuPercent = cpuPercent
        self.memoryPercent = memoryPercent
        self.elapsedTime = elapsedTime
        self.startedAt = startedAt
        self.executablePath = executablePath
        self.displayName = displayName
    }
}
