import Foundation

let arguments = CommandLine.arguments
var filter: String?
if let filterIndex = arguments.firstIndex(of: "--filter"), arguments.count > filterIndex + 1 {
    filter = arguments[filterIndex + 1]
}

runSelfTests(ProcessSnapshotParserTests.cases + ProcessSnapshotProviderTests.cases + TerminationPolicyTests.cases + ProcessTerminatorTests.cases + ProcessListViewStateTests.cases, filter: filter)
