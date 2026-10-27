import AppKit
import QuartzCore
import SwiftUI

/// A separate child window lets the preview extend beyond the NSPopover's clipping boundary.
struct CardHoverPreview {
    let content: AnyView
}

struct CardHoverZoom: ViewModifier {
    let itemID: UUID
    let preview: CardHoverPreview
    let enabled: Bool
    let delay: TimeInterval

    func body(content: Content) -> some View {
        content.background {
            CardHoverZoomAnchor(itemID: itemID, preview: preview, enabled: enabled, delay: delay)
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
    let itemID: UUID
    let preview: CardHoverPreview
    let enabled: Bool
    let delay: TimeInterval

    func makeNSView(context: Context) -> CardHoverZoomTrackingView {
        let view = CardHoverZoomTrackingView(itemID: itemID, preview: preview, enabled: enabled, delay: delay)
        CardHoverZoomController.shared.register(view)
        return view
    }

    func updateNSView(_ nsView: CardHoverZoomTrackingView, context: Context) {
        nsView.preview = preview
        if nsView.isHoverEnabled != enabled || nsView.hoverDelay != delay {
            CardHoverZoomController.shared.cancel(for: nsView)
            nsView.isHoverEnabled = enabled
            nsView.hoverDelay = delay
            nsView.updateTrackingAreas()
        }
        CardHoverZoomController.shared.invalidatePreview(for: nsView)
    }

    static func dismantleNSView(_ nsView: CardHoverZoomTrackingView, coordinator: ()) {
        CardHoverZoomController.shared.unregister(nsView)
    }
}

private final class CardHoverZoomTrackingView: NSView {
    let itemID: UUID
    var preview: CardHoverPreview
    var isHoverEnabled: Bool
    var hoverDelay: TimeInterval
    private var hoverArea: NSTrackingArea?

    init(itemID: UUID, preview: CardHoverPreview, enabled: Bool, delay: TimeInterval) {
        self.itemID = itemID
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
        CardHoverZoomController.shared.mouseExited(self)
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

/// Ignore inward pinches and small movements; open once per outward gesture.
struct CardMagnificationIntent {
    private var accumulated: CGFloat = 0
    private var triggered = false

    mutating func update(delta: CGFloat, phase: NSEvent.Phase) -> Bool {
        if phase.contains(.began) { self = Self() }
        accumulated += delta
        let shouldOpen = !phase.contains(.cancelled) && !triggered && accumulated >= 0.05
        if shouldOpen { triggered = true }
        if phase.contains(.ended) || phase.contains(.cancelled) { self = Self() }
        return shouldOpen
    }
}

/// A trackpad press may arrive just before magnification, or as the fingers lift.
/// Defer pointer activation briefly so that the gesture can cancel it.
struct CardGestureClickGuard {
    static let activationDelay: TimeInterval = 0.18
    private(set) var isGesturing = false
    private var suppressUntil: TimeInterval = 0
    private var swallowedMouseDown = false

    mutating func beginGesture() { isGesturing = true }

    mutating func endGesture(at time: TimeInterval) {
        isGesturing = false
        suppressUntil = time + 0.3
    }

    func suppressesActivation(at time: TimeInterval) -> Bool {
        isGesturing || time < suppressUntil
    }

    mutating func mouseDown(at time: TimeInterval) -> Bool {
        swallowedMouseDown = suppressesActivation(at: time)
        return swallowedMouseDown
    }

    mutating func mouseUp() -> Bool {
        let swallowed = swallowedMouseDown
        swallowedMouseDown = false
        return swallowed
    }

    mutating func cancel(at time: TimeInterval) {
        if isGesturing { endGesture(at: time) }
        swallowedMouseDown = false
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
    private final class WeakTrackingView {
        weak var view: CardHoverZoomTrackingView?
        init(_ view: CardHoverZoomTrackingView) { self.view = view }
    }

    static let shared = CardHoverZoomController()
    private var anchors: [UUID: WeakTrackingView] = [:]
    private weak var source: CardHoverZoomTrackingView?
    private var intent = CardHoverIntent()
    private var timer: Timer?
    private var panel: NSPanel?
    private var sourceFrame: NSRect?
    private var eventMonitor: Any?
    private var magnificationIntent = CardMagnificationIntent()
    private var isManualPreview = false
    private var clickGuard = CardGestureClickGuard()
    private var pendingActivation: DispatchWorkItem?
    private(set) var keyboardZoomItemID: UUID?
    private var keyboardCandidateFrame: NSRect?
    private var keyboardFrameStableSince: TimeInterval = 0

    func toggleKeyboardZoom(itemID: UUID) {
        if keyboardZoomItemID == itemID {
            cancel()
        } else {
            setKeyboardZoomTarget(itemID)
        }
    }

    func followKeyboardSelection(_ itemID: UUID?) {
        guard keyboardZoomItemID != nil || panel != nil else { return }
        guard let itemID else { cancel(); return }
        guard keyboardZoomItemID != itemID else { return }
        setKeyboardZoomTarget(itemID)
    }

    private func setKeyboardZoomTarget(_ itemID: UUID) {
        cancel(animated: false)
        keyboardZoomItemID = itemID
        startTimerIfNeeded()
        checkKeyboardZoom()
    }

    /// Consume Escape even while waiting for a lazy card to scroll into view.
    @discardableResult
    func dismissZoomForEscape() -> Bool {
        guard panel != nil || keyboardZoomItemID != nil else { return false }
        cancel()
        return true
    }

    private func checkKeyboardZoom() {
        guard let itemID = keyboardZoomItemID, let view = anchors[itemID]?.view else { return }
        guard view.isHoverEnabled else { cancel(); return }
        guard let frame = view.screenFrame, !view.visibleRect.isEmpty else { return }
        if panel != nil {
            if frame != sourceFrame { cancel(animated: false, preserveKeyboardZoom: true) }
            return
        }
        let now = ProcessInfo.processInfo.systemUptime
        if keyboardCandidateFrame != frame {
            keyboardCandidateFrame = frame
            keyboardFrameStableSince = now
            return
        }
        // Wait for scrollTo's animation to settle rather than opening at stale coordinates.
        guard now - keyboardFrameStableSince >= 0.08 else { return }
        source = view
        isManualPreview = true
        if eventMonitor == nil { installEventMonitor() }
        show(view)
    }

    func activateCard(itemID: UUID, action: @escaping () -> Void) {
        guard NSApp.currentEvent?.type != .keyDown,
              let view = anchors[itemID]?.view, view.isHoverEnabled else {
            action()
            return
        }
        guard !clickGuard.suppressesActivation(at: ProcessInfo.processInfo.systemUptime) else { return }
        pendingActivation?.cancel()
        // Keep listening after mouseDown: the next event may begin a pinch.
        if source !== view { hover(view) }
        timer?.invalidate()
        timer = nil
        let activation = DispatchWorkItem { [weak self, weak view] in
            guard let self, let view, view.screenFrame != nil,
                  !self.clickGuard.suppressesActivation(at: ProcessInfo.processInfo.systemUptime) else { return }
            self.pendingActivation = nil
            self.cancel(animated: false)
            action()
        }
        pendingActivation = activation
        DispatchQueue.main.asyncAfter(deadline: .now() + CardGestureClickGuard.activationDelay, execute: activation)
    }

    private func beginTrackpadGesture() {
        clickGuard.beginGesture()
        pendingActivation?.cancel()
        pendingActivation = nil
        timer?.invalidate()
        timer = nil
    }

    fileprivate func register(_ view: CardHoverZoomTrackingView) {
        anchors[view.itemID] = WeakTrackingView(view)
    }

    fileprivate func unregister(_ view: CardHoverZoomTrackingView) {
        cancel(for: view)
        if anchors[view.itemID]?.view === view { anchors.removeValue(forKey: view.itemID) }
    }

    func enlarge(itemID: UUID) {
        guard let view = anchors[itemID]?.view else { return }
        enlarge(view)
    }

    private func enlarge(_ view: CardHoverZoomTrackingView) {
        guard view.isHoverEnabled, view.screenFrame != nil else { return }
        if source !== view {
            cancel(animated: false)
            source = view
            installEventMonitor()
        }
        isManualPreview = true
        if panel == nil { show(view) }
        startTimerIfNeeded()
    }

    fileprivate func hover(_ view: CardHoverZoomTrackingView) {
        guard view.isHoverEnabled, view.containsMouse else { return }
        guard keyboardZoomItemID == nil else { return }
        guard !clickGuard.isGesturing else { return }
        // The enlarged preview may cover neighboring cards; keep its source stable.
        guard !isManualPreview || panel == nil else { return }
        if source !== view {
            cancel(animated: false, preservePendingActivation: true)
            source = view
            intent = CardHoverIntent(delay: view.hoverDelay)
            installEventMonitor()
        }
        guard panel == nil else { return }
        intent.move(to: NSEvent.mouseLocation, at: ProcessInfo.processInfo.systemUptime)
        startTimerIfNeeded()
    }

    private func startTimerIfNeeded() {
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
            matching: [.beginGesture, .endGesture, .magnify, .scrollWheel, .keyDown, .leftMouseDown, .leftMouseUp, .rightMouseDown, .otherMouseDown, .mouseMoved, .leftMouseDragged]
        ) { [weak self] event in
            guard let self else { return event }
            if event.type == .keyDown {
                guard !(NSApp.keyWindow?.firstResponder is ShortcutRecorderButton) else { return event }
                let modifiers = event.modifierFlags.intersection([.command, .option, .control, .shift])
                if event.keyCode == 53, modifiers.isEmpty, event.window == self.source?.window {
                    if event.isARepeat { return nil }
                    if self.dismissZoomForEscape() { return nil }
                }
                // AppDelegate owns keyboard navigation and shortcut dispatch. Do not
                // tear down the preview before that monitor can handle the key.
                return event
            }
            if event.type == .beginGesture, let source = self.source,
               source.isHoverEnabled, source.containsMouse || self.containsPreviewMouse {
                self.beginTrackpadGesture()
                return event
            }
            if event.type == .endGesture {
                self.clickGuard.endGesture(at: ProcessInfo.processInfo.systemUptime)
                self.startTimerIfNeeded()
                return event
            }
            if event.type == .magnify, let source = self.source,
               source.isHoverEnabled, source.containsMouse || self.containsPreviewMouse || self.clickGuard.isGesturing {
                if !self.clickGuard.isGesturing { self.beginTrackpadGesture() }
                if self.magnificationIntent.update(delta: event.magnification, phase: event.phase) {
                    self.enlarge(source)
                }
                if event.phase.contains(.ended) || event.phase.contains(.cancelled) {
                    self.clickGuard.endGesture(at: ProcessInfo.processInfo.systemUptime)
                    self.startTimerIfNeeded()
                }
                return nil
            }
            if event.type == .leftMouseDown, let source = self.source,
               source.containsMouse || self.containsPreviewMouse || self.clickGuard.isGesturing {
                let swallowed = self.clickGuard.mouseDown(at: ProcessInfo.processInfo.systemUptime)
                self.timer?.invalidate()
                self.timer = nil
                return swallowed ? nil : event
            }
            if event.type == .leftMouseUp {
                let swallowed = self.clickGuard.mouseUp()
                self.startTimerIfNeeded()
                return swallowed ? nil : event
            }
            if self.clickGuard.isGesturing, event.type == .mouseMoved || event.type == .leftMouseDragged {
                return event
            }
            if event.type == .mouseMoved, self.isManualPreview {
                if self.keyboardZoomItemID == nil, !self.containsPreviewMouse { self.cancel() }
            } else if event.type == .mouseMoved, let source = self.source, source.containsMouse {
                self.hover(source)
            } else {
                self.cancel(
                    animated: event.type == .mouseMoved,
                    preservePendingActivation: event.type == .mouseMoved
                )
            }
            return event
        }
    }

    private var containsPreviewMouse: Bool {
        guard let sourceFrame, panel != nil else { return false }
        return CardHoverIntent.expandedFrame(from: sourceFrame).contains(NSEvent.mouseLocation)
    }

    private func checkHover() {
        if keyboardZoomItemID != nil {
            checkKeyboardZoom()
            return
        }
        guard let source, source.isHoverEnabled, source.screenFrame != nil,
              isManualPreview || source.containsMouse else {
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
        guard source === view, let host = panel?.contentView as? NSHostingView<CardHoverZoomPreview> else { return }
        host.rootView = CardHoverZoomPreview(preview: view.preview)
    }

    fileprivate func mouseExited(_ view: CardHoverZoomTrackingView) {
        guard keyboardZoomItemID == nil else { return }
        if source === view, !isManualPreview, !clickGuard.isGesturing {
            cancel(preservePendingActivation: true)
        }
    }

    fileprivate func cancel(for view: CardHoverZoomTrackingView) {
        if source === view { cancel(preserveKeyboardZoom: keyboardZoomItemID != nil) }
    }

    func cancel(animated: Bool = true, preservePendingActivation: Bool = false, preserveKeyboardZoom: Bool = false) {
        if !preservePendingActivation {
            pendingActivation?.cancel()
            pendingActivation = nil
        }
        clickGuard.cancel(at: ProcessInfo.processInfo.systemUptime)
        timer?.invalidate()
        timer = nil
        if let eventMonitor { NSEvent.removeMonitor(eventMonitor) }
        eventMonitor = nil
        source = nil
        isManualPreview = false
        magnificationIntent = CardMagnificationIntent()
        intent = CardHoverIntent()
        if !preserveKeyboardZoom { keyboardZoomItemID = nil }
        keyboardCandidateFrame = nil
        keyboardFrameStableSince = 0
        if keyboardZoomItemID != nil { startTimerIfNeeded() }
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
