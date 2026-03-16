import GhosttyTerminal
@testable import ShellCraftKit
import Testing

struct ShellCraftKitTests {
    @Test
    func styledPromptUsesVisibleColumnWidth() {
        let shell = ShellDefinition(
            prompt: "\u{1B}[38;5;110mcolor\u{1B}[0m > ",
            welcomeMessage: ""
        ) {}

        #expect(shell.promptDisplayWidth == 8)
    }

    @Test
    func terminalDisplayWidthCountsWideCharacters() {
        #expect("abc".terminalDisplayWidth == 3)
        #expect("你好".terminalDisplayWidth == 4)
        #expect("a你b好".terminalDisplayWidth == 6)
        #expect("\u{1B}[31m红色\u{1B}[0m".terminalDisplayWidth == 4)
    }

    @Test
    func cursorColumnUsesDisplayWidthInsteadOfCharacterCount() {
        #expect(
            terminalCursorColumn(
                promptDisplayWidth: 8,
                input: "测试",
                cursorPosition: 2
            ) == 13
        )

        #expect(
            terminalCursorColumn(
                promptDisplayWidth: 8,
                input: "a测b",
                cursorPosition: 2
            ) == 12
        )

        #expect(
            terminalCursorColumn(
                promptDisplayWidth: 8,
                input: "你好吗",
                cursorPosition: 1
            ) == 11
        )
    }

    @Test
    func sandboxShellSupportsExitAndStyledFallback() {
        let viewport = InMemoryTerminalViewport(
            columns: 80,
            rows: 24,
            widthPixels: 0,
            heightPixels: 0
        )

        switch defaultSandboxShell.processCommand(
            "exit",
            username: "tester",
            terminalSize: viewport
        ) {
        case .exit:
            break

        default:
            Issue.record("expected sandbox shell exit command to terminate the session")
        }

        if case let .output(message) = defaultSandboxShell.processCommand(
            "missing-command",
            username: "tester",
            terminalSize: viewport
        ) {
            #expect(message.contains("\u{1B}["))
            #expect(message.contains("missing-command"))
        } else {
            Issue.record("expected fallback command result to produce output")
        }
    }
}
