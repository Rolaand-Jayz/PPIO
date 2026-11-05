#!/usr/bin/env python3
"""Low-cost PPIO repository-structure / Markdown-link guard.

This script checks document existence and local links. It does NOT grade visual
quality, creative originality, combat balance, audio quality or playtest results.
No Godot, Blender, ComfyUI, GPU, network or optional packages are used.
"""
from pathlib import Path
from urllib.parse import unquote, urlsplit
import re
import sys

ROOT = Path(__file__).resolve().parent.parent
REQUIRED = [
    "README.md", "AGENTS.md", ".goosehints", "CONTRIBUTING.md",
    "docs/00_START_HERE.md",
    "docs/governance/01_LIVING_CONTINUITY_AND_DECISIONS.md",
    "docs/governance/02_SOURCE_CHANGE_LOG.md",
    "docs/governance/03_APPROVAL_AND_LOCKING_STANDARD.md",
    "docs/governance/04_CONTRIBUTOR_AND_RESILIENCE_RULES.md",
    "docs/governance/05_VERTICAL_SLICE_TRANSITION.md",
    "docs/design/01_GAMEPLAY_CONTRACT.md",
    "docs/design/03_COMBAT_TEST_SLICE.md",
    "docs/design/04_CONTROLLER_HUD_UI_AUDIO.md",
    "docs/design/05_RIGGING_AND_ANIMATION.md",
    "docs/design/06_CAMPAIGN_SCOPE_AND_PACING_FRAMEWORK.md",
    "docs/design/07_DISTINCTIVE_DESIGN_AND_QUALITY_GATES.md",
    "docs/production/02_RESOURCE_SAFETY.md",
    "docs/production/05_POST_SLICE_GOOSE_OPTIMIZATION.md",
    "docs/production/06_TOOLCHAIN_INTEGRATION_CONTRACT.md",
    "docs/production/templates/ASSET_IDENTITY_AND_QUALITY_REVIEW.md",
    "docs/design/templates/SECTION_DESIGN_RECORD.md",
]
LINK_PATTERN = re.compile(r"(?<!!)\[[^\]]*\]\(([^)]+)\)")
ERRORS = []
for rel in REQUIRED:
    if not (ROOT / rel).is_file():
        ERRORS.append(f"Missing required file: {rel}")

# Scan local content files only. Skip generated/media and historical archive branches.
for source in [ROOT / "README.md", ROOT / "AGENTS.md",
               ROOT / "CONTRIBUTING.md", *sorted((ROOT / "docs").rglob("*.md"))]:
    if not source.is_file():
        continue
    text = source.read_text(encoding="utf-8")
    for link in LINK_PATTERN.findall(text):
        link = link.strip().split(" ", 1)[0].strip("<>")
        if not link or link.startswith("#"):
            continue
        parsed = urlsplit(link)
        if parsed.scheme or parsed.netloc or link.startswith("//"):
            continue
        path = unquote(parsed.path)
        if not path or path.startswith("/"):
            continue
        target = (source.parent / path).resolve()
        if not target.is_relative_to(ROOT.resolve()) or not target.exists():
            ERRORS.append(f"Broken local Markdown link: {source.relative_to(ROOT)} -> {link}")

for rel, markers in {
    "docs/governance/04_CONTRIBUTOR_AND_RESILIENCE_RULES.md":
        ["R1", "R2", "R3"],
    "docs/design/07_DISTINCTIVE_DESIGN_AND_QUALITY_GATES.md":
        ["Q0", "Q1", "Q2", "Q3", "Q4", "Q5"],
}.items():
    p = ROOT / rel
    if p.is_file():
        body = p.read_text(encoding="utf-8")
        for marker in markers:
            if not re.search(r"\b" + re.escape(marker) + r"\b", body):
                ERRORS.append(f"Required gate marker {marker} absent in {rel}")

if ERRORS:
    for error in ERRORS:
        print(f"FAIL: {error}")
    sys.exit(1)
print(f"PASS: required governance files, local Markdown links and gate markers ({len(REQUIRED)} files)")
