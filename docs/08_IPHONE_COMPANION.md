# iPhone Companion 开发说明

WatchPetCompanion 是 WatchPet 的 iPhone 管理端 MVP。当前阶段它不依赖 Apple Watch 真机，主要用于验证 `.watchpet` 包在 iPhone 端的导入、解析和动作预览体验。

## 当前功能

- 独立 iOS SwiftUI App 项目：`WatchPetCompanion.xcodeproj`
- 内置示例资源包：`WatchPetCompanion/Resources/mochi.watchpet`
- Swift 版未压缩目录包解析器：`WatchPetPackageLoader`
- Manifest 模型：`PetPackageManifest`
- 运行时模型：`PetPackage` / `PetAnimation` / `PetAction`
- 动作帧预览：`SpriteAnimationView`
- 预览动作切换：idle / happy / hungry / eat / sleep / pet / sad / levelUp

## 为什么先支持“解包目录”

`.watchpet` 标准文件本质是 zip。iOS 原生 Foundation 没有高级 zip API，后续可以选择：

1. 引入 ZIPFoundation 等 Swift Package；
2. 自己实现 zip 解包；
3. 由后端或 iPhone 导入阶段先解包到 App 沙盒。

当前 MVP 先实现“已解包 `.watchpet` 目录”的解析和预览，这能提前固定 Swift 端数据模型和 UI 逻辑。后续加 zip 解包时，只需要在进入 `loadUnpackedPackage(at:)` 前多一步解压。

## 云端构建

GitHub Actions 已加入 iOS Companion 构建：

```bash
xcodebuild \
  -project WatchPetCompanion.xcodeproj \
  -scheme WatchPetCompanion \
  -configuration Debug \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO \
  build
```

没有 Mac 设备时，可以通过 GitHub Actions 作为 Xcode 编译反馈。

## 下一步

1. 加入真实文件导入入口：`fileImporter`。
2. 选择 zip 解包方案。
3. 将解析后的宠物包存入 App 沙盒。
4. 增加宠物包列表。
5. 用 WatchConnectivity 同步选中的宠物包到 Apple Watch。
