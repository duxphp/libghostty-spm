import Foundation
import GhosttyKit
@testable import GhosttyTerminal
import Testing

struct TerminalHardwareKeyRouterTests {
    @Test
    func routesUIKitArrowKeysDirectlyForInMemoryBackends() {
        let session = InMemoryTerminalSession(write: { _ in }, resize: { _ in })
        #expect(
            TerminalHardwareKeyRouter.routeUIKit(
                usage: 0x50,
                backend: .inMemory(session)
            ) == .data(Data("\u{1B}[D".utf8))
        )
        #expect(
            TerminalHardwareKeyRouter.routeUIKit(
                usage: 0x52,
                backend: .inMemory(session)
            ) == .data(Data("\u{1B}[A".utf8))
        )
        #expect(
            TerminalHardwareKeyRouter.routeUIKit(
                usage: 0x2A,
                backend: .inMemory(session)
            ) == .data(Data([0x7F]))
        )
    }

    @Test
    func routesUIKitKeysToGhosttyForExecBackends() {
        #expect(
            TerminalHardwareKeyRouter.routeUIKit(
                usage: 0x50,
                backend: .exec
            ) == .ghostty(GHOSTTY_KEY_ARROW_LEFT)
        )
        #expect(
            TerminalHardwareKeyRouter.routeUIKit(
                usage: 0x04,
                backend: .exec
            ) == .ghostty(GHOSTTY_KEY_A)
        )
    }

    @Test
    func routesAppKitArrowKeysDirectlyForInMemoryBackends() {
        let session = InMemoryTerminalSession(write: { _ in }, resize: { _ in })
        #expect(
            TerminalHardwareKeyRouter.routeAppKit(
                keyCode: 0x7B,
                backend: .inMemory(session)
            ) == .data(Data("\u{1B}[D".utf8))
        )
        #expect(
            TerminalHardwareKeyRouter.routeAppKit(
                keyCode: 0x75,
                backend: .inMemory(session)
            ) == .data(Data("\u{1B}[3~".utf8))
        )
    }

    @Test
    func routesAppKitKeysToGhosttyForExecBackends() {
        #expect(
            TerminalHardwareKeyRouter.routeAppKit(
                keyCode: 0x7B,
                backend: .exec
            ) == .ghostty(GHOSTTY_KEY_ARROW_LEFT)
        )
        #expect(
            TerminalHardwareKeyRouter.routeAppKit(
                keyCode: 0x33,
                backend: .exec
            ) == .ghostty(GHOSTTY_KEY_BACKSPACE)
        )
    }
}
