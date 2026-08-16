import AppKit
import AVFoundation

/// Borderless, mouse-transparent desktop-level window.
final class VideoWindow: NSWindow {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect {
        frameRect
    }
}

/// Plays one muted looping video across every screen at the desktop window level.
final class WallpaperPlayer {
    private var player: AVQueuePlayer?
    private var looper: AVPlayerLooper?
    private var slots: [(window: VideoWindow, layer: AVPlayerLayer)] = []

    var videoPath: String?
    var isLoaded: Bool { player != nil }
    var currentItem: AVPlayerItem? { player?.currentItem }
    var currentTime: CMTime { player?.currentTime() ?? .zero }

    /// (Re)create one video window per screen.
    func rebuildWindows() {
        teardownWindows()
        createWindows()
    }

    /// Load a video file and attach it to every screen layer. Returns false if the file is missing.
    @discardableResult
    func load(videoPath path: String) -> Bool {
        guard FileManager.default.fileExists(atPath: path) else {
            tqLogger.error("video file missing: \(path, privacy: .public)")
            return false
        }
        teardownPlayer()

        let item = AVPlayerItem(url: URL(fileURLWithPath: path))
        item.preferredForwardBufferDuration = 1.0
        item.preferredMaximumResolution = largestScreenPixelSize()
        item.preferredPeakBitRate = 6_000_000

        let queue = AVQueuePlayer()
        queue.isMuted = true
        queue.actionAtItemEnd = .pause
        queue.preventsDisplaySleepDuringVideoPlayback = false
        looper = AVPlayerLooper(player: queue, templateItem: item)
        player = queue
        for slot in slots {
            slot.layer.player = queue
        }
        videoPath = path
        tqLogger.info("loaded video: \(path, privacy: .public)")
        return true
    }

    /// Show + play or hide + release the decoder, depending on the energy/lock/sleep state.
    func apply(shouldPlay: Bool) {
        if shouldPlay {
            if player == nil, let path = videoPath {
                _ = load(videoPath: path)
            }
            guard let player else { return }
            for slot in slots {
                if let screen = slot.window.screen {
                    slot.window.setFrame(screen.frame, display: true)
                }
                slot.window.orderFrontRegardless()
            }
            player.play()
        } else {
            for slot in slots {
                slot.window.orderOut(nil)
            }
            teardownPlayer()
        }
    }

    func teardownPlayer() {
        player?.pause()
        player?.replaceCurrentItem(with: nil)
        looper = nil
        for slot in slots {
            slot.layer.player = nil
        }
        player = nil
    }

    private func createWindows() {
        slots = NSScreen.screens.map { screen in
            let window = VideoWindow(
                contentRect: screen.frame,
                styleMask: [.borderless],
                backing: .buffered,
                defer: false
            )
            window.isReleasedWhenClosed = false
            window.hasShadow = false
            window.backgroundColor = .black
            window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)) + 1)
            window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
            window.ignoresMouseEvents = true

            let layer = AVPlayerLayer()
            layer.videoGravity = .resizeAspectFill
            layer.contentsScale = screen.backingScaleFactor
            layer.frame = window.contentView?.bounds ?? .zero
            layer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]

            if let contentView = window.contentView {
                contentView.wantsLayer = true
                contentView.layer?.contentsScale = screen.backingScaleFactor
                contentView.layer?.addSublayer(layer)
            }
            window.setFrame(screen.frame, display: true)

            return (window, layer)
        }
        tqLogger.info("created windows for \(self.slots.count) screen(s)")
    }

    private func teardownWindows() {
        for slot in slots {
            slot.window.orderOut(nil)
            slot.layer.removeFromSuperlayer()
        }
        slots = []
    }

    private func largestScreenPixelSize() -> CGSize {
        var width: CGFloat = 0
        var height: CGFloat = 0
        for screen in NSScreen.screens {
            width = max(width, ceil(screen.frame.width * screen.backingScaleFactor))
            height = max(height, ceil(screen.frame.height * screen.backingScaleFactor))
        }
        return CGSize(width: width, height: height)
    }
}
