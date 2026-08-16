# TQwallpaper Xcode Rebuild Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把 TQwallpaper 从单文件 Objective-C + clang 脚本，重建为可开源、可维护的 Swift + Xcode 工程，并保留全部现有功能。

**Architecture:** AppKit 菜单栏 App（LSUIElement）：`NSStatusItem` 菜单 + 每屏一个桌面层级 `NSWindow`（`CGWindowLevelForKey(.desktopWindow) + 1`）+ 单个 `AVQueuePlayer`/`AVPlayerLooper` 循环播放。纯逻辑（播放/暂停状态机）抽到 `EnergyPolicy`，可单元测试。开机自启用 `SMAppService`。视频素材完全用户自带，仓库不含任何素材。

**Tech Stack:** Swift 5、AppKit、AVFoundation、ServiceManagement、XCTest、Xcode 16+（含 Command Line Tools 可先行，最终以 Xcode 构建验证）。

---

## 前置条件

- Xcode 已安装到 `/Applications/Xcode.app`（用户正在下载）。构建命令统一加 `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer` 前缀，避免与当前 Command Line Tools 冲突，也不需要 sudo。
- 本仓库 `~/Desktop/TQwallpaper` 已存在且已 `git init -b main`（已完成）。
- 参考存档（勿改）：`~/.local/share/jianyuying-wallpaper/`，其中 `src/AppIcon.icns`、`src/TQwallpaper-menu.png` 将被复制进新仓库。

## 文件结构

```
TQwallpaper.xcodeproj/
  project.pbxproj
  xcshareddata/xcschemes/TQwallpaper.xcscheme
TQwallpaper/
  AppDelegate.swift        — 启动、观察者、首启引导、菜单回调、Open With
  StatusMenuController.swift — NSStatusItem + 菜单与状态同步
  WallpaperPlayer.swift    — 多屏桌面窗口 + AVPlayer 循环播放
  EnergyPolicy.swift       — 纯逻辑状态机（可单测）
  LaunchAtLogin.swift      — SMAppService 封装
  VideoPicker.swift        — NSOpenPanel 选择视频/图片
  StaticWallpaper.swift    — 设静态壁纸、截帧转静态
  Logging.swift            — os.Logger 单例
  Info.plist               — LSUIElement + CFBundleDocumentTypes
  Resources/
    AppIcon.icns
    TQwallpaper-menu.png
TQwallpaperTests/
  EnergyPolicyTests.swift
.gitignore
LICENSE
README.md
docs/superpowers/specs/2026-08-16-tqwallpaper-xcode-rebuild-design.md
```

## 约定

- 所有 `xcodebuild` 命令在仓库根目录执行，统一前缀：
  `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild ...`
- Debug 构建产物在 `DerivedData/Build/Products/Debug/TQwallpaper.app`。
- Bundle ID：`dev.tqwallpaper.TQwallpaper`（占位，注册账号/域名后替换）。
- 每个任务结束都提交一次 git。

---

### Task 1: 仓库基础文件

**Files:**
- Create: `.gitignore`
- Create: `LICENSE`
- Create: `README.md`

- [ ] **Step 1: 创建 .gitignore**

```gitignore
.DS_Store
DerivedData/
.build/
*.mp4
*.mov
*.m4v
*.heic
```

- [ ] **Step 2: 创建 LICENSE（MIT）**

```text
MIT License

Copyright (c) 2026 TQwallpaper Contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

- [ ] **Step 3: 创建 README.md（骨架，Task 10 再润色）**

```markdown
# TQwallpaper

macOS menu-bar video wallpaper app. Play any local video as a looping desktop
wallpaper, or freeze the current frame to a static picture.

> Bring your own content. This repository contains **no video or image
> assets** — you choose your own wallpaper videos and pictures.

## Features

- Video wallpaper on every display (desktop window level, mouse transparent)
- Seamless looping (AVPlayerLooper), muted
- Energy-aware: pause on battery / Low Power Mode (optional), on lock and sleep
- Switch to a static picture, or freeze the current frame to JPEG
- Launch at login (SMAppService)
- Open a video in Finder with "Open With → TQwallpaper"

## Requirements

- macOS 14+
- Apple Silicon (arm64)
- Xcode 16+ to build

## Build

```bash
git clone <your-repo-url> TQwallpaper
cd TQwallpaper
xcodebuild -project TQwallpaper.xcodeproj -scheme TQwallpaper -configuration Debug -derivedDataPath DerivedData build
open DerivedData/Build/Products/Debug/TQwallpaper.app
```

## Usage

On first launch, TQwallpaper asks you to pick a video. You can also:

- Right-click a video file in Finder → Open With → TQwallpaper
- Use the menu-bar icon: switch video/static wallpaper, freeze frame,
  battery power-saver, launch at login, quit

## License

MIT

---

## 中文简介

TQwallpaper 是一个 macOS 菜单栏动态壁纸应用：把任意本地视频设为桌面循环播放的
动态壁纸，也可以把当前画面截帧转成静态壁纸。本项目**不包含任何视频/图片素材**，
内容由你自己提供。

功能：多屏视频壁纸、静音无缝循环、电池/低电量/锁屏/睡眠自动暂停、
静态壁纸切换与截帧、开机自启（SMAppService）、访达"打开方式"直接设置。

构建：

```bash
xcodebuild -project TQwallpaper.xcodeproj -scheme TQwallpaper -configuration Debug -derivedDataPath DerivedData build
open DerivedData/Build/Products/Debug/TQwallpaper.app
```

许可证：MIT
```

- [ ] **Step 4: 提交**

```bash
git add .gitignore LICENSE README.md
git commit -m "chore: repo bootstrap (gitignore, LICENSE, README)"
```

Expected: `1 file changed` 之外的 3 个新文件全部提交成功。

---

### Task 2: Xcode 工程骨架

**Files:**
- Create: `TQwallpaper.xcodeproj/project.pbxproj`
- Create: `TQwallpaper.xcodeproj/xcshareddata/xcschemes/TQwallpaper.xcscheme`
- Create: `TQwallpaper/Info.plist`
- Create: `TQwallpaper/Logging.swift`
- Create: `TQwallpaper/EnergyPolicy.swift`（stub：先让测试可编译但失败）
- Create: `TQwallpaper/LaunchAtLogin.swift`（stub）
- Create: `TQwallpaper/WallpaperPlayer.swift`（stub）
- Create: `TQwallpaper/VideoPicker.swift`（stub）
- Create: `TQwallpaper/StaticWallpaper.swift`（stub）
- Create: `TQwallpaper/StatusMenuController.swift`（stub）
- Create: `TQwallpaper/AppDelegate.swift`（stub）
- Create: `TQwallpaperTests/EnergyPolicyTests.swift`（stub：一个空测试类）
- Create: `TQwallpaper/Resources/AppIcon.icns`（复制）
- Create: `TQwallpaper/Resources/TQwallpaper-menu.png`（复制）

- [ ] **Step 1: 创建目录并复制图标**

```bash
mkdir -p TQwallpaper/Resources TQwallpaperTests TQwallpaper.xcodeproj/xcshareddata/xcschemes
cp ~/.local/share/jianyuying-wallpaper/src/AppIcon.icns TQwallpaper/Resources/
cp ~/.local/share/jianyuying-wallpaper/src/TQwallpaper-menu.png TQwallpaper/Resources/
ls -l TQwallpaper/Resources/
```

Expected: `AppIcon.icns` 和 `TQwallpaper-menu.png` 都在。

- [ ] **Step 2: 创建 project.pbxproj**

```text
// !$*UTF8*$!
{
	archiveVersion = 1;
	classes = {
	};
	objectVersion = 56;
	objects = {

/* Begin PBXBuildFile section */
		AA0000000000000000000201 /* AppDelegate.swift in Sources */ = {isa = PBXBuildFile; fileRef = AA0000000000000000000101 /* AppDelegate.swift */; };
		AA0000000000000000000202 /* StatusMenuController.swift in Sources */ = {isa = PBXBuildFile; fileRef = AA0000000000000000000102 /* StatusMenuController.swift */; };
		AA0000000000000000000203 /* WallpaperPlayer.swift in Sources */ = {isa = PBXBuildFile; fileRef = AA0000000000000000000103 /* WallpaperPlayer.swift */; };
		AA0000000000000000000204 /* EnergyPolicy.swift in Sources */ = {isa = PBXBuildFile; fileRef = AA0000000000000000000104 /* EnergyPolicy.swift */; };
		AA0000000000000000000205 /* LaunchAtLogin.swift in Sources */ = {isa = PBXBuildFile; fileRef = AA0000000000000000000105 /* LaunchAtLogin.swift */; };
		AA0000000000000000000206 /* VideoPicker.swift in Sources */ = {isa = PBXBuildFile; fileRef = AA0000000000000000000106 /* VideoPicker.swift */; };
		AA0000000000000000000207 /* StaticWallpaper.swift in Sources */ = {isa = PBXBuildFile; fileRef = AA0000000000000000000107 /* StaticWallpaper.swift */; };
		AA0000000000000000000208 /* Logging.swift in Sources */ = {isa = PBXBuildFile; fileRef = AA0000000000000000000108 /* Logging.swift */; };
		AA0000000000000000000209 /* AppIcon.icns in Resources */ = {isa = PBXBuildFile; fileRef = AA0000000000000000000109 /* AppIcon.icns */; };
		AA0000000000000000000210 /* TQwallpaper-menu.png in Resources */ = {isa = PBXBuildFile; fileRef = AA0000000000000000000110 /* TQwallpaper-menu.png */; };
		AA0000000000000000000211 /* EnergyPolicyTests.swift in Sources */ = {isa = PBXBuildFile; fileRef = AA0000000000000000000111 /* EnergyPolicyTests.swift */; };
/* End PBXBuildFile section */

/* Begin PBXContainerItemProxy section */
		AA0000000000000000000702 /* PBXContainerItemProxy */ = {
			isa = PBXContainerItemProxy;
			containerPortal = AA0000000000000000000001 /* Project object */;
			proxyType = 1;
			remoteGlobalIDString = AA0000000000000000000401;
			remoteInfo = TQwallpaper;
		};
/* End PBXContainerItemProxy section */

/* Begin PBXFileReference section */
		AA0000000000000000000101 /* AppDelegate.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = AppDelegate.swift; sourceTree = "<group>"; };
		AA0000000000000000000102 /* StatusMenuController.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = StatusMenuController.swift; sourceTree = "<group>"; };
		AA0000000000000000000103 /* WallpaperPlayer.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = WallpaperPlayer.swift; sourceTree = "<group>"; };
		AA0000000000000000000104 /* EnergyPolicy.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = EnergyPolicy.swift; sourceTree = "<group>"; };
		AA0000000000000000000105 /* LaunchAtLogin.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = LaunchAtLogin.swift; sourceTree = "<group>"; };
		AA0000000000000000000106 /* VideoPicker.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = VideoPicker.swift; sourceTree = "<group>"; };
		AA0000000000000000000107 /* StaticWallpaper.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = StaticWallpaper.swift; sourceTree = "<group>"; };
		AA0000000000000000000108 /* Logging.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = Logging.swift; sourceTree = "<group>"; };
		AA0000000000000000000109 /* AppIcon.icns */ = {isa = PBXFileReference; lastKnownFileType = image.icns; path = AppIcon.icns; sourceTree = "<group>"; };
		AA0000000000000000000110 /* TQwallpaper-menu.png */ = {isa = PBXFileReference; lastKnownFileType = image.png; path = "TQwallpaper-menu.png"; sourceTree = "<group>"; };
		AA0000000000000000000111 /* EnergyPolicyTests.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = EnergyPolicyTests.swift; sourceTree = "<group>"; };
		AA0000000000000000000112 /* TQwallpaper.app */ = {isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = TQwallpaper.app; sourceTree = BUILT_PRODUCTS_DIR; };
		AA0000000000000000000113 /* TQwallpaperTests.xctest */ = {isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = TQwallpaperTests.xctest; sourceTree = BUILT_PRODUCTS_DIR; };
/* End PBXFileReference section */

/* Begin PBXFrameworksBuildPhase section */
		AA0000000000000000000303 /* Frameworks */ = {
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
		AA0000000000000000000305 /* Frameworks */ = {
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
/* End PBXFrameworksBuildPhase section */

/* Begin PBXGroup section */
		AA0000000000000000000002 = {
			isa = PBXGroup;
			children = (
				AA0000000000000000000003 /* TQwallpaper */,
				AA0000000000000000000004 /* TQwallpaperTests */,
				AA0000000000000000000005 /* Products */,
			);
			sourceTree = "<group>";
		};
		AA0000000000000000000003 /* TQwallpaper */ = {
			isa = PBXGroup;
			children = (
				AA0000000000000000000101 /* AppDelegate.swift */,
				AA0000000000000000000102 /* StatusMenuController.swift */,
				AA0000000000000000000103 /* WallpaperPlayer.swift */,
				AA0000000000000000000104 /* EnergyPolicy.swift */,
				AA0000000000000000000105 /* LaunchAtLogin.swift */,
				AA0000000000000000000106 /* VideoPicker.swift */,
				AA0000000000000000000107 /* StaticWallpaper.swift */,
				AA0000000000000000000108 /* Logging.swift */,
				AA0000000000000000000006 /* Resources */,
			);
			path = TQwallpaper;
			sourceTree = "<group>";
		};
		AA0000000000000000000006 /* Resources */ = {
			isa = PBXGroup;
			children = (
				AA0000000000000000000109 /* AppIcon.icns */,
				AA0000000000000000000110 /* TQwallpaper-menu.png */,
			);
			name = Resources;
			path = Resources;
			sourceTree = "<group>";
		};
		AA0000000000000000000004 /* TQwallpaperTests */ = {
			isa = PBXGroup;
			children = (
				AA0000000000000000000111 /* EnergyPolicyTests.swift */,
			);
			path = TQwallpaperTests;
			sourceTree = "<group>";
		};
		AA0000000000000000000005 /* Products */ = {
			isa = PBXGroup;
			children = (
				AA0000000000000000000112 /* TQwallpaper.app */,
				AA0000000000000000000113 /* TQwallpaperTests.xctest */,
			);
			name = Products;
			sourceTree = "<group>";
		};
/* End PBXGroup section */

/* Begin PBXNativeTarget section */
		AA0000000000000000000401 /* TQwallpaper */ = {
			isa = PBXNativeTarget;
			buildConfigurationList = AA0000000000000000000502 /* Build configuration list for PBXNativeTarget "TQwallpaper" */;
			buildPhases = (
				AA0000000000000000000301 /* Sources */,
				AA0000000000000000000302 /* Resources */,
				AA0000000000000000000303 /* Frameworks */,
			);
			buildRules = (
			);
			dependencies = (
			);
			name = TQwallpaper;
			productName = TQwallpaper;
			productReference = AA0000000000000000000112 /* TQwallpaper.app */;
			productType = "com.apple.product-type.application";
		};
		AA0000000000000000000402 /* TQwallpaperTests */ = {
			isa = PBXNativeTarget;
			buildConfigurationList = AA0000000000000000000503 /* Build configuration list for PBXNativeTarget "TQwallpaperTests" */;
			buildPhases = (
				AA0000000000000000000304 /* Sources */,
				AA0000000000000000000306 /* Resources */,
				AA0000000000000000000305 /* Frameworks */,
			);
			buildRules = (
			);
			dependencies = (
				AA0000000000000000000701 /* PBXTargetDependency */,
			);
			name = TQwallpaperTests;
			productName = TQwallpaperTests;
			productReference = AA0000000000000000000113 /* TQwallpaperTests.xctest */;
			productType = "com.apple.product-type.bundle.unit-test";
		};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
		AA0000000000000000000001 /* Project object */ = {
			isa = PBXProject;
			attributes = {
				BuildIndependentTargetsInParallel = 1;
				LastSwiftUpdateCheck = 1500;
				LastUpgradeCheck = 1500;
				TargetAttributes = {
					AA0000000000000000000401 = {
						CreatedOnToolsVersion = 15.0;
					};
					AA0000000000000000000402 = {
						CreatedOnToolsVersion = 15.0;
						TestTargetID = AA0000000000000000000401;
					};
				};
			};
			buildConfigurationList = AA0000000000000000000501 /* Build configuration list for PBXProject "TQwallpaper" */;
			compatibilityVersion = "Xcode 14.0";
			developmentRegion = en;
			hasScannedForEncodings = 0;
			knownRegions = (
				en,
				Base,
			);
			mainGroup = AA0000000000000000000002;
			productRefGroup = AA0000000000000000000005 /* Products */;
			projectDirPath = "";
			projectRoot = "";
			targets = (
				AA0000000000000000000401 /* TQwallpaper */,
				AA0000000000000000000402 /* TQwallpaperTests */,
			);
		};
/* End PBXProject section */

/* Begin PBXResourcesBuildPhase section */
		AA0000000000000000000302 /* Resources */ = {
			isa = PBXResourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
				AA0000000000000000000209 /* AppIcon.icns in Resources */,
				AA0000000000000000000210 /* TQwallpaper-menu.png in Resources */,
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
		AA0000000000000000000306 /* Resources */ = {
			isa = PBXResourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
/* End PBXResourcesBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
		AA0000000000000000000301 /* Sources */ = {
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
				AA0000000000000000000201 /* AppDelegate.swift in Sources */,
				AA0000000000000000000202 /* StatusMenuController.swift in Sources */,
				AA0000000000000000000203 /* WallpaperPlayer.swift in Sources */,
				AA0000000000000000000204 /* EnergyPolicy.swift in Sources */,
				AA0000000000000000000205 /* LaunchAtLogin.swift in Sources */,
				AA0000000000000000000206 /* VideoPicker.swift in Sources */,
				AA0000000000000000000207 /* StaticWallpaper.swift in Sources */,
				AA0000000000000000000208 /* Logging.swift in Sources */,
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
		AA0000000000000000000304 /* Sources */ = {
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
				AA0000000000000000000211 /* EnergyPolicyTests.swift in Sources */,
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
/* End PBXSourcesBuildPhase section */

/* Begin PBXTargetDependency section */
		AA0000000000000000000701 /* PBXTargetDependency */ = {
			isa = PBXTargetDependency;
			target = AA0000000000000000000401 /* TQwallpaper */;
			targetProxy = AA0000000000000000000702 /* PBXContainerItemProxy */;
		};
/* End PBXTargetDependency section */

/* Begin XCBuildConfiguration section */
		AA0000000000000000000601 /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ALWAYS_SEARCH_USER_PATHS = NO;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				CLANG_WARN_BOOL_CONVERSION = YES;
				CLANG_WARN_CONSTANT_CONVERSION = YES;
				CLANG_WARN_DOCUMENTATION_COMMENTS = YES;
				CLANG_WARN_EMPTY_BODY = YES;
				CLANG_WARN_ENUM_CONVERSION = YES;
				CLANG_WARN_INFINITE_RECURSION = YES;
				CLANG_WARN_INT_CONVERSION = YES;
				CLANG_WARN_UNREACHABLE_CODE = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = dwarf;
				ENABLE_TESTABILITY = YES;
				GCC_C_LANGUAGE_STANDARD = gnu17;
				GCC_DYNAMIC_NO_PIC = NO;
				GCC_NO_COMMON_BLOCKS = YES;
				GCC_OPTIMIZATION_LEVEL = 0;
				GCC_PREPROCESSOR_DEFINITIONS = (
					"DEBUG=1",
					"$(inherited)",
				);
				MACOSX_DEPLOYMENT_TARGET = 14.0;
				MTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;
				MTL_FAST_MATH = YES;
				ONLY_ACTIVE_ARCH = YES;
				SDKROOT = macosx;
				SWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;
				SWIFT_OPTIMIZATION_LEVEL = "-Onone";
			};
			name = Debug;
		};
		AA0000000000000000000602 /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ALWAYS_SEARCH_USER_PATHS = NO;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				CLANG_WARN_BOOL_CONVERSION = YES;
				CLANG_WARN_CONSTANT_CONVERSION = YES;
				CLANG_WARN_DOCUMENTATION_COMMENTS = YES;
				CLANG_WARN_EMPTY_BODY = YES;
				CLANG_WARN_ENUM_CONVERSION = YES;
				CLANG_WARN_INFINITE_RECURSION = YES;
				CLANG_WARN_INT_CONVERSION = YES;
				CLANG_WARN_UNREACHABLE_CODE = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
				ENABLE_NS_ASSERTIONS = NO;
				GCC_C_LANGUAGE_STANDARD = gnu17;
				GCC_NO_COMMON_BLOCKS = YES;
				MACOSX_DEPLOYMENT_TARGET = 14.0;
				MTL_ENABLE_DEBUG_INFO = NO;
				MTL_FAST_MATH = YES;
				SDKROOT = macosx;
				SWIFT_COMPILATION_MODE = wholemodule;
				SWIFT_OPTIMIZATION_LEVEL = "-O";
			};
			name = Release;
		};
		AA0000000000000000000603 /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ARCHS = arm64;
				CODE_SIGN_IDENTITY = "-";
				CODE_SIGN_STYLE = Automatic;
				COMBINE_HIDPI_IMAGES = YES;
				CURRENT_PROJECT_VERSION = 1;
				ENABLE_TESTABILITY = YES;
				INFOPLIST_FILE = TQwallpaper/Info.plist;
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/../Frameworks",
				);
				MACOSX_DEPLOYMENT_TARGET = 14.0;
				MARKETING_VERSION = 1.0.0;
				PRODUCT_BUNDLE_IDENTIFIER = dev.tqwallpaper.TQwallpaper;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SWIFT_VERSION = 5.0;
			};
			name = Debug;
		};
		AA0000000000000000000604 /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ARCHS = arm64;
				CODE_SIGN_IDENTITY = "-";
				CODE_SIGN_STYLE = Automatic;
				COMBINE_HIDPI_IMAGES = YES;
				CURRENT_PROJECT_VERSION = 1;
				INFOPLIST_FILE = TQwallpaper/Info.plist;
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/../Frameworks",
				);
				MACOSX_DEPLOYMENT_TARGET = 14.0;
				MARKETING_VERSION = 1.0.0;
				PRODUCT_BUNDLE_IDENTIFIER = dev.tqwallpaper.TQwallpaper;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SWIFT_VERSION = 5.0;
			};
			name = Release;
		};
		AA0000000000000000000605 /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ARCHS = arm64;
				BUNDLE_LOADER = "$(TEST_HOST)";
				CODE_SIGN_IDENTITY = "-";
				CODE_SIGN_STYLE = Automatic;
				GENERATE_INFOPLIST_FILE = YES;
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/../Frameworks",
					"@loader_path/../Frameworks",
				);
				MACOSX_DEPLOYMENT_TARGET = 14.0;
				PRODUCT_BUNDLE_IDENTIFIER = dev.tqwallpaper.TQwallpaperTests;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SWIFT_VERSION = 5.0;
				TEST_HOST = "$(BUILT_PRODUCTS_DIR)/TQwallpaper.app/Contents/MacOS/TQwallpaper";
			};
			name = Debug;
		};
		AA0000000000000000000606 /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ARCHS = arm64;
				BUNDLE_LOADER = "$(TEST_HOST)";
				CODE_SIGN_IDENTITY = "-";
				CODE_SIGN_STYLE = Automatic;
				GENERATE_INFOPLIST_FILE = YES;
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/../Frameworks",
					"@loader_path/../Frameworks",
				);
				MACOSX_DEPLOYMENT_TARGET = 14.0;
				PRODUCT_BUNDLE_IDENTIFIER = dev.tqwallpaper.TQwallpaperTests;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SWIFT_VERSION = 5.0;
				TEST_HOST = "$(BUILT_PRODUCTS_DIR)/TQwallpaper.app/Contents/MacOS/TQwallpaper";
			};
			name = Release;
		};
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
		AA0000000000000000000501 /* Build configuration list for PBXProject "TQwallpaper" */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				AA0000000000000000000601 /* Debug */,
				AA0000000000000000000602 /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		};
		AA0000000000000000000502 /* Build configuration list for PBXNativeTarget "TQwallpaper" */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				AA0000000000000000000603 /* Debug */,
				AA0000000000000000000604 /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		};
		AA0000000000000000000503 /* Build configuration list for PBXNativeTarget "TQwallpaperTests" */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				AA0000000000000000000605 /* Debug */,
				AA0000000000000000000606 /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		};
/* End XCConfigurationList section */
	};
	rootObject = AA0000000000000000000001 /* Project object */;
}
```

- [ ] **Step 3: 创建共享 Scheme**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion = "1500"
   version = "1.7">
   <BuildAction
      parallelizeBuildables = "YES"
      buildImplicitDependencies = "YES">
      <BuildActionEntries>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "YES"
            buildForProfiling = "YES"
            buildForArchiving = "YES"
            buildForAnalyzing = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "AA0000000000000000000401"
               BuildableName = "TQwallpaper.app"
               BlueprintName = "TQwallpaper"
               ReferencedContainer = "container:TQwallpaper.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "NO"
            buildForProfiling = "NO"
            buildForArchiving = "NO"
            buildForAnalyzing = "NO">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "AA0000000000000000000402"
               BuildableName = "TQwallpaperTests.xctest"
               BlueprintName = "TQwallpaperTests"
               ReferencedContainer = "container:TQwallpaper.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      shouldUseLaunchSchemeArgsEnv = "YES">
      <Testables>
         <TestableReference
            skipped = "NO">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "AA0000000000000000000402"
               BuildableName = "TQwallpaperTests.xctest"
               BlueprintName = "TQwallpaperTests"
               ReferencedContainer = "container:TQwallpaper.xcodeproj">
            </BuildableReference>
         </TestableReference>
      </Testables>
   </TestAction>
   <LaunchAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      launchStyle = "0"
      useCustomWorkingDirectory = "NO"
      ignoresPersistentStateOnLaunch = "NO"
      debugDocumentVersioning = "YES"
      debugServiceExtension = "internal"
      allowLocationSimulation = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "AA0000000000000000000401"
            BuildableName = "TQwallpaper.app"
            BlueprintName = "TQwallpaper"
            ReferencedContainer = "container:TQwallpaper.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </LaunchAction>
   <ProfileAction
      buildConfiguration = "Release"
      shouldUseLaunchSchemeArgsEnv = "YES"
      savedToolIdentifier = ""
      useCustomWorkingDirectory = "NO"
      debugDocumentVersioning = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "AA0000000000000000000401"
            BuildableName = "TQwallpaper.app"
            BlueprintName = "TQwallpaper"
            ReferencedContainer = "container:TQwallpaper.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </ProfileAction>
   <AnalyzeAction
      buildConfiguration = "Debug">
   </AnalyzeAction>
   <ArchiveAction
      buildConfiguration = "Release"
      revealArchiveInOrganizer = "YES">
   </ArchiveAction>
</Scheme>
```

- [ ] **Step 4: 创建 Info.plist**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key>
	<string>$(DEVELOPMENT_LANGUAGE)</string>
	<key>CFBundleDocumentTypes</key>
	<array>
		<dict>
			<key>CFBundleTypeName</key>
			<string>Video Wallpaper</string>
			<key>CFBundleTypeRole</key>
			<string>Viewer</string>
			<key>LSHandlerRank</key>
			<string>Alternate</string>
			<key>LSItemContentTypes</key>
			<array>
				<string>public.mpeg-4</string>
				<string>com.apple.quicktime-movie</string>
				<string>com.apple.m4v-video</string>
			</array>
		</dict>
	</array>
	<key>CFBundleExecutable</key>
	<string>$(EXECUTABLE_NAME)</string>
	<key>CFBundleIconFile</key>
	<string>AppIcon</string>
	<key>CFBundleIdentifier</key>
	<string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleName</key>
	<string>$(PRODUCT_NAME)</string>
	<key>CFBundlePackageType</key>
	<string>$(PRODUCT_BUNDLE_PACKAGE_TYPE)</string>
	<key>CFBundleShortVersionString</key>
	<string>$(MARKETING_VERSION)</string>
	<key>CFBundleVersion</key>
	<string>$(CURRENT_PROJECT_VERSION)</string>
	<key>LSMinimumSystemVersion</key>
	<string>$(MACOSX_DEPLOYMENT_TARGET)</string>
	<key>LSUIElement</key>
	<true/>
	<key>NSHighResolutionCapable</key>
	<true/>
</dict>
</plist>
```

- [ ] **Step 5: 创建 Logging.swift（最终版）**

```swift
import os

let tqLogger = Logger(subsystem: "dev.tqwallpaper.TQwallpaper", category: "app")
```

- [ ] **Step 6: 创建 EnergyPolicy.swift（stub：shouldPlay 恒为 true，供 Task 3 先失败）**

```swift
import Foundation

/// Pure state machine deciding whether the wallpaper video should play.
struct EnergyPolicy {
    var dynamicEnabled = true
    var locked = false
    var sleeping = false
    var onBattery = false
    var lowPowerMode = false
    var powerSaverOn = true

    var shouldPlay: Bool {
        true
    }
}
```

- [ ] **Step 7: 创建其余 stub 文件**

```swift
// TQwallpaper/LaunchAtLogin.swift
import ServiceManagement

enum LaunchAtLogin {
}
```

```swift
// TQwallpaper/WallpaperPlayer.swift
import AppKit
import AVFoundation

final class WallpaperPlayer {
}
```

```swift
// TQwallpaper/VideoPicker.swift
import AppKit
import UniformTypeIdentifiers

enum MediaPicker {
}
```

```swift
// TQwallpaper/StaticWallpaper.swift
import AppKit
import AVFoundation

enum StaticWallpaper {
}
```

```swift
// TQwallpaper/StatusMenuController.swift
import AppKit

final class StatusMenuController: NSObject, NSMenuDelegate {
}
```

```swift
// TQwallpaper/AppDelegate.swift
import AppKit

@main
final class AppDelegate: NSObject, NSApplicationDelegate {
}
```

```swift
// TQwallpaperTests/EnergyPolicyTests.swift
import XCTest

final class EnergyPolicyTests: XCTestCase {
}
```

- [ ] **Step 8: 构建验证工程骨架**

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project TQwallpaper.xcodeproj -scheme TQwallpaper -configuration Debug -derivedDataPath DerivedData build
```

Expected: `** BUILD SUCCEEDED **`，产物 `DerivedData/Build/Products/Debug/TQwallpaper.app`。

- [ ] **Step 9: 提交**

```bash
git add TQwallpaper.xcodeproj TQwallpaper TQwallpaperTests
git commit -m "chore: xcode project scaffold with compiling stubs"
```

---

### Task 3: EnergyPolicy 单元测试（TDD）

**Files:**
- Modify: `TQwallpaperTests/EnergyPolicyTests.swift`
- Modify: `TQwallpaper/EnergyPolicy.swift`

- [ ] **Step 1: 写入完整测试**

```swift
import XCTest
@testable import TQwallpaper

final class EnergyPolicyTests: XCTestCase {
    func testPlaysByDefaultOnACPower() {
        var policy = EnergyPolicy()
        policy.onBattery = false
        policy.lowPowerMode = false
        XCTAssertTrue(policy.shouldPlay)
    }

    func testStopsWhenDynamicDisabled() {
        var policy = EnergyPolicy()
        policy.dynamicEnabled = false
        XCTAssertFalse(policy.shouldPlay)
    }

    func testStopsWhenLocked() {
        var policy = EnergyPolicy()
        policy.locked = true
        XCTAssertFalse(policy.shouldPlay)
    }

    func testStopsWhenSleeping() {
        var policy = EnergyPolicy()
        policy.sleeping = true
        XCTAssertFalse(policy.shouldPlay)
    }

    func testStopsOnBatteryWithPowerSaver() {
        var policy = EnergyPolicy()
        policy.powerSaverOn = true
        policy.onBattery = true
        XCTAssertFalse(policy.shouldPlay)
    }

    func testPlaysOnBatteryWhenPowerSaverOff() {
        var policy = EnergyPolicy()
        policy.powerSaverOn = false
        policy.onBattery = true
        XCTAssertTrue(policy.shouldPlay)
    }

    func testStopsInLowPowerModeWithPowerSaver() {
        var policy = EnergyPolicy()
        policy.powerSaverOn = true
        policy.lowPowerMode = true
        XCTAssertFalse(policy.shouldPlay)
    }

    func testPlaysInLowPowerModeWhenPowerSaverOff() {
        var policy = EnergyPolicy()
        policy.powerSaverOn = false
        policy.lowPowerMode = true
        XCTAssertTrue(policy.shouldPlay)
    }
}
```

- [ ] **Step 2: 运行测试，确认失败**

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project TQwallpaper.xcodeproj -scheme TQwallpaper -configuration Debug -derivedDataPath DerivedData test
```

Expected: 8 个断言中至少 `testStopsWhenDynamicDisabled` 等失败（stub 恒 true）。

- [ ] **Step 3: 实现正确逻辑**

用以下内容整体替换 `TQwallpaper/EnergyPolicy.swift`：

```swift
import Foundation

/// Pure state machine deciding whether the wallpaper video should play.
struct EnergyPolicy {
    var dynamicEnabled = true
    var locked = false
    var sleeping = false
    var onBattery = false
    var lowPowerMode = false
    var powerSaverOn = true

    var shouldPlay: Bool {
        guard dynamicEnabled else { return false }
        if locked || sleeping { return false }
        if powerSaverOn && (onBattery || lowPowerMode) { return false }
        return true
    }
}
```

- [ ] **Step 4: 运行测试，确认通过**

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project TQwallpaper.xcodeproj -scheme TQwallpaper -configuration Debug -derivedDataPath DerivedData test
```

Expected: `** TEST SUCCEEDED **`，8 个测试全部通过。

- [ ] **Step 5: 提交**

```bash
git add TQwallpaper/EnergyPolicy.swift TQwallpaperTests/EnergyPolicyTests.swift
git commit -m "feat: energy policy state machine with unit tests"
```

---

### Task 4: LaunchAtLogin（SMAppService）

**Files:**
- Modify: `TQwallpaper/LaunchAtLogin.swift`

- [ ] **Step 1: 写入完整实现**

用以下内容整体替换 `TQwallpaper/LaunchAtLogin.swift`：

```swift
import ServiceManagement

enum LaunchAtLogin {
    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    static func setEnabled(_ enabled: Bool) throws {
        if enabled {
            guard SMAppService.mainApp.status != .enabled else { return }
            try SMAppService.mainApp.register()
        } else {
            try SMAppService.mainApp.unregister()
        }
    }
}
```

- [ ] **Step 2: 构建验证**

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project TQwallpaper.xcodeproj -scheme TQwallpaper -configuration Debug -derivedDataPath DerivedData build
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: 提交**

```bash
git add TQwallpaper/LaunchAtLogin.swift
git commit -m "feat: launch at login via SMAppService"
```

---

### Task 5: MediaPicker（选视频/图片）

**Files:**
- Modify: `TQwallpaper/VideoPicker.swift`

- [ ] **Step 1: 写入完整实现**

用以下内容整体替换 `TQwallpaper/VideoPicker.swift`：

```swift
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
```

- [ ] **Step 2: 构建验证**

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project TQwallpaper.xcodeproj -scheme TQwallpaper -configuration Debug -derivedDataPath DerivedData build
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: 提交**

```bash
git add TQwallpaper/VideoPicker.swift
git commit -m "feat: media picker for videos and images"
```

---

### Task 6: WallpaperPlayer（多屏视频播放）

**Files:**
- Modify: `TQwallpaper/WallpaperPlayer.swift`

- [ ] **Step 1: 写入完整实现**

用以下内容整体替换 `TQwallpaper/WallpaperPlayer.swift`：

```swift
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

    /// Show + play or hide + pause, depending on the energy/lock/sleep state.
    func apply(shouldPlay: Bool) {
        guard let player else { return }
        if shouldPlay {
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
            player.pause()
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
        videoPath = nil
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
        tqLogger.info("created windows for \(slots.count) screen(s)")
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
```

- [ ] **Step 2: 构建验证**

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project TQwallpaper.xcodeproj -scheme TQwallpaper -configuration Debug -derivedDataPath DerivedData build
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: 提交**

```bash
git add TQwallpaper/WallpaperPlayer.swift
git commit -m "feat: per-screen desktop video wallpaper player"
```

---

### Task 7: StaticWallpaper（静态壁纸 + 截帧）

**Files:**
- Modify: `TQwallpaper/StaticWallpaper.swift`

- [ ] **Step 1: 写入完整实现**

用以下内容整体替换 `TQwallpaper/StaticWallpaper.swift`：

```swift
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

        guard let rep = NSBitmapImageRep(cgImage: image),
              let data = rep.representation(using: .jpeg, properties: [.compressionFactor: 0.92]) else {
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
```

- [ ] **Step 2: 构建验证**

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project TQwallpaper.xcodeproj -scheme TQwallpaper -configuration Debug -derivedDataPath DerivedData build
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: 提交**

```bash
git add TQwallpaper/StaticWallpaper.swift
git commit -m "feat: static wallpaper and freeze-frame support"
```

---

### Task 8: StatusMenuController（菜单栏）

**Files:**
- Modify: `TQwallpaper/StatusMenuController.swift`

- [ ] **Step 1: 写入完整实现**

用以下内容整体替换 `TQwallpaper/StatusMenuController.swift`：

```swift
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
```

- [ ] **Step 2: 构建验证**

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project TQwallpaper.xcodeproj -scheme TQwallpaper -configuration Debug -derivedDataPath DerivedData build
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: 提交**

```bash
git add TQwallpaper/StatusMenuController.swift
git commit -m "feat: menu-bar status controller"
```

---

### Task 9: AppDelegate 装配（应用主体）

**Files:**
- Modify: `TQwallpaper/AppDelegate.swift`

- [ ] **Step 1: 写入完整实现**

用以下内容整体替换 `TQwallpaper/AppDelegate.swift`：

```swift
import AppKit
import AVFoundation
import IOKit.ps

@main
final class AppDelegate: NSObject, NSApplicationDelegate {
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
        NotificationCenter.default.addObserver(self, selector: #selector(powerStateChanged), name: NSProcessInfo.powerStateDidChangeNotification, object: nil)

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
        let lowPower = NSProcessInfo.processInfo.isLowPowerModeEnabled
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
```

- [ ] **Step 2: 构建验证**

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project TQwallpaper.xcodeproj -scheme TQwallpaper -configuration Debug -derivedDataPath DerivedData build
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: 提交**

```bash
git add TQwallpaper/AppDelegate.swift
git commit -m "feat: app delegate wiring (observers, first-run, actions)"
```

---

### Task 10: 完整验证与收尾

**Files:**
- Modify: `README.md`（如验证中发现需要补充说明）

- [ ] **Step 1: 运行全部单元测试**

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project TQwallpaper.xcodeproj -scheme TQwallpaper -configuration Debug -derivedDataPath DerivedData test
```

Expected: `** TEST SUCCEEDED **`，8 个测试全部通过。

- [ ] **Step 2: Release 构建**

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project TQwallpaper.xcodeproj -scheme TQwallpaper -configuration Release -derivedDataPath DerivedData build
```

Expected: `** BUILD SUCCEEDED **`，产物 `DerivedData/Build/Products/Release/TQwallpaper.app`。

- [ ] **Step 3: 手动验证清单（需要用户操作）**

```bash
open DerivedData/Build/Products/Debug/TQwallpaper.app
```

逐项确认：
- [ ] 菜单栏出现 TQwallpaper 图标（无 Dock 图标）
- [ ] 首次启动弹出欢迎框；选一个本地 mp4 → 桌面开始循环播放、无声音
- [ ] 菜单「动态壁纸」取消勾选 → 视频隐藏、恢复原静态壁纸
- [ ] 「更换壁纸…」可切换视频/图片
- [ ] 「将动态转为静态」→ 桌面变为截图 JPEG，弹窗显示路径
- [ ] 「仅接通电源时播放」在电池/低电量时暂停、接电恢复
- [ ] 锁屏、睡眠时暂停，唤醒/解锁恢复（如需）
- [ ] 「开机启动」开关后，系统设置 → 通用 → 登录项中可见 TQwallpaper
- [ ] 访达右键一个 mp4 → 打开方式 → TQwallpaper → 直接设为动态壁纸

- [ ] **Step 4: 提交收尾**

```bash
git add -A
git commit -m "chore: finalize after verification"
```

Expected: 若验证无改动则提示 "nothing to commit"（正常，可跳过本步）。

- [ ] **Step 5: 推送到 GitHub（用户操作）**

在 GitHub 新建空仓库 `TQwallpaper` 后执行：

```bash
git remote add origin git@github.com:<你的用户名>/TQwallpaper.git
git branch -M main
git push -u origin main
```

Expected: `main` 分支推送成功。仓库中不含任何视频素材。

---

## 自检记录

- Spec 覆盖：设计文档中所有决定（Swift/AppKit、多屏、SMAppService、首启引导、Open With、无素材、MIT、占位 Bundle ID、arm64）均有对应任务。
- 类型一致性：`EnergyPolicy` 字段在 Task 3 测试与 Task 9 装配中一致；`WallpaperPlayer` 的 `load(videoPath:)`、`apply(shouldPlay:)`、`teardownPlayer()` 在 Task 6/7/9 中一致；`MediaSelection`/`MediaPicker` 在 Task 5/9 中一致；`LaunchAtLogin` 在 Task 4/9 中一致。
- 无占位符：所有文件均给出完整内容。

## 执行中发现的修复（2026-08-16）

1. **`@main` 不自动设置 delegate**：AppKit 的 `NSApplicationDelegate.main()` 扩展只调用
   `NSApplicationMain`，不会把 delegate 挂到 `NSApp`（正常模板靠 storyboard 装配）。无
   storyboard 工程必须显式设置：在 `AppDelegate` 中提供自定义
   `static func main()`（创建 `NSApplication.shared`、实例化 delegate、`app.run()`）。
   否则 `applicationDidFinishLaunching` 永不执行，App 无图标、无窗口、空转。
2. **菜单栏图标不可见**：原 `TQwallpaper-menu.png` 为深色低透明（平均 alpha 0.18），
   在菜单栏上几乎不可见。改为模板化 SF Symbol `photo.on.rectangle`，自动适配明暗菜单栏。
