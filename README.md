# Playtime Protocol: Innocence Lost

**Canonical project monorepo** — story, gameplay, Godot game, art and sound production, ComfyUI/Blender integration, technical governance, tests and release work.

**Current state (2026-11-04):** This GitHub repository has been repurposed from a public preview website into the project's primary monorepo. The previous six-page site is preserved intact on the Git branch `archive/showcase-2026-11-04`, and has been removed from `main`. This is not a claim that GitHub Pages has been administratively disabled; see the publication note below.

**Goose Desktop:** When working in PPIO, read the root [`.goosehints`](.goosehints) and [Goose repository handoff](docs/production/04_GOOSE_REPO_HANDOFF.md). Goose must verify its working directory and remote before touching existing local OMP artifacts.

Start with [docs/00_START_HERE.md](docs/00_START_HERE.md), then [AGENTS.md](AGENTS.md). This repository is the destination for the already-existing local Godot/ComfyUI work, **not permission to recreate or overwrite that work**.

## Project
A stylized 3D, toy-scale, story-driven JRPG about innocence, consequence, family, trust, sacrifice and the responsibilities that come with growing up. Four playable toy protagonists: Jayze, Kip, Rallo and Captain Crusher (Jonnie). The original 1942-style shoot-'em-up concept is **historical, superseded design**.

## Monorepo layout
- `docs/story/`: narrative canon, character bible, arcs, perspective and geography
- `docs/design/`: gameplay and visual direction
- `docs/production/`: asset factory, system safety, handoff and verified migration
- `docs/governance/`: authority, approval, continuity and change tracking
- `game/`: destination for the existing Godot 4.7.2 project, **not yet imported**
- `production/`: destination for existing ComfyUI workflows, Blender scripts, asset manifests and provenance, **not yet imported**
- `tools/`: destination for OMP's verified scripts and Goose's new safety scripts, **not yet imported**

## Existing local implementation — do not redo it
Goose's 2026-11-04 handoff reports a runnable deterministic Godot combat prototype, smoke tests, an asset manifest, five ComfyUI API workflows and Python/Blender integrations. These remain **local, reported and pending repository verification/import**; the present GitHub tree does not falsely claim to contain them. See [handoff](docs/production/03_HANDOFF_AND_MIGRATION.md).

## Next production deliverable
**Complete combat test slice, controller-first with integrated sound.** See [combat slice build specification](docs/design/03_COMBAT_TEST_SLICE.md) and [gamepad/HUD/UI/music/SFX contract](docs/design/04_CONTROLLER_HUD_UI_AUDIO.md). The available Xbox/XInput-style gamepad is the immediate test target; Steam Controller/Steam Input is an eventual release requirement. Sound and music must actually play in-game. Art may be non-final; implementation must be production-quality.

## Local implementation location
Owner-supplied local source workspace: `/mnt/workdrive/playtime-protocol-godot-comfy-blender`. **Verify its Git root and remote before reconciling with canonical `Rolaand-Jayz/PPIO` on `main`; no assumption of existing synchronization.**

After the playable combat slice is completed, Goose has a separate queued [project-specific harness optimization plan](docs/production/05_POST_SLICE_GOOSE_OPTIMIZATION.md) for skills, recipes, extensions, roles, hooks and context/resource management. This task is deferred until the combat slice is done **and the owner explicitly sends its execution prompt**; it must not interrupt combat implementation.

## Contributor quality and resilience rules
All contributors and agents must follow [CONTRIBUTING.md](CONTRIBUTING.md), the [non-destructive resilience laws](docs/governance/04_CONTRIBUTOR_AND_RESILIENCE_RULES.md), the [distinctive-design quality gates](docs/design/07_DISTINCTIVE_DESIGN_AND_QUALITY_GATES.md), and the [actual Godot/Blender/ComfyUI integration contract](docs/production/06_TOOLCHAIN_INTEGRATION_CONTRACT.md). New major features need distinct physical and mechanical identity, reliable playable integration, honest QA, and owner acceptance. The current combat slice adopts these via [a non-destructive transition](docs/governance/05_VERTICAL_SLICE_TRANSITION.md).

## Production owner
**Goose Desktop** is the designated primary implementation agent. OMP's verified work is prior project work to preserve and reuse. Goose must observe active-user resource headroom and avoid concurrent GPU-heavy jobs.

## Website publication
The six-page preview remains in the `archive/showcase-2026-11-04` Git branch. Its files were removed from the `main` publishing root to stop serving the website after any Pages deployment catches up. **Administratively disable GitHub Pages** under Settings → Pages to fully stop publication. Make this repository private before uploading confidential assets, internal forensics, credentials or nonpublic production materials. Git history and the archive branch remain visible while the repository is public.

## Authority
Recent explicitly approved JRPG decisions override older SHMUP artifacts, concept-site copy, agent-generated hypotheses and speculative vertical slices. See the [authority index](docs/00_START_HERE.md).
