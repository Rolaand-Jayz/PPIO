# Combat test slice — controls reference

Default input: Xbox/XInput-compatible gamepad. Keyboard/mouse has full feature
parity via the same Godot InputMap actions (no divergent gameplay logic).
On-screen prompts follow the last device used (pad glyphs or key names).

## Actions (project.godot InputMap)

| Game action | Pad | Keyboard |
|---|---|---|
| Move unit / grid cursor | Left stick · D-pad | WASD |
| Camera orbit | Right stick | Arrow keys |
| Zoom | LT / RT | `-` / `=` |
| Confirm | A | Enter · Space |
| Cancel / back | B | Esc |
| Command menu / begin combat | Y | Tab |
| (Reserved) ability shortcut | X | F |
| Switch party member / cycle | LB / RB | Q / E |
| Pause | Start | P |

Menus additionally use standard `ui_accept` / `ui_cancel` / `ui_*` navigation
(D-pad/stick, arrows), so focus can never strand: every opened menu grabs
focus, and B/Esc always backs out one level.

## Battle flow

1. **Explore** — step a toy around the room edge; `Y` begins the encounter
   (encounter stinger, combat theme starts).
2. **Move** — reachable cells highlight; move the cursor, `A` confirms a move
   (one move per activation, Kip/Rallo move 2), `A` on the unit's own cell or
   `Y` opens commands without moving, `B` cancels, LB/RB switches toy.
3. **Command** — contextual actions for the selected toy; disabled entries
   (e.g. Ram without momentum, Mend on cooldown) are greyed.
4. **Target** — pick a foe (or ally for Mend); range shown in the entry,
   out-of-range picks are refused with a denial cue.
5. **Resolve** — animation, impact, floating damage, HP bars, camera shake.
6. **Enemy turn** — each foe telegraphs (`!` + warning + ring under target),
   then attacks or advances; dazed foes visibly lose their attack.
7. **Result** — victory/defeat overlay; `A` restarts, `B` quits.

## Pause / settings (Start)

- Resume · Settings · Controls · Restart Battle · Quit.
- Settings: per-bus volume sliders + mute (Master, Music, SFX, UI, Ambience),
  camera-shake toggle. Persisted to `user://settings.cfg`.
