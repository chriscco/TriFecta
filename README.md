<div align="center">
  <img src="./icon.png" width="128" height="128" alt="TriFecta Logo" />
  <h1>TriFecta</h1>
  <p><strong>三色三选，一按即中——用颜色让你从容三选一的 macOS 中文输入法。</strong></p>

  <p>
    <a href="https://github.com/thesadbee/TriFecta/releases">
      <img src="https://img.shields.io/github/v/release/thesadbee/TriFecta?style=for-the-badge&logo=github" alt="Release" />
    </a>
    <a href="https://github.com/thesadbee/TriFecta/stargazers">
      <img src="https://img.shields.io/github/stars/thesadbee/TriFecta?style=for-the-badge&logo=github&color=ffb800" alt="Stars" />
    </a>
    <a href="https://github.com/thesadbee/TriFecta/releases">
      <img src="https://img.shields.io/github/downloads/thesadbee/TriFecta/total?style=for-the-badge&logo=github" alt="Downloads" />
    </a>
    <a href="LICENSE.txt">
      <img src="https://img.shields.io/badge/License-GPL_3.0-blue.svg?style=for-the-badge" alt="License" />
    </a>
  </p>

  <p>
    <a href="https://github.com/thesadbee/TriFecta/releases/latest">下载最新版</a> ｜
    <a href="https://github.com/thesadbee/TriFecta/issues">提交 Issue</a> ｜
    <a href="./README.en.md">English</a>
  </p>
</div>

---

**TriFecta（三色输入法）** 是一款基于 **Rime（Squirrel）** 的 macOS 中文输入法。它解决了原生输入法“候选字编号靠后（7/8/9）要凑近看编号、还得伸手去够数字键”的痛点——用三色分组加 `～` 键精准选字，让你的手指始终不离 `～ 1 2 3` 四个键。

本项目基于 [rime/squirrel](https://github.com/rime/squirrel) 定制（GPL-3.0），可打包为已签名并公证的 `.pkg`，安装后自动完成输入源注册。

## 核心优势

- **三色分组，精准选字**：候选字均分成 3 组，红 / 黄 / 绿三色区分。按 `～` 开启三色，`1/2/3` 选组，再按 `1/2/3` 选字，其它组褪色聚焦，选完自动回蓝。
- **三种输入模式**：触发（`～` 开启三色选字）、常驻（无需触发键，自动打开三色一级菜单）、滑块（二级菜单常驻显示，触发键向后滑动一组，支持回退键）。通过设置面板滑条一键切换。
- **图形化设置面板**：微信输入法风格，左侧导航 + 右侧面板，鼠标点按调参，替代手改 `~/Library/Rime/*.yaml`，保存后立即重新部署。手改 YAML 的方式完全保留。
- **中英混输体验**：`Shift` + 字母直接输出大写，不进入拼音候选，不影响后续中文输入；单 / 双引号左右交替，不再永远只有左半边。
- **原生观感与动画**：横向胶囊候选框、玻璃透明底、状态切换带干净的 `easeInEaseOut` 过渡，不会每次打字都闪。

## 下载与安装

请前往 [GitHub Releases](https://github.com/thesadbee/TriFecta/releases/latest) 下载适合你的安装包。

| 安装方式 | 推荐场景 | 说明 |
| --- | --- | --- |
| **`.pkg`**（推荐） | 普通用户 | 已签名 + 公证，双击即装，自动完成输入源注册 / Rime 方案部署 / 启用选中 |
| **`.dmg`** | 备用 / 手动安装 | 终端一行命令完成安装，脚本自动剥离隔离属性并注册 |
| **源码构建** | 开发者 | `make release` / `make package`，见下文 |

**方式 A：`.pkg`（推荐）**

1. 下载并打开 `TriFecta.pkg`；
2. 按安装向导输入管理员密码；
3. 安装完成后，**系统设置 → 键盘 → 输入法 中 Squirrel（鼠鬚管）已自动出现**，用 `⌃Control + 空格` 切换到 Squirrel 即可打字。

> 若安装后系统输入法列表未刷新，注销重登一次即可（HIToolbox 缓存刷新）。

<details>
<summary><b>方式 B：`.dmg` 安装详细步骤</b></summary>
<br>

> 注意：不要双击 `安装.command` 或 Squirrel.app —— App 是 ad-hoc 签名，双击会被 macOS 拦截。

下载本 dmg，双击打开（挂载到 /Volumes/TriFecta），打开终端粘贴运行：

```bash
cd /Volumes/TriFecta
sudo bash 安装.command
```

脚本会自动：剥离隔离属性 → 复制到 `/Library/Input Methods` → 注册输入源 → 构建 Rime 方案数据 → 启用并选中。全程只需输一次登录密码，看到 `✔ 安装完成！` 即成功。（构建方案数据约 10~60 秒，窗口看似卡住是正常的，别关。）

若仍被拦（提示 `com.apple.quarantine`），先手动清一次再运行：

```bash
xattr -dr com.apple.quarantine /Volumes/TriFecta/安装.command 2>/dev/null
cd /Volumes/TriFecta && sudo bash 安装.command
```

安装后：系统设置 → 键盘 → 输入法 → 点 “+” → 搜索 “Squirrel”（或“鼠鬚管”）→ 添加，用 `⌃Control + 空格` 切到 Squirrel。

</details>

<details>
<summary><b>卸载</b></summary>
<br>

在终端运行以下命令即可干净移除：

```bash
sudo bash -c '
echo ">>> 1. 禁用输入源"
"/Library/Input Methods/Squirrel.app/Contents/MacOS/Squirrel" --disable-input-source 2>/dev/null || echo "  (跳过:无可禁用)"
echo ">>> 2. 杀掉 Squirrel 进程"
pkill -9 -f "Squirrel" 2>/dev/null || echo "  (无进程)"
sleep 1
echo ">>> 3. 删除已装 App"
rm -rf "/Library/Input Methods/Squirrel.app"
echo ">>> 4. 验证"
if [ -d "/Library/Input Methods/Squirrel.app" ]; then echo "  ✘ 仍存在"; else echo "  ✔ 已删除"; fi
echo ">>> 完成"
'
```

卸载后如需彻底清空使用习惯/词库，可再执行 `rm -rf ~/Library/Rime`。

</details>

## 从源码构建

### 本地 CLT 构建（Swift 6 工具链）

无需安装完整 Xcode。使用 Swift 6+ Command Line Tools、macOS SDK、Python 3；测试还需要 Lua（`brew install lua`）。主程序和设置应用暂时保留 Swift 5 语言兼容模式，设置包使用 Swift tools 6.0 和 Swift Testing。

当前入口复用已准备的依赖：`librime/src` 头文件、`lib/librime.1.dylib` 与 `lib/rime-plugins`、`Frameworks/Sparkle.framework`、`bin/rime_deployer` / `rime_dict_manager` / `rime-install`。本次验证使用 librime 1.17.0、Sparkle 2.6.2。干净 checkout 尚需准备这些依赖；旧 `action-install.sh` 还会覆盖方案数据，不要直接对有配置改动的工作区运行。

```bash
make test                          # 26 个 Swift 测试、资源测试和 Lua 回归
make clt                           # 当前机器架构的 release app
bash scripts/check-app.sh          # 签名、启动、临时 Rime 数据部署及输入回归
# debug：bash scripts/build-app.sh debug
```

产物为 `dist/Squirrel.app`，包含图形设置窗口、词库与 Lua 插件，采用本地 ad-hoc 签名。安装时将它放入 `/Library/Input Methods/`，再注销登录，在系统「键盘 → 输入法」中添加鼠须管；如已安装其他 Squirrel，请先备份旧 app。构建过程不会安装 app 或修改 `~/Library/Rime`。已有用户自定义配置可覆盖内置方案，需在实际输入中确认。

此入口用于本地开发；旧 `make release/package` 和 GitHub 发布工作流仍保留 Xcode 路径。尚未迁移公证、通用二进制和独立更新渠道。构建包关闭自动检查更新，手动检查仍连接原上游。

### 原 Xcode 构建路径

TriFecta 基于 [rime/squirrel](https://github.com/rime/squirrel)（GPL-3.0）定制。

- 环境：**Xcode**（14+，macOS 26 beta 亦可）、**cmake**（`brew install cmake`，若手动编译 librime）、**Rime / Squirrel 源码与依赖**

```bash
# 1. 拉取仓库（含 librime / plum / Sparkle 子模块）
git clone --recursive https://github.com/thesadbee/TriFecta.git
cd TriFecta

# 2. 用预编译 librime + Sparkle 快速就绪（跳过编译 librime/Boost）
bash ./action-install.sh

# 3. 构建
export DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer   # 若用 beta Xcode
make release
```

> 若在受限网络下 `git clone`/子模块/`plum` 拉取失败，可用 `codeload`/`raw.githubusercontent` 逐个以 tarball 下载替换（工程在多种环境下均可构建）。

产物：`build/Build/Products/Release/Squirrel.app`（工程仍沿用输入法标识 `im.rime.inputmethod.Squirrel`）。

打包为已签名 + 公证的 `.pkg`（含自动注册 / 部署脚本 `scripts/postinstall`）：

```bash
# 用 Developer ID Application 签名 app + Developer ID Installer 签名 pkg + 公证
# 详见 package/ 相关脚本与 Makefile package 目标
make package
```

## 配置

方案与外观可通过 Rime/主题配置或设置面板调整（`~/Library/Rime` 与工程 `data/`）：

- **三色**：`sources/SquirrelView.swift` 中 `groupColors`（红/黄/绿 RGB + alpha）。
- **分组规则**：候选数 N 均分为 3 组（`groupSize = ceil(N/3)`）。
- **三模式 / 触发键 / 回退键**：设置面板「快捷键」页，或 `~/Library/Rime/squirrel.yaml` 的 `group_colors/*`。
- **胶囊外观**：`data/squirrel.yaml`（`candidate_list_layout: linear`、`font_point`、`line_spacing`、`translucency` 等）。

## 参与项目开发

TriFecta 的进步离不开社区的反馈与贡献。如果遇到 Bug 或有新的功能点子，欢迎提交 [Issue](https://github.com/thesadbee/TriFecta/issues) 或 Pull Request。本项目基于 [Rime](https://github.com/rime/librime) / [Squirrel](https://github.com/rime/squirrel) 定制，遵循 **GPL-3.0** 协议。

---

特别感谢：[rime/librime](https://github.com/rime/librime)（[佛振](https://github.com/lotem) 等）、[rime/squirrel](https://github.com/rime/squirrel)（[Leo Liu](https://github.com/Lekensteyn) 等）、[rime/plum](https://github.com/rime/plum)、[sparkle-project/Sparkle](https://github.com/sparkle-project/Sparkle) 及 rime-prelude / rime-luna-pinyin / rime-essay / rime-bopomofo / rime-cangjie / rime-stroke / rime-terra-pinyin / rime-quick / rime-double-pinyin 等方案数据。

TriFecta 的三色分组 + `～` 精准选字 + 三模式 + 设置面板等功能由 **DeepSeek Harness**（AI 编程代理）协助设计与实现。
