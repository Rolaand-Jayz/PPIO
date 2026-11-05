# Goose Desktop — post-combat quick specialization

**QUEUED.** Begin only after the combat vertical slice is completed **and the owner explicitly asks you to start**. Don't interrupt current work.

**Local project:** `/mnt/workdrive/playtime-protocol-godot-comfy-blender`. Verify its Git root/remotes and protect dirty files.  
**Canonical monorepo:** `https://github.com/Rolaand-Jayz/PPIO.git`, branch `main`.

**Decision style:** Goose is the fast implementer, the owner and ChatGPT are reasoning partners for major decisions. Goose should **just make small safe improvements**, test them and keep what works. No approval ceremony for every skill or extension. Read [the streamlined decision and testing approach](07_GOOSE_SPECIALIZATION_REVIEW_PROTOCOL.md).

## Optimize for actual production work

**1. Start with what's already working.** Read `.goosehints`, `AGENTS.md`, `CONTRIBUTING.md`, existing scripts and the local handoff. Inspect installed Goose version, features and current config, without over-inventorying. Preserve the existing Godot prototype, `tools/comfy.py`, Blender export scripts, guarded ComfyUI launcher, caches/models, tests and Goose/OMP logs. Don't recreate them.

**2. Make Godot + Blender + ComfyUI + audio actually work together.** Follow [toolchain integration](06_TOOLCHAIN_INTEGRATION_CONTRACT.md). Godot Editor inspection plus headless/runtime validation, Blender rig/animation authoring and GLB import, existing guarded ComfyUI workflows, original SFX/music integration and audio buses, Git, tests and asset manifests are all in scope. Prefer safe shell/API adapters over a new MCP extension when they work better. Don't let ComfyUI problems block unrelated work.

**3. Add a few useful project skills, not dozens.** Choose small load-on-demand procedures for Godot gameplay/controller/HUD, Blender rigs and animations, asset pipeline, story/continuity, original audio/UI and quality/testing. Use installed-version-compatible locations and schemas. Don't clone canon into prompt memory; link to approved PPIO documents.

**4. Write short repeatable recipes** for work Goose does repeatedly: safe feature edit + test; Blender → GLB → Godot import; guarded ComfyUI job when authorized; combat/audio/controller QA; checkpoint and resume. Explicit error handling, source paths, output manifests and rollback. Only enable needed extensions. Test each recipe on a small fixture once.

**5. Build resilience into the everyday workflow.** Honor [three laws and fallback ladder](../governance/04_CONTRIBUTOR_AND_RESILIENCE_RULES.md). Keep write ownership serial, one heavy GPU job maximum, lightweight active-user and memory checks, bounded retries, safe fallbacks, and durable checkpoints. Never delete other work or overwrite editor-unsaved scenes. Never use background busy loops or promise work while a session is not running.

**6. Guard against generic AI quality.** Follow [distinctive design and quality gates](../design/07_DISTINCTIVE_DESIGN_AND_QUALITY_GATES.md). Check real shape/mechanism, animation, gameplay role, environmental specificity and audio signatures—not “looks unique” prose. Keep nonfinal art marked as such; offer owner a few meaningful choices when visual direction needs approval. Don't freeze production waiting for perfect documentation.

**7. Model routing:** GLM-5.3 Flash is the default for fast/efficient execution; GLM-5.3 only when complexity, safety or repeated failures justify deeper reasoning. Verify installed provider IDs and actual usage. GLM-5.5 later only after a practical comparison if available. No expensive redundant reviewer trees; no local GPU LLM competing with ComfyUI.

**8. Keep improvements tiny and reversible.** Make one change, run the one or two relevant checks, keep/revert, move on. Use project-scoped config and trusted tools; no unapproved purchases, security/privacy changes, privileged installs or heavy GPU tests while user ACTIVE. Avoid growing an always-on tool collection.

## Deliverable
Leave a working, **simpler** Goose project setup. Report briefly: installed and removed capabilities, what they enable, what was tested, any trade-offs, safety check results, remaining owner decisions, and how to roll back. Prove at least one full low-cost cross-tool path and one checkpoint/resume fallback. For major architectural choices or final permanent setup, present the options to the owner and ChatGPT for a quick reasoned decision.

**Keep it practical. Finish the combat slice first. Do not automatically launch this phase.**
