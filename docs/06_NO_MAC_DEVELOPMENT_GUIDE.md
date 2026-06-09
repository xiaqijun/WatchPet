# 无 Mac 设备开发 WatchPet 指南

你没有 Mac 也可以继续推进 WatchPet，但需要把工作拆成两类：

1. **Windows 上可以完成的工作**
2. **必须通过 macOS/Xcode 验证的工作**

## 1. 现在已经加入的替代方案：GitHub Actions 云端构建

仓库已加入：

```text
.github/workflows/validate.yml
```

它会在 GitHub 上自动执行：

- Python 项目结构校验
- macOS runner 上的 `xcodebuild` watchOS 构建检查

你可以在 GitHub 仓库页面查看：

```text
Actions -> Validate WatchPet
```

这能解决“没有 Mac，无法确认 Xcode 项目是否能编译”的主要问题。

## 2. 没有 Mac 时可以继续做什么

### 可以在 Windows 完成

- 产品规划和 PRD
- `.watchpet` 宠物包规范
- 宠物包打包/校验脚本
- AI 生成后端
- 图像处理/透明背景处理
- 生成 PNG 动画帧
- README、文档、GitHub Actions
- Swift 源码编写和静态检查

### 必须依赖 macOS/Xcode 或云 Mac

- Xcode 真正编译
- Apple Watch Simulator 运行
- 真机调试
- TestFlight
- App Store 上传
- Apple Developer 签名验证

## 3. 推荐路线

### 路线 A：继续 Apple Watch，使用 GitHub Actions 验证

适合：你仍然想做 Apple Watch 版本。

工作方式：

1. 在 Windows 写代码。
2. 推送到 GitHub。
3. GitHub Actions 自动用 macOS 编译。
4. 根据 Actions 报错修复。
5. 等产品成熟后，再租/借 Mac 做真机测试和发布。

优点：不用马上买 Mac。

缺点：不能本地实时调试 UI，反馈较慢。

### 路线 B：租云 Mac

适合：你想要完整 Xcode 调试体验，但不想买设备。

可选：

- MacStadium
- AWS EC2 Mac
- 其他云 Mac/VNC 服务

优点：能运行 Xcode、模拟器、签名。

缺点：付费，配置和网络体验需要折腾。

### 路线 C：买二手 Mac mini

适合：认真做 iOS/watchOS 产品。

建议：

- 二手 Mac mini M1/M2
- 16GB 内存更好，8GB 也可做 MVP

优点：最稳定。

缺点：有硬件成本。

### 路线 D：先改做非 Apple Watch 版本

如果你完全不想依赖 Apple 生态，可以改为：

- Bangle.js 2：JavaScript 开发，门槛低
- PineTime：开源手表固件
- LILYGO T-Watch：ESP32 手表开发板

优点：更开放，不强依赖 Xcode。

缺点：不是 Apple Watch，用户群和体验不同。

## 4. 我建议的下一步

在没有 Mac 的情况下，最合理的下一步是：

1. 先让 GitHub Actions 跑一次 Xcode 构建。
2. 根据 Actions 报错修复项目。
3. 同时继续开发 `.watchpet` 打包/校验工具和 AI 生成后端。
4. 等 watchOS 项目能云端编译后，再考虑租 Mac 做真机调试。
