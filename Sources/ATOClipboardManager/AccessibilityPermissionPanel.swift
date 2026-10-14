import AppKit
import SwiftUI

@MainActor
final class AccessibilityPermissionPanelController: NSObject, NSWindowDelegate {
    private let panel: NSPanel
    private let permission: AccessibilityPermissionManager
    private var dismissAction: ((Bool) -> Void)?
    private var shouldRestoreFocus = true
    private var permissionCheckTimer: Timer?

    var appearance: NSAppearance? {
        get { panel.appearance }
        set { panel.appearance = newValue }
    }

    init(
        permission: AccessibilityPermissionManager,
        language: AppLanguage,
        appearance: NSAppearance?,
        openSystemSettings: @escaping () -> Void,
        dismiss: @escaping (Bool) -> Void
    ) {
        self.permission = permission
        dismissAction = dismiss

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 520),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        self.panel = panel

        super.init()

        let content = AccessibilityPermissionPromptView(
            language: language,
            openSystemSettings: openSystemSettings,
            dismiss: { [weak self] restoreFocus in
                self?.close(restoreFocus: restoreFocus)
            }
        )
        panel.contentViewController = NSHostingController(rootView: content)
        panel.title = Localizer.text(.automaticPastePermissionTitle, language: language)
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isMovableByWindowBackground = true
        panel.isReleasedWhenClosed = false
        panel.hidesOnDeactivate = false
        panel.level = .floating
        panel.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
        panel.appearance = appearance
        panel.delegate = self
        panel.center()
    }

    func show() {
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        startPermissionPolling()
    }

    func close(restoreFocus: Bool = true) {
        shouldRestoreFocus = restoreFocus
        panel.close()
    }

    private func startPermissionPolling() {
        checkPermission()
        guard permissionCheckTimer == nil, panel.isVisible else { return }

        let timer = Timer(timeInterval: 2, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkPermission()
            }
        }
        permissionCheckTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    func windowWillClose(_ notification: Notification) {
        stopPermissionPolling()
        let action = dismissAction
        dismissAction = nil
        action?(shouldRestoreFocus)
    }

    private func checkPermission() {
        permission.refresh()
        if permission.isGranted {
            close(restoreFocus: false)
        }
    }

    private func stopPermissionPolling() {
        permissionCheckTimer?.invalidate()
        permissionCheckTimer = nil
    }
}

private struct AccessibilityPermissionPromptView: View {
    let language: AppLanguage
    let openSystemSettings: () -> Void
    let dismiss: (Bool) -> Void

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.orange.opacity(0.14))
                    Image(systemName: "hand.raised.fill")
                        .font(.system(size: 25, weight: .semibold))
                        .foregroundStyle(.orange)
                }
                .frame(width: 58, height: 58)

                Text(Localizer.text(.automaticPastePermissionTitle, language: language))
                    .font(.system(size: 20, weight: .semibold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color(nsColor: .labelColor))

                Text(Localizer.text(.automaticPastePermissionMessage, language: language))
                    .font(.system(size: 13))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color(nsColor: .secondaryLabelColor))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 34)
            .padding(.top, 32)
            .padding(.bottom, 22)

            HStack(spacing: 16) {
                DraggableApplicationIcon(
                    accessibilityLabel: Localizer.text(.draggableATOIcon, language: language),
                    onSuccessfulDrop: { dismiss(false) }
                )
                .frame(width: 62, height: 62)

                VStack(alignment: .leading, spacing: 5) {
                    Text(Localizer.text(.dragATOToAccessibility, language: language))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color(nsColor: .labelColor))
                    Text(Localizer.text(.dragATOToAccessibilityHint, language: language))
                        .font(.system(size: 12))
                        .foregroundStyle(Color(nsColor: .secondaryLabelColor))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(14)
            .background(
                Color(nsColor: .selectedContentBackgroundColor).opacity(0.13),
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
            .padding(.horizontal, 24)

            Spacer(minLength: 20)

            HStack(spacing: 10) {
                Button(Localizer.text(.notNow, language: language)) {
                    dismiss(true)
                }
                    .keyboardShortcut(.cancelAction)

                Spacer()

                Button(Localizer.text(.openAccessibilitySettings, language: language)) {
                    openSystemSettings()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
            .controlSize(.large)
            .padding(.horizontal, 24)
            .padding(.vertical, 18)
            .background(Color(nsColor: .controlBackgroundColor))
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(Color(nsColor: .separatorColor))
                    .frame(height: 1)
            }
        }
        .frame(width: 480, height: 520)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}
