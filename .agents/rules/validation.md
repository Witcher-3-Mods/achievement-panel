---
title: Validation and safe deployment
impact: HIGH
tags: validation, packaging, deployment
---

# Validation and safe deployment

## Table of Contents

1. [Start with a working control](#1-start-with-a-working-control)
2. [Make experiments discriminate](#2-make-experiments-discriminate)
3. [Reassess uninformative experiments](#3-reassess-uninformative-experiments)
4. [Prioritize the requested outcome](#4-prioritize-the-requested-outcome)
5. [Validate the whole lifecycle](#5-validate-the-whole-lifecycle)
6. [Respect the chosen verification workflow](#6-respect-the-chosen-verification-workflow)
7. [Trace production behavior](#7-trace-production-behavior)
8. [Review edge cases at the owning boundary](#8-review-edge-cases-at-the-owning-boundary)
9. [Cover readout disagreement](#9-cover-readout-disagreement)
10. [Separate build readiness from runtime proof](#10-separate-build-readiness-from-runtime-proof)
11. [Bound temporary diagnostics](#11-bound-temporary-diagnostics)
12. [Validate the observer's scope](#12-validate-the-observers-scope)
13. [Sample asynchronous state freshly](#13-sample-asynchronous-state-freshly)
14. [Fix the actual mod failure](#14-fix-the-actual-mod-failure)
15. [Remove obsolete active implementations](#15-remove-obsolete-active-implementations)
16. [Verify authorized deployment targets](#16-verify-authorized-deployment-targets)
17. [Keep external actions separately authorized](#17-keep-external-actions-separately-authorized)
18. [Respect documentation edit scope](#18-respect-documentation-edit-scope)
19. [State verification limits](#19-state-verification-limits)
20. [Verify actual release inputs](#20-verify-actual-release-inputs)
21. [Cross-check public claims against authoritative evidence](#21-cross-check-public-claims-against-authoritative-evidence)
22. [Make audit coverage explicit](#22-make-audit-coverage-explicit)
23. [Review semantic consistency beyond one incident](#23-review-semantic-consistency-beyond-one-incident)

## 1. Start with a working control

**Impact: HIGH**

Start with the smallest reproducible failure and a known-working control. Compare their architecture and lifecycle before adding instrumentation, especially when an older implementation or native sibling already works. Treat that control as evidence to examine early, not only as a final regression check.

**Incorrect:**

```text
Add more logging before looking at the older working panel.
```

**Correct:**

```text
Compare the failing path with the known-working native or previous implementation first.
```

## 2. Make experiments discriminate

**Impact: HIGH**

For each experiment, state the hypothesis, the observation that would distinguish it from alternatives, and the next decision for either outcome. Prefer the cheapest test that can change the decision. Change one relevant variable at a time where practical; more logs or repeated rebuilds are not progress unless they resolve uncertainty.

**Incorrect:**

```text
Rebuild with extra logs without specifying what the result would change.
```

**Correct:**

```text
State a hypothesis, distinguishing observation and decision for either outcome.
```

## 3. Reassess uninformative experiments

**Impact: HIGH**

After two consecutive experiments that reveal no new distinguishing evidence, pause that line of investigation and reassess the initial design. Summarize established facts, rejected hypotheses, remaining unknowns and alternatives, including reuse of a working native path. Explain the expected information gain and time/build cost before continuing. Do not repeat an equivalent experiment unless a changed condition or new evidence makes its result informative.

**Incorrect:**

```text
Repeat equivalent rebuilds after two experiments reveal nothing new.
```

**Correct:**

```text
Summarize known facts and compare alternative architectures before another experiment.
```

## 4. Prioritize the requested outcome

**Impact: HIGH**

Distinguish the user's requested outcome from a complete explanation of inaccessible engine internals. When a supported, lower-risk design can satisfy the request, present it early rather than making exhaustive root-cause research a prerequisite. Stay within the authorized scope; an explicit root-cause investigation may still require deeper research.

**Incorrect:**

```text
Require a complete explanation of inaccessible engine internals before offering a supported native path.
```

**Correct:**

```text
Offer a lower-risk supported solution early; continue deeper investigation when requested.
```

## 5. Validate the whole lifecycle

**Impact: HIGH**

Verify a lifecycle change across cold start, repeated opening, warm transitions, native/custom context switching and teardown or cancellation where applicable. Separate observed failure boundaries from suspected internal causes. A successful architectural change establishes that the tested path works, not the exact defect in the replaced path.

**Incorrect:**

```text
Test only a warm tab switch and claim cold startup is fixed.
```

**Correct:**

```text
Test cold open, reopen, native/custom transitions and cancellation; distinguish observation from hypothesis.
```

## 6. Respect the chosen verification workflow

**Impact: HIGH**

The user removed the automated test suite. Do not add test files, fixtures or CI/skill test stages unless requested. Verify changes through these rules, direct source/artifact inspection and relevant in-game observations. Keep production safeguards such as validated paths, package allowlists, byte integrity and release-tag verification; removing tests does not authorize removing those safeguards.

**Incorrect:**

```text
Recreate src/tests or add a regression stage after the user requested its removal.
```

**Correct:**

```text
Review the changed production boundary and report the actual evidence without introducing a new suite.
```

## 7. Trace production behavior

**Impact: HIGH**

Review the actual production code and its callers, not a handwritten copy of its algorithm. Distinguish source-level reasoning, compiled artifact inspection and observed game behavior; none alone establishes every other layer.

**Incorrect:**

```text
Describe a model of an algorithm as proof of production behavior.
```

**Correct:**

```text
Trace the real implementation and name any runtime assumptions not directly observed.
```

## 8. Review edge cases at the owning boundary

**Impact: HIGH**

Review namespaces, module boundaries, duplicate declarations, catalogue mappings and known compiler failures. Trace empty, single and multiple entries, malformed values, repeated calls and reordered events in the production implementation, rather than narrowing the review to one reported account or row.

**Incorrect:**

```text
Review only the successful path for the reported item.
```

**Correct:**

```text
Inspect failure branches, bounds and lifecycle ordering in the code that owns the behavior.
```

## 9. Cover readout disagreement

**Impact: HIGH**

Review the readout's handling of agreeing, inverted, missing, conflicting, constant and newly earned inputs, including accounts unrelated to development. Trace earned status with a reset counter and low difficulty.

**Incorrect:**

```text
Test only the developer account's current counters.
```

**Correct:**

```text
Cover inverted, missing, conflicting and constant reads plus newly earned and reset counters.
```

## 10. Separate build readiness from runtime proof

**Impact: HIGH**

Distinguish implementation/build readiness from confirmed runtime resolution. Announce readiness as specified by implement; confirm a UI fix only after observing it in the game. Static inspection and Script Studio are supporting tools, not proof of game-runtime compatibility.

**Incorrect:**

```text
Call a UI fix confirmed because Script Studio reports no errors.
```

**Correct:**

```text
Report build readiness and await an actual game test for runtime confirmation.
```

## 11. Bound temporary diagnostics

**Impact: HIGH**

When comparison with a working control leaves an actionable hypothesis that requires instrumentation, observe the actual data/lifecycle boundary with bounded, temporary diagnostics. Follow the reassessment checkpoint above; do not expand instrumentation indefinitely or substitute speculative retries for evidence. Identify diagnostic builds, avoid personal data or gameplay writes, clean up listeners/UI, and remove probes before release after evidence is captured.

**Incorrect:**

```text
Keep adding probes indefinitely or ship diagnostic listeners.
```

**Correct:**

```text
Instrument a discriminating boundary, capture evidence and remove release probes.
```

## 12. Validate the observer's scope

**Impact: HIGH**

Validate each diagnostic against a known-working state and state its scope. A parent's display tree, application domain or error listener may not cover a child movie: absence there is not proof that the child failed to load or construct. Correlate with the child's engine handle, configuration and data-delivery acknowledgements. D13 rendered 79 rows while the parent still reported `journal=0` and no journal class; those parent probes cannot distinguish success from failure on their own.

**Incorrect:**

```text
Infer a child failed because the parent's domain cannot see its class.
```

**Correct:**

```text
Correlate a known-working child with its engine handle and receiver acknowledgements.
```

## 13. Sample asynchronous state freshly

**Impact: HIGH**

For asynchronous navigation, label immediate observations as such and take fresh bounded samples after every relevant transition. Do not treat the previous child returned immediately after a request, or a stopped timer's last snapshot, as the final state. Keep overlays non-interactive and make underlying UI inspectable; retain useful diagnostics without introducing a new failure or hiding the result being investigated.

**Incorrect:**

```text
Read the previous child immediately after navigation and call it final.
```

**Correct:**

```text
Label the immediate sample and take fresh bounded observations after the transition.
```

## 14. Fix the actual mod failure

**Impact: HIGH**

Capture the full diagnostic. Fix errors in the mod first; do not rewrite vanilla scripts merely because the compiler also reports unrelated warnings.

**Incorrect:**

```text
Rewrite vanilla scripts because unrelated warnings appear beside a mod error.
```

**Correct:**

```text
Capture the full error and correct the failing mod-owned boundary.
```

## 15. Remove obsolete active implementations

**Impact: HIGH**

When replacing a monolith with multiple files, remove the obsolete active script from the package. Never leave two active versions or backups inside `mods`.

**Incorrect:**

```text
Ship a backup .ws beside its replacement.
```

**Correct:**

```text
Keep one active implementation and backups outside the game's mods directory.
```

## 16. Verify authorized deployment targets

**Impact: HIGH**

Before authorized deployment, verify the current files have not changed, back them up outside `mods`, and verify backup and installed hashes. Use validated exact paths; do not erase broad directories or stop the game without permission.

**Incorrect:**

```text
Recursively overwrite a computed mods path without checking it.
```

**Correct:**

```text
Resolve exact targets, verify current files, back up outside mods and compare hashes.
```

## 17. Keep external actions separately authorized

**Impact: HIGH**

Repository changes do not automatically authorize game deployment, commits or publication.

**Incorrect:**

```text
Commit or install because repository edits were requested.
```

**Correct:**

```text
Leave edits local unless commit, deployment or publication is authorized.
```

## 18. Respect documentation edit scope

**Impact: HIGH**

Do not add, remove or change README.md content without an explicit user request to edit README.md. Report development status, diagnostics and verification in the conversation instead. When README.md edits are explicitly requested, keep it compact. Maintain the four rule categories linked by AGENTS.md rather than adding one file per incident. Reading README.md and other public documentation is required when verifying their claims; the editing restriction is not a reading restriction.

**Incorrect:**

```text
Change README during a read-only audit, or skip reading it because edits are forbidden.
```

**Correct:**

```text
Read README as audit evidence; request explicit authorization before changing its content.
```

## 19. State verification limits

**Impact: HIGH**

A successful source or package integrity check is not an engine compile, an in-game restart observation, a legal clearance or a security guarantee. Report those limits explicitly.

**Incorrect:**

```text
Describe a static PASS as proof of legal clearance or game compatibility.
```

**Correct:**

```text
Report exactly which checks passed and which runtime, provenance or legal checks remain open.
```

## 20. Verify actual release inputs

**Impact: HIGH**

Release automation packages the committed, locally cooked mod; GitHub runners do not rebuild proprietary REDkit assets. Verify package inputs and notices before publication. Resolve the actual remote release tag to its commit, peeling annotated tags, and compare it with the packaged commit SHA the workflow tagged. Release metadata such as target_commitish is not evidence of an existing tag's target. Reject mismatches without moving tags; recheck before upload/publication. Remote tag protections are still needed against privileged concurrent or later changes.

**Incorrect:**

```text
Assume GitHub runners rebuild locally cooked REDkit resources.
```

**Correct:**

```text
Inspect the committed cooked package and included notices used by release automation.
```

## 21. Cross-check public claims against authoritative evidence

**Impact: HIGH**

During an audit, enumerate material claims in README, license sections, badges, metadata, install instructions and release workflows. Compare each with the applicable authority and actual artifact: license text for granted rights, production code for behavior, package contents for shipped paths, and release inputs for version/integrity claims. Record claim, source location, authority/evidence, result and owner. Cover both directions: declared guarantees must be supported, and material restrictions or prerequisites must not be concealed by a broader public claim. Do not assume two matching license copies establish documentation consistency.

**Incorrect:**

```text
README grants commercial redistribution; both LICENSE copies prohibit it; conclude PASS because their hashes match.
```

**Correct:**

```text
Report the contradiction with both locations and check usage, modification, redistribution, commercial use, notices and third-party scope separately.
```

## 22. Make audit coverage explicit

**Impact: HIGH**

Classify checked claims as supported, contradicted, unverified or not applicable. A confirmed contradiction is a finding, not an uncertainty. Missing evidence is unverified only for the affected claim; describe the missing evidence and why it matters. No contradiction or unexamined required surface may disappear into a global PASS. Record revision, dirty/untracked inputs and package identity; invalidate affected conclusions when those inputs change.

**Incorrect:**

```text
Report licenses PASS without reading the documentation, or apply yesterday's review to a changed package.
```

**Correct:**

```text
List the checked surfaces, their evidence and any excluded or changed inputs before consolidating the result.
```

## 23. Review semantic consistency beyond one incident

**Impact: HIGH**

Compare public declarations with actual authorities across independent dimensions: license identity and rights, package paths, persistence, versions and release identity. Review all material declarations, not only the first matching label or a known keyword. A second conflicting statement is still a finding; unfamiliar wording requires interpretation from evidence rather than a silent pass.

**Incorrect:**

```text
Search only for MIT or accept matching license-file hashes as proof that README and the package agree.
```

**Correct:**

```text
Compare each material claim with the applicable clause, production implementation or exact distributed artifact and explain any discrepancy.
```

## References

Reference: [CDPR script-mod tutorial](https://cdprojektred.atlassian.net/wiki/spaces/W3REDkit/pages/36241465/WS+Create+your+first+script+mod), [Script Studio](https://cdprojektred.atlassian.net/wiki/spaces/W3REDkit/pages/36864027/WS+Script+Studio+basics), installed game sources and verified Steam status.
