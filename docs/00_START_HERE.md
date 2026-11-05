# Playtime Protocol — documentation authority

This is the operational index for **Playtime Protocol: Innocence Lost**. It deliberately adopts the discipline of *The Twentieth Revision*: explicit source hierarchy, bounded draft freedom, continuity tracking, and append-only provenance. It does **not** reuse that novel's fictional canon.

## Current authority, strongest first
1. Direct, explicit owner-approved decisions and [story canon](story/01_STORY_CANON.md).
2. [Character bible](story/02_CHARACTER_BIBLE.md), [arc ledger](story/03_CHARACTER_AND_RELATIONSHIP_ARCS.md), and [geography/chronology](story/05_TIMELINE_AND_GEOGRAPHY.md). Conflicts require a recorded resolution; don't resolve by recency alone.
3. [POV and narrative standard](story/04_POV_AND_SCENE_STANDARD.md), [gameplay](design/01_GAMEPLAY_CONTRACT.md), [visual direction](design/02_VISUAL_DIRECTION.md), [combat test slice](design/03_COMBAT_TEST_SLICE.md), and [controller-first HUD/UI/audio](design/04_CONTROLLER_HUD_UI_AUDIO.md).
4. [Production pipeline](production/01_ASSET_FACTORY.md), [resource safety](production/02_RESOURCE_SAFETY.md), [local handoff](production/03_HANDOFF_AND_MIGRATION.md), [Goose's canonical repository/acceptance handoff](production/04_GOOSE_REPO_HANDOFF.md), and [DEFERRED post-combat Goose optimization](production/05_POST_SLICE_GOOSE_OPTIMIZATION.md).
5. Working implementations, test proxies, illustrations, old concept-site text, speculative tasks.

## Binding contributor quality and resilience
- [Contributing standard](../CONTRIBUTING.md)
- [Ordered resilience laws R1–R3](governance/04_CONTRIBUTOR_AND_RESILIENCE_RULES.md)
- [Non-destructive current-slice transition](governance/05_VERTICAL_SLICE_TRANSITION.md)
- [Campaign section scope and pacing plan (numbers still unapproved)](design/06_CAMPAIGN_SCOPE_AND_PACING_FRAMEWORK.md)
- [Distinctive design / anti-sameness and quality review](design/07_DISTINCTIVE_DESIGN_AND_QUALITY_GATES.md)
- [Godot Editor, Blender, ComfyUI, audio and QA integration requirements](production/06_TOOLCHAIN_INTEGRATION_CONTRACT.md)

## Governance
- [Acceptance/locking rules](governance/03_APPROVAL_AND_LOCKING_STANDARD.md)
- [Living continuity and decisions](governance/01_LIVING_CONTINUITY_AND_DECISIONS.md)
- [Append-only source change log](governance/02_SOURCE_CHANGE_LOG.md)

## Current playable milestone
A complete production-quality **non-final proxy** combat slice: four party proxies, 2–3 enemy proxies, arena, controller-first HUD/UI, functioning original music and sound effects, full controller-only battle/restart and keyboard/mouse parity. Xbox-style pad now; Steam Controller integration later. Avoid cloning the FF7 Rebirth interface or importing its combat rules without approval. See the two design specifications above.

## Locked vs unresolved
**Established direction:** 3D toy-scale JRPG, Godot 4.7.2/GDScript, four named toys, CJ age 12, newborn twins, toy-limited CJ perspective, outward journey to the alley and return, and the game's growth themes. **Unresolved:** exact playable map graph, chronology, Unknown design, heirloom powers, final art specifications, final combat values and fully validated ComfyUI stability. Do not fill these with convenient inventions.

## Historical distinctions
The original vertically scrolling 1942 SHMUP (sixteen craft, 15 arcade stages, four-year-old twins) is superseded; its older files remain archival material in other locations. The six-page public concept site is preserved in the `archive/showcase-2026-11-04` branch, not a source of current authority. The noncanonical `The Passage` vertical-slice proposal is only a testing vignette until explicitly approved.

## Change workflow
Check canon → identify dependent sources → make minimal changes → test where appropriate → append decision/change entry with provenance → report evidence and unresolved questions. Avoid new parallel documents when an existing canonical file has the proper home.
