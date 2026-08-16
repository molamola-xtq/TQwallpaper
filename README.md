# TQwallpaper

[![CI](https://github.com/molamola-xtq/TQwallpaper/actions/workflows/ci.yml/badge.svg)](https://github.com/molamola-xtq/TQwallpaper/actions/workflows/ci.yml)

macOS menu-bar video wallpaper app. Play any local video as a looping desktop
wallpaper, or freeze the current frame to a static picture.

> Bring your own content. This repository contains **no video or image
> assets** — you choose your own wallpaper videos and pictures.

## Demo

A looping, muted video wallpaper on the desktop:

<video src="docs/demo/demo.mp4" controls muted loop width="640"></video>

*Or view the [animated GIF](docs/demo/wallpaper-demo.gif).*

Sample frames from a user-provided video:

![frame 1](docs/demo/frame-1.jpg)
![frame 2](docs/demo/frame-2.jpg)
![frame 3](docs/demo/frame-3.jpg)

## Download

Latest release: [Releases](https://github.com/molamola-xtq/TQwallpaper/releases)

Download the zip, move `TQwallpaper.app` to your Applications folder, then pick
a video on first launch. No bundled content — bring your own.

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
