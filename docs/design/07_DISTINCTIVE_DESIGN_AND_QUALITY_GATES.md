# Distinctive design and production-quality acceptance gates

**Governing requirement:** Playtime Protocol must be recognizable *because its designs, behaviors, game feel and material language are particular to this world*, not because prompts use the words “unique,” “premium,” “professional,” or “cinematic.” This applies to human-authored, AI-generated and procedurally authored work alike. It governs ALL assets, combat encounters, animations, sound, UI and playable sections.

**Status:** Binding design-review procedure and rejection conditions. **It does not declare any provisional concept, character costume, enemy identity, game mechanic, melody or location canon-final.** Owner retains final artistic and mechanical approval.

## The anti-sameness rule
A new asset or encounter must have a **documented design identity derived from Playtime Protocol's causal constraints**: what toy/object it is, how it was manufactured/owned/repaired, how it physically moves, what part of the family home it occupies, what player action it enables, and what its story or tactile consequence is. A generated image that merely looks attractive does not satisfy this.

**Mandatory artifact identity sheet** (for each major character, enemy family, room kit, UI motif, animation set, audio family or novel encounter):
1. **Purpose and use:** what role does it serve in actual play and story? What should the player read from gameplay distance?
2. **Physical logic:** tangible origin, toy construction (mold seams, joint limits, materials, wheelbase, plastic wear, fabric, armor fastening, or other warranted details), real scale, collisions and constraints.
3. **Three distinguishing commitments** tied to *observable behavior*, not adjectives. Example for a nonfinal Kip candidate: wheelbase and steering meaningfully govern turns; a spring-mounted weapon moves with chassis load; sound changes with wheel contact. These are **examples**, not final art/move approvals.
4. **Internal contrast:** name the nearest two existing party/enemy/prop/UI/audio designs, state how shape, material, motion, behavior and/or sound remain independently recognizable. No “same body plus color and accessory.”
5. **Rejected defaults:** identify the tempting generic AI tropes that must NOT appear (generic glowing armor, identical idle cycles, interchangeable fantasy humanoid rigs, repetitive particle bursts, blue sci-fi UI, copy-paste boss patterns, generic toy store interiors). This list is illustrative, not a universal prohibition on a particular color or material.
6. **Real-world/use context:** why *this* family home, specific worn/kept toy, family object, physical situation, stage, and relationship would have produced this design.
7. **Reference provenance and rights:** original research and inspiration, with similarity review. No tracing or direct imitation of a protected existing game/brand character or audio.
8. **Implementation consequences:** rig/sockets and animation requirements, combat interaction, VFX and SFX signature, UI needs, readability and test/rollback.
9. **Status:** concept/proxy/proposed/final, reviewer, open owner decisions and actual test evidence.

## Deliberate divergence without infinite generation
For major new designs, prepare **2–3 genuinely different *structural* directions** from a bounded brief (not hundreds of recolors). A meaningful alternative must change construction, silhouette/mechanism, functional play or material/animation response—not just palette, composition, amount of detail or prompt adjectives. Use rough low-cost blockouts, diagrams or sketches first; expensive GPU generation only if safely allowed.

Record a comparison showing which approach makes the strongest unique promise and why. If every candidate looks or functions like the same generic archetype, reject the batch and **change the design constraints**, not merely the seed or style words. Do not require multiple generated versions when an already-approved/reused asset satisfies this gate or when generation is unsafe. Preserve rejected candidates as provenance when useful, without promoting them to canon.

## Distinction dimensions — no interchangeable party members
**Jayze:** weapon-bearing anime-action toy **archetype**, but distinguish him through manufactured joint language, weapon handling, emotional body language, stance and tactical expression; not recognizable franchise costume/moves.

**Kip:** genuinely small die-cast weaponized car, with meaningful wheelbase, steering, chassis pitch, momentum, contact and mechanical sound. Never a standard humanoid auto-rig or a generic glowing sci-fi sports car.

**Rallo:** low, compact muscular gargoyle-like toy with physically constrained hovering/wing articulation and a different center of mass, strike height, tactical reach and voice/body rhythm from Jayze.

**Captain Crusher / Jonnie:** garage-sale, repaired female soldier action figure with substantial functional exoskeleton mechanism, deliberate heavy articulation and defensive/support identity. Repair history should cause plausible physical differences; not “armored Jayze” or generic mech suit.

**Enemy proxies:** represent different player decisions/telegraph languages; avoid same humanoid with 3 recolors. Noncanonical enemies must not inadvertently decide what the Unknown is.

**Environment:** distinctive, specific family-home wear, object relationships, plausible geometry/scale, toy-accessible structures, and visual story; not infinite wallpaper rooms, maze-like corridors or interchangeable spooky dungeons. Outbound and return states are physically continuous.

**HUD/UI:** controller-native hierarchy and focus that communicates this game's party roles and toy-scale tactile theme; avoid derivative FF7 layouts, default asset-store RPG panels, generic neon sci-fi motifs and baked-in inaccessible text.

**Motion/VFX:** every role must communicate physical mass, scale, articulation, action timing, recovery and impact differently; do not paste an identical idle, attack recoil, speed curve or magical flash across the roster.

**Audio/music:** individual physical sonic identities, motifs and tactical communication; no generic “epic fantasy,” identical impact sweeps, overused stock risers, or licensed melody imitation. Distinct SFX must correspond to material, movement and attack, not random spectacle.

**Combat/level design:** encounters must ask *different questions* of the player, not merely have new HP/speed values. Link spatial affordance, enemy intent, party role, time, objective and emotional meaning; avoid boilerplate combat every fixed number of minutes.

## Hard reject rules
Reject or quarantine a candidate, **even if visually impressive**, when any applies:
- Identifiable imitation of existing copyrighted/trademarked character, franchise HUD, music, voice or level.
- Silhouette and mechanical behavior indistinguishable from another roster member/enemy family except color/accessories.
- Impossible or unmotivated toy construction/joints, attachment, material deformation, geometry, scale, wheel motion, hover, exoskeleton articulation or collision.
- Rig breaks, nonfunctional animations, T-pose flash, sliding contacts, malformed GLB, wrong sockets or animation/VFX/SFX impacts that misrepresent combat state.
- Environment invents unapproved geometry or violates actual toy sightlines/physical connectivity.
- Input or UI relies on mouse despite controller-first commitment, unreadable text/focus, broken target clarity or confusing combat telegraphs.
- Audio is clipping/missing, unlicensed, mismatched to event or repetitive enough to erase role identity.
- Unjustified design convergence: same action patterns, room kit, character construction, camera, rhythm, sonic signatures or material vocabulary cloned across different features.
- Hidden provenance, missing sources, claims of tests or originality approval not actually performed.

## Evidence gates (each independently recorded)
**Q0 — Brief:** identity sheet with observable distinguishing commitments, constraints, rights, intended mechanics, nonfinal status.

**Q1 — Originality/contrast:** internal cross-roster or cross-location comparison; silhouettes side by side at game camera in grayscale; show how *mechanism, motion and tactical function* differ. Rework if differences are only paint or surface detail.

**Q2 — Production build:** real materials, topology, rig weights/joints, authored/rigged animation, event timing, controlled audio, clean sources, formats, import and licensing. Verify using applicable automated tests; *never self-score beyond what test evidence proves*.

**Q3 — In-game integration:** controller-playable view, actual combat/environment use, sound/VFX synchronization, HUD, frame rate and resource constraints, visual legibility at target resolutions, no broken state and no hidden desktop interference.

**Q4 — Direction review:** side-by-side screen captures and, for movement/audio, brief playable/video/audio examples with an identity-sheet rationale. Owner marks **ACCEPTED FOR SLICE**, **REVISE** or **REJECT**. **ACCEPTED FOR SLICE is not final-canon approval.** Human judgment is essential; objective scripts cannot certify originality or taste.

**Q5 — Maintenance:** accepted asset remains swappable, versioned, licensed, compatible with existing rigs/animation/API and documented for future final-art replacement. A proxy isn't disposable junk.

## Controlled iteration and refusal to lower quality
- First fix *structural* problems (wrong silhouette/mechanism, samey combat, impossible geometry) before surface polish.
- Use a bounded issue-specific refinement cycle: identify measurable fail, change one design/technical cause, compare before/after in actual game, preserve last-known-good. Stop expensive repeats and choose an alternate medium if progress stalls; the goal remains open, not secretly accepted.
- Under deadlines or resource pressure, **reduce breadth, not quality**: fewer well-built enemies or one complete room is preferable to generic mass-produced content. Where the approved combat-slice minimum is unmet, report a true gap and continue rather than lowering its acceptance rules without approval.
- Do not replace all characters with placeholder primitives merely to meet a check; a short graybox phase is acceptable as a development step, never as final slice signoff.
- Don't invent unique mechanics that violate agreed combat rules, and don't convert speculative artistic directions into final canon. Make experiments isolated and reviewable.

## Required quality decision record
Each review records asset/feature ID, original design brief, reference/license, at least three observable uniqueness commitments, comparison targets, images/test artifacts, technical QA state, owner judgment, open changes and rollback. Tests can automatically catch missing files/invalid links and regressions; **aesthetic and originality acceptance requires review**.

This gate applies to current combat vertical slice at its **next safe checkpoint** using a non-destructive comparison. Existing completed OMP/Goose assets are preserved and evaluated, not automatically trashed or mass-regenerated.
