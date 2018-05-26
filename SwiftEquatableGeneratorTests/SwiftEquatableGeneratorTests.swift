//
//  Copyright © 2018 Dmitry Frishbuter. All rights reserved.
//

import XCTest

class SwiftEquatableGeneratorTests: XCTestCase {
    func assert(input: [String], output: [String], file: StaticString = #file, line: UInt = #line) {
        do {
            let lines = try generate(selection: input, indentation: "    ", leadingIndent: "")
            if(lines != output) {
                XCTFail("Output is not correct; expected:\n\(output.joined(separator: "\n"))\n\ngot:\n\(lines.joined(separator: "\n"))", file: file, line: line)
            }
        } catch {
            XCTFail("Could not generate initializer: \(error)", file: file, line: line)
        }
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
}
