import AppKit
import SwiftUI

struct TrackedScrollView<Content: View>: NSViewRepresentable {
    @Binding var progress: CGFloat
    let content: Content

    init(progress: Binding<CGFloat>, @ViewBuilder content: () -> Content) {
        _progress = progress
        self.content = content()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(progress: $progress)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.contentView.postsBoundsChangedNotifications = true

        let hostingView = NSHostingView(rootView: content)
        scrollView.documentView = hostingView
        context.coordinator.scrollView = scrollView
        context.coordinator.hostingView = hostingView

        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.scrollDidChange),
            name: NSView.boundsDidChangeNotification,
            object: scrollView.contentView
        )

        DispatchQueue.main.async {
            context.coordinator.refreshLayoutAndProgress()
        }

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        context.coordinator.hostingView?.rootView = content
        DispatchQueue.main.async {
            context.coordinator.refreshLayoutAndProgress()
        }
    }

    static func dismantleNSView(_ scrollView: NSScrollView, coordinator: Coordinator) {
        NotificationCenter.default.removeObserver(coordinator)
    }

    final class Coordinator: NSObject {
        var progress: Binding<CGFloat>
        weak var scrollView: NSScrollView?
        var hostingView: NSHostingView<Content>?

        init(progress: Binding<CGFloat>) {
            self.progress = progress
        }

        @objc func scrollDidChange() {
            updateProgress()
        }

        func refreshLayoutAndProgress() {
            updateLayout()
            updateProgress()
        }

        func updateLayout() {
            guard let scrollView, let hostingView else { return }

            hostingView.layoutSubtreeIfNeeded()
            let width = scrollView.contentView.bounds.width
            let height = hostingView.fittingSize.height
            let visibleHeight = scrollView.contentView.bounds.height

            hostingView.frame = NSRect(
                x: 0,
                y: 0,
                width: width,
                height: max(height, visibleHeight)
            )
            scrollView.documentView = hostingView
        }

        func updateProgress() {
            guard let scrollView, let documentView = scrollView.documentView else { return }

            let visibleHeight = scrollView.contentView.bounds.height
            let totalHeight = documentView.frame.height
            let offset = scrollView.contentView.bounds.origin.y
            let scrollable = totalHeight - visibleHeight

            guard scrollable > 1 else {
                progress.wrappedValue = 0
                return
            }

            progress.wrappedValue = min(max(offset / scrollable, 0), 1)
        }
    }
}
