# Asset factory — Goose / ComfyUI / Blender / Godot

## Existing pipeline and ownership
Goose Desktop is primary implementer. Reuse OMP's already-built local artifacts rather than making new versions for their own sake. As of the November 4 handoff, file-verified **locally by Goose** (not yet in PPIO): `tools/comfy.py` (submit/wait/cancel/upload/overrides), `tools/blender_process.py` (.glb export smoke test), five API-format workflows (SDXL concept work for Kip/Jayze/HUD, Flux2-Klein Kip, Hunyuan3D Kip), model files in shared library, and an existing 6.9 GB contiguous SDXL cache copy. **No ComfyUI generation has yet been run** according to that handoff.

## Pipeline contract
Approved asset spec → locate/reuse existing workflow+inputs → license check → one queued ComfyUI job → bounded execution/monitoring → Blender normalization → package sources+manifest → Godot import → visual and gameplay QA → human review if needed → accept/revise/reject.

Use conventional Blender/Godot scripting whenever it is more reliable than generative models. Do not conflate an image, a usable rigged model and a complete engine asset.

## Workflow families
Character concepts/reference; 3D mesh candidates; modular environment geometry; material/texture sets; rigging/sockets; movement and animation; VFX; UI/icons; legally sourced/original audio; cutscene support; Godot packaging/import. Each asset spec includes a stable ID, canon status (`canon`, `concept_only`, `debug_only`), source references, license, source workflow/model versions and hashes, settings/seed, outputs, dependency hashes, quality gate status and approval.

## Validation gates
G0 brief+commercial-use rights → G1 generated outputs parse → G2 geometry/scale/pivots/materials → G3 rig/animation when applicable → G4 Godot import → G5 gameplay camera/interaction/telegraph → G6 owner aesthetic/canon sign-off for key characters.

### Essential restrictions
- Never assume installed models permit commercial distribution; inspect checkpoint/node/data license.
- Reuse previous approved sources, avoid downloads/duplicate graphs unless essential.
- No unapproved copying of anime characters, TV franchises, licensed music or voices.
- Model and runtime settings chosen only after actual AMD/ROCm capacity and thermal/memory checks.
- No concurrent heavy ComfyUI models or simultaneous local LLM inference.
- Store large models, generated caches, crash dumps and raw outputs outside Git unless an approved storage/LFS plan exists.
- Preserve source files, manifests and successful code; no uncontrolled bulk regeneration.
- The Passage is a noncanonical testing vignette; never move it into story canon without approval.

See [resource safety](02_RESOURCE_SAFETY.md) and [migration](03_HANDOFF_AND_MIGRATION.md).

## Combat slice — sound and interface are deliverables, not later extras
Read [the combat slice build contract](../design/03_COMBAT_TEST_SLICE.md) and [controller/HUD/audio contract](../design/04_CONTROLLER_HUD_UI_AUDIO.md). Supply coherent, source-traceable proxy UI graphics, menu selection feedback, combat SFX and original loopable music with usable game-audio bus controls. A source WAV or static HUD image on disk is NOT accepted until its Godot event/scene binding, input focus, correct playback/mixing and controller operation have been validated. Prefer lightweight deterministic audio synthesis / rights-cleared original sources if ComfyUI is unstable; do not postpone the battle because GPU-based sound creation is unavailable.

## Mandatory rigged/animated asset acceptance
Every combat-test character and enemy must have a character-appropriate working rig (not merely a mesh), editable Blender source, proper bones/part pivots and skinning, required sockets, named combat animations or intentional procedural motion, stable Godot import and runtime animation-state transitions. Validate timing against authoritative combat events, hit/VFX/SFX cues, interrupts and camera readability. Kip is a vehicle rig, Rallo has low-hover motion, Jonnie has mechanical exoskeleton articulation, Jayze is a jointed toy humanoid. See [rig and animation acceptance](../design/05_RIGGING_AND_ANIMATION.md). Do not call an asset complete on Blender-only demonstration.

## Distinctiveness is a separate acceptance gate
Follow [distinctive design and quality gates](../design/07_DISTINCTIVE_DESIGN_AND_QUALITY_GATES.md). Require an [identity/contrast sheet](templates/ASSET_IDENTITY_AND_QUALITY_REVIEW.md) for major character/enemy/area/UI/audio/mechanic families: role, physical constraints, three observable distinctions, internal similarity comparison, actual in-game tests and owner decision. This is not a generic prompt instruction and cannot be satisfied by recolors, more texture detail, identical rigs/movesets, generic particle themes or aesthetic superlatives. Preserve existing working prototypes and iterate safely toward ACCEPTED FOR SLICE; final-canon approval remains distinct. A high-resolution asset that cannot rig/import/animate/read/play correctly is not production-quality.
