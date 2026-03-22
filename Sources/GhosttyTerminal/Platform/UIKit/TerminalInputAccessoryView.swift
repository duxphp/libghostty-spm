//
//  TerminalInputAccessoryView.swift
//  libghostty-spm
//

#if canImport(UIKit) && !targetEnvironment(macCatalyst)
    import SwiftUI
    import UIKit

    @MainActor
    final class TerminalInputAccessoryView: UIView {
        weak var terminalView: UITerminalView?
        private var hostingController: UIHostingController<TerminalInputBarContent>?

        init(terminalView: UITerminalView) {
            self.terminalView = terminalView
            super.init(frame: CGRect(x: 0, y: 0, width: 0, height: 52))
            autoresizingMask = .flexibleWidth
            setupHosting()
        }

        @available(*, unavailable)
        required init?(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override var intrinsicContentSize: CGSize {
            CGSize(width: UIView.noIntrinsicMetric, height: 52)
        }

        private func setupHosting() {
            let content = makeContent()
            let hc = UIHostingController(rootView: content)
            hc.view.translatesAutoresizingMaskIntoConstraints = false
            hc.view.backgroundColor = .clear
            addSubview(hc.view)
            NSLayoutConstraint.activate([
                hc.view.leadingAnchor.constraint(equalTo: leadingAnchor),
                hc.view.trailingAnchor.constraint(equalTo: trailingAnchor),
                hc.view.topAnchor.constraint(equalTo: topAnchor),
                hc.view.bottomAnchor.constraint(equalTo: bottomAnchor),
            ])
            hostingController = hc

            terminalView?.stickyModifiers.onChange = { [weak self] in
                self?.refreshContent()
            }
        }

        func refreshContent() {
            hostingController?.rootView = makeContent()
        }

        private func makeContent() -> TerminalInputBarContent {
            guard let terminalView else {
                return TerminalInputBarContent(
                    ctrlActivation: .inactive,
                    altActivation: .inactive,
                    commandActivation: .inactive,
                    onModifier: { _ in },
                    onKey: { _ in }
                )
            }
            return TerminalInputBarContent(
                ctrlActivation: terminalView.stickyModifiers.ctrl,
                altActivation: terminalView.stickyModifiers.alt,
                commandActivation: terminalView.stickyModifiers.command,
                onModifier: { [weak terminalView] modifier in
                    terminalView?.stickyModifiers.toggle(modifier)
                },
                onKey: { [weak terminalView] key in
                    terminalView?.handleInputBarKey(key)
                }
            )
        }
    }
#endif
