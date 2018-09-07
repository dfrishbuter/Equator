//
//  Copyright © 2018 Dmitry Frishbuter. All rights reserved.
//

import Foundation
import XcodeKit

class SourceEditorCommand: NSObject, XCSourceEditorCommand {

    func perform(with invocation: XCSourceEditorCommandInvocation, completionHandler: @escaping (Swift.Error?) -> Void) {
        do {
            try generateEquatable(invocation: invocation)
            completionHandler(nil)
        } catch {
            completionHandler(error)
        }
    }

    private func generateEquatable(invocation: XCSourceEditorCommandInvocation) throws {
        guard invocation.buffer.contentUTI == "public.swift-source" else {
            throw GeneratorError.notSwiftLanguage
        }
        guard let selection = invocation.buffer.selections.firstObject as? XCSourceTextRange else {
            throw GeneratorError.noSelection
        }

        var selectedText: [String]
        if selection.start.line == selection.end.line {
            let startLine = invocation.buffer.lines[selection.start.line] as! String
            selectedText = [String(startLine.utf8.prefix(selection.end.column).dropFirst(selection.start.column))!]
        } else {
            selectedText = [String((invocation.buffer.lines[selection.start.line] as! String).utf8.dropFirst(selection.start.column))!]
            selectedText += ((selection.start.line + 1)..<selection.end.line).map {
                invocation.buffer.lines[$0] as! String
            }
            selectedText += [String((invocation.buffer.lines[selection.end.line] as! String).utf8.prefix(selection.end.column))!]
        }

        var initializer = try generate(
            selection: selectedText,
            indentation: indentSequence(for: invocation.buffer),
            leadingIndent: leadingIndentation(from: selection, in: invocation.buffer)
        )

        initializer.insert("", at: 0) // separate from selection with empty line

        let targetRange = selection.end.line + 1 ..< selection.end.line + 1 + initializer.count
        invocation.buffer.lines.insert(initializer, at: IndexSet(integersIn: targetRange))
    }
}

private func indentSequence(for buffer: XCSourceTextBuffer) -> String {
    return buffer.usesTabsForIndentation
        ? "\t"
        : String(repeating: " ", count: buffer.indentationWidth)
}

private func leadingIndentation(from selection: XCSourceTextRange, in buffer: XCSourceTextBuffer) -> String {
    let firstLineOfSelection = buffer.lines[selection.start.line] as! String
    if let nonWhitespace = firstLineOfSelection.rangeOfCharacter(from: CharacterSet.whitespaces.inverted) {
        return String(firstLineOfSelection.prefix(upTo: nonWhitespace.lowerBound))
    } else {
        return ""
    }
}
