# Goose production toolchain integration contract

**Owner requirement:** The project-specialized harness must genuinely interoperate with the user's installed **Godot Editor**, **Godot runtime/headless CLI**, **Blender**, **ComfyUI**, asset manifests/import pipeline, original audio/SFX workflow, Git, QA and relevant supporting tools. A recipe that merely describes these applications is **not an integration**.

**Local project workspace:** `/mnt/workdrive/playtime-protocol-godot-comfy-blender` (owner-supplied, root/remote to be verified).
**Canonical GitHub destination:** `https://github.com/Rolaand-Jayz/PPIO.git`, branch `main`.

## Governing constraints
Read [contributors](../../CONTRIBUTING.md), [resilience rules](../governance/04_CONTRIBUTOR_AND_RESILIENCE_RULES.md), [resource safety](02_RESOURCE_SAFETY.md), and [post-slice optimization](05_POST_SLICE_GOOSE_OPTIMIZATION.md). Inspect locally installed versions, executable paths, schemas, and current working adapters before selecting any extension/skill or editing editor settings. Local modifications must be project-scoped, reversible, traceable and non-destructive. Don't assume cloud model APIs or new tools are free.

## 1. Godot Editor — real editor and runtime
- Verify editor executable and actual project.godot location. Prefer supported Godot 4.7.2 commands and inspect current project code; do not create a second project as a workaround.
- Support **both** batch/headless tests and *actual editor project inspection* (scene graph, scripts, imported assets, animation tracks, InputMap, audio buses, resources, runtime/debug issues). An editor MCP/remote interface is optional if verified secure and compatible; shell/file/native Godot methods can suffice when they provide the same reliable results.
- Treat live unsaved scenes as user work. Never overwrite scene/resource files being edited by the user, create import loops or invalid UIDs. Check editor state and coordinate file-write ownership.
- Acceptance: edit a harmless test scene/resource (or worktree copy), perform headless import/parse test, verify runtime references, and demonstrate an editor-inspectable result without touching the user's active editor state.

## 2. Blender — geometry, rigs, animation
- Verify Blender version, headless Python API, add-ons and current `tools/blender_process.py` implementation. Use installed real toolchain, no unreviewed package upgrades.
- Support inspect/edit/export of meshes, materials, scale, pivots, skeletons, skin weights, sockets, animation clips, procedural wheel/hover/exoskeleton mechanisms, FBX/glTF limitations and QA renders where safe. Retain editable `.blend` source and versioned GLB.
- Support Godot import checks of rig names, animation timings, scale, sockets and material paths. Avoid GPU rendering when user active; lightweight CPU/headless tests only when safe.
- Acceptance: take a small noncanonical rig fixture through source Blender → `.glb` → Godot animation playback/import with provenance and no broken scene reference. Do not pretend a Blender render alone proves game integration.

## 3. ComfyUI — already-built guarded workflows
- Reuse existing `tools/comfy.py` and five API-format graphs, installed model library, launcher, guard and logs rather than installing a second ComfyUI or duplicating models.
- Validate API endpoint/version, typed input overrides, submit/history/result/download, bounded cancellation, provenance, idempotent workflow version hashes and shared image/mesh output handling. Existing package components do not imply a successful run.
- Preserve DynamicVRAM enabled and the documented safer launch policy; active-user idle gate and one heavy job at a time. A real prompt-to-asset test must be separately authorized or occur under the established idle policy. On GPU failure, pivot to Blender/Godot tools.
- Acceptance: demonstrate harmless API health check, validated workflow API JSON and idempotent ledger/cancel handling without a live heavy job; **later** one guarded successful small job and resource recovery, without claiming this already happened.

## 4. Original sound, audio and music
- Support rights-cleared/procedural source creation, analysis of format/peak/loop metadata, conversion, manifest/provenance, Godot `AudioStream` import, bus routing, event synchronization and testable volume/mute settings. No compulsory paid sound generator or copyrighted samples.
- Acceptance: original short cue + loop test fixture successfully imported and triggered in Godot with controller menu audio state and documented listening test requirement.

## 5. QA, Git and broader supporting systems
- Add only tools that reduce real friction: targeted script/scene parse tests, deterministic battle regression, project-provenance search, geometry/animation contract checks, input/audio test harness, asset manifest validation, rights/secret checks and Git branch/worktree operations.
- Preserve user's repo history; inspect Git remote/branch before push. Never force-push or blindly upload source material while the repo may still be public.
- Optional editor MCP, ComfyUI MCP, Blender MCP, visual screenshot comparison, audio QC, project context index, task status app: individually evaluate for correct version/permission, security, overhead and measurable value. Don't install everything by default.
- Acceptance: one cross-tool project recipe follows an actual owned fixture through Godot/Blender/ComfyUI-independent stages, records PASS/FAIL and artifacts, emits a checkpoint, and leaves the workstation responsive.

## 6. Integration isolation and safety
- Use separate safe adapter processes, scoped API credentials, loopback-only ports and timeouts, not giant always-on extension collections. Gate heavy runs and avoid duplicate listeners, competing GPU models and simultaneous scene edits.
- One agent has write ownership for a scene/asset/output during each phase; reviewers may inspect read-only. Prior state can be restored; assets remain interchangeable without modifying battle authority.
- On disconnection, unsupported extension or API break: preserve output and switch to supported file/API/script interface, or checkpoint and continue independent work. No destructive reset or blanket tool install.

## Definition of done — after combat slice
Goose can open/inspect **the actual Godot project**, modify/test a non-destructive fixture, build/inspect a rig in **Blender**, invoke or safely gate existing **ComfyUI** workflows, integrate and validate **original audio**, run a cross-tool import check, issue a source-provenance report and checkpoint its state. All relevant integrations are tested in the installed environment, not just enumerated in documentation. No unapproved costs, system interference or data loss.
