# 开发执行计划 v1.0

## 里程碑 M1：跑通 Watch 本地 Demo

周期：1-2 天，已有代码骨架。

任务：

- 在 macOS/Xcode 打开 `WatchPetXcodeProject`。
- 设置 Team 和 Bundle Identifier。
- 修正任何 Xcode 编译问题。
- 跑通 Apple Watch Simulator。
- 测试摸摸、喂食、睡觉、状态保存。
- 可选：暂时关闭 HealthKit，避免模拟器授权干扰。

验收：

- App 启动显示宠物。
- 点按宠物触发动画。
- 状态条变化。
- 重启状态保留。

## 里程碑 M2：真实素材替换

周期：1-2 天。

任务：

- 制作一只正式测试宠物素材。
- 每个动作 4-8 帧。
- 替换 Assets.xcassets 中的占位图。
- 优化动画 fps 和尺寸。

验收：

- 所有动作视觉统一。
- Apple Watch 小屏清晰。
- 动画不卡顿。

## 里程碑 M3：iPhone Companion

周期：3-5 天。

任务：

- 新增 iOS App target。
- 宠物详情页。
- 本地宠物包列表。
- WatchConnectivity 同步状态和资源。

验收：

- iPhone 能选择宠物。
- Apple Watch 能接收资源/配置。

## 里程碑 M4：`.watchpet` 导入

周期：3-5 天。

任务：

- 实现 zip 解包。
- 校验 `manifest.json`。
- iPhone 预览动画。
- 同步到 Watch。

验收：

- 一个 `.watchpet` 文件能完整导入。
- 手表端能显示导入宠物。

## 里程碑 M5：AI 生成 MVP

周期：1-2 周。

任务：

- 照片上传。
- 候选主形象生成。
- 用户选择。
- 基础动作生成。
- 透明背景处理。
- `.watchpet` 打包下载。

验收：

- 用户可从照片生成一只可导入的手表宠物。
- 至少支持 8 个基础动作。

## 技术债清单

- 当前 Xcode 项目未在 macOS/Xcode 实机编译验证。
- 当前 AppIcon 是占位配置，无正式图标。
- 当前 Widget 还未并入完整 Xcode 项目 target。
- HealthKit 授权需真机验证。
- `.watchpet` 当前只有规范和示例，还未实现解析器。

## 近期最小下一步

1. 用 Mac 打开 `WatchPet.xcodeproj`。
2. 先不改业务代码，只解决编译问题。
3. 运行模拟器确认 UI。
4. 根据 Xcode 报错回填项目配置。
