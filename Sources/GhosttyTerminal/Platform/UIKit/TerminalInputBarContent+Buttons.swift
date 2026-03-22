//
//  TerminalInputBarContent+Buttons.swift
//  libghostty-spm
//

#if canImport(UIKit) && !targetEnvironment(macCatalyst)
    import SwiftUI

    enum TerminalInputBarKey {
        case esc, tab
        case arrowLeft, arrowUp, arrowDown, arrowRight
        case symbol(String)
        case paste
    }

    struct StickyModifierButton: View {
        let title: String
        let systemImage: String
        let activation: TerminalStickyModifierState.Activation
        let action: () -> Void

        var body: some View {
            Button(action: action) {
                Image(systemName: systemImage)
                    .font(.system(size: 15, weight: .medium))
                    .frame(width: 36, height: 36)
                    .overlay(alignment: .bottom) {
                        if activation == .locked {
                            Capsule()
                                .fill(Color.accentColor)
                                .frame(width: 14, height: 3)
                                .offset(y: -3)
                        }
                    }
            }
            .accessibilityLabel(title)
            .accessibilityValue(activationLabel)
            .modifier(StickyModifierButtonStyle(activation: activation))
        }

        private var activationLabel: String {
            switch activation {
            case .inactive: "off"
            case .armed: "on"
            case .locked: "locked"
            }
        }
    }

    struct BarKeyButton: View {
        let label: String
        let systemImage: String?
        let action: () -> Void

        init(_ label: String, systemImage: String? = nil, action: @escaping () -> Void) {
            self.label = label
            self.systemImage = systemImage
            self.action = action
        }

        var body: some View {
            Button(action: action) {
                Group {
                    if let systemImage {
                        Image(systemName: systemImage)
                            .font(.system(size: 14, weight: .medium))
                    } else {
                        Text(label)
                            .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    }
                }
                .frame(width: 36, height: 36)
            }
            .accessibilityLabel(label)
            .modifier(BarKeyButtonStyle())
        }
    }

    // MARK: - Button Styles

    private struct StickyModifierButtonStyle: ViewModifier {
        let activation: TerminalStickyModifierState.Activation

        func body(content: Content) -> some View {
            content
                .foregroundStyle(activation != .inactive ? Color.accentColor : .primary)
                .background(
                    activation != .inactive
                        ? Color.accentColor.opacity(0.18)
                        : Color(.systemGray5).opacity(0.92),
                    in: Circle()
                )
        }
    }

    private struct BarKeyButtonStyle: ViewModifier {
        func body(content: Content) -> some View {
            content
                .foregroundStyle(.primary)
                .background(Color(.systemGray5).opacity(0.92), in: Circle())
        }
    }
#endif
