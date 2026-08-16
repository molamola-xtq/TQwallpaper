import AppKit
import UniformTypeIdentifiers

enum MediaSelection {
    case video(URL)
    case image(URL)

    static func isVideo(_ url: URL) -> Bool {
        ["mp4", "mov", "m4v"].contains(url.pathExtension.lowercased())
    }
}

enum MediaPicker {
    static func chooseWallpaper(completion: @escaping (MediaSelection?) -> Void) {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = false
        panel.title = "更换壁纸"
        panel.message = "选择视频作为动态壁纸，或选择图片作为静态壁纸"
        panel.allowedContentTypes = [
            .mpeg4Movie,
            .quickTimeMovie,
            UTType(filenameExtension: "m4v") ?? .mpeg4Movie,
            .jpeg,
            .png,
            .heic,
            .tiff,
        ]
        panel.begin { response in
            guard response == .OK, let url = panel.url else {
                completion(nil)
                return
            }
            completion(MediaSelection.isVideo(url) ? .video(url) : .image(url))
        }
    }
}
