//
//  RimeSchemasAndRepositoryTests.swift
//  TriFectaSettingsTests
//

import Foundation
import Testing
@testable import TriFectaSettingsCore

final class RimeSchemasTests {
  @Test func testLunaPinyinSwitches() throws {
    let schema = try RimeSchemas.parseSchema(id: "luna_pinyin", yamlText: Fixtures.lunaPinyinSchema)
    #expect(schema.displayName == "朙月拼音")
    #expect(schema.switches.count == 4)
    #expect(schema.fullShapeSwitch?.index == 1)
    let simp = schema.simplifiedSwitch
    #expect(simp != nil, "luna_pinyin 通过 zh_hant/zh_hans 变体组支持简繁")
    #expect(simp?.index == 2)
    #expect(simp?.options == ["zh_hant", "zh_hans", "zh_hant_hk", "zh_hant_tw"])
  }

  @Test func testTerraPinyinSimplification() throws {
    let schema = try RimeSchemas.parseSchema(id: "terra_pinyin", yamlText: Fixtures.terraPinyinSchema)
    #expect(schema.simplifiedSwitch?.name == "simplification")
    #expect(schema.simplifiedSwitch?.index == 2)
    #expect(schema.fullShapeSwitch?.index == 1)
  }

  @Test func testColorHexRoundTrip() {
    #expect(RimeModel.hexDump(0xAD2933F0) == "0xAD2933F0")
    // 6 位 0xBBGGRR 补全 alpha
    let node = try! RimeModel.compose("c: 0x606060\n")
    #expect(RimeModel.hexColor(node["c"]) == 0xFF606060)
  }

  @Test func testEmitPlainSafe() {
    #expect(YamlLineEditor.isPlainSafe("azure"))
    #expect(YamlLineEditor.isPlainSafe("Avenir"))
    #expect(!(YamlLineEditor.isPlainSafe("[label]. [candidate] [comment]")))
    #expect(!(YamlLineEditor.isPlainSafe("PingFang SC")))
    #expect(!(YamlLineEditor.isPlainSafe("15")))
    #expect(!(YamlLineEditor.isPlainSafe("true")))
  }
}

final class SettingsRepositoryTests {
  var tmp: URL!
  var paths: ConfigPaths!
  var repo: SettingsRepository!

  init() throws {
    tmp = FileManager.default.temporaryDirectory
      .appendingPathComponent("TriFectaTests-\(UUID().uuidString)", isDirectory: true)
    let imeApp = tmp.appendingPathComponent("Squirrel.app", isDirectory: true)
    let ss = imeApp.appendingPathComponent("Contents", isDirectory: true)
      .appendingPathComponent("SharedSupport", isDirectory: true)
    try FileManager.default.createDirectory(at: ss, withIntermediateDirectories: true)
    try Fixtures.squirrelYaml.write(to: ss.appendingPathComponent("squirrel.yaml"), atomically: true, encoding: .utf8)
    try Fixtures.defaultYaml.write(to: ss.appendingPathComponent("default.yaml"), atomically: true, encoding: .utf8)
    try Fixtures.lunaPinyinSchema.write(to: ss.appendingPathComponent("luna_pinyin.schema.yaml"), atomically: true, encoding: .utf8)
    try Fixtures.terraPinyinSchema.write(to: ss.appendingPathComponent("terra_pinyin.schema.yaml"), atomically: true, encoding: .utf8)
    paths = ConfigPaths(userDir: tmp.appendingPathComponent("Rime", isDirectory: true),
                        imeAppURL: imeApp)
    repo = SettingsRepository(paths: paths)
  }

  deinit {
    try? FileManager.default.removeItem(at: tmp)
  }

  @Test func testFirstWriteCopiesBaselineAndEdits() throws {
    #expect(!(FileManager.default.fileExists(atPath: paths.userSquirrelYaml.path)))
    var style = try RimeModel.effectiveModel(paths: paths).style
    style.colorScheme = "azure"
    style.fontPoint = 18
    let outcome = try repo.apply(ChangeSet(style: style), deploy: false)
    #expect(outcome.squirrelYamlCreated)
    let userText = try String(contentsOf: paths.userSquirrelYaml, encoding: .utf8)
    #expect(userText.contains("  color_scheme: azure\n"))
    #expect(userText.contains("  font_point: 18\n"))
    #expect(userText.contains("unknown_user_key:"), "基线完整，未知键保留")
    #expect(userText.hasSuffix("\n"), "保留换行")
    // 再读模型应与写入一致
    let model = try RimeModel.effectiveModel(paths: paths)
    #expect(model.style.colorScheme == "azure")
    #expect(model.style.fontPoint == 18)
    #expect(model.squirrelYamlSource == .user(paths.userSquirrelYaml))
  }

  @Test func testGroupColorsApplyAndReread() throws {
    var gc = GroupColorsValues.defaults
    gc.red = 0xAD112233
    gc.enabled = false
    _ = try repo.apply(ChangeSet(groupColors: gc), deploy: false)
    let model = try RimeModel.effectiveModel(paths: paths)
    #expect(model.groupColors.red == 0xAD112233)
    #expect(!(model.groupColors.enabled))
    #expect(model.groupColors.yellow == GroupColorsValues.defaults.yellow, "未改的颜色保持默认")
  }

  @Test func testSchemaListApply() throws {
    let model0 = try RimeModel.effectiveModel(paths: paths)
    var list = model0.schemaList
    #expect(list == RimeModel.recommendedSchemaList, "未自定义时使用推荐默认（简中+繁中各一）")
    #expect(!(model0.schemaListCustomized), "未自定义方案列表")
    list = ["cangjie5", "luna_pinyin"]
    _ = try repo.apply(ChangeSet(schemaList: list), deploy: false)
    let model = try RimeModel.effectiveModel(paths: paths)
    #expect(model.schemaList == ["cangjie5", "luna_pinyin"])
    #expect(model.schemaListCustomized, "保存后视为已自定义")
    let fileText = try String(contentsOf: paths.userDefaultCustomYaml, encoding: .utf8)
    #expect(fileText.contains("  schema_list:\n    - schema: cangjie5\n"))
  }

  @Test func testSwitchResetPerSchema() throws {
    let model = try RimeModel.effectiveModel(paths: paths)
    // 找 luna_pinyin 与 terra 的简繁开关 index
    guard let luna = model.schemas.first(where: { $0.id == "luna_pinyin" }),
          let simp = luna.simplifiedSwitch else {
      Issue.record("fixture 中应有 luna_pinyin 及简繁开关")
      return
    }
    _ = try repo.apply(ChangeSet(switchResets: [luna.id: [simp.index: 1]]), deploy: false)
    let updated = try RimeModel.effectiveModel(paths: paths)
    #expect(updated.switchResets[luna.id]?[simp.index] == 1, "用户补丁覆盖默认 reset")
    #expect(updated.userResetPatchKeys[luna.id]?.contains(simp.index) == true, "已保存的 reset 键应被标记为 patch key")
    let fileText = try String(contentsOf: paths.userSchemaCustomYaml(luna.id), encoding: .utf8)
    #expect(fileText.contains("\"switches/@\(simp.index)/reset\": 1\n"))
  }

  @Test func testApplyDiffSkipsUnchangedStyleKeys() throws {
    // 首次写入只改 color_scheme；font_point 不应被"冻结"到用户文件
    let model = try RimeModel.effectiveModel(paths: paths)
    var style = model.style
    style.colorScheme = "azure"   // 仅改这个
    _ = try repo.apply(ChangeSet(style: style), deploy: false)
    let userText = try String(contentsOf: paths.userSquirrelYaml, encoding: .utf8)
    #expect(userText.contains("color_scheme: azure"))
    let node = try RimeModel.compose(userText)
    let parsed = RimeModel.readStyle(node)
    #expect(parsed.fontPoint == 15, "未改的键保持基线值（未写入用户文件也无妨，读取一致）")
  }

  @Test func testIncludeAndPatchResolution() throws {
    // __include 继承 + __patch 的 switches/@N/reset 必须被解析（luna_pinyin_simp 实战形态）
    let ss = paths.sharedSupport
    try Fixtures.simpSchema.write(to: ss.appendingPathComponent("luna_pinyin_simp.schema.yaml"), atomically: true, encoding: .utf8)
    let schema = try RimeSchemas.parseSchema(id: "luna_pinyin_simp", yamlURL: ss.appendingPathComponent("luna_pinyin_simp.schema.yaml"))
    #expect(schema.displayName == "朙月拼音·简化字")
    #expect(schema.switches.count == 4, "继承自 luna_pinyin 的 4 个开关")
    #expect(schema.simplifiedSwitch?.index == 2)
    #expect(schema.simplifiedSwitch?.reset == 1, "__patch 的 @2/reset: 1 生效")
    #expect(schema.fullShapeSwitch?.index == 1)
  }

  @Test func testResetToBaseline() throws {
    _ = try repo.apply(ChangeSet(style: {
      var s = (try RimeModel.effectiveModel(paths: paths)).style
      s.colorScheme = "aqua"
      return s
    }()), deploy: false)
    let moved = try repo.resetToBaseline()
    #expect(!(moved.isEmpty))
    #expect(!(FileManager.default.fileExists(atPath: paths.userSquirrelYaml.path)))
    let model = try RimeModel.effectiveModel(paths: paths)
    #expect(model.style.colorScheme == "native", "还原基线后回到 SharedSupport 值")
    #expect(model.schemaList == RimeModel.recommendedSchemaList, "还原后回到推荐默认")
  }
}
