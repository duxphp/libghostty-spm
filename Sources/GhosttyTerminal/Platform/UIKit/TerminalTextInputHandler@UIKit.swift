//
//  TerminalTextInputHandler@UIKit.swift
//  libghostty-spm
//

#if canImport(UIKit)
    import GhosttyKit
    import UIKit

    @MainActor
    final class TerminalTextInputHandler {
        private weak var view: UITerminalView?
        private(set) var markedText: String?
        private var selectedRange = NSRange(location: 0, length: 0)

        var hasMarkedText: Bool {
            guard let markedText else { return false }
            return !markedText.isEmpty
        }

        var documentLength: Int {
            markedText?.utf16.count ?? 0
        }

        init(view: UITerminalView) {
            self.view = view
        }

        // MARK: - Text Input

        func insertText(_ text: String) {
            guard let view else { return }
            let shouldNotifySelectionChange = shouldNotifySelectionChange

            view.inputDelegate?.textWillChange(view)
            if shouldNotifySelectionChange {
                view.inputDelegate?.selectionWillChange(view)
            }

            markedText = nil
            selectedRange = NSRange(location: 0, length: 0)
            view.surface?.preedit("")
            view.surface?.sendText(text)

            if shouldNotifySelectionChange {
                view.inputDelegate?.selectionDidChange(view)
            }
            view.inputDelegate?.textDidChange(view)
        }

        func setMarkedText(_ text: String?, selectedRange: NSRange) {
            guard let view else { return }

            view.inputDelegate?.textWillChange(view)
            view.inputDelegate?.selectionWillChange(view)

            markedText = text
            self.selectedRange = clampedSelectedRange(selectedRange, in: text)

            if let text, !text.isEmpty {
                view.surface?.preedit(text)
            } else {
                view.surface?.preedit("")
            }

            view.inputDelegate?.selectionDidChange(view)
            view.inputDelegate?.textDidChange(view)
        }

        func unmarkText() {
            guard let view else { return }
            let shouldNotifySelectionChange = shouldNotifySelectionChange
            let committedText = markedText

            view.inputDelegate?.textWillChange(view)
            if shouldNotifySelectionChange {
                view.inputDelegate?.selectionWillChange(view)
            }

            markedText = nil
            selectedRange = NSRange(location: 0, length: 0)
            if let committedText, !committedText.isEmpty {
                view.surface?.sendText(committedText)
            }
            view.surface?.preedit("")

            if shouldNotifySelectionChange {
                view.inputDelegate?.selectionDidChange(view)
            }
            view.inputDelegate?.textDidChange(view)
        }

        func markedTextRange() -> TerminalTextRange? {
            guard let markedText, !markedText.isEmpty else { return nil }
            return TerminalTextRange(location: 0, length: markedText.utf16.count)
        }

        func selectedTextRange() -> TerminalTextRange {
            TerminalTextRange(
                location: selectedRange.location,
                length: selectedRange.length
            )
        }

        func setSelectedTextRange(_ range: UITextRange?) {
            let updatedRange = if let range = range as? TerminalTextRange {
                clampedSelectedRange(
                    NSRange(
                        location: range.location,
                        length: range.length
                    ),
                    in: markedText
                )
            } else {
                NSRange(location: 0, length: 0)
            }
            guard selectedRange != updatedRange else { return }
            updateSelectedRange(updatedRange)
        }

        func text(in range: TerminalTextRange) -> String? {
            guard let markedText else {
                return range.isEmpty ? "" : nil
            }

            let nsRange = NSRange(
                location: range.location,
                length: range.length
            )
            let nsText = markedText as NSString
            guard nsRange.location >= 0, nsRange.length >= 0 else { return nil }
            guard nsRange.location + nsRange.length <= nsText.length else { return nil }
            return nsText.substring(with: nsRange)
        }

        private var shouldNotifySelectionChange: Bool {
            hasMarkedText || selectedRange.location != 0 || selectedRange.length != 0
        }

        private func clampedSelectedRange(
            _ range: NSRange,
            in text: String?
        ) -> NSRange {
            let length = text?.utf16.count ?? 0
            let location = min(max(range.location, 0), length)
            let end = min(max(range.location + range.length, location), length)
            return NSRange(location: location, length: end - location)
        }

        private func updateSelectedRange(_ range: NSRange) {
            if let view {
                view.inputDelegate?.selectionWillChange(view)
            }
            selectedRange = range
            if let view {
                view.inputDelegate?.selectionDidChange(view)
            }
        }
    }
#endif
