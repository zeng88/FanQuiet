import Foundation

public enum ProcessListViewState {
    case loading
    case loaded([ProcessSnapshot])
    case empty
    case failed(String)

    public func visibleRows(currentUID: UInt32) -> [ProcessSnapshot] {
        guard case .loaded(let snapshots) = self else { return [] }
        return Array(snapshots.filter {
            TerminationPolicy.decision(for: $0, currentUID: currentUID) == .allowed
        }.sorted { $0.cpuPercent > $1.cpuPercent }.prefix(15))
    }

    public func topProcess(currentUID: UInt32) -> ProcessSnapshot? {
        visibleRows(currentUID: currentUID).first
    }
}
