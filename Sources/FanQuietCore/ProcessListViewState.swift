import Foundation

public enum ProcessListViewState {
    case loading
    case loaded([ProcessSnapshot])
    case empty
    case failed(String)

    public var rows: [ProcessSnapshot] {
        switch self {
        case .loaded(let snapshots): return Array(snapshots.sorted { $0.cpuPercent > $1.cpuPercent }.prefix(15))
        case .loading, .empty, .failed: return []
        }
    }

    public var topProcess: ProcessSnapshot? { rows.first }
}
