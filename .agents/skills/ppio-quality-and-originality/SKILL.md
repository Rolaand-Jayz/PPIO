---
name: ppio-quality-and-originality
description: Technical quality checks, anti-sameness comparison, gameplay distinctiveness, and rejection of generic AI results. Use for quality review, acceptance checks, and any "is this good enough" judgment.
---

# PPIO quality & originality gates

## Hard rejections (never accept because it "technically functions")
- Generic AI-looking characters (interchangeable silhouettes, same face/body plan with palette swaps)
- Copied combat patterns, repetitive animation reuse across the cast, identical telegraphs for different enemies
- Generic environments, unreadable HUD, or audio that doesn't match its event (impact/windup/telegraph)
- Unvalidated outputs of any kind (generated files are NOT accepted until tests + review pass)

## Originality evidence standard
Originality comes from OBSERVABLE construction: silhouettes, motion signatures, mechanics, relationships (party interplay, enemy roles), environments, and sound — never from prompt adjectives ("unique", "cool"). Claiming originality requires a side-by-side comparison against existing cast/encounters and owner slice approval.

## Readability checklist (combat slice)
- At gameplay camera distance: each unit identifiable by SHAPE not color alone (portrait chips are shape-coded; enemy telegraphs are distinct per role: wind-up key spin, double-fist raise, gimbal ring charge).
- Timing chain intact per attack: windup → telegraph (with '!' + ring) → active window → impact (rules apply EXACTLY here via apply_enemy_step) → hit reaction → recovery. VFX/SFX on the impact fraction (IMPACT_AT), never double-triggered.
- Rules authority preserved: battle_rules.gd outcome unchanged by presentation changes; tests/battle_smoke.gd + tests/slice_integration.gd pass after any change.

## Review procedure
Compare new asset/behavior side-by-side with at least two existing ones; list concrete physical/mechanical corrections (not adjectives); preserve working assets until replacements are ACCEPTED (never delete before replacement approved); log verdicts in ops/CHANGELOG.md. See docs/design/07_DISTINCTIVE_DESIGN_AND_QUALITY_GATES.md (canonical).
