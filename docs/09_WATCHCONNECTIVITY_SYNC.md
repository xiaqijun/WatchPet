# WatchConnectivity 同步链路 v0.1

本阶段加入 iPhone Companion 到 Apple Watch 的同步骨架，目标是先跑通“选择宠物包 -> 发送元数据 -> 手表端接收并更新显示”的最小闭环。

## 当前实现

### iPhone Companion

新增：

- `WatchPetCompanion/Services/CompanionWatchSyncManager.swift`

能力：

- 启动 `WCSession`
- 显示配对状态、Watch App 安装状态、实时可达状态
- 将当前预览的宠物包元数据通过 `updateApplicationContext` 保存为最新同步上下文
- 如果手表实时可达，通过 `sendMessage` 发送即时消息

当前 payload：

```json
{
  "kind": "watchpet.package.selection",
  "packageId": "example-mochi-cat",
  "name": "Mochi",
  "species": "cat",
  "style": "pixel-cute",
  "selectedAction": "idle",
  "sentAt": 1781000000
}
```

### Apple Watch

新增：

- `WatchPet/WatchCompanionSyncManager.swift`

能力：

- 启动 `WCSession`
- 接收 `applicationContext`
- 接收实时 `message`
- 解析宠物包元数据
- 在 Watch 主界面标题区域显示来自 iPhone 的宠物名和同步状态

## 为什么先同步元数据

完整 `.watchpet` 资源包包含多张 PNG，后续需要处理：

- 文件传输队列
- 沙盒存储
- 资源版本号
- 中断恢复
- 清理旧资源
- Watch 端动态加载图片帧

这些会显著增加复杂度。因此 v0.1 先同步元数据，证明 iPhone 与 Watch 的通信链路、UI 状态和消息格式可用。

## 后续资源同步方案

推荐使用三阶段：

1. iPhone 发送 manifest 元数据；
2. iPhone 使用 `transferFile` 分批发送动作帧或 zip；
3. Watch 端保存到 Application Support 后切换动态资源播放器。

## 云端验证

GitHub Actions 会继续执行：

- Python 项目结构校验
- `.watchpet` 示例包校验
- iOS Companion Simulator 构建
- watchOS Simulator 构建

由于 CI 没有真实配对设备，WatchConnectivity 只能验证编译，实际消息收发需要未来用真机或云 Mac + 配对设备验证。
