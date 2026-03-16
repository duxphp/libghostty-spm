//
//  TerminalSurfaceCoordinator.swift
//  libghostty-spm
//
//  Created by Lakr233 on 2026/3/16.
//

import Foundation
import GhosttyKit
import MSDisplayLink

/// Shared terminal state and logic used by both UIKit and AppKit views.
///
/// Platform views own a `TerminalSurfaceCoordinator` instance and set platform-specific
/// hooks via closures. The core handles surface lifecycle, metrics
/// synchronization, and frame rendering via display link.
@MainActor
final class TerminalSurfaceCoordinator {
    weak var delegate: (any TerminalSurfaceViewDelegate)? {
        didSet { bridge.delegate = delegate }
    }

    var controller: TerminalController? {
        didSet {
            guard controller !== oldValue else { return }
            rebuildIfReady(removingBridgeFrom: oldValue)
        }
    }

    var configuration: TerminalSurfaceOptions = .init() {
        didSet {
            guard !configuration.isEquivalent(to: oldValue) else { return }
            rebuildIfReady()
        }
    }

    var surface: TerminalSurface?
    let bridge = TerminalCallbackBridge()

    // MARK: - Platform Hooks

    var isAttached: () -> Bool = { false }
    var scaleFactor: () -> Double = { 2.0 }
    var viewSize: () -> (width: Double, height: Double) = { (0, 0) }
    var platformSetup: ((inout ghostty_surface_config_s) -> Void)?
    var onMetricsUpdate: (() -> Void)?

    /// Called after every display-link render (`tick`).
    ///
    /// When `synchronizeMetrics` sends a new pixel size to ghostty via
    /// `setSize`, the underlying IOSurface is not rebuilt synchronously.
    /// Until the next full render pass ghostty still uses the **old**
    /// IOSurface, so it derives an incorrect `contentsScale` for the
    /// IOSurfaceLayer (e.g. old-pixel-height / new-point-height → 4.62
    /// instead of the expected 3.0). This causes a visible "jump" on
    /// every layout change (keyboard show/hide, rotation, color-scheme
    /// toggle, etc.).
    ///
    /// Platform views use this hook to silently enforce the correct
    /// `contentsScale` and `frame` on sublayers after each render,
    /// correcting any drift introduced by ghostty within a single frame.
    var onPostRender: (() -> Void)?

    private var lastMetrics: TerminalViewportMetrics?

    // MARK: - Display Link

    private var displayLink: DisplayLink?
    private let displayLinkTarget = DisplayLinkTarget()

    func startDisplayLink() {
        guard displayLink == nil else { return }
        displayLinkTarget.core = self
        let link = DisplayLink()
        link.delegatingObject(displayLinkTarget)
        displayLink = link
    }

    func stopDisplayLink() {
        displayLink = nil
        displayLinkTarget.core = nil
    }

    // MARK: - Surface Lifecycle

    func rebuildIfReady(removingBridgeFrom previousController: TerminalController? = nil) {
        tearDownSurface(removingBridgeFrom: previousController ?? controller)
        guard let controller else { return }
        guard isAttached() else { return }

        let scale = scaleFactor()
        let rawSurface = controller.createSurface(
            bridge: bridge,
            configuration: configuration,
            platformSetup: { [self] config in
                platformSetup?(&config)
                config.scale_factor = scale
            }
        )
        guard let rawSurface else { return }

        bridge.rawSurface = rawSurface
        surface = TerminalSurface(rawSurface)
        synchronizeMetrics()
    }

    // MARK: - Metrics

    func synchronizeMetrics() {
        guard let surface else { return }

        let scale = scaleFactor()
        let size = viewSize()
        guard size.width > 0, size.height > 0 else { return }

        let pixelWidth = UInt32((size.width * scale).rounded(.down))
        let pixelHeight = UInt32((size.height * scale).rounded(.down))
        guard pixelWidth > 0, pixelHeight > 0 else { return }

        surface.setContentScale(x: scale, y: scale)
        surface.setSize(width: pixelWidth, height: pixelHeight)

        guard let surfaceSize = surface.size(),
              surfaceSize.columns > 0, surfaceSize.rows > 0
        else {
            onMetricsUpdate?()
            return
        }

        let metrics = TerminalViewportMetrics(surfaceSize: surfaceSize, scale: scale)
        guard metrics != lastMetrics else {
            onMetricsUpdate?()
            return
        }

        lastMetrics = metrics
        configuration.inMemorySession?.updateViewport(surfaceSize)
        if let delegate = delegate as? any TerminalSurfaceGridResizeDelegate {
            delegate.terminalDidResize(surfaceSize)
        } else if let delegate = delegate as? any TerminalSurfaceResizeDelegate {
            delegate.terminalDidResize(
                columns: Int(surfaceSize.columns),
                rows: Int(surfaceSize.rows)
            )
        }
        onMetricsUpdate?()
    }

    func fitToSize() {
        synchronizeMetrics()
    }

    // MARK: - Frame Rendering

    func tick() {
        controller?.tick()
        surface?.refresh()
        surface?.draw()
        onPostRender?()
    }

    // MARK: - Focus

    func setFocus(_ focused: Bool) {
        surface?.setFocus(focused)
        (delegate as? any TerminalSurfaceFocusDelegate)?
            .terminalDidChangeFocus(focused)
    }

    // MARK: - Cleanup

    func freeSurface() {
        tearDownSurface(removingBridgeFrom: controller)
    }

    deinit {
        displayLink = nil
    }

    private func tearDownSurface(removingBridgeFrom controller: TerminalController?) {
        configuration.inMemorySession?.setSurface(nil)
        bridge.rawSurface = nil
        surface?.setFocus(false)
        surface?.free()
        surface = nil
        lastMetrics = nil
        controller?.remove(bridge)
    }
}

// MARK: - DisplayLinkTarget

/// Bridges the `nonisolated` display link callback back to `@MainActor`
/// TerminalSurfaceCoordinator. Stored as a separate object because `TerminalSurfaceCoordinator` itself
/// is `@MainActor` and cannot directly conform to `nonisolated` protocol.
private final class DisplayLinkTarget: DisplayLinkDelegate, @unchecked Sendable {
    @MainActor var core: TerminalSurfaceCoordinator?

    nonisolated func synchronization(context _: DisplayLinkCallbackContext) {
        DispatchQueue.main.async { [weak self] in
            MainActor.assumeIsolated {
                self?.core?.tick()
            }
        }
    }
}
