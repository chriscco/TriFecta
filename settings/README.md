# TriFecta 设置（TriFectaSettings）

微信输入法风格的 TriFecta / Rime(Squirrel) 图形化设置窗口：左侧导航 + 右侧设置面板，
鼠标点击调参，替代手改 `~/Library/Rime/*.yaml`；保存后通过分布式通知让输入法立即
重新部署，配置即时生效。**手改 YAML 的方式完全保留**（设置只是多个前端）。

## 工程结构

```
settings/
├── Package.swift                 # SwiftPM 构建定义（主构建路径，CLT 环境即可）
├── project.yml                   # xcodegen 定义（生成 TriFectaSettings.xcodeproj）
├── TriFectaSettings.xcodeproj    # 已生成并提交（Xcode 用户可直接打开）
├── Deps/Yams                     # vendored Yams 5.1.3（MIT，离线可构建的本地包）
├── Sources/
│   ├── TriFectaSettingsCore/     # 无 UI 核心：YamlLineEditor（保留注释/未知键）、
│   │                             #   RimeSchemas、EffectiveModel、SettingsRepository、Deployer
│   ├── TriFectaSettings/         # SwiftUI app（输入/外观/界面/快捷键/同步/关于 6 个页面）
│   └── TriFectaSettingsCLI/      # 冒烟 CLI（dump/set/deploy/sync/restore/path）
├── Tests/TriFectaSettingsTests/  # Swift Testing（26 个用例）
└── scripts/
    ├── build-app.sh              # swift build → 组装 TriFectaSettings.app（ad-hoc 签名）
    ├── test.sh                   # CLT / Xcode 均可运行，支持 swift test 参数
    ├── install.sh                # 安装进输入法包 Contents/MacOS/（WeType 同款布局）
    └── smoke-test.sh             # 全流程冒烟（真实 ~/Library/Rime + 部署触发）
```

## 构建

需要 Swift 6.0 或更新的工具链（`swift --version`）；仅安装 Command Line Tools 即可。
包使用 Swift 5 语言模式，暂不引入 Swift 6 严格并发迁移。

```bash
# 方式一：脚本（推荐，Command Line Tools 环境即可）
bash settings/scripts/build-app.sh release
# 产物：settings/dist/TriFectaSettings.app

# 方式二：Xcode（xcodegen 已生成工程；构建时从本地 Deps/Yams 解析依赖，无需联网）
open settings/TriFectaSettings.xcodeproj        # 或
xcodebuild -project settings/TriFectaSettings.xcodeproj \
  -scheme TriFectaSettings -configuration Release build

# 单元测试
bash settings/scripts/test.sh
# 可转发 SwiftPM 参数，例如：
bash settings/scripts/test.sh --filter YamlLineEditorTests
```

> 注：若仓库位于 iCloud 同步目录（如 ~/Documents），xcodebuild/xctest 的代码签名会
> 因 `com.apple.fileprovider` 扩展属性失败——SwiftPM 时用独立 scratch 路径：
> `bash settings/scripts/test.sh --scratch-path /tmp/tsbuild`（build-app.sh 已内置该处理）。

## 安装

```bash
bash settings/scripts/install.sh
# 等价操作：构建 + sudo 拷贝到 /Library/Input Methods/Squirrel.app/Contents/MacOS/TriFectaSettings.app
# + 重签名（ad-hoc）。卸载：sudo rm -rf 该目录（用户配置保留）。
```

安装后：输入法菜单（或 Ctrl+Option+` 的上下文菜单）中的「设置…」即打开本窗口；
菜单中同时保留「打开 Rime 配置文件夹…」（手改 YAML 路径）。
无需重启输入法——菜单每次点击都会解析设置 app 的路径。

## 页面 → 配置文件映射

| 页面 | 控件 | 配置键 | 文件 |
|---|---|---|---|
| 输入 | 输入方案（勾选/默认） | `patch.schema_list` | `~/Library/Rime/default.custom.yaml` |
| 输入 | 默认简繁 | `patch."switches/@N/reset"` | `~/Library/Rime/<schema>.custom.yaml` |
| 输入 | 全角标点 | `patch."switches/@N/reset"` | 同上 |
| 外观 | 主题/候选布局/文字方向/字体/字号/候选格式 | `style/...`（color_scheme、candidate_list_layout、text_orientation、font_face、font_point、candidate_format） | `~/Library/Rime/squirrel.yaml` |
| 外观 | 三色配色（TriFecta 独有） | `group_colors.{enabled,red,yellow,green}`（裸 `0xAABBGGRR`，缺省回退内置红黄绿） | `~/Library/Rime/squirrel.yaml` |
| 快捷键 | ～键三色开关 | `group_colors.enabled` | `~/Library/Rime/squirrel.yaml` |
| 快捷键 | Shift 切换中英 | `patch."ascii_composer/switch_key/Shift_L/R"`（inline_ascii/noop） | `~/Library/Rime/default.custom.yaml` |
| 同步 | 同步用户数据按钮 | （无 sync 配置节；调用输入法进程 sync） | — |
| 关于 | 版本/GitHub/检查更新 | 读输入法 Info.plist | — |

约束实现：
- **只改认识的键**：`YamlLineEditor` 逐行手术式编辑，其余行（注释/未知键/用户手写）原字节保留；
  每次保存用 Yams 全量解析校验 + `.bak` 备份 + 原子写。
- **首次保存**：`~/Library/Rime/squirrel.yaml` 不存在时，先从安装包 SharedSupport 拷贝基线再改
  （保证 `preset_color_schemes`/`app_options` 等不因用户级文件的全量覆盖语义丢失）。
- **保存即生效**：向运行中的输入法投递 `SquirrelReloadNotification`（`deliverImmediately`，
  与菜单「部署」同一条代码路径）；输入法未运行时退化在 SharedSupport 目录执行 `--build`。

## 相关文档

- Rime 官方定制指南（.custom.yaml 补丁机制）：<https://github.com/rime/home/wiki/CustomizationGuide>
- 仓库：<https://github.com/thesadbee/TriFecta>

## 已知限制

- 「检查更新」打开 GitHub Releases 页：Sparkle 更新器只在输入法进程内，设置 app 不再引副本。
- 颜色拾色器仅编辑 RGB；透明度固定 0.68（与内置三色一致，不暴露透明度滑杆）。
- `smoke-test.sh` 会暂时修改真实的 `~/Library/Rime` 配置并触发部署；日常验证优先运行使用临时目录的 `test.sh`。
