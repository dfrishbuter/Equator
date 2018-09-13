//
//  Copyright © 2018 Dmitry Frishbuter. All rights reserved.
//

import XCTest

class SwiftEquatableGeneratorTests: XCTestCase {

    func assert(input: [String], output: [String], file: StaticString = #file, line: UInt = #line) {
        do {
            let lines = try generate(selection: input, indentation: "    ", leadingIndent: "")
            if lines != output {
                let joinedOutput = output.joined(separator: "\n")
                let joinedLines = lines.joined(separator: "\n")
                XCTFail("Output is not correct; expected:\n\(joinedOutput)\n\ngot:\n\(joinedLines)", file: file, line: line)
            }
        }
        catch {
            XCTFail("Could not generate equatable extension: \(error)", file: file, line: line)
        }
    }

    func testStringMultiplier() {
        XCTAssertEqual("test" * 0, "")
        XCTAssertEqual("test" * 1, "test")
        XCTAssertEqual("test" * 2, "testtest")
    }

    func testNoAccessModifiers() {
        assert(
            input: [
                "class User: Codable {",
                "    var a: Int",
                "    var b: Int",
                "}"
            ],
            output: [
                "extension User: Equatable {",
                "    static func == (lhs: User, rhs: User) -> Bool {",
                "        return lhs.a == rhs.a &&",
                "               lhs.b == rhs.b",
                "    }",
                "}"
            ])
    }

    func testNoProperties() {
        assert(
            input: [
                "class User: Codable {",
                "}"
            ],
            output: [
                "extension User: Equatable {",
                "    static func == (lhs: User, rhs: User) -> Bool {",
                "    }",
                "}"
            ])
    }

    func testEmptyLineInBetween() {
        assert(
            input: [
                "class User: Codable {",
                "    let a: Int",
                "",
                "    let b: Int",
                "}"
            ],
            output: [
                "extension User: Equatable {",
                "    static func == (lhs: User, rhs: User) -> Bool {",
                "        return lhs.a == rhs.a &&",
                "               lhs.b == rhs.b",
                "    }",
                "}"
            ])
    }

    func testSingleAccessModifier() {
        assert(
            input: [
                "class User: Codable {",
                "    internal let a: Int",
                "    private let b: Int",
                "}"
            ],
            output: [
                "extension User: Equatable {",
                "    static func == (lhs: User, rhs: User) -> Bool {",
                "        return lhs.a == rhs.a &&",
                "               lhs.b == rhs.b",
                "    }",
                "}"
            ])
    }

    func testDoubleAccessModifier() {
        assert(
            input: [
                "class User: Codable {",
                "    public internal(set) let a: Int",
                "    public private(set) let b: Int",
                "}"
            ],
            output: [
                "extension User: Equatable {",
                "    static func == (lhs: User, rhs: User) -> Bool {",
                "        return lhs.a == rhs.a &&",
                "               lhs.b == rhs.b",
                "    }",
                "}"
            ])
    }

    func testCommentLine() {
        assert(
            input: [
                "/// a very important class",
                "class User: Codable {",
                "    /// a very important property",
                "    let a: Int",
                "    // this one, not so much",
                "    let b: Int",
                "    /*",
                "     * pay attention to this one",
                "     */",
                "    let c: String",
                "}"
            ],
            output: [
                "extension User: Equatable {",
                "    static func == (lhs: User, rhs: User) -> Bool {",
                "        return lhs.a == rhs.a &&",
                "               lhs.b == rhs.b &&",
                "               lhs.c == rhs.c",
                "    }",
                "}"
            ])
    }

    func testDynamicVar() {
        assert(
            input: [
                "class User: Codable {",
                "    dynamic var hello: String",
                "    dynamic var a: Int?",
                "    var b: Float",
                "}"
            ],
            output: [
                "extension User: Equatable {",
                "    static func == (lhs: User, rhs: User) -> Bool {",
                "        return lhs.hello == rhs.hello &&",
                "               lhs.a == rhs.a &&",
                "               lhs.b == rhs.b",
                "    }",
                "}"
            ])
    }

    func testWeakVar() {
        assert(
            input: [
                "class User: Codable {",
                "    weak var hello: String",
                "    var a: Int?",
                "}"
            ],
            output: [
                "extension User: Equatable {",
                "    static func == (lhs: User, rhs: User) -> Bool {",
                "        return lhs.hello == rhs.hello &&",
                "               lhs.a == rhs.a",
                "    }",
                "}"
            ])
    }

    func testMethod() {
        assert(
            input: [
                "class User: Codable {",
                "    let a: Int",
                "    let b: Int",
                "    func doSomething(with value: Int) {",
                "    }",
                "}"
            ],
            output: [
                "extension User: Equatable {",
                "    static func == (lhs: User, rhs: User) -> Bool {",
                "        return lhs.a == rhs.a &&",
                "               lhs.b == rhs.b",
                "    }",
                "}"
            ])
    }

    func testEscapingClosure() {
        assert(
            input: [
                "class Handler {",
                "    let a: (String) -> Int?",
                "    let b: () -> () -> Void",
                "    let c: ((String, Int))->()",
                "}"
            ],
            output: [
                "extension Handler: Equatable {",
                "    static func == (lhs: Handler, rhs: Handler) -> Bool {",
                "        return lhs.a == rhs.a &&",
                "               lhs.b == rhs.b &&",
                "               lhs.c == rhs.c",
                "    }",
                "}"
            ])
    }

    func testNoEscapingAttribute() {
        assert(
            input: [
                "class Handler {",
                "    let a: (() -> Void)?",
                "    let b: [() -> Void]",
                "    let c: (()->())!",
                "}"
            ],
            output: [
                "extension Handler: Equatable {",
                "    static func == (lhs: Handler, rhs: Handler) -> Bool {",
                "        return lhs.a == rhs.a &&",
                "               lhs.b == rhs.b &&",
                "               lhs.c == rhs.c",
                "    }",
                "}"
            ])
    }

    func testEnum() {
        assert(
            input: [
                "enum Kind {",
                "    case a",
                "    case b",
                "}"
            ],
            output: [
                "extension Kind: Equatable {",
                "    static func == (lhs: Kind, rhs: Kind) -> Bool {",
                "        switch (lhs, rhs) {",
                "        case (.a, .a):",
                "            return true",
                "        case (.b, .b):",
                "            return true",
                "        default:",
                "            return false",
                "        }",
                "    }",
                "}"
            ])
    }

    func testEnumWithConformance() {
        assert(
            input: [
                "enum Kind: Codable {",
                "    case a",
                "    case b",
                "}"
            ],
            output: [
                "extension Kind: Equatable {",
                "    static func == (lhs: Kind, rhs: Kind) -> Bool {",
                "        switch (lhs, rhs) {",
                "        case (.a, .a):",
                "            return true",
                "        case (.b, .b):",
                "            return true",
                "        default:",
                "            return false",
                "        }",
                "    }",
                "}"
            ])
    }

    func testEnumWithMethod() {
        assert(
            input: [
                "enum Kind: Codable {",
                "    case a",
                "    case b",
                "    func doSomething(with value: Int) {",
                "    }",
                "}"
            ],
            output: [
                "extension Kind: Equatable {",
                "    static func == (lhs: Kind, rhs: Kind) -> Bool {",
                "        switch (lhs, rhs) {",
                "        case (.a, .a):",
                "            return true",
                "        case (.b, .b):",
                "            return true",
                "        default:",
                "            return false",
                "        }",
                "    }",
                "}"
            ])
    }
}
