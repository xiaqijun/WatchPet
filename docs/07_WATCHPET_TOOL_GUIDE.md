# `.watchpet` 工具使用指南

仓库提供 `scripts/watchpet_tool.py`，用于在没有 Xcode/Mac 的情况下先完成宠物资源包制作、校验、打包和解包。

## 命令概览

```bash
python scripts/watchpet_tool.py validate <path>
python scripts/watchpet_tool.py pack <source-folder> <output.watchpet> --force
python scripts/watchpet_tool.py unpack <input.watchpet> <output-folder> --force
python scripts/watchpet_tool.py scaffold <folder>
```

## 1. 校验资源包文件夹

```bash
python scripts/watchpet_tool.py validate examples/mochi
```

输出：

```text
OK: watchpet package is valid
```

## 2. 打包 `.watchpet`

```bash
python scripts/watchpet_tool.py pack examples/mochi examples/mochi.watchpet --force
```

`.watchpet` 本质是 zip，但固定使用 `.watchpet` 扩展名。

## 3. 校验 `.watchpet` 文件

```bash
python scripts/watchpet_tool.py validate examples/mochi.watchpet
```

工具会临时解压并检查：

- `manifest.json` 是否存在且可解析
- `format` / `formatVersion` 是否支持
- 8 个基础动作是否齐全
- 每个动作目录是否存在 PNG 帧
- PNG 文件头、尺寸、alpha 通道
- canvas 尺寸是否合理
- zip 路径是否安全

## 4. 解包 `.watchpet`

```bash
python scripts/watchpet_tool.py unpack examples/mochi.watchpet examples/mochi-unpacked --force
```

解包时会做 zip-slip 防护，避免压缩包写出目标目录。

## 5. 创建空白模板

```bash
python scripts/watchpet_tool.py scaffold work/my-pet
```

它会生成：

```text
work/my-pet/
├── manifest.json
└── sprites/
    ├── idle/
    ├── happy/
    ├── hungry/
    ├── eat/
    ├── sleep/
    ├── pet/
    ├── sad/
    └── levelUp/
```

你只需要把 PNG 帧放进对应动作目录，然后运行 validate/pack。

## 示例包

已提供：

- `examples/mochi/`：未打包的示例资源包
- `examples/mochi.watchpet`：已打包示例
- `examples/manifest.example.json`：manifest 示例

## 下一步开发方向

这个 Python 工具是 iPhone App 导入逻辑的参考实现。后续 Swift 端应实现同等能力：

1. 解压 `.watchpet`
2. 读取并校验 `manifest.json`
3. 加载动作帧
4. 在 iPhone 端预览
5. 使用 WatchConnectivity 同步到 Apple Watch
