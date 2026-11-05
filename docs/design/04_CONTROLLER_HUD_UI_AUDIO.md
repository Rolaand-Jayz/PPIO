# Controller-first combat, HUD, UI and sound contract

**Owner reference:** The fluid, console-native encounter presentation and command access of **Final Fantasy VII Rebirth**. This describes the **quality and user experience to aim for**, not permission to clone its HUD or copy its control scheme, music, characters, art assets, or copyrighted effects. The existing PPIO combat prototype is the authority for presently implemented rules until revised with evidence and owner approval.

## 1. Input priority and architecture
**Default design target: Xbox/XInput-compatible gamepad for the current test.** The owner can test on this now. **Keyboard and mouse are fully functional secondary inputs**, not second-class or a requirement to operate the game. **Steam Controller / Steam Input is a release requirement, not a blocker for this slice**; preserve support through abstract Godot InputMap actions and a controller-profile adapter. On Linux, don't incorrectly assume the Windows-only XInput API is the transport; recognize the Xbox-style controller through Godot/SDL and verify button labels and axes.

- Define meaningful gameplay actions (`move`, `camera`, `attack`, `dodge`, `guard`, `interact`, `open_commands`, `confirm`, `cancel`, `next_target`, `prev_target`, `cycle_party`, `pause`, `shortcut_modifier`) independent of hardware buttons.
- Analog left-stick movement and right-stick camera/target adjustments **when relevant to the current battle design**; D-pad for menus/party/commands, face buttons for action and acceptance, shoulders/triggers for defense/selection/shortcuts.
- Establish a coherent **provisional** Xbox button mapping through existing InputMap, then expose it in an in-game Controls menu. Do not lock exact mapping before it is tested in the actual combat slice.
- Analog deadzones, stick repeat timing, hold versus tap, input consumption (UI vs game), debounce, pause state and rebind/reset behavior must be handled robustly.
- Controller connects/disconnects/hotplugs without input deadlock. If the connected input changes, update on-screen glyphs and contextual help promptly; the game must remain controllable.
- Ignore controller input when the unfocused application could accidentally receive it, according to Godot support/settings. No unrelated desktop input interception.
- Steam Input later should map to the same abstract game actions, support analog + trackpads/gyro as appropriate, and require no scene-wide input rewrites; **do not claim Steam Controller verified now**.

## 2. FF7 Rebirth-like interaction *principles*, not mechanics cloning
Reference qualities: direct physical control, an immediately reachable tactical **command layer**, readable party status, shortcuts to commonly used actions and smooth transitions between battle and menus. If the existing combat design benefits from tactical time slowdown, treat it as a **separate design proposal**; do not import ATB/slow-motion systems over existing deterministic combat without explicit review.

- A player always understands who is selected/acting, what is targeted, what action is available, resource requirements, and the likely consequence.
- Command menus are gamepad-native: stick/D-pad focus, confirm/cancel, contextual descriptions, consistent back-stack, remembered focus when appropriate, and deliberate safe defaults.
- Contextual button guidance uses the **current controller glyphs** (Xbox for present tests), with keyboard/mouse labels when keyboard/mouse is last used.
- Party and target selection, combat command layer, quick-action slots if supported by existing mechanics, pause menu, settings, victory/defeat/restart must be operable entirely by gamepad.
- Do not require pointer hovering, dragging, wheel scrolling or tiny click targets. Prioritize readable spacing, high contrast, clear selected/focused state and stable focus after animation transitions.
- Deliberate transition animations, minimal obstruction of combat, sensible safe margins and contrast over VFX. Verify 1920×1080 (16:9) and 3440×1440 (21:9) layout when supported; preserve UI scaling and HUD anchor behavior across resolutions.
- Support legible fonts, color-independent statuses, remapping discoverability, and optional reduce-motion/toggle-hold settings when feasible. Do not make sound alone the only clue.

## 3. Mandatory combat HUD and UI coverage
- **Battle:** party portraits or proxy icons; health/resource/status; active-character indication; opponent/target identifiers; action/command list; selection cues; ability availability/cooldowns as dictated by actual rules; clear enemy telegraphs and hit/status feedback.
- **Menus:** fully navigable title/test entry; pause and resume; Controls/help; Settings; result/victory/defeat; restart/quit to test entry.
- **Transitions:** encounter start and end, party/target switching, menu opening/closing and animation cancellation do not leak input or trap focus.
- **UI styling:** intentionally cohesive manufactured-toy/family-world visual language, not borrowed Final Fantasy assets and not generic developer widgets. Proxy icons/art are acceptable; layout, hierarchy and usability are not placeholders.

## 4. Sound and music are part of the executable slice
**No "audio later" shortcut.** Music and effects are necessary to judge combat impact, pacing, tactical readability and polish. Every required sound is connected to actual gameplay or UI events.

### Music deliverables
- Original, loopable **combat theme**: one coherent mid-intensity test cue with battle energy that doesn't fatigue or mask commands/impacts.
- Brief original **encounter start**, **victory** and **defeat** cues (may be simple authored stingers); transitions are intentional.
- Optional adaptive combat intensity layer only if the current state machine exposes stable combat phases; do **not** construct a large adaptive soundtrack system before the single-loop mix works.
- Seamless loop edits, sensible intro/outro, click-free transitions/fades, predictable pause/resume behavior, and target loudness balanced against impact/command feedback.
- Optional muted background ambience in arena (distant domestic activity, miniature toy mechanical environment), with stereo/spatial placement that doesn't mask critical cues.

### Sound effect coverage
- **UI:** move focus, confirm, cancel/back, open/close command menu, unavailable command, target change, party switch, pause/resume, result highlight and restart.
- **Combat:** basic attacks for each of the four toy roles; one signature skill per role if implemented; projectile/weapon launch and impact where appropriate; enemy telegraph, enemy attack, hit, blocked/parried/guarded, evade, KO/downed, heal/assist, status application/removal and battle resolution.
- **Physical toy identity:** distinguish plastic clicks, metal armor, wheels, small mechanical motion, hover/wing motion, floor/contact materials, room-scale reflections and distance cues as needed for gameplay. Kip must sound like a small car, Jonnie like heavier articulated machinery; Jayze and Rallo must also have identities.
- **Priority:** mechanical event clarity > elaborate sound library. Prefer a few excellent, correctly triggered cues to many unconnected or repetitive assets.
- No unlicensed third-party sounds, copyrighted Final Fantasy melodies/samples, imitation of distinctive commercial game audio, or unapproved voice cloning. Original/procedural/local-licensed sounds are acceptable. Spoken voice is **not required** for this combat test unless explicitly approved.

### Runtime audio engineering
- Godot buses: `Master`, `Music`, `SFX`, `UI`, `Ambience` (and `Voice` if voice exists), with persistent in-game volume/mute settings reachable by controller.
- Implement event-driven audio playback; deterministic gameplay state is independent of whether sound plays. Avoid double-fire, overlapping instances causing clipping, or missing audio on repeated actions.
- Spatialize world effects where beneficial; keep important HUD/action confirmation audible and consistent regardless of camera distance.
- Use high-quality source files (e.g., WAV/FLAC originals) and reasonable Godot-compatible runtime formats (e.g., streamed OGG for long music, imported WAV for short effects) with clean loop points, trim/normalization and reproducible export settings.
- Keep audio metadata: source/author/license, original/generated/procedural label, mastering/export notes, replacement status, per-event binding and actual tested playback status. Do not conflate a file on disk with an implemented sound.
- Verify no ear-piercing peaks, silent events, accidental phase/clicks at loop boundaries, severe masking or fatigue, and that mute/volume settings work correctly.

## 5. Controller-and-audio integrated acceptance
In one real playthrough **using only the connected Xbox-style gamepad**, tester must: enter test, navigate menus, select party/target, execute actions, respond to telegraphs, pause and change audio levels, resume, finish battle, view result, and restart. The correct UI prompt and audible cue should accompany these actions. Repeat on keyboard/mouse and check all primary actions.

Inspect focus state, audio level consistency, lost/multiple-event SFX, music looping, controller hotplug/focus loss and 16:9/21:9 layout. Record what was exercised on real hardware, what is simulated, what is not yet tested. Steam Controller release coverage stays as future validation, not current blocker.
