---
name: guard
description: Coordinate a read-only audit of this Witcher 3 mod for REDkit compatibility, third-party licensing and security. Use when a mod safety, compliance or pre-release guard review is requested; not for ordinary UI edits.
---

# Guard

Delegate the review to four independent agents. This skill coordinates only; it does not replace their reviews or implement fixes.

## Phase 1 — Scope and snapshot

Identify the requested repository, revision and installable package. Include relevant dirty and untracked files, not just HEAD. Record the revision and hashes of audited inputs so later edits cannot inherit a stale PASS. State the intended use and distribution: local build, public source or installable noncommercial Witcher 3 mod are different scopes. Read AGENTS.md and its rules. Tell the user that four read-only reviews will run.

## Phase 2 — Artifacts and public claims

Inventory shipped resources, source assets, build-only dependencies, packaging and release inputs. Read README and other public documentation, LICENSE, notices, manifests and applicable metadata; a prohibition on editing README does not prohibit auditing it.

Prepare a coverage matrix with one row per material claim: claim and source location, applicable authority or implementation evidence, responsible reviewer, result and limitation. Check both directions: promises need evidence, and restrictions/prerequisites must not be contradicted by broader promises. Include:

- License identity and separate rights to use, modify, redistribute and use commercially; original versus third-party material and prior grants.
- Installation paths, prerequisites, shipped files and versions against the actual package.
- Behavior, persistence and platform support against production code and available runtime evidence.
- Security, authenticity and build/release claims against the actual workflow and artifacts.

Do not fill this matrix from filenames or duplicate-file hashes alone. Pass raw scope and required coverage, not provisional conclusions, to reviewers.

## Phase 3 — Four independent reviews

Read the four task definitions and supply each in full, with the same scope and snapshot, to a separate subagent. Run in batches if concurrency limits require it:

- [REDkit compliance](../../agents/redkit-compliance.md)
- [Licenses and provenance](../../agents/licenses.md)
- [Security](../../agents/security.md)
- [Independent vulnerability, licensing and report review](../../agents/vulnerability-hunter.md)

Give the hunter fresh context containing its instructions and raw artifacts, not other reviewers' findings or assurances. Its first pass independently examines security, licensing and public claims. Each reviewer must return inspected surfaces and evidence, including unavailable checks, rather than a verdict alone.

## Phase 4 — Evidence and applicability gate

Classify each material claim as supported, contradicted, unverified or not applicable, with evidence. A contradiction is a finding even if other checks pass. An unknown affects the specified claim/component; do not turn it into either blanket clearance or a blanket prohibition.

For licensing, use actual texts and primary official sources applicable to the artifact and intended use. Distinguish officially supplied native UI resources used in a noncommercial in-game mod from independently added middleware or standalone SDK redistribution. Record component, provenance, use, applicable clause and any missing evidence. A copyright header, missing standalone vendor agreement or zero price alone establishes neither permission nor a release blocker. Report an actual conflicting restriction when found; do not invent vendor rights or hide residual uncertainty.

## Phase 5 — Independent report cross-check

After the hunter's first pass and the other three reports finish, send those reports to the same hunter. Require a second pass against raw artifacts: scope/snapshot, omitted claims, contradictory conclusions, applicable clauses and unsupported PASS results. Agreement among agents is not evidence. Ask it to challenge semantic gaps that hash equality or keyword presence miss by tracing raw claims to their authorities. Keep security, licensing and report-quality findings separate.

## Phase 6 — Consolidation and handoff

Wait for all four final results, including the hunter's cross-check. Resolve conflicting interpretations against evidence or leave the precise dispute unverified. Check coverage and snapshot freshness before deduplicating findings. Missing agents, missing required surfaces or changed unreviewed inputs make the combined review incomplete. Do not silently waive findings to produce a green result.

Present the combined result in the conversation, with per-agent results and the material claim/evidence gaps. Do not create a separate report file unless requested. Suggest scoped remediation and the affected manual verification scenarios; applying fixes requires separate authorization. The automated test suite was removed by the user: do not create or run a replacement suite. Use rule-based source/artifact review and retain production integrity safeguards.

If delegation is unavailable, report that `guard` could not run. Do not silently perform the specialist audits yourself. Audit instructions do not authorize changes, installation, publication, uploads or execution of untrusted binaries. Ask for direction before any remediation outside an existing implementation request.

## Output

For each agent, include its result (`PASS`, `FINDINGS` or `UNVERIFIED`), concrete findings with paths/lines, checks performed and remaining runtime/legal/security limitations. Include the reviewed snapshot, coverage summary and exact missing evidence. Use `PASS` only for the examined scope with no findings or material unresolved checks; report findings and uncertainties together when both exist. Never equate this technical audit with legal clearance or a guarantee of no vulnerabilities.
