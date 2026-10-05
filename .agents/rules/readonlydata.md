---
title: Read-only data and isolated UI
impact: HIGH
tags: achievements, read-only, ui
---

# Read-only data and isolated UI

This panel observes the game. Never repair its display by changing real achievements, statistics, inventory or save facts. Distinguish account achievements, save progress and the current attempt.

## Table of Contents

1. [Verify data semantics](#1-verify-data-semantics)
2. [Use verified read-only APIs](#2-use-verified-read-only-apis)
3. [Render a captured snapshot](#3-render-a-captured-snapshot)
4. [Bound platform interpretation](#4-bound-platform-interpretation)
5. [Reject ambiguous reads](#5-reject-ambiguous-reads)
6. [Preserve unknown progress](#6-preserve-unknown-progress)
7. [Keep counters independent from unlocks](#7-keep-counters-independent-from-unlocks)
8. [Trace each denominator](#8-trace-each-denominator)
9. [Describe counter meaning](#9-describe-counter-meaning)
10. [Apply state precedence](#10-apply-state-precedence)
11. [Require evidence for blockers](#11-require-evidence-for-blockers)
12. [Generate localized runtime data](#12-generate-localized-runtime-data)
13. [Keep details focused](#13-keep-details-focused)
14. [Verify row rendering](#14-verify-row-rendering)
15. [Reuse artwork with its behavior understood](#15-reuse-artwork-with-its-behavior-understood)
16. [Isolate pins from real quests](#16-isolate-pins-from-real-quests)
17. [Preserve pins across menu closure](#17-preserve-pins-across-menu-closure)
18. [Use a dedicated context](#18-use-a-dedicated-context)
19. [Keep synthetic rows read-only](#19-keep-synthetic-rows-read-only)
20. [Refresh selection atomically](#20-refresh-selection-atomically)
21. [Separate original and third-party rights](#21-separate-original-and-third-party-rights)
22. [Persist only bounded preferences](#22-persist-only-bounded-preferences)
23. [Separate summaries from descriptions](#23-separate-summaries-from-descriptions)
24. [Refresh category summaries explicitly](#24-refresh-category-summaries-explicitly)
25. [Keep sorting local and deterministic](#25-keep-sorting-local-and-deterministic)
26. [Use native tab preferences](#26-use-native-tab-preferences)
27. [Separate expansion from visible pins](#27-separate-expansion-from-visible-pins)
28. [Evaluate third-party rights for the actual intended use](#28-evaluate-third-party-rights-for-the-actual-intended-use)

## 1. Verify data semantics

**Impact: HIGH**

Verify achievement/statistic mappings against the installed `gamerProfile.ws`, `types.ws`, `r4Game.ws`, `engine/game.ws` and platform definitions. A suggestive method name does not establish its runtime semantics.

**Incorrect:**

```text
Infer achievement semantics from a suggestive API name.
```

**Correct:**

```text
Trace the installed profile, enum and platform definitions.
```

## 2. Use verified read-only APIs

**Impact: HIGH**

Available read-only building blocks include `GetStatValue`, `GetUnlockedAchievements`, `IsAchievementUnlocked`, `GetAchievementsDisabled`, difficulty-history queries, DLC availability, player level, equipped slots and fast-travel queries. Verify signatures before use.

**Incorrect:**

```text
Call an unverified achievement API or unlock a row to repair its status.
```

**Correct:**

```text
Use installed read-only APIs with verified signatures.
```

## 3. Render a captured snapshot

**Impact: HIGH**

Capture one snapshot when the panel refreshes. Presentation must not query the game again. HUD tracking may refresh a snapshot at a throttled interval (currently two seconds), only while pins exist; never query every frame. Keep platform interpretation behind the readout boundary.

**Incorrect:**

```text
Query game statistics once per row or HUD frame.
```

**Correct:**

```text
Capture once per refresh; throttle HUD reads while pins exist.
```

## 4. Bound platform interpretation

**Impact: HIGH**

Compare results with verified platform status. Do not blindly AND, OR or invert disagreeing APIs. Never store an account-specific unlock reference or use it to select a reader. The user explicitly authorized a temporary inverted `IsAchievementUnlocked` reader using canonical `EA_` keys after comparing Steam screenshots with raw output: false means earned. Diagnostic UI and enumeration probes were subsequently removed at the user's request. This interpretation is not verified across game builds or platforms.

**Incorrect:**

```text
Invert unlock results universally because one account looked wrong.
```

**Correct:**

```text
Keep the authorized interpretation behind the readout boundary and disclose platform limits.
```

## 5. Reject ambiguous reads

**Impact: HIGH**

Reject constant or ambiguous responses. The current calls expose no read-success flag, so this also excludes legitimate zero/all-unlocked accounts until those cases can be distinguished from failed reads. A readout failure is a panel error, not a fourth achievement state. Do not infer unlocks from reaching a counter threshold.

**Incorrect:**

```text
Treat constant false output as a verified zero-achievement account.
```

**Correct:**

```text
Surface a readout error until failure can be distinguished from valid account data.
```

## 6. Preserve unknown progress

**Impact: HIGH**

Missing progress is not zero. Current-attempt counters can reset, and loaded saves can differ from account progress.

**Incorrect:**

```text
Display missing progress as 0/10.
```

**Correct:**

```text
Keep unavailable progress distinct from a confirmed zero.
```

## 7. Keep counters independent from unlocks

**Impact: HIGH**

Show the actual counter even for earned achievements, above the target (40/6), or below it after a reset. Never replace it with target/target. Keep unlock state independent from the displayed counter. If the game itself stops recording, do not fabricate a historical total.

**Incorrect:**

```text
Force every earned row to target/target.
```

**Correct:**

```text
Show the actual counter, including 40/6 or a reset value, beside independently confirmed status.
```

## 8. Trace each denominator

**Impact: HIGH**

Trace each denominator to the gameplay check. XML requiredValue applies only to the statistics registered by W3GamerProfile; it must not override direct conditions such as four occupied mutagen slots, level 35 or 100 travel points. Check every other direct counter when fixing one mismatch.

**Incorrect:**

```text
Apply XML requiredValue to every achievement.
```

**Correct:**

```text
Use the actual gameplay condition for direct checks such as four mutagen slots.
```

## 9. Describe counter meaning

**Impact: HIGH**

Describe counter semantics in the progress section: occupied slots and active potion effects are current state, combat chains are current attempts, recipes are learned recipes, and read books are historical read events in the save, not inventory quantity.

**Incorrect:**

```text
Label inventory book count as historical books read.
```

**Correct:**

```text
Explain whether a value is current state, current attempt or saved history.
```

## 10. Apply state precedence

**Impact: HIGH**

Exactly three achievement states are displayed. Confirmed earned status wins over current restrictions. Use the lowest difficulty recorded in the save, not just today's setting.

**Incorrect:**

```text
Mark an earned achievement blocked because difficulty was lowered.
```

**Correct:**

```text
Confirmed earned wins; evaluate restrictions using the recorded lowest difficulty.
```

## 11. Require evidence for blockers

**Impact: HIGH**

Missing quest facts do not prove a missable achievement is blocked. State incomplete story-block coverage honestly. Distinguish reversible restrictions from permanent restrictions for the current save.

**Incorrect:**

```text
Declare a missable achievement impossible because a quest fact is absent.
```

**Correct:**

```text
Mark a permanent blocker only when the relevant condition is verified.
```

## 12. Generate localized runtime data

**Impact: HIGH**

Keep translations in the package's `locales/pl.json` and `locales/en.json`. Run `powershell -NoProfile -ExecutionPolicy Bypass -File tools/Build-Witcher3ModsLocales.ps1` after edits to regenerate the shipped WitcherScript lookup; JSON files are not read by the game at runtime. Use the text/subtitle language from `GetGameLanguageName`, not the audio language; Polish selects PL, every other value selects EN. Presentation uses the language captured in its readout, without additional game queries. Polish achievement titles are verified against the Steam global achievements page.

**Incorrect:**

```text
Edit locale JSON and assume the game reads it at runtime.
```

**Correct:**

```text
Regenerate the WitcherScript lookup and select by text/subtitle language.
```

## 13. Keep details focused

**Impact: HIGH**

Details contain only description, progress, availability/block reason and the two technical keys. Avoid repeating those fields in README.

**Incorrect:**

```text
Repeat technical keys and long descriptions throughout README.
```

**Correct:**

```text
Put description, progress, availability and technical keys in the details panel.
```

## 14. Verify row rendering

**Impact: HIGH**

Earned rows are green with a completion mark. Verify HTML, status fields and glyphs in the actual renderer; passing a field to Flash is not proof it is supported.

**Incorrect:**

```text
Send a status field and assume the native renderer consumes it.
```

**Correct:**

```text
Confirm the earned green row and completion artwork in the actual renderer.
```

## 15. Reuse artwork with its behavior understood

**Impact: HIGH**

The current font does not support Unicode check/cross glyphs. Use native completion artwork. A reused renderer also brings tracking/highlight handlers: verify its input behavior and lifecycle, not just its artwork.

**Incorrect:**

```text
Insert unsupported Unicode checkmarks or ignore inherited input handlers.
```

**Correct:**

```text
Use native completion artwork and inspect the renderer's input lifecycle.
```

## 16. Isolate pins from real quests

**Impact: HIGH**

Achievement pins belong to mod-owned UI state, never real journal entries or quest tracking. Preserve all real objective indices, highlights and counter updates; append achievement presentation after quest content. Cover no quest, no objectives, many objectives, fast travel, removing the final pin, and reopening the menu. State persistence and pin limits explicitly.

**Incorrect:**

```text
Create synthetic journal entries to track achievements.
```

**Correct:**

```text
Append mod-owned HUD rows without changing real objective indices or quest state.
```

## 17. Preserve pins across menu closure

**Impact: HIGH**

Tracked rows are gold; otherwise earned rows are green and blocked rows red. Use native menu input with a localized Track/Stop tracking button. Closing the panel must not discard pins while the HUD instance remains alive.

**Incorrect:**

```text
Clear tracking whenever the panel closes.
```

**Correct:**

```text
Keep pins on their mod-owned owner and expose localized native tracking input.
```

## 18. Use a dedicated context

**Impact: HIGH**

Use a dedicated menu-context type. Preserve normal engine behaviour outside that context.

**Incorrect:**

```text
Apply achievement rendering to every glossary screen.
```

**Correct:**

```text
Gate custom behavior on a dedicated menu-context type.
```

## 19. Keep synthetic rows read-only

**Impact: HIGH**

Synthetic rows must not be treated as real journal entries, mark documents as read, increment Bookworm or overwrite normal tutorial menu state.

**Incorrect:**

```text
Let a synthetic row trigger OnEntryRead and Bookworm progression.
```

**Correct:**

```text
Bypass native journal side effects for custom rows only.
```

## 20. Refresh selection atomically

**Impact: HIGH**

Verify cold open, remembered-tab reopen, switching native/custom tabs, empty and populated data, repeated delivery, category focus, and teardown. Update title, icon, objectives and description as one selection; never leave stale details from the previous row.

**Incorrect:**

```text
Change title while leaving the previous achievement's description.
```

**Correct:**

```text
Refresh title, icon, objectives and description for the same selected row.
```

## 21. Separate original and third-party rights

**Impact: HIGH**

Respect third-party license obligations when reusing code or assets; do not misrepresent their provenance. Keep the root and packaged project license copies identical. Original project material uses personal noncommercial source-available terms; third-party MIT and other notices remain intact and separate. Never claim this change revokes rights already granted for earlier versions.

**Incorrect:**

```text
Call the entire package MIT because one embedded library is MIT.
```

**Correct:**

```text
Retain each component's notices and keep the original-material license copies identical.
```

## 22. Persist only bounded preferences

**Impact: HIGH**

User-authorized tracking persistence stores only three canonical achievement keys under the custom raw-config group `Witcher3ModsAchievementPanel`, using the verified next-gen `GetRawConfigValueByStr` / `SetRawConfigValueByStr` API and `SaveUserSettings`. Never write gameplay facts or account state. Validate keys against the catalogue, discard duplicates/unknown keys, clear unused slots, and save only on actual preference changes: pin/unpin or removing confirmed completed pins. Completion pruning may run during a throttled HUD refresh, but unchanged ticks and failed readouts must never write settings. Settings are shared across saves; restart persistence still needs runtime verification.

**Incorrect:**

```text
Write gameplay facts or save all preferences every HUD tick.
```

**Correct:**

```text
Validate at most three canonical pin keys and save only changed preferences.
```

## 23. Separate summaries from descriptions

**Impact: HIGH**

Keep full row descriptions separate from `secondLabel`, which controls the center header. List descriptions may be ellipsized; details retain full text.

**Incorrect:**

```text
Use an ellipsized list label as the full detail description.
```

**Correct:**

```text
Keep secondLabel, shortened list text and full details distinct.
```

## 24. Refresh category summaries explicitly

**Impact: HIGH**

Category focus must refresh summary title, subtitle, crest, objectives and description together. Native quest `setTitle` / `setText` are no-ops: use the mod-owned Flash summary method.

**Incorrect:**

```text
Call native quest setText and assume it updates a category summary.
```

**Correct:**

```text
Use the mod-owned summary method to update all summary fields together.
```

## 25. Keep sorting local and deterministic

**Impact: HIGH**

Preserve category order; sort pinned achievements before unpinned ones, then by localized plain title, including Polish letter order. Keep native quest sorting unchanged.

**Incorrect:**

```text
Sort native quests along with achievement pins using raw localized HTML.
```

**Correct:**

```text
Sort custom rows by pin state and localized plain title, preserving category order.
```

## 26. Use native tab preferences

**Impact: HIGH**

Remember the achievement tab through the native glossary UI preference, without overwriting native quest list state.

**Incorrect:**

```text
Overwrite native quest selection to remember the achievement tab.
```

**Correct:**

```text
Use the glossary's native tab preference for the custom tab.
```

## 27. Separate expansion from visible pins

**Impact: HIGH**

Category expansion is a separate user-authorized UI preference: store five validated booleans under `Witcher3ModsAchievementPanel/Witcher3ModsCategory0..4`, save only changed user choices, never initialization or renderer cleanup. Defaults: only base game expanded. On opening focus the first category header while details show the summary. Collapsed categories retain tracked, unearned rows; keep logical expansion distinct from a physically visible pin sublist.

**Incorrect:**

```text
Infer an expanded category from a visible pinned child and save during initialization.
```

**Correct:**

```text
Track logical expansion separately, validate five booleans and persist only user changes.
```

## 28. Evaluate third-party rights for the actual intended use

**Impact: HIGH**

Separate original project rights, retained third-party notices, and the permissions applicable to the intended use. Distinguish an in-game noncommercial mod based on officially supplied UI resources from redistribution of a standalone middleware SDK or unrelated commercial product. Consult official modding documentation as well as license texts. An attribution header alone proves neither a grant nor a prohibition; free distribution alone does not establish permission. A missing vendor agreement is not automatically a release blocker: identify the affected component, provenance, proposed use, applicable terms and unresolved question. Do not claim blanket legal clearance or relicense third-party materials.

**Incorrect:**

```text
Declare every Scaleform-containing mod forbidden because no standalone SDK license is in the repository; alternatively declare all bundled assets free because the mod costs nothing.
```

**Correct:**

```text
Assess the documented CDPR modding permission and restrictions for the exact native UI-derived artifact, retain notices and separately investigate any independently added middleware or actual conflicting terms.
```

## References

Reference: [CDPR script-mod tutorial](https://cdprojektred.atlassian.net/wiki/spaces/W3REDkit/pages/36241465/WS+Create+your+first+script+mod), [Script Studio](https://cdprojektred.atlassian.net/wiki/spaces/W3REDkit/pages/36864027/WS+Script+Studio+basics), installed game sources and verified Steam status.
