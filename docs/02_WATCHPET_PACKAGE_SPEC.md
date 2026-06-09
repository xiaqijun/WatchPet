# `.watchpet` 宠物包规范 v1.0

## 目标

`.watchpet` 是 WatchPet 的宠物资源包格式，用于封装宠物的元数据、预览图、图标和动作帧。文件本质为 zip，可通过 iPhone App 导入并同步到 Apple Watch。

## 文件结构

```text
pet-name.watchpet
├── manifest.json
├── preview.png
├── icon.png
└── sprites/
    ├── idle/
    │   ├── 000.png
    │   ├── 001.png
    │   └── 002.png
    ├── happy/
    ├── hungry/
    ├── eat/
    ├── sleep/
    ├── pet/
    ├── sad/
    └── levelUp/
```

## manifest 示例

```json
{
  "format": "watchpet",
  "formatVersion": "1.0.0",
  "id": "mochi-cat-001",
  "name": "Mochi",
  "species": "cat",
  "style": "pixel-cute",
  "author": "user",
  "preview": "preview.png",
  "icon": "icon.png",
  "canvas": {
    "width": 160,
    "height": 160,
    "scale": 2
  },
  "animations": {
    "idle": { "path": "sprites/idle", "fps": 4, "loop": true },
    "happy": { "path": "sprites/happy", "fps": 6, "loop": false },
    "hungry": { "path": "sprites/hungry", "fps": 4, "loop": true },
    "eat": { "path": "sprites/eat", "fps": 6, "loop": false },
    "sleep": { "path": "sprites/sleep", "fps": 2, "loop": true },
    "pet": { "path": "sprites/pet", "fps": 6, "loop": false },
    "sad": { "path": "sprites/sad", "fps": 4, "loop": true },
    "levelUp": { "path": "sprites/levelUp", "fps": 8, "loop": false }
  }
}
```

## 图片规范

| 项 | 建议 |
|---|---|
| 格式 | PNG |
| 背景 | 透明 |
| 尺寸 | 128x128、160x160 或 184x184 |
| 帧数 | 每动作 4-8 帧 |
| 文件大小 | 单帧尽量 < 50KB |
| 命名 | `000.png`, `001.png` |
| 风格 | 像素风/Q版贴纸风优先 |

## 必需动作

- idle
- happy
- hungry
- eat
- sleep
- pet
- sad
- levelUp

## 校验规则

导入时应检查：

1. `manifest.json` 存在且 JSON 可解析。
2. `format === "watchpet"`。
3. `formatVersion` 支持。
4. 必需动作都存在。
5. 每个动作路径存在且至少 1 帧。
6. 图片尺寸不超过上限。
7. 文件总大小不超过同步阈值。
8. 图片为 PNG，且有 alpha 通道更佳。

## 版本兼容

- `1.0.0`：静态 PNG 帧动画。
- 未来 `1.1.0`：可加入音效、动作标签、道具适配。
- 未来 `2.0.0`：可加入骨骼动画或矢量动画，但不建议用于 MVP。

## 参考实现

仓库提供 Python 参考工具：

```bash
python scripts/watchpet_tool.py validate examples/mochi.watchpet
python scripts/watchpet_tool.py pack examples/mochi examples/mochi.watchpet --force
python scripts/watchpet_tool.py unpack examples/mochi.watchpet examples/mochi-unpacked --force
```

详见 `docs/07_WATCHPET_TOOL_GUIDE.md`。
