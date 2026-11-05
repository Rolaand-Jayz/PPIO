# Agent operating contract — PPIO

**Canonical monorepo: `https://github.com/Rolaand-Jayz/PPIO.git`, branch `main`.** Goose must work in that Git tree, not `Shadow-library`, `PPIO`'s archival website branch, or another local repository. At session start check root, status and remote; if the local Godot tree belongs elsewhere, preserve it and import deliberately. Read `.goosehints` and `docs/production/04_GOOSE_REPO_HANDOFF.md`.

**Mandatory contributor authority:** Read `CONTRIBUTING.md`, `docs/governance/04_CONTRIBUTOR_AND_RESILIENCE_RULES.md`, and `docs/design/07_DISTINCTIVE_DESIGN_AND_QUALITY_GATES.md`. R1: preserve work and obey repo rules. R2: do not crash or interfere with the user. R3: pursue the authorized goal using safe reversible alternatives, checkpoints and meaningful recovery. Higher laws override lower laws. Originality requires observable design evidence and owner review, never just adjectives.

Read `docs/00_START_HERE.md` and the relevant canonical docs before changes. Goose Desktop is the primary implementation agent. This repository's Git history, verified files, and written decisions outrank assumptions from chat summaries or old OMP logs.

1. **Do not restart the project.** Inspect local work, file hashes, manifests, Git state, successful tests and any OMP/Goose handoff before editing. Import completed Godot and ComfyUI work incrementally; do not overwrite working files.
2. **Never silently change canon.** Story/geography/character changes require an explicit approval entry. Concept drafts, website copy, proxies, and test vignettes are not canon.
3. **Respect source hierarchy:** story invariants and approved decisions → character/arc/geography ledgers → narrative/visual/gameplay specifications → production operations → implementation notes and prototypes.
4. **Test efficiently.** First do read-only inspection; then targeted static validation; only then a single representative GPU-intensive job when safe and authorized. Avoid expensive repeated scans, builds and duplicate model downloads.
5. **Protect desktop responsiveness.** Before and during GPU work consult `docs/production/02_RESOURCE_SAFETY.md`. No additional GPU job while the user is active without permission. No unbounded retries or simultaneous model loads.
6. **Constrain tooling.** Preserve the verified ComfyUI startup args. Verify installed CLI flags. Do not blindly toggle DynamicVRAM, pinned memory, smart memory, ROCm or PyTorch versions. Avoid running another server on port 8188.
7. **Evidence over declaration.** Report status as verified, reported-but-unverified, blocked, or proposal. A generated file is not accepted until validation and relevant approval.
8. **Keep project sources portable.** Godot 4.7.2, GDScript initially, Linux/AMD first, glTF 2.0/`.glb` for 3D handoff; preserve Blender source, workflows, seeds, settings, license provenance and reliable import metadata.
9. **Keep secrets and bulky artifacts out of Git.** Models, giant generated files, credentials, personal data, raw crash dumps and local system logs must not be committed by default. Use artifact stores or Git LFS only after approval and sizing.
10. **Update ledgers on meaningful decisions.** Consult `docs/governance/03_APPROVAL_AND_LOCKING_STANDARD.md` and append to `docs/governance/02_SOURCE_CHANGE_LOG.md`; never rewrite history to conceal a changed decision.

The previously hosted website is archived only. Do not restore public Pages or add new site files to `main` without approval.

**Live-job safety update:** Goose reports `tools/comfy_guard.sh` now exists locally; its no-job and error paths were checked but not its live interrupt under GPU pressure. See the reconciled five-run memory evidence in `docs/production/02_RESOURCE_SAFETY.md`. Neither resource monitoring nor the current ComfyUI flags guarantee freeze prevention.

**Current priority — combat test slice:** Read `docs/design/03_COMBAT_TEST_SLICE.md` and `docs/design/04_CONTROLLER_HUD_UI_AUDIO.md` before working on the combat feature. Controller is the primary input: the current test is an Xbox-style gamepad, mouse+keyboard are secondary but fully supported, Steam Controller compatibility is later. Full gamepad HUD/UI navigation and integrated **original music, SFX, UI sound and bus mixing** are mandatory. Do not defer sound as cosmetic work. FF7 Rebirth is a UX reference only, not a license to reproduce audio/UI or silently replace battle rules.

**Owner-confirmed local source location:** `/mnt/workdrive/playtime-protocol-godot-comfy-blender` (verify its Git remote, do not presume it is already the PPIO checkout). **Deferred task:** AFTER the combat slice is genuinely completed, follow `docs/production/05_POST_SLICE_GOOSE_OPTIMIZATION.md` to audit and specialize Goose itself. This is not permission to run both programs at once. Contributor safety/quality/process rules are now established; **numeric** campaign duration, section sizing, combat frequency and final creative approvals remain pending owner decisions. Only begin post-slice specialization after the owner separately invokes it.
