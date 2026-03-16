# GhosttyKit

Swift Package wrapping [Ghostty](https://ghostty.org)'s terminal emulator library for Apple platforms.

> Pre-built `libghostty` static library distributed as an XCFramework binary target.

## Platforms

- macOS 13+
- iOS 16+
- Mac Catalyst 16+

## Products

| Library           | Description                                                                     |
| ----------------- | ------------------------------------------------------------------------------- |
| `GhosttyKit`      | Re-exports the libghostty C API (`ghostty.h`)                                   |
| `GhosttyTerminal` | Swift wrapper — native views, SwiftUI integration, input handling, display link |

## Installation

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/Lakr233/libghostty-spm.git", from: "0.1.0"),
]
```

Then add the product you need:

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "GhosttyTerminal", package: "libghostty-spm"),
    ]
)
```

## Usage

### SwiftUI (iOS 17+ / macOS 14+)

```swift
import SwiftUI
import GhosttyTerminal

struct ContentView: View {
    @State private var context = TerminalViewState(
        theme: .init(
            light: TerminalConfiguration {
                $0.withBackgroundOpacity(0.9)
            },
            dark: TerminalConfiguration {
                $0.withBackgroundOpacity(0.7)
            }
        ),
        terminalConfiguration: TerminalConfiguration {
            $0.withFontSize(14)
            $0.withCursorStyle(.block)
            $0.withCursorStyleBlink(true)
        }
    )

    var body: some View {
        TerminalSurfaceView(context: context)
            .navigationTitle(context.title)
            .onAppear {
                context.configuration = TerminalSurfaceOptions(
                    backend: .hostManaged(session)
                )
            }
    }
}
```

`TerminalViewState` is an `@Observable` class that publishes terminal state:

- `title` — current terminal title
- `surfaceSize` — grid dimensions (columns, rows, pixels)
- `isFocused` — whether the terminal has input focus
- `renderedConfig` — the effective composed `terminal.conf` text
- `effectiveColorScheme` — the active light/dark scheme adopted from SwiftUI
- `theme` — light/dark visual overrides built from typed config commands
- `terminalConfiguration` — behavior-oriented config commands layered in order
- `configuration` — surface backend and settings
- `onClose` — callback when the terminal session ends

### UIKit

```swift
import GhosttyTerminal

let terminalView = TerminalView(frame: .zero)
terminalView.delegate = self
terminalView.controller = TerminalController(configFilePath: path)
terminalView.configuration = TerminalSurfaceOptions(
    backend: .hostManaged(session)
)
```

### AppKit

```swift
import GhosttyTerminal

let terminalView = TerminalView(frame: bounds)
terminalView.delegate = self
terminalView.controller = TerminalController(configFilePath: path)
terminalView.configuration = TerminalSurfaceOptions(
    backend: .hostManaged(session)
)
```

`TerminalView` is a type alias that resolves to `UITerminalView` (iOS/Catalyst) or `AppTerminalView` (macOS).

### Host-Managed I/O

For sandboxed apps that cannot spawn subprocesses, use the host-managed backend:

```swift
let session = InMemoryTerminalSession(
    write: { data in
        // Terminal produced output bytes — process or display them
    },
    resize: { viewport in
        // Terminal grid resized — update your backend
    }
)

// Feed input to the terminal
session.receive("Hello, terminal!\r\n")

// Signal process exit
session.finish(exitCode: 0, runtimeMilliseconds: 0)
```

### TerminalSurfaceViewDelegate

Implement the delegate for event callbacks (UIKit/AppKit usage):

```swift
func terminalDidChangeTitle(_ title: String)
func terminalDidResize(_ size: TerminalGridMetrics)
func terminalDidResize(columns: Int, rows: Int)
func terminalDidChangeFocus(_ focused: Bool)
func terminalDidRingBell()
func terminalDidClose(processAlive: Bool)
```

All methods have default empty implementations.

## Architecture

```
GhosttyKit (C API)
    libghostty.a — Ghostty core (Zig → static lib)
    ghostty.h — C header

GhosttyTerminal (Swift)
    TerminalViewState          — @Observable state for SwiftUI
    TerminalSurfaceView        — SwiftUI View (wraps representable)
    TerminalView               — Platform view typealias (UIView / NSView)
    TerminalController         — App lifecycle, config, surface creation
    TerminalSurfaceCoordinator — Shared logic, display link, metrics
    TerminalSurface            — Thin wrapper around ghostty_surface_t
    TerminalKeyEventHandler    — Keyboard event translation (AppKit)
    InMemoryTerminalSession — Sandbox-safe I/O backend
```

## Building from Source

The package includes a pre-built XCFramework. To rebuild libghostty from the Ghostty source:

```bash
# Requires: zig compiler
./Script/build.sh
```

This applies patches from `Patches/ghostty/`, builds for all target architectures, and assembles the XCFramework.

## Example Apps

- `Example/GhosttyTerminalApp/` — macOS demo (AppKit + delegate pattern)
- `Example/MobileGhosttyApp/` — iOS demo (UIKit + safe area handling)

Both use a mock echo terminal (`MockTerminalSession`) with the host-managed I/O backend to run inside App Sandbox without spawning subprocesses.

## License

MIT License. See [LICENSE](LICENSE) for details.

The bundled `libghostty` binary is built from [Ghostty](https://ghostty.org), which has its own license terms.
