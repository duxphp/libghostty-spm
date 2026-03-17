//
//  UITerminalView+Keyboard.swift
//  libghostty-spm
//
//  Created by Lakr233 on 2026/3/17.
//

#if canImport(UIKit)
    import GhosttyKit
    import UIKit

    public extension UITerminalView {
        override func pressesBegan(
            _ presses: Set<UIPress>,
            with _: UIPressesEvent?
        ) {
            for press in presses {
                guard let key = press.key else { continue }
                handleKeyPress(key, action: GHOSTTY_ACTION_PRESS)
            }
        }

        override func pressesEnded(
            _ presses: Set<UIPress>,
            with _: UIPressesEvent?
        ) {
            for press in presses {
                guard let key = press.key else { continue }
                handleKeyPress(key, action: GHOSTTY_ACTION_RELEASE)
            }
            hardwareKeyHandled = false
        }

        override func pressesCancelled(
            _ presses: Set<UIPress>,
            with event: UIPressesEvent?
        ) {
            hardwareKeyHandled = false
            super.pressesCancelled(presses, with: event)
        }

        internal func handleKeyPress(
            _ key: UIKey,
            action: ghostty_input_action_e
        ) {
            guard let surface else { return }

            let filteredModifierFlags = filteredModifierFlags(for: key)
            let isCommandModified = filteredModifierFlags.contains(.command)
            let mods = TerminalInputModifiers(from: filteredModifierFlags)

            if action == GHOSTTY_ACTION_PRESS,
               shouldSuppressUIKeyInput(for: key, isCommandModified: isCommandModified)
            {
                hardwareKeyHandled = true
            }

            let delivery = TerminalHardwareKeyRouter.routeUIKit(
                usage: UInt16(key.keyCode.rawValue),
                backend: configuration.backend
            )

            if action == GHOSTTY_ACTION_RELEASE, delivery.isDirectInput {
                return
            }

            if handleDirectInputIfNeeded(
                delivery,
                action: action,
                isCommandModified: isCommandModified,
                filteredModifierFlags: filteredModifierFlags
            ) {
                return
            }

            var keyEvent = ghostty_input_key_s()
            keyEvent.action = action
            keyEvent.mods = mods.ghosttyMods
            if case let .ghostty(ghosttyKey) = delivery {
                keyEvent.keycode = ghosttyKey.rawValue
            } else {
                keyEvent.keycode = GHOSTTY_KEY_UNIDENTIFIED.rawValue
            }
            keyEvent.composing = inputHandler.hasMarkedText

            var consumedFlags = filteredModifierFlags
            consumedFlags.remove(.control)
            consumedFlags.remove(.command)
            keyEvent.consumed_mods = TerminalInputModifiers(from: consumedFlags).ghosttyMods

            guard action == GHOSTTY_ACTION_PRESS || action == GHOSTTY_ACTION_REPEAT else {
                surface.sendKeyEvent(keyEvent)
                return
            }

            let filteredIgnoringModifiers = TerminalInputText.filteredFunctionKeyText(
                key.charactersIgnoringModifiers
            )

            if let codepoint = filteredIgnoringModifiers?.unicodeScalars.first {
                keyEvent.unshifted_codepoint = codepoint.value
            }

            guard !isCommandModified else {
                surface.sendKeyEvent(keyEvent)
                return
            }

            guard let text = TerminalInputText.filteredFunctionKeyText(key.characters),
                  !text.isEmpty
            else {
                surface.sendKeyEvent(keyEvent)
                return
            }

            text.withCString { ptr in
                keyEvent.text = ptr
                surface.sendKeyEvent(keyEvent)
            }
        }

        internal func shouldSuppressUIKeyInput(
            for key: UIKey,
            isCommandModified: Bool
        ) -> Bool {
            guard !isCommandModified else { return false }
            guard key.modifierFlags.intersection([.alternate, .control]).isEmpty else {
                return false
            }
            guard !key.characters.isEmpty else {
                return key.keyCode == .keyboardDeleteOrBackspace
            }
            return true
        }

        private func handleDirectInputIfNeeded(
            _ delivery: TerminalHardwareKeyDelivery,
            action: ghostty_input_action_e,
            isCommandModified: Bool,
            filteredModifierFlags: UIKeyModifierFlags
        ) -> Bool {
            // When IME composition is active, UIKit must own editing keys such as
            // backspace and arrows so candidate text stays in sync.
            guard !inputHandler.hasMarkedText else { return false }
            guard !isCommandModified else { return false }
            guard filteredModifierFlags.intersection([.alternate, .control]).isEmpty else {
                return false
            }
            guard action == GHOSTTY_ACTION_PRESS || action == GHOSTTY_ACTION_REPEAT else {
                return false
            }
            guard case let .data(sequence) = delivery else { return false }
            guard case let .inMemory(session) = configuration.backend else { return false }

            session.sendInput(sequence)
            return true
        }

        private func filteredModifierFlags(for key: UIKey) -> UIKeyModifierFlags {
            var flags = key.modifierFlags
            let isFunctionKey =
                TerminalInputText.filteredFunctionKeyText(key.characters) == nil ||
                TerminalInputText.filteredFunctionKeyText(key.charactersIgnoringModifiers) == nil
            if isFunctionKey {
                flags.remove(.numericPad)
            }
            return flags
        }
    }
#endif
