@testable import GhosttyTerminal
import Testing

struct TerminalInputTextTests {
    @Test
    func filtersApplePrivateUseFunctionKeysFromTextPath() {
        #expect(TerminalInputText.filteredFunctionKeyText("\u{F702}") == nil)
        #expect(TerminalInputText.filteredFunctionKeyText("\u{F703}") == nil)
        #expect(TerminalInputText.filteredFunctionKeyText("UIKeyInputLeftArrow") == nil)
        #expect(TerminalInputText.filteredFunctionKeyText("UIKeyInputUpArrow") == nil)
        #expect(TerminalInputText.filteredFunctionKeyText("a") == "a")
        #expect(TerminalInputText.filteredFunctionKeyText("你好") == "你好")
        #expect(TerminalInputText.filteredFunctionKeyText("\u{FFFF}") == "\u{FFFF}")
        #expect(TerminalInputText.filteredFunctionKeyText("打\u{FFFF}撒") == "打\u{FFFF}撒")
    }

    @Test
    func recognizesPrivateUseFunctionKeyScalars() {
        #expect(TerminalInputText.isPrivateUseFunctionKey("\u{F702}"))
        #expect(TerminalInputText.isPrivateUseFunctionKey("\u{F703}"))
        #expect(!TerminalInputText.isPrivateUseFunctionKey("a"))
        #expect(!TerminalInputText.isPrivateUseFunctionKey("你"))
    }

    @Test
    func recognizesUIKitNamedFunctionKeys() {
        #expect(TerminalInputText.isUIKitNamedFunctionKey("UIKeyInputLeftArrow"))
        #expect(TerminalInputText.isUIKitNamedFunctionKey("UIKeyInputDownArrow"))
        #expect(!TerminalInputText.isUIKitNamedFunctionKey("a"))
        #expect(!TerminalInputText.isUIKitNamedFunctionKey("你好"))
    }
}
