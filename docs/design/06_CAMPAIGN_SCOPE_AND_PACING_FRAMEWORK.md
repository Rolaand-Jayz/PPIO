# Entire-game scope, spatial scale and pacing framework

**Authority:** Required PLANNING AND REVIEW PROCEDURE for all future campaign sections. **No final campaign length, section duration, encounter rate, difficulty curve or playable geometry dimensions have been owner-approved.** Do not make provisional numeric examples authoritative.

## Overall project, not just one battle
Playtime Protocol: Innocence Lost is a stylized, toy-scale 3D JRPG, with four distinctive toys (Jayze, Kip, Rallo and Captain Crusher/Jonnie) moving through a particular family home. The journey includes an outward movement from familiar spaces across the long hallway and family-belongings encounters, toward kitchen, porch/backyard and alley, then an intentional return. Character growth, consequences, perspective-limited knowledge of CJ, and the reuse of physical locations must survive translation from story to player experience.

**Hierarchy:** full campaign → narrative act / outbound-return leg → spatial section → encounter/scene → action → assets and implementation. A lower-level component must serve the parent; never invent a room, boss, fight, mechanic, detour or collectible just because generating it is easy.

## Required campaign blueprint before full production
Maintain a versioned plan describing: act structure and party composition by story moment; known/unknown map connections and vertical clearances at toy scale; total playtime budget (owner approval required); traversal/exploration, dialogue, puzzle, combat, interlude, retry and optional-content shares; encounter roles and frequency; standard/elite/boss duration goals; rest and recovery; skill unlock and mastery pacing; chapter/section boundaries; return-route reuse; visual/rig/audio asset-family counts; performance and team workload. Tie each proposed quantity to evidence or owner approval. **Don't substitute the 8–12-hour target of a separate isometric RPG or the noncanonical 30–40-minute testing vignette.**

## Mandatory section design record
Each section promoted beyond `debug_only` needs:
- **Identity:** section ID, location, parent act, owner-approved purpose and dramatic question, entrance/exit conditions, involved toys and required abilities.
- **Spatial truth:** scale anchor, proven connections, actual path length, playable volume, collision/clearance, combat camera angles, checkpoints, occlusion, sightlines to CJ, outward and return states.
- **Narrative state:** toy perspective, observable CJ beat, character knowledge, relationship residue, rescue/family-object significance and callback dependencies.
- **Time:** target minimum / typical / maximum first-playthrough minutes, with separate movement, exploration, interaction, dialogue/cutscene, combat, retry, menu and optional-content contributions. All unapproved values explicitly `TBD — OWNER DECISION`.
- **Combat:** intended count and distribution of mandatory/optional encounters; each encounter's teaching/drama purpose; standard/elite/boss classification; target duration range, cumulative combat-time share, spacing between encounters and recovery/quiet beats.
- **Progression:** mechanics introduced, repeated meaningfully before a challenge, party skills/combos available, expected difficulty, resources, fail/retry safety and accessibility.
- **Production:** props, reusable environment modules, meshes, rigs, animations, UI, original music/SFX, licensing, performance risk, import and QA cost.
- **Validation:** exact owner approval status, prototype evidence, timed playtest distribution, observed boredom, player confusion, difficulty/frustration, measured encounter duration, rollback and missing inputs.

## Section size is experiential, not only architectural
Travel time is measured at **real in-game controller speed** and camera constraints, not guessed from adult-scale room area. Measure traversal, reorientation, interactions, dialogue, fights, exploration and retries. Keep a small room rich in interaction if that serves its purpose; don't pad a corridor or add generic random battles to hit a number. Each section must create an experience appropriate to its story importance and rhythm.

The house must remain a consistent, recognizable place on the return trip. Reuse geometry and change the experience through character understanding, obstacles, available abilities, human observations, lighting and sound, but don't silently add doors or change connected spaces.

## Combat duration and frequency planning
Before adding a fight:
1. State its purpose: teach, test, escalate, protect, reveal, create tactical uncertainty, resolve an arc, or mark a meaningful decision.
2. Identify party composition, movement constraints, enemy behavior, player action choices, expected difficulty, resources and encounter start/end conditions.
3. Estimate the actual player-facing time, **including command selection, animation, openings, transitions, interruptions and retries**. Distinguish test measured time from proposed target.
4. Place it in a section rhythm: time since prior combat, exploration and character moments between fights, tension/recovery, optional or required nature. No automated “one fight every N minutes” rule without owner approval.
5. Evaluate sameness: a new encounter must vary materially in tactics, space, objectives, enemy pressures, party interactions or story consequences—not just damage/HP, recolor or extra copies.
6. Playtest several encounters with actual controller use. Report P25/P50/P75 durations, failure/restart rates, time in menus, apparent player fatigue and variation by skill; compare with owner-approved target once one exists.
7. Propose adjustments as traceable changes. Don't lower quality or inflate playtime to satisfy an unapproved estimate.

## Story pacing and emotional causality
Early wins should feel meaningfully easy. The Unknown forces loss of certainty; separation gives each character distinct pressure; reunion and the return home must show earned behavioral change. Alternate discovery, threat, restraint, humor, reflection and agency according to dramatic need, not an automatic fixed quota. A fight that makes characters act against their established arcs or reveals CJ events from an impossible vantage is invalid even if technically fun.

## Authority boundary and provisional tests
The current complete combat slice may use local provisional duration/HP/encounter and arena targets for testing. They are **TEST-SLICE ONLY**, not the global pacing specification. Owner approval is required before numeric targets become mandatory production constraints. If unanswered, mark OPEN/TBD while completing unrelated safe work.
