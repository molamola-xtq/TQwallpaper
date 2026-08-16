import AppKit

final class StatusMenuController: NSObject, NSMenuDelegate {
    var dynamicEnabledProvider: () -> Bool = { true }
    var wallpaperTitleProvider: () -> String = { "" }
    var freezeEnabledProvider: () -> Bool = { false }
    var powerSaverProvider: () -> Bool = { true }
    var launchAtLoginProvider: () -> Bool = { false }
    var onToggleDynamic: () -> Void = {}
    var onChooseWallpaper: () -> Void = {}
    var onFreeze: () -> Void = {}
    var onTogglePowerSaver: () -> Void = {}
    var onToggleLaunchAtLogin: () -> Void = {}
    var onQuit: () -> Void = {}

    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let menu = NSMenu()

    private let dynamicItem = NSMenuItem(title: "动态壁纸", action: nil, keyEquivalent: "")
    private let chooseItem = NSMenuItem(title: "更换壁纸…", action: nil, keyEquivalent: "")
    private let freezeItem = NSMenuItem(title: "将动态转为静态", action: nil, keyEquivalent: "")
    private let fileItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
    private let powerItem = NSMenuItem(title: "仅接通电源时播放", action: nil, keyEquivalent: "")
    private let launchItem = NSMenuItem(title: "开机启动", action: nil, keyEquivalent: "")
    private let quitItem = NSMenuItem(title: "退出", action: nil, keyEquivalent: "q")

    override init() {
        super.init()
        setupStatusItem()
        setupMenu()
    }

    private func setupStatusItem() {
        statusItem.button?.toolTip = "TQwallpaper 动态壁纸"
        if let icon = NSImage(named: "TQwallpaper-menu.png") {
            icon.size = NSSize(width: 18, height: 18)
            icon.isTemplate = true
            statusItem.button?.image = icon
            statusItem.button?.title = ""
        } else {
            let symbol = NSImage(systemSymbolName: "sparkles", accessibilityDescription: "TQwallpaper")
            symbol?.isTemplate = true
            statusItem.button?.image = symbol
            statusItem.button?.title = "TQ"
        }
        statusItem.menu = menu
    }

    private func setupMenu() {
        menu.delegate = self

        dynamicItem.target = self
        dynamicItem.action = #selector(toggleDynamic)
        menu.addItem(dynamicItem)

        chooseItem.target = self
        chooseItem.action = #selector(chooseWallpaper)
        menu.addItem(chooseItem)

        freezeItem.target = self
        freezeItem.action = #selector(freeze)
        menu.addItem(freezeItem)

        fileItem.isEnabled = false
        menu.addItem(fileItem)

        menu.addItem(.separator())

        powerItem.target = self
        powerItem.action = #selector(togglePowerSaver)
        menu.addItem(powerItem)

        launchItem.target = self
        launchItem.action = #selector(toggleLaunchAtLogin)
        menu.addItem(launchItem)

        menu.addItem(.separator())

        quitItem.target = self
        quitItem.action = #selector(quit)
        menu.addItem(quitItem)
    }

    func menuWillOpen(_ menu: NSMenu) {
        dynamicItem.state = dynamicEnabledProvider() ? .on : .off
        freezeItem.isEnabled = freezeEnabledProvider()
        fileItem.title = wallpaperTitleProvider()
        powerItem.state = powerSaverProvider() ? .on : .off
        launchItem.state = launchAtLoginProvider() ? .on : .off
    }

    @objc private func toggleDynamic() { onToggleDynamic() }
    @objc private func chooseWallpaper() { onChooseWallpaper() }
    @objc private func freeze() { onFreeze() }
    @objc private func togglePowerSaver() { onTogglePowerSaver() }
    @objc private func toggleLaunchAtLogin() { onToggleLaunchAtLogin() }
    @objc private func quit() { onQuit() }
}
