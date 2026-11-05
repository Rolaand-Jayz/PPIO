# Combat test slice — implementation report (2026-11-05)

Owner direction: complete, polished, controller-first JRPG combat test with
expressly **non-final proxy** art/audio. This report separates what is
**verified** (headless engine runs + rendered captures on this machine) from
what is **reported-only** (requires the owner's hands, ears, or hardware).

## Status: VERIFIED (headless/rendered, on this machine)

1. **Project launches and runs.** `scenes/encounter.tscn` boots to explore,
   transitions through battle, and reaches victory/defeat/restart.
   Evidence: `tests/slice_integration.gd` PASS (0 script errors),
   rendered captures `artifacts/captures/*.png`.
2. **Four party proxies modeled, rigged, animated** — Jayze (humanoid,
   `Socket_Weapon`), Kip (vehicle: steer pivots + axle wheel chain,
   `Socket_Muzzle`), Rallo (winged hover, `Socket_ClawR`), Jonnie (heavy
   exoskeleton, `Socket_Pounder`). 8 clips each (idle/move/attack/ability/
   guard/hit/defeat/victory; Kip +ram; Jonnie +brace).
3. **Three enemy proxies modeled, rigged, animated** — Sprocket (wind-up
   chaser), Clanker (heavy slam), Gimbal (ranged disc). Each has a distinct
   telegraph clip + attack + hit + defeat.
4. **Animation states run inside real battles** — attacks play with windup/
   impact/recovery timing marks; hit reactions, defeats, guard poses, telegraph
   poses, victory/defeat clips all trigger from director state. Evidence:
   integration test asserts animation players are live before/after actions;
   captures 03–07 show mid-battle poses.
5. **Deterministic rules are authoritative.** `battle_rules.gd` v2 keeps all
   v1 mechanics (guard −2, momentum, co-op, music box, sign-step advance) and
   adds Rallo screech (daze), Jonnie pound/mend/brace, Gimbal ranged pressure.
   The enemy phase is planned (`plan_enemy_phase`) then applied step-by-step
   (`apply_enemy_step`) so presentation cannot alter outcomes.
   Evidence: `tests/battle_smoke.gd` PASS (20 scenario groups, v1 intents
   preserved + v2 coverage incl. plan/apply hp consistency).
6. **Sync of animation/VFX/SFX.** Impact events fire at per-action timing
   fractions of each clip; damage floats, HP bars, flashes, camera shake and
   impact SFX trigger at the same mark. Kip's wheel spin rate is derived from
   actual travel distance, not a canned loop.
7. **Controller-first flow implemented end to end** via abstract InputMap
   actions (`battle_*`, `move_*`, `cam_*`, `party_*`, `pause`): movement,
   camera, targeting, party switching, command menus, guard/abilities,
   pause/settings/audio, victory/defeat/restart — all reachable without
   keyboard/mouse. Keyboard/mouse parity through the same actions.
8. **HUD/UI.** Party status (HP/guard/daze/acted/ram-ready/mend cooldown),
   opponent intel with next-round intents, command menu with availability,
   targeting with range flags, contextual device-aware prompts, pause/settings
   (per-bus volume + mute + camera shake, persisted), controls reference,
   victory/defeat overlay with rematch. Layout uses edge anchors with
   expand aspect (16:9 verified in captures; 21:9 not visually verified).
9. **Audio integrated.** Original loopable combat theme (27.4s, A minor
   140 BPM), encounter/victory/defeat stingers, room ambience, ~29 event-bound
   SFX (per-toy attack identities, impacts, guard, KO, telegraph, UI cues),
   buses Master/Music/SFX/UI/Ambience with runtime volume/mute.
   Evidence: files generated deterministically; playback routed in-engine
   (dummy device in headless). **Listening quality is unverified** (below).
10. **Environment/VFX.** Toy-scale bedroom-floor diorama with vertex-color
    grid, obstacles matching rules `BLOCKED_CELLS`, music box at `MUSIC_BOX`;
    telegraph rings, impacts, slash arcs, projectiles, guard domes, heal
    sparkles, floaters. Charcoal backdrop keeps silhouettes legible
    (checked in captures at battle camera distance).
11. **Repeat play has no broken state** — restart restores rules, positions,
    bars, camera and music; integration test covers restart + pause/resume.

## Status: REPORTED-ONLY (requires owner participation)

- **Physical controller test** (hotplug, deadzone feel, Steam Input later):
  implemented per spec but not exercised on real hardware here.
- **Listening test** (loudness balance, loop click-free, no ear-piercing
  peaks): synthesized with bounded peaks/normalization, but not auditioned.
- **21:9 (3440×1440) composition**: anchors/expand should hold; not verified
  visually.
- **Steam Controller / Steam Input**: release target, intentionally untested.
- **Kip wheel spin direction sign**: rotation is distance-derived; the
  forward-roll sign should be eyeballed once in a live session and flipped
  in `unit_view.gd` if needed (one-character change).
- **Performance/resource creep over long sessions**: not profiled here.

## Known limitations / non-final decisions (do not treat as canon)

- All models/materials/audio are **proxy** (`approval: provisional` in
  `assets/asset-manifest.json`); appearance is primitive-block toy shorthand,
  deliberately replaceable without touching controllers/rules/sockets.
- Enemy names/designs are noncanonical placeholders (spec: neutral
  prototypes, not Unknown designs).
- Combat values (damage/HP/ranges) are provisional test values inherited
  from the v1 prototype and extended conservatively.
- Items/inventory are out of scope (none exist in the deterministic rules);
  the music box `interact` covers the environmental-object role.
- Rallo's wings are simple slabs (membrane shape is provisional).
- One arena (bedroom floor) exists; it is noncanonical until approved.

## How to run / test

See `README.md` ("Combat test slice" section) for engine paths, asset
rebuild commands, and test invocations. Controls: `docs/CONTROLS.md`.

## Safety status

No GPU generation was run this session (user active; policy honored).
All work is CPU-only Blender/Godot/Python. No secrets, model weights, or
forensics committed; benchmark leftovers gitignored.
