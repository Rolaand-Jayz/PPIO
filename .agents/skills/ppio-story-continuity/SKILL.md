---
name: ppio-story-continuity
description: Canon, character arcs, toy perspective, geography, chronology, and owner approvals for Playtime Protocol. Use before story-adjacent decisions, naming, new content, or anything that could become canon.
---

# PPIO story continuity

## Source hierarchy (never invert)
1. Story invariants + approved decisions (owner entries in ops/DECISIONS.md)
2. Character/arc/geography ledgers (canonical repo `main` branch docs)
3. Narrative/visual/gameplay specifications
4. Production operations
5. Implementation notes, prototypes, chat summaries (lowest; never canon)

## Rules
- NEVER silently change canon. Story/geography/character changes need an explicit approval entry in ops/DECISIONS.md + a line in docs/governance/02_SOURCE_CHANGE_LOG.md (append-only; never rewrite history to hide a decision).
- Concept drafts, website copy, proxies, test vignettes are NOT canon. Combat-slice names are explicitly noncanonical placeholders (Sprocket/Clanker/Gimbal; owner will finalize) — see docs/COMBAT_SLICE_REPORT.md and decision D-012.
- Everything shipped so far is proxy/provisional (`status: provisional` in assets/asset-manifest.json). Do not make unapproved final canon decisions (appearance, world art, soundtrack identity).
- Toy perspective: the world is a child's room at toy scale; characters are toys (action figure, RC-style vehicle, gargoyle figurine, heavy soldier exoskeleton toy). When proposing anything new, state how it reads from toy scale and why it stays distinct from existing cast members.
- Canon conflict → escalate to the owner (ChatGPT is the reasoning partner); do not self-approve major decisions.
