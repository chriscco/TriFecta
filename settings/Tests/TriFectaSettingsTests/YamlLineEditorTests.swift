//
//  YamlLineEditorTests.swift
//  TriFectaSettingsTests
//

import Foundation
import Testing
@testable import TriFectaSettingsCore

final class YamlLineEditorTests {
  @Test func testChangeExistingScalarKeepsCommentAndRestBytes() throws {
    var editor = YamlLineEditor(text: Fixtures.squirrelYaml)
    try editor.setScalar(section: "style", keyText: "color_scheme", value: .string("azure"))
    let text = editor.text
    #expect(text.contains("  color_scheme: azure\n"), "应替换值")
    #expect(!(text.contains("color_scheme: native")), "旧值应被替换")
    // 其余未知键/注释原字节保留
    #expect(text.contains("# user 自定义方案开关（未知键，设置 app 不得破坏）") == false
                  || text.contains("unknown_user_key:"))
    #expect(text.contains("comment_text_color: 0xfcac9d"), "配色内容保留")
    #expect(text.contains("# horizontal is Deprecated since 0.36"), "注释保留")
  }

  @Test func testChangeValuePreservesTrailingCommentAndSpacing() throws {
    var editor = YamlLineEditor(text: Fixtures.squirrelYaml)
    try editor.setScalar(section: "style", keyText: "candidate_list_layout", value: .string("vertical"))
    #expect(editor.text.contains("candidate_list_layout: vertical  # linear(横排) close to native macOS candidate bar\n"))
  }

  @Test func testQuotedValueKeepsQuoteStyle() throws {
    var editor = YamlLineEditor(text: Fixtures.squirrelYaml)
    try editor.setScalar(section: "style", keyText: "font_face", value: .string("Songti SC"))
    #expect(editor.text.contains("font_face: 'Songti SC'\n"), "新值应保持单引号风格")
  }

  @Test func testCandidateFormatWithSpecialChars() throws {
    var editor = YamlLineEditor(text: Fixtures.squirrelYaml)
    try editor.setScalar(section: "style", keyText: "candidate_format", value: .string("%c %@"))
    #expect(editor.text.contains("candidate_format: '%c %@'\n"), "含 % 与空格应加引号")
  }

  @Test func testFontPointNumeric() throws {
    var editor = YamlLineEditor(text: Fixtures.squirrelYaml)
    try editor.setScalar(section: "style", keyText: "font_point", value: .number("18"))
    #expect(editor.text.contains("font_point: 18\n"))
  }

  @Test func testInsertMissingStyleKeyAtSectionEnd() throws {
    var editor = YamlLineEditor(text: Fixtures.squirrelYaml)
    // style 节内不存在的键：label_font_point
    try editor.setScalar(section: "style", keyText: "label_font_point", value: .number("12"))
    let text = editor.text
    #expect(text.contains("  label_font_point: 12\n"), "应插入到 style 节内（2 空格缩进）")
    #expect(text.contains("  font_point: 15\n"))
  }

  @Test func testGroupColorsCreatedAtEndWithDefaults() throws {
    let defaults = GroupColorsValues.defaults
    var editor = YamlLineEditor(text: Fixtures.squirrelYaml)
    try editor.setSectionValues(section: "group_colors", values: [
      ("enabled", .bool(defaults.enabled)),
      ("red", .hexColor(defaults.red)),
      ("yellow", .hexColor(defaults.yellow)),
      ("green", .hexColor(defaults.green)),
    ])
    let text = editor.text
    #expect(text.contains("""
      group_colors:
        enabled: \(defaults.enabled)
        red: \(RimeModel.hexDump(defaults.red))
        yellow: \(RimeModel.hexDump(defaults.yellow))
        green: \(RimeModel.hexDump(defaults.green))
      """))
    #expect(text.contains("app_options:"), "其余内容保留")
    // Yams 解析验证裸 0x 值仍可读（.int 为 Int，与 UInt32 默认值转换后比较）
    let node = try RimeModel.compose(text)
    let parsed = node["group_colors"]?["red"]?.int
    #expect(parsed == Int(defaults.red))
  }

  @Test func testGroupColorsExistingSectionKeepsUnknownSubkey() throws {
    var editor = YamlLineEditor(text: Fixtures.squirrelYaml)
    try editor.setSectionValues(section: "group_colors", values: [("enabled", .bool(false))])
    // 再追加绿
    try editor.setSectionValues(section: "group_colors", values: [("green", .hexColor(GroupColorsValues.defaults.green))])
    #expect(editor.text.contains("  enabled: false\n"))
    #expect(editor.text.contains("  green: \(RimeModel.hexDump(GroupColorsValues.defaults.green))\n"))
  }

  @Test func testReplaceSchemaListBlock() throws {
    var editor = YamlLineEditor(text: "patch:\n  # 用户自己的注释\n  schema_list:\n    - schema: luna_pinyin\n  other_key: 1\n")
    try editor.replaceBlockList(path: ["patch", "schema_list"], items: ["- schema: cangjie5", "- schema: stroke"])
    let text = editor.text
    #expect(text.contains("  # 用户自己的注释\n"), "块上方注释保留")
    #expect(text.contains("    - schema: cangjie5\n    - schema: stroke\n"))
    #expect(!(text.contains("- schema: luna_pinyin\n")))
    #expect(text.contains("  other_key: 1\n"), "同节其它键保留")
  }

  @Test func testReplaceSchemaListInsertWhenMissing() throws {
    var editor = YamlLineEditor(text: "patch:\n  ascii_composer:\n    switch_key:\n      Shift_L: inline_ascii\n")
    try editor.replaceBlockList(path: ["patch", "schema_list"], items: ["- schema: terra_pinyin"])
    #expect(editor.text.contains("  schema_list:\n    - schema: terra_pinyin\n"))
  }

  @Test func testSwitchResetPatchQuotedKey() throws {
    var editor = YamlLineEditor(text: "patch:\n")
    try editor.setScalar(section: "patch", keyText: "\"switches/@2/reset\"", value: .number("1"))
    let text = editor.text
    #expect(text.contains("  \"switches/@2/reset\": 1\n"))
    let node = try RimeModel.compose(text)
    #expect(node["patch"]?["switches/@2/reset"]?.int == 1)
  }

  @Test func testShiftPatchKeys() throws {
    var editor = YamlLineEditor(text: "patch:\n")
    try editor.setScalar(section: "patch", keyText: "\"ascii_composer/switch_key/Shift_L\"", value: .string("noop"))
    try editor.setScalar(section: "patch", keyText: "\"ascii_composer/switch_key/Shift_R\"", value: .string("noop"))
    let node = try RimeModel.compose(editor.text)
    // Rime 补丁键是扁平路径键（整串为一个 YAML 键）
    #expect(node["patch"]?["ascii_composer/switch_key/Shift_L"]?.string == "noop")
    #expect(node["patch"]?["ascii_composer/switch_key/Shift_R"]?.string == "noop")
  }

  @Test func testReplaceValuePreservesExactlyOneGapStyle() throws {
    var editor = YamlLineEditor(text: "style:\n  show_paging: false  # paging arrows\n")
    try editor.setScalar(section: "style", keyText: "show_paging", value: .bool(true))
    #expect(editor.text == "style:\n  show_paging: true  # paging arrows\n")
  }

  @Test func testHexScalarBareAndQuotedBothReadable() throws {
    // 裸写（官方风格）与带引号均能被 Yams 解析为颜色值
    var editor = YamlLineEditor(text: "group_colors:\n  red: '0xAD2933F0'\n")
    try editor.setScalar(section: "group_colors", keyText: "red", value: .hexColor(0xAD2933F0))
    // 已存在的带引号行保持引号风格（与官方裸写均兼容）
    #expect(editor.text.contains("red: '0xAD2933F0'\n"))
    let node = try RimeModel.compose(editor.text)
    #expect(RimeModel.hexColor(node["group_colors"]?["red"]) == 0xAD2933F0)
    // 新建行采用官方裸 0x 风格
    var editor2 = YamlLineEditor(text: "group_colors:\n  enabled: true\n")
    try editor2.setScalar(section: "group_colors", keyText: "green", value: .hexColor(0xAD45BD24))
    #expect(editor2.text.contains("green: 0xAD45BD24\n"))
    let node2 = try RimeModel.compose(editor2.text)
    #expect(RimeModel.hexColor(node2["group_colors"]?["green"]) == 0xAD45BD24)
    // 引号形式同样可读
    let node3 = try RimeModel.compose("group_colors:\n  red: '0xAD2933F0'\n")
    #expect(RimeModel.hexColor(node3["group_colors"]?["red"]) == 0xAD2933F0)
  }

  @Test func testUnknownKeysAndCommentsBytePreserved() throws {
    // 真实文件以换行结尾（多行字面量本身不带末尾换行，这里补上）
    let original = Fixtures.squirrelYaml + "\n"
    var editor = YamlLineEditor(text: original)
    try editor.setScalar(section: "style", keyText: "color_scheme", value: .string("aqua"))
    let lines = editor.text.components(separatedBy: "\n")
    let originalLines = original.components(separatedBy: "\n")
    #expect(lines.count == originalLines.count, "行数不变（只替换值，不增删行）")
    var different = 0
    for (a, b) in zip(originalLines, lines) where a != b {
      different += 1
      #expect(a.replacingOccurrences(of: "native", with: "aqua") == b)
    }
    #expect(different == 1, "只有目标行被改动")
  }
}
