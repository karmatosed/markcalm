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
        hostingView.sizingOptions = .minSize
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

        context.coordinator.scheduleInitialLayoutRefresh()

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        context.coordinator.hostingView?.rootView = content
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
        private var lastLayoutWidth: CGFloat = 0
        private var lastContentHeight: CGFloat = 0
        private var didInitialScrollToTop = false

        init(progress: Binding<CGFloat>) {
            self.progress = progress
        }

        @objc func scrollDidChange() {
            updateLayoutIfWidthChanged()
            updateProgress()
        }

        func scheduleInitialLayoutRefresh() {
            cancelPendingLayoutRefresh()

            let delays: [TimeInterval] = [0, 0.1, 0.35]
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
            let scrollToTop = !didInitialScrollToTop
            updateLayout(force: true, scrollToTop: scrollToTop)
            if scrollToTop {
                didInitialScrollToTop = true
            }
            updateProgress()
        }

        func updateLayoutIfWidthChanged() {
            guard let scrollView else { return }
            let width = max(scrollView.contentView.bounds.width, 1)
            guard abs(width - lastLayoutWidth) >= 1 else { return }
            updateLayout(force: true)
        }

        func updateLayout(force: Bool = false, scrollToTop: Bool = false) {
            guard let scrollView, let containerView, let hostingView else { return }

            let clipView = scrollView.contentView
            let width = max(clipView.bounds.width, 1)
            hostingView.layoutSubtreeIfNeeded()

            let contentHeight = Self.measuredContentHeight(hostingView: hostingView, width: width)
            let visibleHeight = clipView.bounds.height
            let documentHeight = max(contentHeight, visibleHeight)

            if !force,
               abs(width - lastLayoutWidth) < 1,
               abs(contentHeight - lastContentHeight) < 1 {
                return
            }

            let savedOrigin = clipView.bounds.origin

            lastLayoutWidth = width
            lastContentHeight = contentHeight

            containerView.frame = NSRect(x: 0, y: 0, width: width, height: documentHeight)
            hostingView.frame = NSRect(x: 0, y: 0, width: width, height: contentHeight)

            if scrollView.documentView !== containerView {
                scrollView.documentView = containerView
            }

            if scrollToTop {
                clipView.scroll(to: NSPoint(x: 0, y: 0))
            } else {
                clipView.scroll(to: savedOrigin)
            }
            scrollView.reflectScrolledClipView(clipView)
        }

        func updateProgress() {
            guard let scrollView, let documentView = scrollView.documentView else { return }

            let visibleRect = scrollView.contentView.documentVisibleRect
            let scrollable = documentView.frame.height - visibleRect.height

            guard scrollable > 1 else {
                progress.wrappedValue = 1
                return
            }

            progress.wrappedValue = min(max(visibleRect.origin.y / scrollable, 0), 1)
        }

        private static func measuredContentHeight(
            hostingView: NSHostingView<Content>,
            width: CGFloat
        ) -> CGFloat {
            hostingView.sizingOptions = .minSize
            // Height 0 clips markdown during measurement and trims the top of the document.
            hostingView.setFrameSize(NSSize(width: width, height: 10_000))
            hostingView.layoutSubtreeIfNeeded()

            let height = hostingView.fittingSize.height
            if height.isFinite, height > 1 {
                return ceil(height)
            }

            let intrinsic = hostingView.intrinsicContentSize.height
            if intrinsic.isFinite, intrinsic > 1 {
                return ceil(intrinsic)
            }

            return 1
        }
    }
}

/// Top-left origin so scroll position matches top-to-bottom reading progress.
final class FlippedContainerView: NSView {
    override var isFlipped: Bool { true }
}
