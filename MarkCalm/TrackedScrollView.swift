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

        let container = FlippedContainerView()
        let hostingView = NSHostingView(rootView: content)
        hostingView.translatesAutoresizingMaskIntoConstraints = true
        container.addSubview(hostingView)

        scrollView.documentView = container
        context.coordinator.scrollView = scrollView
        context.coordinator.containerView = container
        context.coordinator.hostingView = hostingView

        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.scrollDidChange),
            name: NSView.boundsDidChangeNotification,
            object: scrollView.contentView
        )

        context.coordinator.scheduleLayoutRefresh()

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        context.coordinator.hostingView?.rootView = content
        context.coordinator.hostingView?.invalidateIntrinsicContentSize()
        context.coordinator.scheduleLayoutRefresh()
    }

    static func dismantleNSView(_ scrollView: NSScrollView, coordinator: Coordinator) {
        NotificationCenter.default.removeObserver(coordinator)
        coordinator.cancelPendingLayoutRefresh()
    }

    final class Coordinator: NSObject {
        var progress: Binding<CGFloat>
        weak var scrollView: NSScrollView?
        weak var containerView: FlippedContainerView?
        var hostingView: NSHostingView<Content>?
        private var layoutRefreshWorkItems: [DispatchWorkItem] = []

        init(progress: Binding<CGFloat>) {
            self.progress = progress
        }

        @objc func scrollDidChange() {
            updateProgress()
        }

        func scheduleLayoutRefresh() {
            cancelPendingLayoutRefresh()

            // Markdown layout can settle over several frames after load or content changes.
            let delays: [TimeInterval] = [0, 0.05, 0.15, 0.35, 0.75]
            for delay in delays {
                let work = DispatchWorkItem { [weak self] in
                    self?.refreshLayoutAndProgress()
                }
                layoutRefreshWorkItems.append(work)
                DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
            }
        }

        func cancelPendingLayoutRefresh() {
            layoutRefreshWorkItems.forEach { $0.cancel() }
            layoutRefreshWorkItems.removeAll()
        }

        func refreshLayoutAndProgress() {
            updateLayout()
            updateProgress()
        }

        func updateLayout() {
            guard let scrollView, let containerView, let hostingView else { return }

            let width = max(scrollView.contentView.bounds.width, 1)
            hostingView.layoutSubtreeIfNeeded()

            let contentHeight = Self.measuredContentHeight(hostingView: hostingView, width: width)
            let visibleHeight = scrollView.contentView.bounds.height
            let totalHeight = max(contentHeight, visibleHeight)

            containerView.frame = NSRect(x: 0, y: 0, width: width, height: totalHeight)
            hostingView.frame = NSRect(x: 0, y: 0, width: width, height: contentHeight)
            scrollView.documentView = containerView
        }

        func updateProgress() {
            guard let scrollView, let documentView = scrollView.documentView else { return }

            let visibleRect = scrollView.contentView.documentVisibleRect
            let scrollable = documentView.frame.height - visibleRect.height

            guard scrollable > 1 else {
                progress.wrappedValue = 1
                return
            }

            // Flipped document coordinates: origin.y grows as the reader scrolls down.
            progress.wrappedValue = min(max(visibleRect.origin.y / scrollable, 0), 1)
        }

        private static func measuredContentHeight(
            hostingView: NSHostingView<Content>,
            width: CGFloat
        ) -> CGFloat {
            hostingView.setFrameSize(NSSize(width: width, height: 1))
            hostingView.layoutSubtreeIfNeeded()

            let fitting = hostingView.fittingSize
            if fitting.height > 1 {
                return ceil(fitting.height)
            }

            return ceil(max(hostingView.intrinsicContentSize.height, 1))
        }
    }
}

/// Top-left origin so scroll position matches top-to-bottom reading progress.
final class FlippedContainerView: NSView {
    override var isFlipped: Bool { true }
}
