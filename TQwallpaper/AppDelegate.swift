import AppKit
import AVFoundation
import IOKit.ps

@main
final class AppDelegate: NSObject, NSApplicationDelegate {
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }

    private enum Keys {
        static let dynamicEnabled = "dynamicEnabled"
        static let videoPath = "videoPath"
        static let staticImagePath = "staticImagePath"
        static let powerSaverOnBattery = "powerSaverOnBattery"
        static let hasShownWelcome = "hasShownWelcome"
    }

    private let player = WallpaperPlayer()
    private var statusMenu: StatusMenuController!
    private let prefs = UserDefaults.standard

    private var dynamicEnabled = true
    private var powerSaverOn = true
    private var locked = false
    private var sleeping = false
    private var onBattery = false
    private var lowPowerMode = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        loadPreferences()
        setupObservers()
        player.rebuildWindows()
        setupStatusMenu()

        if let saved = prefs.string(forKey: Keys.videoPath) {
            player.load(videoPath: saved)
        }
        if prefs.string(forKey: Keys.videoPath) == nil, !prefs.bool(forKey: Keys.hasShownWelcome) {
            prefs.set(true, forKey: Keys.hasShownWelcome)
            presentWelcome()
        }

        refreshPowerState()
        applyState()

        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.refreshPowerState()
        }
    }

    // MARK: - Observers

    private func setupObservers() {
        let ws = NSWorkspace.shared.notificationCenter
        ws.addObserver(self, selector: #selector(systemWillSleep), name: NSWorkspace.willSleepNotification, object: nil)
        ws.addObserver(self, selector: #selector(systemDidWake), name: NSWorkspace.didWakeNotification, object: nil)
        ws.addObserver(self, selector: #selector(screensChanged), name: NSApplication.didChangeScreenParametersNotification, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(screensChanged), name: NSApplication.didChangeScreenParametersNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(powerStateChanged), name: Notification.Name("NSProcessInfoPowerStateDidChangeNotification"), object: nil)

        let dnc = DistributedNotificationCenter.default()
        dnc.addObserver(self, selector: #selector(screenDidLock), name: NSNotification.Name("com.apple.screenIsLocked"), object: nil)
        dnc.addObserver(self, selector: #selector(screenDidUnlock), name: NSNotification.Name("com.apple.screenIsUnlocked"), object: nil)
    }

    @objc private func systemWillSleep(_ note: Notification) {
        sleeping = true
        applyState()
    }

    @objc private func systemDidWake(_ note: Notification) {
        sleeping = false
        refreshPowerState()
        applyState()
    }

    @objc private func screenDidLock(_ note: Notification) {
        locked = true
        applyState()
    }

    @objc private func screenDidUnlock(_ note: Notification) {
        locked = false
        applyState()
    }

    @objc private func screensChanged(_ note: Notification) {
        player.rebuildWindows()
        if let saved = prefs.string(forKey: Keys.videoPath) {
            player.load(videoPath: saved)
        }
        applyState()
    }

    @objc private func powerStateChanged(_ note: Notification) {
        refreshPowerState()
        applyState()
    }

    // MARK: - State

    private func shouldPlay() -> Bool {
        var policy = EnergyPolicy()
        policy.dynamicEnabled = dynamicEnabled
        policy.powerSaverOn = powerSaverOn
        policy.locked = locked
        policy.sleeping = sleeping
        policy.onBattery = onBattery
        policy.lowPowerMode = lowPowerMode
        return policy.shouldPlay
    }

    private func applyState() {
        player.apply(shouldPlay: shouldPlay())
    }

    private func refreshPowerState() {
        let battery = isOnBattery()
        if battery != onBattery {
            onBattery = battery
            tqLogger.info("power source changed: \(battery ? "battery" : "AC")")
            applyState()
        }
        let lowPower = ProcessInfo.processInfo.isLowPowerModeEnabled
        if lowPower != lowPowerMode {
            lowPowerMode = lowPower
            tqLogger.info("low power mode: \(lowPower)")
            applyState()
        }
    }

    private func isOnBattery() -> Bool {
        guard let blob = IOPSCopyPowerSourcesInfo()?.takeRetainedValue() else { return false }
        guard let list = IOPSCopyPowerSourcesList(blob)?.takeRetainedValue() else { return false }
        let count = CFArrayGetCount(list)
        guard count > 0 else { return false }

        var foundBattery = false
        for index in 0..<count {
            let source = unsafeBitCast(CFArrayGetValueAtIndex(list, index), to: CFTypeRef.self)
            guard let rawDescription = IOPSGetPowerSourceDescription(blob, source) else { continue }
            let description = rawDescription.takeUnretainedValue() as NSDictionary
            guard let state = description[kIOPSPowerSourceStateKey] as? String else { continue }
            if state == kIOPSACPowerValue as String { return false }
            if state == kIOPSBatteryPowerValue as String { foundBattery = true }
        }
        return foundBattery
    }

    // MARK: - Preferences

    private func loadPreferences() {
        dynamicEnabled = prefs.object(forKey: Keys.dynamicEnabled) as? Bool ?? true
        powerSaverOn = prefs.object(forKey: Keys.powerSaverOnBattery) as? Bool ?? true
    }

    // MARK: - Status menu

    private func setupStatusMenu() {
        statusMenu = StatusMenuController()
        statusMenu.dynamicEnabledProvider = { [weak self] in self?.dynamicEnabled ?? true }
        statusMenu.wallpaperTitleProvider = { [weak self] in self?.currentWallpaperTitle() ?? "" }
        statusMenu.freezeEnabledProvider = { [weak self] in self?.player.isLoaded ?? false }
        statusMenu.powerSaverProvider = { [weak self] in self?.powerSaverOn ?? true }
        statusMenu.launchAtLoginProvider = { LaunchAtLogin.isEnabled }
        statusMenu.onToggleDynamic = { [weak self] in self?.toggleDynamic() }
        statusMenu.onChooseWallpaper = { [weak self] in self?.chooseWallpaper() }
        statusMenu.onFreeze = { [weak self] in self?.freezeToStatic() }
        statusMenu.onTogglePowerSaver = { [weak self] in self?.togglePowerSaver() }
        statusMenu.onToggleLaunchAtLogin = { [weak self] in self?.toggleLaunchAtLogin() }
        statusMenu.onQuit = { [weak self] in self?.quit() }
    }

    private func currentWallpaperTitle() -> String {
        if dynamicEnabled, let path = player.videoPath {
            return "当前壁纸：动态 \(URL(fileURLWithPath: path).lastPathComponent)"
        }
        if let path = prefs.string(forKey: Keys.staticImagePath) {
            return "当前壁纸：静态 \(URL(fileURLWithPath: path).lastPathComponent)"
        }
        return "当前壁纸：未设置"
    }

    // MARK: - Actions

    private func toggleDynamic() {
        dynamicEnabled.toggle()
        prefs.set(dynamicEnabled, forKey: Keys.dynamicEnabled)
        applyState()
    }

    private func togglePowerSaver() {
        powerSaverOn.toggle()
        prefs.set(powerSaverOn, forKey: Keys.powerSaverOnBattery)
        applyState()
    }

    private func chooseWallpaper() {
        MediaPicker.chooseWallpaper { [weak self] selection in
            guard let self, let selection else { return }
            switch selection {
            case .video(let url):
                self.setVideoWallpaper(url)
            case .image(let url):
                self.setStaticWallpaper(url)
            }
        }
    }

    private func setVideoWallpaper(_ url: URL) {
        guard player.load(videoPath: url.path) else {
            presentAlert(title: "无法播放", message: "找不到视频文件：\n\(url.path)")
            return
        }
        prefs.set(url.path, forKey: Keys.videoPath)
        dynamicEnabled = true
        prefs.set(true, forKey: Keys.dynamicEnabled)
        applyState()
    }

    private func setStaticWallpaper(_ url: URL) {
        do {
            try StaticWallpaper.setImage(at: url)
            prefs.set(url.path, forKey: Keys.staticImagePath)
            dynamicEnabled = false
            prefs.set(false, forKey: Keys.dynamicEnabled)
            applyState()
        } catch {
            presentAlert(title: "设置失败", message: error.localizedDescription)
        }
    }

    private func freezeToStatic() {
        do {
            let url = try StaticWallpaper.freezeFrame(from: player)
            try StaticWallpaper.setImage(at: url)
            prefs.set(url.path, forKey: Keys.staticImagePath)
            dynamicEnabled = false
            prefs.set(false, forKey: Keys.dynamicEnabled)
            applyState()
            presentAlert(title: "已转为静态壁纸", message: url.path)
        } catch {
            presentAlert(title: "无法转换", message: error.localizedDescription)
        }
    }

    private func toggleLaunchAtLogin() {
        do {
            try LaunchAtLogin.setEnabled(!LaunchAtLogin.isEnabled)
        } catch {
            presentAlert(title: "开机启动设置失败", message: error.localizedDescription)
        }
    }

    private func quit() {
        player.teardownPlayer()
        NSApp.terminate(nil)
    }

    // MARK: - First run

    private func presentWelcome() {
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = "欢迎使用 TQwallpaper"
        alert.informativeText = "选择你的视频作为动态壁纸，或选择图片作为静态壁纸。你随时可以在菜单栏图标中更换。"
        alert.addButton(withTitle: "选择壁纸…")
        alert.addButton(withTitle: "稍后")
        if alert.runModal() == .alertFirstButtonReturn {
            chooseWallpaper()
        }
    }

    private func presentAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = title
        alert.informativeText = message
        alert.addButton(withTitle: "好")
        alert.runModal()
    }

    // MARK: - Open With

    func application(_ sender: NSApplication, openFiles filenames: [String]) {
        guard let first = filenames.first else { return }
        let url = URL(fileURLWithPath: first)
        if MediaSelection.isVideo(url) {
            setVideoWallpaper(url)
        } else {
            setStaticWallpaper(url)
        }
    }
}
