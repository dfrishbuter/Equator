//
//  Copyright © 2018 Dmitry Frishbuter. All rights reserved.
//

import Foundation
import XcodeKit

class SourceEditorCommand: NSObject, XCSourceEditorCommand {

    func perform(with invocation: XCSourceEditorCommandInvocation, completionHandler: @escaping (Error?) -> Void) {
        do {
            try generateEquatable(invocation: invocation)
            completionHandler(nil)
        }
        catch {
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
            guard let startLine = invocation.buffer.lines[selection.start.line] as? String else {
                throw GeneratorError.noSelection
            }
            selectedText = [String(startLine.utf8.prefix(selection.end.column).dropFirst(selection.start.column))!]
        }
        else {
            guard let startLine = invocation.buffer.lines[selection.start.line] as? String,
                  let startText = String(startLine.utf8.dropFirst(selection.start.column)),
                  let endLine = invocation.buffer.lines[selection.end.line] as? String,
                  let endText = String(endLine.utf8.prefix(selection.end.column)) else {
                throw GeneratorError.noSelection
            }
            selectedText = [startText]
            selectedText += ((selection.start.line + 1)..<selection.end.line).compactMap { lineNumber -> String? in
                invocation.buffer.lines[lineNumber] as? String
            }
            selectedText += [endText]
        }

        var initializer = try generate(
            selection: selectedText,
            indentation: indentSequence(for: invocation.buffer),
            leadingIndent: leadingIndentation(from: selection, in: invocation.buffer)
        )

        initializer.insert("", at: 0) // separate from selection with empty line

        let targetRange = (selection.end.line + 1) ..< (selection.end.line + 1 + initializer.count)
        invocation.buffer.lines.insert(initializer, at: IndexSet(integersIn: targetRange))
    }
}

private func indentSequence(for buffer: XCSourceTextBuffer) -> String {
    return buffer.usesTabsForIndentation ? "\t" : String(repeating: " ", count: buffer.indentationWidth)
}

private func leadingIndentation(from selection: XCSourceTextRange, in buffer: XCSourceTextBuffer) -> String {
    guard let firstLineOfSelection = buffer.lines[selection.start.line] as? String else {
        return ""
    }
    if let nonWhitespace = firstLineOfSelection.rangeOfCharacter(from: CharacterSet.whitespaces.inverted) {
        return String(firstLineOfSelection.prefix(upTo: nonWhitespace.lowerBound))
    }
    else {
        return ""
    }
}
