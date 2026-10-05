---
name: implement
description: Implement Witcher 3 mod changes through toolchain preflight, native-source research, WitcherScript/Flash edits, REDkit cooking, local-build handoff and manual verification. Use for implementation and diagnostic-build requests, not read-only explanations. Includes the repository's build commands and source locations for a fresh session.
---

# Implement

Work from the repository root. The deliverable is `src/modWitcher3ModsAchievementPanel`, not `.build`. Follow these phases in order; do not announce readiness until the installable folder is complete.

## Phase 1 — Toolchain and scope preflight

Read `AGENTS.md` and all linked rules before edits. Collect the request and additions into a checklist, inspect `git status --short`, and preserve unrelated changes. README edits, game installation, publication and commits need separate user authorization.

Check the tools actually needed for this change with `Test-Path -LiteralPath` / `Get-Command`, then check their invocation works. Do not assume that files or executables from a previous session remain available.

| Capability | Used here | When required |
| --- | --- | --- |
| Build runner | Windows PowerShell, .NET (`Add-Type`, compression, image support) | Repository build and package integrity |
| Flash export/recompile | Java plus JPEXS `ffdec.jar` | Flash/UI changes |
| Import/cook/bundle | REDkit `bin/x64_RedKit/wcc_lite.exe` | Changed Flash assets |
| Native API references | Installed game scripts and REDkit AS/SWF sources | Relevant API or UI work |
| Search | `rg`; otherwise `Get-ChildItem` + `Select-String` | Source discovery |

Known local paths (discovery hints, not portable requirements):

- Game: `D:/SteamLibrary/steamapps/common/The Witcher 3`
- REDkit: `D:/SteamLibrary/steamapps/common/The Witcher 3 REDkit`
- Java: `C:/Program Files/JetBrains/WebStorm 2026.2/jbr/bin/java.exe`
- JPEXS: `.build/tooling/ffdec/ffdec.jar` (last used version 26.3.0)

Read the relevant scripts' parameter declarations before invoking them. For script-only edits, Java/REDkit cooking is not required if packaged UI assets remain compatible and unchanged. This workflow does not require WolvenKit, a separate old MODkit, or the REDkit GUI. Do not install/download missing tools automatically; report the missing prerequisite and continue only with work that does not need it. Never label an uncooked UI change ready to copy.

Native Java/REDkit commands may require execution approval. The cook script also writes temporary resources under REDkit's `bin/gameplay`; obtain required authorization rather than working around sandbox restrictions. Permission for that scratch work is not permission to install into the game.

## Phase 2 — Find the owning source and verify the API

Use current files, not old chat claims, as the starting point:

- Mod runtime: `src/modWitcher3ModsAchievementPanel/content/scripts/local/*.ws`. Menu lifecycle lives in `Witcher3ModsMenuIntegration.ws`; catalogue, readout, presentation and HUD tracking are separate modules.
- Translations: packaged `locales/pl.json` and `locales/en.json`; these generate a WitcherScript lookup and are not parsed as JSON at runtime.
- Flash patches: `tools/Build-Witcher3ModsFlash.ps1` and `tools/flash/*.as.inc`; icon source images/manifest are fixed offline inputs in `src/assets/achievement-icons`.
- Native WitcherScript: `<Game>/content/content0/scripts`; start with `game/gui/menus`, `game/gui/flashScriptImports.ws`, and the owner of the called API. Verify signatures, visibility and native event routing.
- Native Flash: `<REDkit>/r4data/gameplay/gui_new/actionscript`; `red/core/CoreComponent.as` and `CoreMenu.as` own initialization/registration, while `red/game/witcher3/menus` owns individual panels.
- Original compiled UI: `<REDkit>/r4data/gameplay/gui_new/swf`. The current build starts from journal and HUD SWFs. Source AS and compiled SWFs can differ: inspect the actual exported class when choosing patch anchors.
- Official CDPR language/annotation references are linked in `AGENTS.md`; use REDkit documentation for editor/cooking questions and official Adobe/Scaleform references for unfamiliar Flash APIs. Prefer installed native code for target-version behavior. An `import` declaration exposes an engine call, not its C++ implementation; do not invent the missing internals.

For read-only Flash inspection, export selected classes into an ignored `.build` subdirectory:

```powershell
& $Witcher3ModsJava -jar $Witcher3ModsFfdec -selectclass 'red.game.witcher3.menus.journal.QuestJournalMenu' -export script '.build/inspect-journal' $Witcher3ModsNativeSwf
```

Resolve those variables from the verified paths first. Do not copy generated/native source trees into distributable project sources. A diagnostic screenshot proves only the boundary it observes: distinguish loading, construction, stage attachment, registration, configuration and data delivery. Preserve working native behavior outside the mod context.

## Phase 3 — Implement

Edit maintained source with `apply_patch`, not generated exports. Change the build transformation or `.as.inc` template when changing Flash so the next build reproduces the result. Keep patch anchors unique/fail-fast. Update translations and generated lookups together. Review the change against the repository rules at its owning boundary. The user removed the automated test suite; do not recreate test files, fixtures or a test-running phase unless explicitly requested.

For diagnostic builds, use a visible version label, bounded logs, listener/timer cleanup and explicit uncertainty. Avoid gameplay writes, repeated blind reloads, or suppressing native errors. Root-menu instrumentation is an exceptional lifecycle investigation, not a place for ordinary layout helpers: retain timeline setup and native registration, and compare native versus instrumented code. Temporary diagnostics must be removed before release after runtime confirmation.

## Phase 4 — Build and prepare the installable folder

Run from the repository root, substituting the verified tool paths:

```powershell
# Only when translations changed:
powershell -NoProfile -ExecutionPolicy Bypass -File tools/Build-Witcher3ModsLocales.ps1

# When Flash changed:
powershell -NoProfile -ExecutionPolicy Bypass -File tools/Build-Witcher3ModsFlash.ps1 -RedkitPath $Witcher3ModsRedkit -JavaPath $Witcher3ModsJava -FfdecPath $Witcher3ModsFfdec
powershell -NoProfile -ExecutionPolicy Bypass -File tools/Pack-Witcher3ModsFlash.ps1 -RedkitPath $Witcher3ModsRedkit -AllowRedkitScratch
```

The Flash builder exports native classes, applies maintained patches, embeds icons and recompiles SWFs into `.build/flash`. The pack script imports SWF into REDkit resources, cooks for PC, bundles, generates metadata, unbundles and checks artifact integrity before replacing the repository package's `content/blob0.bundle` and `metadata.store`. It does not install the mod into the game.

Inspect exit codes and logs. `.build/package-<id>` holds per-step logs, cooked/unpacked resources and previous package backups. Scratch cleanup is restricted to generated, hash-checked files, with recoverable copies retained. If a scratch target already exists, stop and inspect it; do not delete or overwrite an unknown resource to force the build through.

Build-time input and artifact-integrity checks belong to preparing the deliverable; they may run before the handoff. If compilation/cooking fails, report that the build is not ready. Do not distribute mixed new scripts and old incompatible binaries. Local work prepares only the mod folder; distribution packaging belongs exclusively to the GitHub release workflow after a PR merge to `main`.

## Phase 5 — Notify the user immediately

Once the complete folder is ready, before unrelated follow-up work, say:

> Implementacja zakończona — folder moda jest gotowy do sprawdzenia w grze.

Link/name `src/modWitcher3ModsAchievementPanel`, identify a diagnostic build as diagnostic, state whether the game installation was changed, and give the concrete runtime test needed. Build readiness is not confirmed bug resolution or a release/audit verdict.

## Phase 6 — Final handoff

Report implemented scope, the manual/source/build-integrity checks actually performed and unresolved runtime observations. If a correction changes the package, rebuild when required and identify the replacement folder. WitcherScript compilation and first-open, reopen and tab-switch rendering still require the target game or suitable editor validation; JPEXS and cooking do not prove them.

There is no automated-test phase. Preserve production build safeguards (input validation, byte/hash comparisons, safe paths and release-tag checks); they prevent invalid publication and are not a replacement test suite. Run guard only when requested. Do not install, commit, push or publish without the applicable authorization.

Required order: tool preflight → source research → implementation → build/integrity checks → user notification → final result.
