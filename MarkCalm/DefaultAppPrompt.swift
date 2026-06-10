import SwiftUI

struct DefaultAppPromptModifier: ViewModifier {
    @AppStorage(AppStorageKey.hasDismissedDefaultAppPrompt)
    private var hasDismissedDefaultAppPrompt = false

    @State private var isPresented = false

    func body(content: Content) -> some View {
        content
            .onAppear {
                guard !hasDismissedDefaultAppPrompt else { return }
                isPresented = true
            }
            .sheet(isPresented: $isPresented) {
                DefaultAppPromptSheet(
                    onOpenSettings: openDefaultAppsSettings,
                    onDismiss: dismissPrompt
                )
            }
    }

    private func openDefaultAppsSettings() {
        if let url = URL(
            string: "x-apple.systempreferences:com.apple.settings.Desktop-Extension?Default_Apps"
        ) {
            NSWorkspace.shared.open(url)
        }
        dismissPrompt()
    }

    private func dismissPrompt() {
        hasDismissedDefaultAppPrompt = true
        isPresented = false
    }
}

private struct DefaultAppPromptSheet: View {
    let onOpenSettings: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Make MarkCalm the default app for Markdown files?")
                .font(.headline)

            Text("You can change this anytime in System Settings.")
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                Spacer()
                Button("Not Now", action: onDismiss)
                    .keyboardShortcut(.cancelAction)
                Button("Open System Settings", action: onOpenSettings)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 420)
    }
}

extension View {
    func defaultAppPrompt() -> some View {
        modifier(DefaultAppPromptModifier())
    }
}
