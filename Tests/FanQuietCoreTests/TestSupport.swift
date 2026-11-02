import Foundation

struct SelfTestCase {
    let suite: String
    let name: String
    let run: () throws -> Void

    init(_ suite: String, _ name: String, _ run: @escaping () throws -> Void) {
        self.suite = suite
        self.name = name
        self.run = run
    }
}

struct SelfTestFailure: Error, CustomStringConvertible {
    let description: String
}

func expectTrue(_ value: @autoclosure () -> Bool, _ message: String = "expected true") throws {
    guard value() else { throw SelfTestFailure(description: message) }
}

func expectEqual<Value: Equatable>(
    _ actual: Value,
    _ expected: Value,
    _ message: String = "values differ"
) throws {
    guard actual == expected else {
        throw SelfTestFailure(description: "\(message): expected <\(expected)>; got <\(actual)>")
    }
}

func runSelfTests(_ cases: [SelfTestCase], filter: String?) {
    let selected = cases.filter { filter == nil || $0.suite.contains(filter!) }
    guard !selected.isEmpty else {
        fputs("No self-tests matched the filter.\n", stderr)
        exit(EXIT_FAILURE)
    }

    var failures = 0
    for testCase in selected {
        do {
            try testCase.run()
            print("PASS \(testCase.suite): \(testCase.name)")
        } catch {
            failures += 1
            fputs("FAIL \(testCase.suite): \(testCase.name): \(error)\n", stderr)
        }
    }

    if failures > 0 {
        fputs("\(failures) of \(selected.count) self-tests failed.\n", stderr)
        exit(EXIT_FAILURE)
    }
    print("PASS \(selected.count) self-tests")
}
