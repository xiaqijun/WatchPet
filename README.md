# WatchPet

WatchPet 是一个 Apple Watch 随身电子宠物项目：用户可以把真实宠物照片转化为轻量 2D 动画宠物，在 Apple Watch 上摸摸、喂食、睡觉、陪玩和通过步数升级。

> 当前仓库是 MVP/设计验证版本：包含 watchOS 本地 Demo、占位宠物动画素材、`.watchpet` 资源包规范、AI 生成流程规划和完整开发路线图。

## 当前完成内容

- Apple Watch 独立 App 代码骨架
- SwiftUI 宠物主界面
- 宠物状态：饥饿值、心情、精力、经验、等级
- 互动：摸摸、喂食、睡觉
- 动作：idle / happy / hungry / eat / sleep / pet / sad / levelUp
- HealthKit 步数经验接口骨架
- 占位 PNG 帧动画资源
- `.watchpet` manifest 示例
- 完整产品/技术/生成/开发规划文档

## 项目结构

```text
WatchPet/
├── WatchPet.xcodeproj              # Xcode 项目结构
├── WatchPet/                       # watchOS App 源码和资源
│   ├── WatchPetApp.swift
│   ├── ContentView.swift
│   ├── PetModel.swift
│   ├── PetStore.swift
│   ├── PetSpriteView.swift
│   ├── HealthStepProvider.swift
│   ├── Assets.xcassets/
│   └── WatchPetAssets/manifest.example.json
├── WatchPetWidget/                 # Widget/Complication 后续 target 骨架
├── docs/                           # 完整规划文档
├── scripts/                        # 验证脚本
└── examples/                       # 示例资源包/配置
```

## 如何运行

1. 在 macOS 上安装 Xcode。
2. 打开 `WatchPet.xcodeproj`。
3. 设置 Team 与 Bundle Identifier。
4. 选择 `WatchPet` scheme。
5. 运行到 Apple Watch Simulator 或 Apple Watch 真机。
6. 如果不想测试步数，可先在 `PetStore.bootstrap()` 注释 HealthKit 调用。

## 文档入口

- [总规划](docs/00_MASTER_PLAN.md)
- [PRD](docs/01_PRD.md)
- [`.watchpet` 宠物包规范](docs/02_WATCHPET_PACKAGE_SPEC.md)
- [AI 生成规划](docs/03_AI_GENERATION_PLAN.md)
- [开发执行计划](docs/04_DEVELOPMENT_PLAN.md)
- [交付清单](docs/05_DELIVERY_CHECKLIST.md)

## 当前限制

- 当前生成环境是 Windows，无法本地执行 Xcode 编译验证。
- AppIcon 仍是占位配置，需要替换正式图标。
- Widget 文件已提供，但还未并入 Xcode target。
- `.watchpet` 解析器尚未实现，当前为规范与 manifest 示例。

## License

MIT
