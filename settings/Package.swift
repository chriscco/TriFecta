// swift-tools-version:6.0
// TriFectaSettings — 微信输入法风格的 TriFecta（Rime/Squirrel）图形化设置窗口。
// 构建：swift build -c release（Command Line Tools 环境即可构建，详见 scripts/build-app.sh）
// Xcode 用户：直接打开 settings/TriFectaSettings.xcodeproj（由 project.yml 经 xcodegen 生成）
import PackageDescription

let package = Package(
    name: "TriFectaSettings",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        // 本地 vendored Yams 5.1.3（MIT，独立即装即用，离线可构建）
        .package(name: "Yams", path: "Deps/Yams"),
    ],
    targets: [
        // 核心逻辑库（无 UI 依赖，可单元测试/CLI 复用）
        .target(
            name: "TriFectaSettingsCore",
            dependencies: [
                .product(name: "Yams", package: "Yams"),
            ],
            path: "Sources/TriFectaSettingsCore"
        ),
        // 设置 app（SwiftUI）
        .executableTarget(
            name: "TriFectaSettings",
            dependencies: ["TriFectaSettingsCore"],
            path: "Sources/TriFectaSettings",
            exclude: ["Resources"]
        ),
        // 冒烟 CLI（dump/set/deploy，供测试与 CI）
        .executableTarget(
            name: "TriFectaSettingsCLI",
            dependencies: ["TriFectaSettingsCore"],
            path: "Sources/TriFectaSettingsCLI"
        ),
        .testTarget(
            name: "TriFectaSettingsTests",
            dependencies: ["TriFectaSettingsCore"],
            path: "Tests/TriFectaSettingsTests"
        ),
    ],
    swiftLanguageModes: [.v5]
)
