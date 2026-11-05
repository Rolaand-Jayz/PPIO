# Goose takeover and migration into PPIO

## Provenance and status
The **local** Goose handoff (2026-11-04) attested via on-disk file checks to:
- Godot 4.7.2 combat prototype, deterministic battle rules, scenes, smoke tests, asset manifest schema — runnable locally.
- `tools/comfy.py`, `tools/blender_process.py`, five ComfyUI API workflows and installed referenced models; 6.9 GB SDXL cache copy ready.
- OMP stopped cleanly at ~21:07, no pending calls and no ComfyUI process listening on 8188.
- Goose added `tools/resmon.sh`, `tools/comfy_start.sh`, `ops/HANDOFF-2026-11-04.md` in its local working tree; its `loginctl IdleHint` check reported ACTIVE.
- Generation pipeline not yet exercised; stability issue not resolved.

**These are supplied handoff findings, not independent GitHub verification.** Do not mark them as committed to PPIO until a diff/file inspection and test are recorded.

## Migration — perform, do not recreate
1. Locate Goose's local working tree; inspect Git remotes, staged/untracked files and any existing commits; make a lossless backup/branch before changes.
2. Read local project README, handoff and OMP freeze forensics; map its root to PPIO monorepo layout. **Do not move files merely to match a diagram if it breaks imports.** Maintain paths until tests confirm relocation.
3. Check license/rights/private data before pushing to the still-public PPIO. Keep model weights, caches, generated large files, local logs, secrets and identifying data out.
4. Import executable Godot scenes, scripts, tests and asset schemas; import existing ComfyUI JSON graphs, adapters and Blender scripts unchanged at first. Record per-path provenance.
5. Run **headless/static** Godot and Python smoke tests without triggering GPU workloads; compare outcomes to local baseline.
6. Bring Goose resource monitor and launcher into version control after reviewing for local hardcoded paths and private information. Verify they protect actual jobs, not just startup.
7. Add provenance and correct dependency versions; only then integrate pipeline end-to-end, one small run at a time under safe authorization.
8. Record original/new paths, source commit/manifest hashes, what was *reused* versus newly implemented, tests, and rollback procedure.

## Pending tasks, no forced rework
- Safe ComfyUI API start/health check.
- One monitored low-memory SDXL execution when user idle or explicitly approved.
- Verify GPU memory release and failure cancellation.
- Then Blender and Godot integration/asset QA.
- Reconcile existing local story guideline documents if they are more recent or have explicit approvals not captured here.

**If local files conflict with this GitHub scaffold**, preserve both states; identify the authoritative approval or test before merging. PPIO is the destination canonical monorepo; the local implementation remains the source of verified code until migrated.

## Addendum — Goose's later 2026-11-04 report

Goose reported completion of: (1) `tools/comfy_guard.sh` per-job monitoring/interrupt logic; (2) five-run DynamicVRAM evidence and correction, preserved locally at `ops/DYNAMICVRAM-EVIDENCE.md`; (3) a TTR-style local `ops/DECISIONS.md` and append-only `ops/CHANGELOG.md`; plus preservation of OMP's original forensic report. The newest report stated user ACTIVE and **no actual ComfyUI generation yet completed**. The local scripts/logs remain **reported, not imported or independently verified in GitHub**.

**Required destination:** `https://github.com/Rolaand-Jayz/PPIO.git`, `main`. Start with [the explicit Goose repository handoff](04_GOOSE_REPO_HANDOFF.md) and `.goosehints` (loaded when the Goose working directory is inside the correct checkout). Reconcile rather than blindly replacing local governance files. Don't assume the local working directory and GitHub repository are currently the same. Stage safe code/doc imports only after checking public-repository privacy and source licensing.
