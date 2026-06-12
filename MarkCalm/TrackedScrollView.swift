import AppKit
import SwiftUI

@MainActor
@Observable
final class ScrollProgress {
    var value: CGFloat = 0
}

struct TrackedScrollView<Content: View>: NSViewRepresentable {
    let progress: ScrollProgress
    let content: Content

    init(progress: ScrollProgress, @ViewBuilder content: () -> Content) {
        self.progress = progress
        self.content = content()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(progress: progress)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.postsFrameChangedNotifications = true
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

        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.viewFrameDidChange),
            name: NSView.frameDidChangeNotification,
            object: scrollView
        )

        context.coordinator.scheduleInitialLayout()

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        context.coordinator.hostingView?.rootView = content
    }

    static func dismantleNSView(_ scrollView: NSScrollView, coordinator: Coordinator) {
        NotificationCenter.default.removeObserver(coordinator)
        coordinator.cancelPendingLayout()
    }

    final class Coordinator: NSObject {
        let progress: ScrollProgress
        weak var scrollView: NSScrollView?
        weak var containerView: FlippedContainerView?
        var hostingView: NSHostingView<Content>?
        private var layoutWorkItems: [DispatchWorkItem] = []
        private var lastLayoutWidth: CGFloat = 0
        private var lastContentHeight: CGFloat = 0
        private var lastReportedProgress: CGFloat = -1
        private var didInitialScrollToTop = false

        init(progress: ScrollProgress) {
            self.progress = progress
        }

        @objc func scrollDidChange() {
            let fraction = currentProgressFraction()
            Task { @MainActor in
                applyProgress(fraction)
            }
        }

        @objc func viewFrameDidChange() {
            Task { @MainActor in
                updateLayout(preserveScrollPosition: true)
            }
        }

        func scheduleInitialLayout() {
            cancelPendingLayout()

            for delay in [0.0, 0.15] as [TimeInterval] {
                let work = DispatchWorkItem { [weak self] in
                    Task { @MainActor in
                        guard let self else { return }
                        let scrollToTop = !self.didInitialScrollToTop
                        self.updateLayout(preserveScrollPosition: !scrollToTop, scrollToTop: scrollToTop)
                        if scrollToTop {
                            self.didInitialScrollToTop = true
                        }
                        self.applyProgress(self.currentProgressFraction())
                    }
                }
                layoutWorkItems.append(work)
                DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
            }
        }

        func cancelPendingLayout() {
            layoutWorkItems.forEach { $0.cancel() }
            layoutWorkItems.removeAll()
        }

        @MainActor
        func updateLayout(preserveScrollPosition: Bool, scrollToTop: Bool = false) {
            guard let scrollView, let containerView, let hostingView else { return }

            let clipView = scrollView.contentView
            let width = max(clipView.bounds.width, 1)
            let savedOrigin = clipView.bounds.origin

            hostingView.layoutSubtreeIfNeeded()
            let contentHeight = Self.measuredContentHeight(hostingView: hostingView, width: width)
            let visibleHeight = clipView.bounds.height
            let documentHeight = max(contentHeight, visibleHeight)

            if abs(width - lastLayoutWidth) < 1,
               abs(contentHeight - lastContentHeight) < 1 {
                return
            }

            lastLayoutWidth = width
            lastContentHeight = contentHeight

            containerView.frame = NSRect(x: 0, y: 0, width: width, height: documentHeight)
            hostingView.frame = NSRect(x: 0, y: 0, width: width, height: contentHeight)

            if scrollView.documentView !== containerView {
                scrollView.documentView = containerView
            }

            if scrollToTop {
                clipView.scroll(to: .zero)
            } else if preserveScrollPosition {
                clipView.setBoundsOrigin(savedOrigin)
            }

            scrollView.reflectScrolledClipView(clipView)
        }

        func currentProgressFraction() -> CGFloat {
            guard let scrollView, let documentView = scrollView.documentView else { return 0 }

            let visibleRect = scrollView.contentView.documentVisibleRect
            let scrollable = documentView.frame.height - visibleRect.height

            if scrollable > 1 {
                return min(max(visibleRect.origin.y / scrollable, 0), 1)
            }
            return 1
        }

        @MainActor
        func applyProgress(_ fraction: CGFloat) {
            guard abs(fraction - lastReportedProgress) > 0.001 else { return }
            lastReportedProgress = fraction
            progress.value = fraction
        }

        private static func measuredContentHeight(
            hostingView: NSHostingView<Content>,
            width: CGFloat
        ) -> CGFloat {
            hostingView.sizingOptions = .minSize
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
