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
