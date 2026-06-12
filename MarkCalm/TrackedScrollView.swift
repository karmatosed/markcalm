import AppKit
import SwiftUI

/// Legacy AppKit scroll wrapper — kept for reference; reading view uses SwiftUI `ScrollView` in `ContentView`.
struct TrackedScrollView<Content: View>: NSViewRepresentable {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .noBorder

        let hostingView = NSHostingView(rootView: content)
        hostingView.sizingOptions = .minSize
        scrollView.documentView = hostingView
        context.coordinator.hostingView = hostingView

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        context.coordinator.hostingView?.rootView = content
        context.coordinator.hostingView?.invalidateIntrinsicContentSize()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator {
        var hostingView: NSHostingView<Content>?
    }
}
