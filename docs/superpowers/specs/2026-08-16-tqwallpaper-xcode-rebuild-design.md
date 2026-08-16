# TQwallpaper Xcode 重建设计

日期：2026-08-16
状态：已确认

## 背景与目标

现有 TQwallpaper（`~/.local/share/jianyuying-wallpaper/`）是一个可用的 macOS 菜单栏动态壁纸原型：Objective-C 单文件、clang 脚本构建、LaunchAgent 自启、内置个人视频素材。目标是把项目重建为一个**可开源、可维护、以后可上架**的 Swift/Xcode 工程。

约束：

- 暂不注册 Apple Developer 账号、不生成证书；本地用 "Sign to Run Locally" 构建运行。
- 视频素材版权采用**用户自带**模式，仓库不含任何视频素材。
- 项目开源在 GitHub，采用 MIT 许可证。
- 新建仓库 `~/Desktop/TQwallpaper`，全新 git 历史；旧目录原样保留作个人存档，不推送。

## 已确认的设计决定

| 决定 | 选择 |
| --- | --- |
| 工程形态 | Xcode 工程（.xcodeproj），Swift |
| 界面框架 | AppKit：NSStatusItem + NSWindow + AVPlayerLayer |
| 仓库位置 | `~/Desktop/TQwallpaper`，全新 git 历史 |
| 许可证 | MIT |
| 开机自启 | SMAppService（macOS 13+） |
| 首启体验 | 欢迎弹窗引导选择视频 + 支持"打开方式 → TQwallpaper" |
| 视频素材 | 用户自带，仓库不含素材 |
| Bundle ID | 占位 `dev.tqwallpaper.TQwallpaper`，注册账号/域名后替换 |
| 最低系统 | macOS 14.0 |
| 架构 | 先 arm64，上架前再加 universal |
| 沙盒/签名 | 暂不启用；后续按分发渠道补充 |
| CI | 暂不做；开源后按需加 GitHub Actions |

## 架构

单一 macOS App target。代码按职责拆分：

- `AppDelegate.swift` — 启动、菜单栏装配、首启欢迎引导、打开文件（Open With）处理。
- `StatusMenuController.swift` — 菜单项、状态勾选与同步。
- `WallpaperPlayer.swift` — 每屏一个桌面层级窗口（`kCGDesktopWindowLevelKey + 1`，无边框、忽略鼠标、全空间）+ AVPlayerLooper 循环。
- `EnergyPolicy.swift` — 纯逻辑状态机：dynamicOn / locked / sleeping / onBattery / lowPower → 是否播放。可单元测试。
- `LaunchAtLogin.swift` — SMAppService.register/unregister 封装，菜单同步状态。
- `VideoPicker.swift` — NSOpenPanel（UTType，mp4/mov/m4v、jpg/png/heic/tiff）。
- `StaticWallpaper.swift` — 设静态壁纸（`NSWorkspace.setDesktopImageURL`，仅用户操作触发）、截帧转静态。
- `TQwallpaperTests/` — EnergyPolicy 状态机单元测试。

## 行为与数据流

- 用户选择视频后路径存入 UserDefaults，启动时自动加载播放；多屏每屏一个窗口。
- 状态机决定 播放 / 暂停 / 隐藏：动态关、锁屏、睡眠、省电（电池或低电量）时暂停并隐藏窗口，释放解码器。
- 静态壁纸与动态转静态只由用户菜单操作触发。
- 菜单：动态壁纸（开关）、更换壁纸（视频/图片）、将动态转为静态、当前壁纸、仅接通电源时播放、开机启动、退出。
- 首启（无已保存视频）弹欢迎提示；`CFBundleDocumentTypes` 注册 mp4/mov/m4v，支持访达右键打开。
- 日志使用 `os.Logger`。

## 错误处理

- 视频缺失/损坏：菜单提示，不崩溃。
- 截帧失败、写盘失败：NSAlert 提示。
- 播放中显示器配置变化：重建窗口。
- 用户取消选择：无副作用。

## 测试与验证

- 单元测试：EnergyPolicy 状态机（省电 + 电池、低电量、锁屏、睡眠组合）。
- 手动验证清单：多屏、锁屏、睡眠、低电量、切视频、设静态、截帧、自启开关、打开方式。

## 仓库形态

- `~/Desktop/TQwallpaper`：TQwallpaper.xcodeproj、源码、TQwallpaperTests、README.md、LICENSE（MIT）、.gitignore、docs。
- README 中英双语（英文为主），说明功能、构建方式、用户自带素材的使用流程。
- .gitignore：DerivedData、.build、本地视频/图片素材、UserDefaults 无关文件。
- 图标复用现有 AppIcon.icns 与 TQwallpaper-menu.png。

## 实施顺序

1. 初始化仓库：.gitignore、LICENSE、README 骨架。
2. 建立 Xcode 工程骨架（Swift/AppKit，min macOS 14）。
3. 移植核心播放与状态逻辑（WallpaperPlayer + EnergyPolicy）。
4. 菜单、选视频、静态壁纸、截帧、SMAppService、打开方式。
5. 单元测试 + 手动验证清单执行。
6. 完善 README、截图说明，推 GitHub（用户操作）。
