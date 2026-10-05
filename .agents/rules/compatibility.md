---
title: WitcherScript and REDkit compatibility
impact: HIGH
tags: witcherscript, compiler, ownership
---

# WitcherScript and REDkit compatibility

Use the installed game's scripts as the final API reference. General REDkit examples may target another compiler build. Do not assume C++, C# or TypeScript syntax works in WitcherScript.

## Table of Contents

1. [Choose the native host before presentation](#1-choose-the-native-host-before-presentation)
2. [Trace a working lifecycle](#2-trace-a-working-lifecycle)
3. [Isolate custom bindings](#3-isolate-custom-bindings)
4. [Treat host replacement as architecture](#4-treat-host-replacement-as-architecture)
5. [Prove cold initialization early](#5-prove-cold-initialization-early)
6. [Do not write through engine globals](#6-do-not-write-through-engine-globals)
7. [Own mutable panel state](#7-own-mutable-panel-state)
8. [Respect const ownership](#8-respect-const-ownership)
9. [Cover all global-write forms](#9-cover-all-global-write-forms)
10. [Use supported annotation syntax](#10-use-supported-annotation-syntax)
11. [Preserve event return contracts](#11-preserve-event-return-contracts)
12. [Use supported reference tests](#12-use-supported-reference-tests)
13. [Verify APIs before using them](#13-verify-apis-before-using-them)
14. [Preserve signatures and local declarations](#14-preserve-signatures-and-local-declarations)
15. [Respect private method ownership](#15-respect-private-method-ownership)
16. [Preserve encoding and supported glyphs](#16-preserve-encoding-and-supported-glyphs)
17. [Preserve native Flash initialization](#17-preserve-native-flash-initialization)
18. [Verify runtime symbol availability](#18-verify-runtime-symbol-availability)
19. [Verify callback receipt](#19-verify-callback-receipt)
20. [Inspect static initialization](#20-inspect-static-initialization)

## 1. Choose the native host before presentation

**Impact: HIGH**

Choose the runtime host independently from the desired presentation. Prefer the native host already used by working siblings in the target context. Reuse content, renderers or child modules through supported extension points instead of importing another feature's entire controller or root merely to obtain its appearance.

**Incorrect:**

```text
Use a quest controller as a glossary root because its list looks right.
```

**Correct:**

```text
Keep the native glossary host and adapt supported child content.
```

## 2. Trace a working lifecycle

**Impact: HIGH**

Before choosing or replacing a host, trace a working equivalent: parent/owner, requested type, resource selection, construction, registration, engine binding, configuration and teardown. Check actual installed sources and a known-working implementation; similar class names, inheritance or successful compilation do not establish lifecycle compatibility.

**Incorrect:**

```text
Assume matching base classes imply the same startup sequence.
```

**Correct:**

```text
Trace a working sibling from requested type through configuration and teardown.
```

## 3. Isolate custom bindings

**Impact: HIGH**

Preserve the host's identity, ownership and startup contract by default. Keep custom data and presentation isolated from native state, bindings and callbacks. Verify that embedded components do not bring an independent registration path, unsupported callbacks or gameplay side effects, and preserve native behavior outside the custom context.

**Incorrect:**

```text
Let achievement rows use real quest tracking callbacks.
```

**Correct:**

```text
Keep mod-owned data and callbacks inside the custom context.
```

## 4. Treat host replacement as architecture

**Impact: HIGH**

Treat cross-context hosting, root replacement and lifecycle reordering as architectural changes, not ordinary layout edits. Explain why the native-host approach is insufficient and what evidence supports the alternative before implementing it. If this materially expands the authorized scope, obtain user direction first.

**Incorrect:**

```text
Replace the root controller as an incidental layout change.
```

**Correct:**

```text
Explain the native host limitation and validate the alternative within authorized scope.
```

## 5. Prove cold initialization early

**Impact: HIGH**

Prefer a minimal, reversible integration that proves the host can start and display content before transferring the full feature. Validate cold initialization as well as warm navigation; a component working after another screen has opened does not establish that it can initialize independently.

**Incorrect:**

```text
Transfer the whole UI and test only after visiting a native quest tab.
```

**Correct:**

```text
First open a minimal native-host panel from a cold state, then add content.
```

## 6. Do not write through engine globals

**Impact: HIGH**

Never directly assign to a member rooted at engine globals such as `theGame`. In our target build, `theGame.w3AchievementPanelDecoder = ...` caused this exact compiler error.

**Incorrect:**

```text
theGame.Witcher3ModsAdapter = Witcher3ModsSelectedAdapter;
```

**Correct:**

```text
Store Witcher3ModsAdapter on a mod-owned session object.
```

## 7. Own mutable panel state

**Impact: HIGH**

Store mutable panel state on a mod-owned object. The current readout recomputes its validation per refresh; no field is added to `CR4Game`.

**Incorrect:**

```text
Add a mutable decoder field to CR4Game.
```

**Correct:**

```text
Keep mutable state on the panel owner or recompute the readout.
```

## 8. Respect const ownership

**Impact: HIGH**

Do not bypass const ownership by casting or aliasing a global. If an actual engine mutation is required for another feature, use a verified engine method and explicit authorization.

**Incorrect:**

```text
Cast theGame to an alias and write through it.
```

**Correct:**

```text
Use a verified engine method only for an authorized engine mutation.
```

## 9. Cover all global-write forms

**Impact: HIGH**

Review direct global member assignments, including compound assignment and increment/decrement. Inspect the exact failing line, not only the error wording.

**Incorrect:**

```text
Check only theGame.member = value.
```

**Correct:**

```text
Also reject +=, -=, increment and decrement through engine globals.
```

## 10. Use supported annotation syntax

**Impact: HIGH**

Place `function` immediately after `@wrapMethod` / `@addMethod`. Do not add `private`, `protected` or `public` there in this target build: that form previously failed compilation.

**Incorrect:**

```text
@addMethod(CR4Game) followed by private function.
```

**Correct:**

```text
@addMethod(CR4Game) followed immediately by function.
```

## 11. Preserve event return contracts

**Impact: HIGH**

Engine events can have an implicit bool return. Do not use bare `return;` in wrappers such as `OnRequestMenu` or `OnEntryRead`; use branches and preserve the verified signature.

**Incorrect:**

```text
Use bare return; inside a wrapped event with an implicit bool result.
```

**Correct:**

```text
Branch around custom work and preserve the verified event signature.
```

## 12. Use supported reference tests

**Impact: HIGH**

Test object references with `if (object)` / `if (!object)`. Our `object != NULL` comparison failed with a Void type mismatch.

**Incorrect:**

```text
if (Witcher3ModsObject != NULL)
```

**Correct:**

```text
if (Witcher3ModsObject)
```

## 13. Verify APIs before using them

**Impact: HIGH**

Do not invent API names. `StringToName` is absent in the checked installation; use `name` literals or verified enum mappings.

**Incorrect:**

```text
Call StringToName because another language has an equivalent.
```

**Correct:**

```text
Use a verified name literal or explicit enum mapping.
```

## 14. Preserve signatures and local declarations

**Impact: HIGH**

Preserve parameter types, order and `out`; declare locals at the top of each function.

**Incorrect:**

```text
Drop out from a wrapped parameter or declare locals after statements.
```

**Correct:**

```text
Match the native signature and declare locals at the top.
```

## 15. Respect private method ownership

**Impact: HIGH**

Verify method visibility and ownership in the installed source, not only its signature. A cast does not grant access to private methods. Keep private calls inside their declaring class via a prefixed bridge; do not widen native visibility. Review cross-class calls (the observed example was journal `PopulateData` called from a base-menu wrapper), and check the same constraint for any new bridge.

**Incorrect:**

```text
Cast a menu to call its private PopulateData from another class.
```

**Correct:**

```text
Keep the private call in its declaring class behind a prefixed bridge.
```

## 16. Preserve encoding and supported glyphs

**Impact: HIGH**

Keep UTF-8 and use `Get-Content -Encoding UTF8` in PowerShell. Validate non-ASCII glyphs in the actual game font.

**Incorrect:**

```text
Read UTF-8 as the system code page and assume Unicode marks render.
```

**Correct:**

```text
Read with -Encoding UTF8 and test the actual game font.
```

## 17. Preserve native Flash initialization

**Impact: HIGH**

Preserve native Flash document/root classes, constructors, timeline setup and registration when changing presentation or adding diagnostics. Recompiling apparently equivalent source can change runtime initialization; successful compilation and source similarity are insufficient. Prefer observation from an already working owner or script boundary, and keep summary helpers on `TextAreaModule`. If root instrumentation is unavoidable, isolate it as a reversible experiment, preserve a native baseline, and verify both cold open and a previously working navigation path before relying on its observations. If that path regresses, first remove the instrumentation and compare again. In this project, removing D11 root instrumentation restored tab-switch rendering in D13; that experiment did not resolve the original cold-open issue. Compare exported native and built root code when the root is meant to stay untouched. Guard nullable timeline labels before string operations.

**Incorrect:**

```text
Recompile the document root merely to attach a logger.
```

**Correct:**

```text
Observe a working boundary; compare native and built root bytecode if root changes are necessary.
```

## 18. Verify runtime symbol availability

**Impact: HIGH**

Flash compilation alone does not establish runtime symbol availability. Verify added calls against shipped/native code and inspect the failing boundary. The patched list hit ReferenceError 1065 while scheduling via `flash.utils.setTimeout`; use the native `Timer` class pattern with explicit listener cleanup and a one-shot repeat count, then verify in game. Do not generalize this incident into a ban on all native package functions.

**Incorrect:**

```text
Treat successful compilation of setTimeout as proof it exists at runtime.
```

**Correct:**

```text
Use the verified native Timer pattern with a one-shot listener and cleanup, then test in game.
```

## 19. Verify callback receipt

**Impact: HIGH**

Verify both ends of Flash-to-WitcherScript callbacks. A return from `dispatchEvent` confirms dispatch, not execution by the engine. Require a receiver-side acknowledgement during diagnostics; do not assume an added ordinary method is registered as a callable UI event. Prefer a verified native event with an isolated prefixed marker when bridging custom readiness signals.

**Incorrect:**

```text
Treat dispatchEvent returning as proof WitcherScript received the event.
```

**Correct:**

```text
Verify the registered receiver and obtain a receiver-side acknowledgement.
```

## 20. Inspect static initialization

**Impact: HIGH**

When recompiling exported Flash classes, inspect script/static initializers as well as instance methods. Exported AS can omit imports used by statements outside the package/class. Preserve their native qualified symbol bindings and check compiled bytecode before cooking; a logger's instance-level try/catch cannot catch failures that precede its construction. D24's exported `CoreComponent` retained `Extensions.enabled` / `noInvisibleAdvance` but omitted `import scaleform.gfx.Extensions`, producing an unresolved initializer lookup and breaking the whole Glossary. Do not merely check that diagnostic strings exist in the artifact.

**Incorrect:**

```text
Check only instance methods and logger strings in exported AS.
```

**Correct:**

```text
Inspect script initializers, qualified Extensions bindings and compiled bytecode before cooking.
```

## References

Reference: [CDPR language guide](https://cdprojektred.atlassian.net/wiki/spaces/W3REDkit/pages/36307090/WS+Language+Guide), [CDPR annotations](https://cdprojektred.atlassian.net/wiki/spaces/W3REDkit/pages/36241598/WS+Script+Compilation+Errors+overrides), and installed `content/content0/scripts`.
