# Contributing to Playtime Protocol: Innocence Lost

**Scope:** All human and AI contributions to this monorepo, including Goose Desktop. This repository is the authoritative destination for story, combat, systems, art, tools, assets and governance. The owner-supplied local project folder is `/mnt/workdrive/playtime-protocol-godot-comfy-blender`, but its actual Git root/remote must be verified before integration into `https://github.com/Rolaand-Jayz/PPIO.git` (`main`).

## Required reading
- [Repository entry and authority](docs/00_START_HERE.md) and [agent contract](AGENTS.md).
- [Contributor/resilience laws](docs/governance/04_CONTRIBUTOR_AND_RESILIENCE_RULES.md) and [current-slice transition](docs/governance/05_VERTICAL_SLICE_TRANSITION.md).
- [Story canon](docs/story/01_STORY_CANON.md), [character bible](docs/story/02_CHARACTER_BIBLE.md), [arcs](docs/story/03_CHARACTER_AND_RELATIONSHIP_ARCS.md), [toy POV](docs/story/04_POV_AND_SCENE_STANDARD.md), [geography](docs/story/05_TIMELINE_AND_GEOGRAPHY.md).
- [Combat/gameplay](docs/design/01_GAMEPLAY_CONTRACT.md), [campaign scope and pacing](docs/design/06_CAMPAIGN_SCOPE_AND_PACING_FRAMEWORK.md), and [toolchain integration](docs/production/06_TOOLCHAIN_INTEGRATION_CONTRACT.md).
- [Approval/locking](docs/governance/03_APPROVAL_AND_LOCKING_STANDARD.md), [resource safety](docs/production/02_RESOURCE_SAFETY.md), [living decisions](docs/governance/01_LIVING_CONTINUITY_AND_DECISIONS.md) and [source changelog](docs/governance/02_SOURCE_CHANGE_LOG.md).

## Three ordered laws — no exceptions through lower-priority rules
**R1 — Be non-destructive and follow established repository rules.** Preserve history, approved canon, verified work, asset provenance and existing integrations. Protect secrets, privacy, licenses and local working-tree state. Never erase or silently replace work.

**R2 — Do not crash the system or interfere with the user.** User activity has precedence over automation throughput. Respect active/idle and resource gates; throttle, cancel gracefully or pivot to safe work. Monitoring is not a guaranteed memory cap.

**R3 — Get the authorized goal done.** Solve blockers with safe alternatives; do not abandon work at the first failure. Continue independently executable tasks and retain durable checkpoints. A genuine authorization or safety blockade means **checkpoint and yield**, not infinite retries, hidden polling or overriding R1/R2. Resume when an allowed path exists.

See the [operational fallback ladder](docs/governance/04_CONTRIBUTOR_AND_RESILIENCE_RULES.md).

## Project invariants
**Narrative:** Character names, relationships, toy-only observation of CJ, physical geography, chronology, knowledge and relationship residue are governed by higher-authority source files. An unapproved enemy or heirloom model, section concept or test scene does not become canon.

**Gameplay:** Preserve the existing deterministic combat state machine and rules unless an approved decision changes them. Record effects of any combat change on action ordering, targeting, timing, hit windows, controller input, UI, rigging, animation, VFX/SFX, audio and save/replay. Gameplay events are authoritative, not animation frames or effects.

**Complete game scope:** Each proposed campaign section must account for actual traversal, encounters, encounter duration, narrative beats, party availability, exploration, puzzles, backtracking, audio, assets and replay. Follow the [planning and measurement framework](docs/design/06_CAMPAIGN_SCOPE_AND_PACING_FRAMEWORK.md). **No canonical minute-count, campaign length, combat density or pacing number exists yet.** Mark them `TBD — owner approval`, not guesses. A separately proposed 8–12-hour isometric RPG is NOT this game's budget.

**Distinctive design / anti-sameness:** Every important character, enemy, environment, UI, animation, audio or encounter submission must pass [the originality and quality gates](docs/design/07_DISTINCTIVE_DESIGN_AND_QUALITY_GATES.md) with an [identity/contrast review](docs/production/templates/ASSET_IDENTITY_AND_QUALITY_REVIEW.md). Color changes, surface decoration and generic AI superlatives cannot establish originality. Compare silhouettes and physical mechanisms, movement/combat interactions, audio/material signatures and story-specific use against existing designs. Technical defects and copy-paste gameplay can be rejected regardless of render attractiveness. **Owner accepts concept direction; agents do not self-certify final originality.**

**Production quality:** Keep source, reproducible exports, versioned rigs/clips/sockets, licenses, Godot imports, unit/headless validation, coherent presentation and controller-first UI. Keep non-final test artwork marked as provisional, but do not excuse broken integration.

**Tools:** Integrations must respect the actual installed Godot Editor, Blender, ComfyUI, audio pipeline and Git/QA tools. Avoid multiple editors mutating the same unsaved scene, duplicate ComfyUI servers, unnecessary MCP extensions or unbounded GPU jobs.

## Required change record
Before a substantive change: identify owner/feature, authority, existing behavior, scope, dependencies, acceptance criteria, safe rollback and whether a higher-authority decision is required. During the change: use small atomic edits, targeted tests and preserved backups. Afterward: report exact files, commands, test outcomes, regression risks, authorizations, and append meaningful decision/provenance entries. Distinguish VERIFIED, PROPOSED, NOT TESTED, BLOCKED and OWNER-APPROVED.

Prohibited absent explicit informed approval: force-push, hard reset, destructive clean, broad deletion, breaking stable APIs without migration, reinitializing Git, replacing established canon, copying copyrighted source, posting secrets, publishing private assets, global privileged installs or paid actions.

## Acceptance and safe transition
- No new critical failures in deterministic combat, Godot scene/import health, controller focus, rig/animation event timing, audio routing or source-provenance checks relevant to the changed code.
- A new area/section requires a filled scope/pacing record; proposed numbers do not become binding until owner approval.
- **Grandfather the ongoing combat slice.** The current OMP/Goose implementation is prior work to preserve. Apply the new rules at its next safe checkpoint through [a non-destructive mapping and adaptation process](docs/governance/05_VERTICAL_SLICE_TRANSITION.md). Do not demand rebuilding the slice, moving every directory or retroactively invalidating progress for missing paperwork.
- A feature passes only after relevant tests actually run and human visual/controller/audio approval where required. A known untested step is NOT TESTED, not PASSED.

## Lightweight enforcement
The repository includes a **non-GPU governance check** for required documents and relative links, plus a PR checklist. It cannot prove code quality, story coherence or real-device behavior. Review and branch protection are configured separately by the owner; do not claim CI enforces approvals unless settings and required checks are verified.

**Sequencing:** These contributor rules apply immediately at a safe checkpoint, without interrupting or resetting the present combat slice. Finish the combat slice first. Goose's post-slice tool/skills/recipes/resilience specialization remains a separate, deferred owner-invoked assignment. These rules are available immediately without triggering that task.
