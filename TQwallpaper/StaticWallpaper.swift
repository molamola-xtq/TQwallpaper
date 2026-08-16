import AppKit
import AVFoundation

enum StaticWallpaper {
    enum StaticWallpaperError: LocalizedError {
        case noVideoLoaded
        case encodeFailed
        case noApplicationSupport

        var errorDescription: String? {
            switch self {
            case .noVideoLoaded: return "当前没有加载动态视频。"
            case .encodeFailed: return "截图编码失败。"
            case .noApplicationSupport: return "无法访问 Application Support 目录。"
            }
        }
    }

    /// Set the same image as the desktop picture on every screen.
    static func setImage(at url: URL) throws {
        for screen in NSScreen.screens {
            try NSWorkspace.shared.setDesktopImageURL(url, for: screen, options: [:])
        }
    }

    /// Grab the current frame from the player's video and write it as a JPEG.
    static func freezeFrame(from player: WallpaperPlayer) throws -> URL {
        guard let item = player.currentItem else {
            throw StaticWallpaperError.noVideoLoaded
        }
        let generator = AVAssetImageGenerator(asset: item.asset)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero

        let time = CMTimeCompare(player.currentTime, .zero) > 0
            ? player.currentTime
            : CMTime(seconds: 1, preferredTimescale: 600)

        let image: CGImage
        do {
            image = try generator.copyCGImage(at: time, actualTime: nil)
        } catch {
            throw StaticWallpaperError.encodeFailed
        }

        let rep = NSBitmapImageRep(cgImage: image)
        guard let data = rep.representation(using: .jpeg, properties: [.compressionFactor: 0.92]) else {
            throw StaticWallpaperError.encodeFailed
        }

        let directory = try applicationSupportDirectory()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        let url = directory.appendingPathComponent("frozen-\(formatter.string(from: Date())).jpg")
        try data.write(to: url, options: .atomic)
        return url
    }

    private static func applicationSupportDirectory() throws -> URL {
        guard let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            throw StaticWallpaperError.noApplicationSupport
        }
        return base.appendingPathComponent("TQwallpaper", isDirectory: true)
    }
}
