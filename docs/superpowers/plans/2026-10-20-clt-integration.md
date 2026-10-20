# CLT integration implementation plan

Goal: Build a locally runnable input method with PRs #11, #12, #14, #15 using Swift 6 tools and Command Line Tools.

Architecture: Keep Swift 5 language compatibility while moving settings to Swift tools 6 and Swift Testing. Compile the existing input method directly with swiftc; assemble existing resources, libraries, plugins and settings app into the existing Squirrel bundle structure. Preserve macOS 13 minimum and existing input source identity.

- [x] Isolate work from user grammar/schema edits in feat/clt-pr-integration; merge the four PR branches.
- [x] Migrate settings test runner and remove full Xcode checks; run all existing tests.
- [x] Add a CLT app build entry point, localization conversion and bundle checks. Reuse existing prepared dependencies; fail clearly when unavailable.
- [x] Run bundle checks, signature verification and safe CLI launch. Verify real Rime deployment in a temporary user directory with the bundled deployer.
- [x] Document build/install commands and limitations; copy final artifact to original repository dist without installing over the active input method.

Scope: root Makefile and scripts, settings package/tests/scripts/readme, build documentation. No language-mode-6 concurrency rewrite, public release, automatic update channel migration or user configuration overwrite.

Validation: CLT Swift 6.3.3 arm64 release app; 26 Swift Testing tests, 2 resource conversion tests, 15 Lua checks passed. Bundled librime generated real candidates, committed Caps Lock code, produced slash, committed hyphenated text and paged back with Lua in a temporary user directory. Settings executable remained alive during launch check. App signature passed deep/strict verification. InputMethodKit registration and interactive host-app typing remain manual.

Additional integration fix: luna_pinyin imports symbols.yaml, which overrode PR #12 punctuation.yaml; updated its half-shape slash list and verified the regression with librime.
