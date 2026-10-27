import AppKit
import QuartzCore
import SwiftUI

/// A separate child window lets the preview extend beyond the NSPopover's clipping boundary.
struct CardHoverPreview {
    let content: AnyView
}

struct CardHoverZoom: ViewModifier {
    let preview: CardHoverPreview
    let enabled: Bool
    let delay: TimeInterval

    func body(content: Content) -> some View {
        content.background {
            CardHoverZoomAnchor(preview: preview, enabled: enabled, delay: delay)
                .accessibilityHidden(true)
        }
    }
}

/// Images magnify; text and file details reflow into the additional space.
/// The preview receives a concrete view, never a ViewModifier.Content proxy.
struct CardHoverZoomPreview: View {
    let preview: CardHoverPreview

    var body: some View {
        preview.content
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private struct CardHoverZoomAnchor: NSViewRepresentable {
    let preview: CardHoverPreview
    let enabled: Bool
    let delay: TimeInterval

    func makeNSView(context: Context) -> CardHoverZoomTrackingView {
        CardHoverZoomTrackingView(preview: preview, enabled: enabled, delay: delay)
    }

    func updateNSView(_ nsView: CardHoverZoomTrackingView, context: Context) {
        nsView.preview = preview
        CardHoverZoomController.shared.invalidatePreview(for: nsView)
        if nsView.isHoverEnabled != enabled || nsView.hoverDelay != delay {
            nsView.isHoverEnabled = enabled
            nsView.hoverDelay = delay
            nsView.updateTrackingAreas()
        }
    }

    static func dismantleNSView(_ nsView: CardHoverZoomTrackingView, coordinator: ()) {
        CardHoverZoomController.shared.cancel(for: nsView)
    }
}

private final class CardHoverZoomTrackingView: NSView {
    var preview: CardHoverPreview
    var isHoverEnabled: Bool
    var hoverDelay: TimeInterval
    private var hoverArea: NSTrackingArea?

    init(preview: CardHoverPreview, enabled: Bool, delay: TimeInterval) {
        self.preview = preview
        isHoverEnabled = enabled
        hoverDelay = delay
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) { nil }

    // This background only tracks the pointer; the SwiftUI button keeps all clicks.
    override func hitTest(_ point: NSPoint) -> NSView? { nil }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let hoverArea { removeTrackingArea(hoverArea) }
        hoverArea = nil
        guard isHoverEnabled else { return }
        let area = NSTrackingArea(
            rect: .zero,
            options: [.mouseEnteredAndExited, .mouseMoved, .activeAlways, .inVisibleRect],
            owner: self
        )
        addTrackingArea(area)
        hoverArea = area
    }

    override func mouseEntered(with event: NSEvent) {
        CardHoverZoomController.shared.hover(self)
    }

    override func mouseMoved(with event: NSEvent) {
        CardHoverZoomController.shared.hover(self)
    }

    override func mouseExited(with event: NSEvent) {
        CardHoverZoomController.shared.cancel(for: self)
    }

    override func viewWillMove(toWindow newWindow: NSWindow?) {
        if newWindow !== window { CardHoverZoomController.shared.cancel(for: self) }
        super.viewWillMove(toWindow: newWindow)
    }

    var screenFrame: NSRect? {
        guard let window, window.isVisible, !isHiddenOrHasHiddenAncestor,
              bounds.width > 0, bounds.height > 0 else { return nil }
        return window.convertToScreen(convert(bounds, to: nil))
    }

    var containsMouse: Bool {
        guard let window, screenFrame != nil else { return false }
        let point = convert(window.convertPoint(fromScreen: NSEvent.mouseLocation), from: nil)
        return visibleRect.contains(point)
    }
}

/// Clock-based intent is independent of animation and can be tested without real-time waits.
struct CardHoverIntent {
    var delay: TimeInterval = TimeInterval(AppSettings.defaultHoverZoomDelay)
    private(set) var position: NSPoint?
    private(set) var stationarySince: TimeInterval?

    mutating func move(to point: NSPoint, at time: TimeInterval) {
        guard position != point else { return }
        position = point
        stationarySince = time
    }

    func isReady(at time: TimeInterval) -> Bool {
        guard let stationarySince else { return false }
        return time - stationarySince >= delay
    }

    static func expandedFrame(from frame: NSRect, scale: CGFloat = 1.8) -> NSRect {
        frame.insetBy(dx: -frame.width * (scale - 1) / 2, dy: -frame.height * (scale - 1) / 2)
    }
}

@MainActor
final class CardHoverZoomController {
    static let shared = CardHoverZoomController()
    private weak var source: CardHoverZoomTrackingView?
    private var intent = CardHoverIntent()
    private var timer: Timer?
    private var panel: NSPanel?
    private var sourceFrame: NSRect?
    private var eventMonitor: Any?

    fileprivate func hover(_ view: CardHoverZoomTrackingView) {
        guard view.isHoverEnabled, view.containsMouse else { return }
        if source !== view {
            cancel(animated: false)
            source = view
            intent = CardHoverIntent(delay: view.hoverDelay)
            installEventMonitor()
        }
        guard panel == nil else { return }
        intent.move(to: NSEvent.mouseLocation, at: ProcessInfo.processInfo.systemUptime)
        if timer == nil {
            let timer = Timer(timeInterval: 0.05, repeats: true) { [weak self] _ in
                Task { @MainActor [weak self] in self?.checkHover() }
            }
            RunLoop.main.add(timer, forMode: .common)
            self.timer = timer
        }
    }

    private func installEventMonitor() {
        eventMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.scrollWheel, .keyDown, .leftMouseDown, .rightMouseDown, .otherMouseDown, .mouseMoved, .leftMouseDragged]
        ) { [weak self] event in
            guard let self else { return event }
            if event.type == .mouseMoved, let source = self.source, source.containsMouse {
                self.hover(source)
            } else {
                self.cancel(animated: event.type == .mouseMoved)
            }
            return event
        }
    }

    private func checkHover() {
        guard let source, source.isHoverEnabled, source.containsMouse else {
            cancel()
            return
        }
        guard panel == nil else {
            if source.screenFrame != sourceFrame { cancel(animated: false) }
            return
        }
        intent.move(to: NSEvent.mouseLocation, at: ProcessInfo.processInfo.systemUptime)
        if intent.isReady(at: ProcessInfo.processInfo.systemUptime) { show(source) }
    }

    private func show(_ source: CardHoverZoomTrackingView) {
        guard let parent = source.window, let frame = source.screenFrame else { return }
        let panel = NSPanel(contentRect: frame, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.ignoresMouseEvents = true
        panel.hidesOnDeactivate = true
        panel.isReleasedWhenClosed = false
        panel.animationBehavior = .none
        panel.appearance = source.effectiveAppearance
        let host = NSHostingView(rootView: CardHoverZoomPreview(preview: source.preview))
        host.appearance = source.effectiveAppearance
        host.frame = NSRect(origin: .zero, size: frame.size)
        // Do not let SwiftUI's ideal size constrain the animated window frame.
        host.sizingOptions = []
        panel.contentView = host
        self.panel = panel
        sourceFrame = frame
        let expanded = CardHoverIntent.expandedFrame(from: frame)
        let reduceMotion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        if reduceMotion {
            panel.setFrame(expanded, display: false)
            panel.alphaValue = 0
        }
        parent.addChildWindow(panel, ordered: .above)
        panel.orderFront(nil)
        NSAnimationContext.runAnimationGroup { context in
            context.duration = reduceMotion ? 0.12 : 0.26
            context.timingFunction = CAMediaTimingFunction(controlPoints: 0.16, 1, 0.3, 1)
            if reduceMotion {
                panel.animator().alphaValue = 1
            } else {
                panel.animator().setFrame(expanded, display: true)
            }
        }
    }

    fileprivate func invalidatePreview(for view: CardHoverZoomTrackingView) {
        if source === view { cancel(animated: false) }
    }

    fileprivate func cancel(for view: CardHoverZoomTrackingView) {
        if source === view { cancel() }
    }

    func cancel(animated: Bool = true) {
        timer?.invalidate()
        timer = nil
        if let eventMonitor { NSEvent.removeMonitor(eventMonitor) }
        eventMonitor = nil
        source = nil
        intent = CardHoverIntent()
        guard let panel else { return }
        let frame = sourceFrame
        self.panel = nil
        sourceFrame = nil
        let close = {
            panel.parent?.removeChildWindow(panel)
            panel.orderOut(nil)
        }
        guard animated else { close(); return }
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.16
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            if !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion, let frame {
                panel.animator().setFrame(frame, display: true)
            }
            panel.animator().alphaValue = 0
        } completionHandler: {
            close()
        }
    }
}
