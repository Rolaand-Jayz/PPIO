# Post-combat-slice Goose specialization and optimization

**STATUS: QUEUED — DO NOT EXECUTE WHILE BUILDING THE COMBAT SLICE.**

**Owner-provided local project folder:** `/mnt/workdrive/playtime-protocol-godot-comfy-blender`  
**Canonical GitHub monorepo:** `https://github.com/Rolaand-Jayz/PPIO.git`  
**Canonical Git branch:** `main`

The local path is a working location, **not proof that its current Git remote or root is PPIO**. Before any change, inspect `git rev-parse --show-toplevel`, `git status --short`, `git remote -v`, `git branch -vv`, and last commit. Protect uncommitted local Godot/Blender/ComfyUI code, models, OMP work, Goose work and operational ledgers. Do not force-push, reset, clobber or reinitialize a working tree to make it match a remote.

## Entry condition
Only begin **after the existing combat test slice reaches its recorded completion/QA milestone**: complete controller-first encounter and HUD, four party and 2–3 enemy rigs with real Godot animations, environment, VFX, original music and SFX, victory/defeat/restart, tested integrations, and transparent manual-test limitations. If the owner still needs to test the physical controller or listen to audio, explicitly report WAITING FOR OWNER VALIDATION; do not mislabel untested checks as PASS. This optimization is **the next phase**, not a parallel effort.

## Mission
Goose Desktop will inspect its *actual installed version* and optimize **itself for long-term Playtime Protocol development**, not only combat. Evaluate native features and supported extensions, MCP tools, project skills, custom agents/roles, portable recipes, lifecycle hooks, persistent context, model/provider routing, optional desktop/MCP Apps and process/resource controls. Implement only improvements that have an observable quality, reliability, efficiency or safety benefit.

**Boundaries:** Do not invent or lock global contributor rules, campaign length, section duration, encounter density, combat pacing, narrative structure, final design or progression numbers. These remain under separate owner discussion. Do not incur costs, enable background schedules, install untrusted/privileged components, alter system-wide drivers/packages, compromise security, or switch GPU-heavy model workloads on while the user is ACTIVE without express authorization.

## 1 — Audit and baseline
- Confirm Goose Desktop/CLI version, capabilities and configuration paths against *official documentation for the installed build*. Do not assume the latest docs describe current installed behavior.
- Inventory currently enabled/discoverable extensions, MCP servers, plugins, skills, agent roles, recipes, hooks, Apps, process helpers, model providers, local/global settings and permission grants. Record scope and overhead, not secrets.
- Inspect existing `tools/comfy.py`, `tools/blender_process.py`, `tools/resmon.sh`, `tools/comfy_start.sh`, `tools/comfy_guard.sh`, Godot tests and all functional OMP/Goose integration artifacts. Verify they exist. **Do not recreate working adapters.**
- Baseline at least four low-cost tasks: find a canonical character/POV rule; inspect a combat state without changes; run a narrow Godot headless test; trace an asset manifest from source through import. Record correctness, tool calls, repeated reads, latency, CPU/RAM and failures. No GPU stress test.
- Produce a gap/benefit matrix: existing capability, observed limitation, proposed change, permissions, dependencies, test and rollback.

## 2 — Maintain authoritative and small context
- Keep `.goosehints`, `AGENTS.md` and persistent notes concise, prioritizing links to precise, authoritative PPIO docs. Avoid injecting the entire story bible or engineering spec on every message.
- Use scoped per-directory context only if it improves task-specific accuracy. Provenance and canon remain in PPIO's governed source files, **not agent memory**.
- Set up reliable session checkpoint/resume summaries: verified Git root/commit, dirty files, task scope, decisions, tests, safety status, open blockers, next safe action. Keep context retrieval targeted and output bounded.
- Respect Goose's existing `ops/DECISIONS.md`, `ops/CHANGELOG.md` and PPIO governance history without overwriting either.

## 3 — Specialist skills, roles and recipes
Inspect what the installed Goose version supports. Prefer a compact project-scoped implementation; current upstream conventions support project skills in `.agents/skills/<name>/SKILL.md` and portable YAML recipes. Create and validate **only useful modules**, rather than installing every available package.

Candidate skills:
1. `ppio-godot-combat` — deterministic actions, party state, controller-first inputs, HUD and headless tests.
2. `ppio-rig-animation` — Blender toy-specific rigs, skinning, sockets, GLB, Godot animation states, hit/VFX/SFX synchronization.
3. `ppio-asset-factory` — existing guarded ComfyUI workflows, reusable Blender exporters, Godot import, licensing and manifests.
4. `ppio-narrative-continuity` — toy POV, geography, character arcs, approved canon and change impact.
5. `ppio-audio-ui` — event-linked original SFX/music, audio buses, input focus and gamepad menu QA.
6. `ppio-quality-release` — bounded tests, artifact provenance, quality gates and safe deployment.

Candidate focused roles if supported: Gameplay Engineer, Technical Artist, Narrative Continuity Reviewer, Audio/UI Integrator and QA Reviewer. Keep one primary working agent; use isolated **read-only or nonconflicting** reviewers only when beneficial. Never have competing subagents edit the same files, or two agents run heavy GPU tasks concurrently.

Candidate recipes: combat-change-and-regress; asset-generate-normalize-import; rig-animate-validate; story-change-impact-audit; audio-UI-test; project-checkpoint-and-resume. Each recipe must define inputs, allowed tools/extensions, bounded workload/turns, required tests, PASS/BLOCKED/FAIL outputs and rollback. For explicit `extensions` lists verify essential platform tools (e.g., Summon when delegation is needed) stay available. Do not schedule unattended recipes.

## 4 — Extensions, MCP and hooks
- Inspect built-in Developer, Git, Skills/Summon, extension management and other already-working capabilities first. Avoid installing redundant Godot, Blender or ComfyUI extensions when a local scripted adapter is more reliable.
- If a validated gap exists, investigate official/maintained Godot tooling, a Blender bridge, a lightweight ComfyUI API MCP, audio analysis tools, and a canon/file indexing utility. Prefer narrowly scoped permissions, pinned trusted versions, localhost-only interfaces, and no credential exposure.
- Add **project-scoped**, reviewable hooks only where they make a measurable difference: before-commit secret/license check; after relevant edit a small syntax/manifest check; checkpoint after a session. Make hooks bounded, nonrecursive, idempotent, disableable and tested on harmless fixtures. Never run the whole asset pipeline or memory-heavy validation from a global hook.
- Consider a lightweight Goose Desktop/MCP App for asset progress and QA/approval status **only if** a simpler text report does not suffice. Don't build an app merely because Apps exist.

## 5 — Models, safety and process overhead
- Evaluate available cloud/subscription and local reasoning models by actual task success and cost, without changing user auth or charging money. Keep GPU-based local LLMs off while ComfyUI uses the GPU.
- Restrict always-on extensions, output volume, session history and concurrent child processes. Use low-cost headless checks, small targeted file searches and deterministic local code before invoking expensive models.
- Keep active/idle resource gates, `resmon.sh` preflight, `comfy_guard.sh` monitoring, `--reserve-vram 3` and the established safer DynamicVRAM configuration until new, verified evidence authorizes a change. An interrupt guard is not guaranteed protection from sudden driver stalls.

## 6 — Verify, package and hand off
- For each proposed optimization, compare the same low-resource baseline task before/after, and measure errors, latency, duplicate work, context/tool overhead, CPU/RAM, and test outcome. Reject or roll back changes that worsen reliability.
- Test skill discovery and use, recipe loading/execution, agent delegation under restricted extensions, safe hook firing, session checkpoint/restart, and the failure/rollback path without GPU stress.
- Commit portable project-scoped configuration and docs to **PPIO** in reviewable increments after confirming remote/branch and PUBLIC-repo privacy restrictions. Keep machine-local paths/secrets in untracked local-only config. Preserve every existing working integration.
- Provide: installed/retained/removed components, configuration files and paths, recipe/skill invocation instructions, before/after evidence, security/permission changes, running process overhead, revert instructions, and pending approvals.

**Definition of done:** A fresh Goose session in the correctly reconciled PPIO-linked local folder can discover task-relevant skills and tools, run a project recipe, preserve canon and work already completed, execute a bounded QA test, checkpoint progress and respect workstation headroom. Improvements must be demonstrable; merely adding tools does not count.

**Do not begin the next game-development assignment or expand project governance without the owner's separate instruction.**
