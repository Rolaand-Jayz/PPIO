# Approval, locking, and document reconciliation standard

Modelled after the continuity discipline of *The Twentieth Revision*, adapted to interactive game development.

## Decision authority
- Explicit owner-approved direction governs. Old document timestamps alone do not make them authoritative.
- Canon invariants → character/arc/geography records → narrative/gameplay/art contracts → production specs → experimental implementation.
- Conflicts at the same tier require an explicit recorded decision, not agent preference.
- Proposed, experimental and debug artifacts must be labeled as such; a runnable scene is not automatically narrative canon.

## Change transaction
Record: old rule → new rule → why → approval provenance → affected characters/scenes/geometry/gameplay → impact on existing assets and tests → conflicts → rollback → documents updated. Edit highest-authority affected source first, then dependents. Append a change log entry. Never fictionalize past approvals.

## Content/scene lock
Before locking a scene: confirm toy POV, geography, story chronology, character knowledge and relationship residue, asset/rights status, gameplay/camera plausibility, owner review and regression. After lock: update living continuity; audit dependent docs; append change-log entry; preserve versioned source and a short evidence report.

## Creative freedom
Agents may discover incidental staging, expressive animation, noncanonical blockouts, local dialogue rhythm and implementation details. They may not silently change established names, ages, thematic endings, party arcs, protected unknowns, chronology, known adjacency, physical reachability or approval status.

## Production acceptance
Each asset must pass brief/license provenance, generation validity, geometry/rig checks where applicable, Godot import, gameplay-camera/readability and appropriate owner sign-off. Failed candidates stay isolated from accepted assets, and expensive retries are bounded. Distinguish PASS, NEEDS REVISION, BLOCKED and NOT TESTED.

## Distinctive design/production-quality approval
Before declaring a major character, enemy, arena, combat interaction, animation family, HUD style, or music/SFX identity **ACCEPTED FOR SLICE**, require the [quality gate record](../design/07_DISTINCTIVE_DESIGN_AND_QUALITY_GATES.md) and [asset identity review](../production/templates/ASSET_IDENTITY_AND_QUALITY_REVIEW.md). Three observable causal distinguishing features, in-game comparison against nearby designs, technical validation and owner review are required. Technical acceptance does NOT imply final artistic canon; vague claims of originality, generated beauty or automated similarity scores do not qualify. An incomplete or low-quality candidate remains REVISE/REJECT, with a safe remediation path; never relabel it complete.

## Full-campaign scope and section approval
Section design uses [the campaign and pacing framework](../design/06_CAMPAIGN_SCOPE_AND_PACING_FRAMEWORK.md), with the owner approving playtime, physical section scale, encounter frequency/duration and progression targets. Until then, numeric values are TEST_ONLY / TBD, never canon. Current combat slice is accepted against its own explicit requirements, not a fictitious full-campaign quota.
