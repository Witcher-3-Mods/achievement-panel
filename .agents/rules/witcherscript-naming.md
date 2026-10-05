---
title: WitcherScript naming and module boundaries
impact: HIGH
tags: witcherscript, naming, architecture
---

# WitcherScript naming and module boundaries

## Table of Contents

1. [Keep the public package identity](#1-keep-the-public-package-identity)
2. [Namespace custom symbols](#2-namespace-custom-symbols)
3. [Preserve native identifiers](#3-preserve-native-identifiers)
4. [Rename complete tokens](#4-rename-complete-tokens)
5. [Avoid known parser collisions](#5-avoid-known-parser-collisions)
6. [Separate responsibilities](#6-separate-responsibilities)
7. [Preserve the vanilla path](#7-preserve-the-vanilla-path)
8. [Keep implementation provenance honest](#8-keep-implementation-provenance-honest)

## 1. Keep the public package identity

**Impact: HIGH**

The public mod name is `Witcher3ModsAchievementPanel`. Its installable folder is `modWitcher3ModsAchievementPanel`; retain the loader-required `mod` prefix.

**Incorrect:**

```text
Ship AchievementPanel without the mod prefix.
```

**Correct:**

```text
Ship modWitcher3ModsAchievementPanel.
```

## 2. Namespace custom symbols

**Impact: HIGH**

Prefix every custom type, function, field, parameter, local variable, enum value, menu tag and log channel with `Witcher3Mods`; use descriptive names after the prefix.

**Incorrect:**

```text
Add StatusSession and selectedItem to the shared namespace.
```

**Correct:**

```text
Add Witcher3ModsStatusSession and Witcher3ModsSelectedItem.
```

## 3. Preserve native identifiers

**Impact: HIGH**

Keep engine wrapper names, native types and fields, `wrappedMethod`, Flash property names, achievement IDs, statistic/fact keys and DLC identifiers unchanged.

**Incorrect:**

```text
Rename wrappedMethod or an EA_ achievement key.
```

**Correct:**

```text
Prefix only custom symbols; leave native contracts unchanged.
```

## 4. Rename complete tokens

**Impact: HIGH**

Rename tokens, not arbitrary substrings. Verify casts, constructors and every reference. Do not reuse a type name for a variable.

**Incorrect:**

```text
Replace every occurrence of a substring, including engine types.
```

**Correct:**

```text
Rename custom declarations and their references; check casts and constructors.
```

## 5. Avoid known parser collisions

**Impact: HIGH**

Do not use `entry` or `hint` as identifiers; they caused parser errors in the target installation.

**Incorrect:**

```text
Declare a local named entry or hint.
```

**Correct:**

```text
Use Witcher3ModsRow or Witcher3ModsButtonHint.
```

## 6. Separate responsibilities

**Impact: HIGH**

Keep responsibilities separate: catalogue data, read-only game queries, captured status, presentation, native menu integration and HUD tracking. WitcherScript files share the script namespace; do not invent JavaScript-style imports.

**Incorrect:**

```text
Query game state from the renderer and import a .ws file as JavaScript.
```

**Correct:**

```text
Keep catalogue, readout, presentation and integration in separate shared-namespace modules.
```

## 7. Preserve the vanilla path

**Impact: HIGH**

Prefer narrowly scoped wrappers over replacing entire vanilla files. Keep `wrappedMethod` on the original-behaviour path.

**Incorrect:**

```text
Replace the whole native handler to add one custom branch.
```

**Correct:**

```text
Handle the custom context in a wrapper; call wrappedMethod for native contexts.
```

## 8. Keep implementation provenance honest

**Impact: HIGH**

Read external mods to understand requirements, not to disguise copied implementation. Renaming is not an independent rewrite. Do not copy their custom classes, handlers, persistence conventions or translations. Standard language syntax, platform IDs and documented game API calls naturally remain shared; never promise zero textual overlap.

**Incorrect:**

```text
Copy another mod and rename its classes to claim an independent implementation.
```

**Correct:**

```text
Study requirements, implement independently, and identify any explicitly licensed reused material.
```

## References

Reference: [CDPR language guide](https://cdprojektred.atlassian.net/wiki/spaces/W3REDkit/pages/36307090/WS+Language+Guide), [CDPR annotations](https://cdprojektred.atlassian.net/wiki/spaces/W3REDkit/pages/36241598/WS+Script+Compilation+Errors+overrides), and installed `content/content0/scripts`.
