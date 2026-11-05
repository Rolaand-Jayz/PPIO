# Asset / feature identity and quality review — TEMPLATE

**Copy per significant asset or feature**; this template is not itself an approval. Keep its ID linked to the manifest. The goal is to distinguish genuine design identity from generic prompt decorations.

- Asset/feature ID:
- Owner/reviewer:
- Date and source commit:
- Target: character / enemy / section / animation / mechanic / UI / audio / environment
- Status: PROPOSED / CONCEPT_ONLY / DEBUG_ONLY / ACCEPTED_FOR_SLICE / FINAL_APPROVED
- Source rule and approved gameplay/story role:
- License and references (including source-file and model/procedural provenance):

## Identity — three observable commitments (required)
Each commitment must describe something visible, playable or audible, *and why it arises from this toy/family/world*; words like beautiful, cinematic, high quality and unique do not qualify.

1. **Physical/structural distinction:** 
   - Evidence:
2. **Movement/interaction/combat distinction:**
   - Evidence:
3. **Material/audio/world-history distinction:**
   - Evidence:

## Contrast review
- Closest existing project design A:
- Closest existing project design B:
- How shape differs **at actual gameplay distance**:
- How articulation/motion or game mechanics differ:
- How material/light/texture and sound differ:
- What appears too similar or generic:
- Deliberately rejected AI defaults/tropes:
- Other inspirations, originality/rights concerns:

## Alternatives (when design is new/uncertain)
- Direction 1 — structural/mechanical thesis:
- Direction 2 — structurally distinct thesis:
- Optional direction 3:
- Chosen direction and reason (or still awaiting approval):
- Do **not** create expensive GPU batches to populate this field; rough blockouts and written constraints can suffice.

## Technical quality evidence
- Editable source / build/export path:
- Geometry/UV/material/rig/socket/animation checks:
- Godot import/controller/camera/scene evidence:
- Combat hit timing, VFX/SFX and UI evidence (as applicable):
- Audio cue/license/loop/peak evidence (as applicable):
- Performance and active-user safety check:
- Known defects, regression tests, repair and rollback:
- Real-playtest status versus script-only tests:

## Q0–Q5 review
| Gate | PASS / REVISE / REJECT / NOT TESTED | Evidence/reference |
| --- | --- | --- |
| Q0 identity brief |  |  |
| Q1 internal originality and silhouette contrast |  |  |
| Q2 build/rig/audio/art technical integrity |  |  |
| Q3 in-game playable integration |  |  |
| Q4 owner direction review |  |  |
| Q5 versioning and replaceability |  |  |

**Decision:** ACCEPTED FOR SLICE / REVISE / REJECT / OWNER REVIEW PENDING  
**Owner explicitly approved final canon?** YES / NO (default NO)  
**Next correction and check:**

*Automated lint cannot judge visual or mechanical originality. Approval requires the owner or their explicitly designated reviewer.*
