//
//  Copyright © 2018 Dmitry Frishbuter. All rights reserved.
//

import Foundation

enum SIGError: Swift.Error {
    case notSwiftLanguage
    case noSelection
    case invalidSelection
    case parseError
}

let accessModifiers = ["open", "public", "internal", "private", "fileprivate"]

func generate(selection: [String], indentation: String, leadingIndent: String) throws -> [String] {
    guard let definitionLine = selection.first(where: { line -> Bool in
        return (line.contains("class") || line.contains("struct")) && line.contains("{")
    }) else {
        throw SIGError.parseError
    }
    let scanner = Scanner(string: definitionLine)
    for modifier in accessModifiers {
        if scanner.scanString(modifier, into: nil) {
            break
        }
    }
    scanner.scanString("final", into: nil)
    guard scanner.scanString("class", into: nil) || scanner.scanString("struct", into: nil) else {
        throw SIGError.parseError
    }
    var dampName = scanner.string.contains(":") ? scanner.scanUpTo(":")?.trimmingCharacters(in: .whitespaces) : nil
    if dampName == nil {
        dampName = scanner.scanUpTo("{")?.dropLast().trimmingCharacters(in: .whitespaces)
    }
    guard let definitionName = dampName else {
        throw SIGError.parseError
    }
    
    var variables = [(String, String)]()

    for line in selection.dropFirst() {
        let scanner = Scanner(string: line)

        var weak = scanner.scanString("weak", into: nil)
        for modifier in accessModifiers {
            if scanner.scanString(modifier, into: nil) {
                break
            }
        }
        for modifier in accessModifiers {
            if scanner.scanString(modifier, into: nil) {
                guard let _ = scanner.scanUpTo(")"), let _ = scanner.scanString(")") else {
                    throw SIGError.parseError
                }
            }
        }
        weak = weak || scanner.scanString("weak", into: nil)

        guard scanner.scanString("let", into: nil) || scanner.scanString("var", into: nil) || scanner.scanString("dynamic var", into: nil) else {
            continue
        }
        guard let variableName = scanner.scanUpTo(":"),
            scanner.scanString(":", into: nil),
            let variableType = scanner.scanUpTo("\n") else {
                throw SIGError.parseError
        }
        variables.append((variableName, variableType))
    }

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
    
    let lines = (
        ["extension \(definitionName): Equatable {"] +
        ["\(indentation)static func == (lhs: \(definitionName), rhs: \(definitionName)) -> Bool {"] +
        expressions +
        ["\(indentation)}"] +
        ["}"]
    )

    return lines.map { "\($0)" }
}

private func addEscapingAttributeIfNeeded(to typeString: String) -> String {
    let predicate = NSPredicate(format: "SELF MATCHES %@", "\\(.*\\)->.*")
    if predicate.evaluate(with: typeString.replacingOccurrences(of: " ", with: "")),
        !isOptional(typeString: typeString) {
        return "@escaping " + typeString
    } else {
        return typeString
    }
}

private func isOptional(typeString: String) -> Bool {
    guard typeString.hasSuffix("!") || typeString.hasSuffix("?") else {
        return false
    }
    var balance = 0
    var indexOfClosingBraceMatchingFirstOpenBrace: Int?

    for (index, character) in typeString.enumerated() {
        if character == "(" {
            balance += 1
        } else if character == ")" {
            balance -= 1
        }
        if balance == 0 {
            indexOfClosingBraceMatchingFirstOpenBrace = index
            break
        }
    }

    return indexOfClosingBraceMatchingFirstOpenBrace == typeString.count - 2
}
