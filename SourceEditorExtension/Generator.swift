//
//  Copyright © 2018 Dmitry Frishbuter. All rights reserved.
//

import Foundation

enum GeneratorError: Error {
    case notSwiftLanguage
    case noSelection
    case invalidSelection
    case parseError
}

let accessModifiers = ["open", "public", "internal", "private", "fileprivate"]

func generate(selection: [String], indentation: String, leadingIndent: String) throws -> [String] {
    if selection.contains(where: { $0.contains("enum") }) {
        return try generateForEnum(selection: selection, indentation: indentation, leadingIndent: leadingIndent)
    }
    guard let definitionLine = selection.first(where: { line -> Bool in
        return (line.contains("class") || line.contains("struct")) && line.contains("{")
    }) else {
        throw GeneratorError.parseError
    }
    let scanner = Scanner(string: definitionLine)
    for modifier in accessModifiers {
        if scanner.scanString(modifier, into: nil) {
            break
        }
    }
    scanner.scanString("final", into: nil)
    guard scanner.scanString("class", into: nil) || scanner.scanString("struct", into: nil) else {
        throw GeneratorError.parseError
    }
    var dampName = scanner.string.contains(":") ? scanner.scanUpTo(":")?.trimmingCharacters(in: .whitespaces) : nil
    if dampName == nil {
        dampName = scanner.scanUpTo("{")?.dropLast().trimmingCharacters(in: .whitespaces)
    }
    guard let definitionName = dampName else {
        throw GeneratorError.parseError
    }

    let vars = try variables(fromSelection: selection)
    return objectLines(definitionName: definitionName, variables: vars, indentation: indentation)
}

private func variables(fromSelection selection: [String]) throws -> [(String, String)] {
    var variables = [(String, String)]()

    for line in selection.dropFirst() {
        let scanner = Scanner(string: line)

        _ = scanner.scanString("weak", into: nil)
        for modifier in accessModifiers {
            if scanner.scanString(modifier, into: nil) {
                break
            }
        }
        for modifier in accessModifiers {
            if scanner.scanString(modifier, into: nil) {
                guard scanner.scanUpTo(")") != nil, scanner.scanString(")") != nil else {
                    throw GeneratorError.parseError
                }
            }
        }

        guard scanner.scanString("let", into: nil) || scanner.scanString("var", into: nil) || scanner.scanString("dynamic var", into: nil) else {
            continue
        }
        guard let variableName = scanner.scanUpTo(":"), scanner.scanString(":", into: nil), let variableType = scanner.scanUpTo("\n") else {
            throw GeneratorError.parseError
        }
        variables.append((variableName, variableType))
    }

    return variables
}

private func objectLines(definitionName: String, variables: [(String, String)], indentation: String) -> [String] {
    let expressions = variables.enumerated().map { (arg: (offset: Int, element: (name: String, type: String))) -> String in
        let (offset, element) = arg
        let base = "lhs.\(element.name) == rhs.\(element.name)"
        let `return` = "return "
        let returnSpacing = `return`.reduce(into: "") { (result, _) in
            result += " "
        }
        var line = "\(indentation)" + (offset == 0 ? (indentation + `return` + base) : (indentation + returnSpacing + base))
        if offset != variables.indices.last {
            line += " &&"
        }
        return line
    }

    var lines = ["extension \(definitionName): Equatable {"]
    lines += ["\(indentation)static func == (lhs: \(definitionName), rhs: \(definitionName)) -> Bool {"]
    lines += expressions
    lines += ["\(indentation)}"]
    lines += ["}"]

    return lines.map { "\($0)" }
}

private func generateForEnum(selection: [String], indentation: String, leadingIndent: String) throws -> [String] {
    guard let definitionLine = selection.first(where: { line -> Bool in
        return line.contains("enum") && line.contains("{")
    }) else {
        throw GeneratorError.parseError
    }
    let scanner = Scanner(string: definitionLine)
    for modifier in accessModifiers {
        if scanner.scanString(modifier, into: nil) {
            break
        }
    }
    guard scanner.scanString("enum", into: nil) else {
        throw GeneratorError.parseError
    }
    var dampName = scanner.string.contains(":") ? scanner.scanUpTo(":")?.trimmingCharacters(in: .whitespaces) : nil
    if dampName == nil {
        dampName = scanner.scanUpTo("{")?.dropLast().trimmingCharacters(in: .whitespaces)
    }
    guard let definitionName = dampName else {
        throw GeneratorError.parseError
    }

    var caseNames = [String]()

    for line in selection.dropFirst() {
        let scanner = Scanner(string: line)

        guard scanner.scanString("case", into: nil) else {
            continue
        }

        guard let caseName = scanner.scanUpTo("\n") else {
            throw GeneratorError.parseError
        }
        caseNames.append(caseName)
    }

    return enumLines(definitionName: definitionName, caseNames: caseNames, indentation: indentation)
}

private func enumLines(definitionName: String, caseNames: [String], indentation: String) -> [String] {
    var expressions = [String]()
    caseNames.forEach { caseName in
        expressions.append("\(indentation * 2)case (.\(caseName), .\(caseName)):")
        expressions.append("\(indentation * 3)return true")
    }

    var lines = ["extension \(definitionName): Equatable {"]
    lines += ["\(indentation)static func == (lhs: \(definitionName), rhs: \(definitionName)) -> Bool {"]
    lines += ["\(indentation * 2)switch (lhs, rhs) {"]
    lines += expressions
    lines += ["\(indentation * 2)default:"]
    lines += ["\(indentation * 3)return false"]
    lines += ["\(indentation * 2)}"]
    lines += ["\(indentation)}"]
    lines += ["}"]

    return lines.map { "\($0)" }
}

private func addEscapingAttributeIfNeeded(to typeString: String) -> String {
    let predicate = NSPredicate(format: "SELF MATCHES %@", "\\(.*\\)->.*")
    if predicate.evaluate(with: typeString.replacingOccurrences(of: " ", with: "")), !isOptional(typeString: typeString) {
        return "@escaping " + typeString
    }
    else {
        return typeString
    }
}

private func isOptional(typeString: String) -> Bool {
    guard typeString.hasSuffix("!") || typeString.hasSuffix("?") else {
        return false
    }
    var balance = 0
    var closingBraceIndexMatchingFirstOpenBrace: Int?

    for (index, character) in typeString.enumerated() {
        if character == "(" {
            balance += 1
        }
        else if character == ")" {
            balance -= 1
        }
        if balance == 0 {
            closingBraceIndexMatchingFirstOpenBrace = index
            break
        }
    }

    return closingBraceIndexMatchingFirstOpenBrace == typeString.count - 2
}

extension String {
    static func * (lhs: String, rhs: Int) -> String {
        return Array(0..<rhs).reduce(into: "") { result, _ in
            result += lhs
        }
    }
}
