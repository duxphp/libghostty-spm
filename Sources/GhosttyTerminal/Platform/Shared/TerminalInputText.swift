//
//  TerminalInputText.swift
//  libghostty-spm
//

import Foundation

enum TerminalInputText {
    static func filteredFunctionKeyText(_ text: String?) -> String? {
        guard let text else { return nil }
        if isUIKitNamedFunctionKey(text) {
            return nil
        }

        let filteredScalars = text.unicodeScalars.filter { scalar in
            !shouldDiscardTextScalar(scalar)
        }
        guard !filteredScalars.isEmpty else { return nil }

        let filtered = String(String.UnicodeScalarView(filteredScalars))
        return filtered.isEmpty ? nil : filtered
    }

    static func shouldDiscardTextScalar(_ scalar: UnicodeScalar) -> Bool {
        if isPrivateUseFunctionKey(scalar) {
            return true
        }

        return isUnicodeNoncharacter(scalar)
    }

    static func isPrivateUseFunctionKey(_ scalar: UnicodeScalar) -> Bool {
        scalar.value >= 0xF700 && scalar.value <= 0xF8FF
    }

    static func isUnicodeNoncharacter(_ scalar: UnicodeScalar) -> Bool {
        let value = scalar.value

        if (0xFDD0...0xFDEF).contains(value) {
            return true
        }

        return value <= 0x10FFFF && (value & 0xFFFE) == 0xFFFE
    }

    static func isUIKitNamedFunctionKey(_ text: String) -> Bool {
        text.hasPrefix("UIKeyInput")
    }
}
