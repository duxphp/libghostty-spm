//
//  TerminalInputBarContent.swift
//  libghostty-spm
//

#if canImport(UIKit) && !targetEnvironment(macCatalyst)
    import SwiftUI

    struct TerminalInputBarContent: View {
        var ctrlActivation: TerminalStickyModifierState.Activation
        var altActivation: TerminalStickyModifierState.Activation
        var commandActivation: TerminalStickyModifierState.Activation
        var onModifier: (TerminalStickyModifierState.Modifier) -> Void
        var onKey: (TerminalInputBarKey) -> Void

        var body: some View {
            if #available(iOS 26, *) {
                GlassEffectContainer(spacing: 10) {
                    scrollContainer
                        .glassEffect(
                            .regular.tint(.white.opacity(0.08)),
                            in: .capsule
                        )
                }
            } else {
                scrollContainer
                    .background(.ultraThinMaterial, in: .capsule)
            }
        }

        private var scrollContainer: some View {
            ScrollView(.horizontal, showsIndicators: false) {
                barContent
                    .padding(.horizontal, 10)
                    .fixedSize(horizontal: true, vertical: false)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 52)
        }

        private var barContent: some View {
            HStack(spacing: 8) {
                modifierSection
                barDivider
                keySection
                barDivider
                symbolSection
            }
            .padding(.vertical, 8)
        }

        // MARK: - Sections

        private var modifierSection: some View {
            HStack(spacing: 4) {
                StickyModifierButton(
                    title: "Escape",
                    systemImage: "escape",
                    activation: .inactive,
                    action: { onKey(.esc) }
                )
                StickyModifierButton(
                    title: "Control",
                    systemImage: "control",
                    activation: ctrlActivation,
                    action: { onModifier(.ctrl) }
                )
                StickyModifierButton(
                    title: "Option",
                    systemImage: "option",
                    activation: altActivation,
                    action: { onModifier(.alt) }
                )
                StickyModifierButton(
                    title: "Command",
                    systemImage: "command",
                    activation: commandActivation,
                    action: { onModifier(.command) }
                )
            }
        }

        private var keySection: some View {
            HStack(spacing: 4) {
                BarKeyButton("Tab", systemImage: "arrow.right.to.line") {
                    onKey(.tab)
                }
                BarKeyButton("Left", systemImage: "arrowshape.left") {
                    onKey(.arrowLeft)
                }
                BarKeyButton("Up", systemImage: "arrowshape.up") {
                    onKey(.arrowUp)
                }
                BarKeyButton("Down", systemImage: "arrowshape.down") {
                    onKey(.arrowDown)
                }
                BarKeyButton("Right", systemImage: "arrowshape.right") {
                    onKey(.arrowRight)
                }
            }
        }

        private var symbolSection: some View {
            HStack(spacing: 4) {
                ForEach(Self.symbols, id: \.self) { sym in
                    BarKeyButton(sym) { onKey(.symbol(sym)) }
                }
                BarKeyButton("Paste", systemImage: "doc.on.clipboard") {
                    onKey(.paste)
                }
            }
        }

        private var barDivider: some View {
            Circle()
                .fill(Color.secondary.opacity(0.28))
                .frame(width: 6, height: 6)
        }

        private static let symbols = ["|", "/", "~", "-", "_", "`", "'", "\""]
    }
#endif
