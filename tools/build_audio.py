#!/usr/bin/env python3
# Combat-slice audio factory — synthesizes original music and SFX (no
# copyrighted sources, no samples). Deterministic; rebuild anytime:
#   python3 tools/build_audio.py
# Outputs WAV into assets/audio/sfx + assets/audio/ui, OGG for music/ambience
# via ffmpeg. All audio is original/procedural, status: proxy (non-final).

import math
import os
import subprocess
import struct
import wave

import numpy as np

SR = 44100
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SFX_DIR = os.path.join(ROOT, "assets", "audio", "sfx")
UI_DIR = os.path.join(ROOT, "assets", "audio", "ui")
MUS_DIR = os.path.join(ROOT, "assets", "audio", "music")

# ------------------------------------------------------------- primitives

def t(dur):
    return np.arange(int(SR * dur)) / SR

def env(n, attack=0.005, release=0.05, shape=1.0):
    e = np.ones(n)
    a = min(max(1, int(attack * SR)), n)
    r = min(max(1, int(release * SR)), n)
    e[:a] = np.linspace(0, 1, a)
    e[-r:] *= np.linspace(1, 0, r) ** shape
    return e

def sine(freq, dur, vol=1.0, attack=0.005, release=0.05):
    return vol * np.sin(2 * math.pi * freq * t(dur)) * env(len(t(dur)), attack, release)

def sweep(f0, f1, dur, vol=1.0, kind="sine", attack=0.005, release=0.05):
    tt = t(dur)
    freqs = np.linspace(f0, f1, len(tt))
    phase = 2 * math.pi * np.cumsum(freqs) / SR
    if kind == "square":
        wavef = np.sign(np.sin(phase))
    elif kind == "saw":
        wavef = 2 * ((phase / (2 * math.pi)) % 1) - 1
    elif kind == "tri":
        wavef = 2 * np.abs(2 * ((phase / (2 * math.pi)) % 1) - 1) - 1
    else:
        wavef = np.sin(phase)
    return vol * wavef * env(len(tt), attack, release)

def noise(dur, vol=1.0, lp=None, hp=None, attack=0.002, release=0.05):
    x = np.random.default_rng(1234 + int(dur * 1000)).uniform(-1, 1, int(SR * dur))
    if lp:
        alpha = math.exp(-2 * math.pi * lp / SR)
        out = np.zeros_like(x)
        acc = 0.0
        for i in range(len(x)):
            acc = (1 - alpha) * x[i] + alpha * acc
            out[i] = acc
        x = out * (1 - alpha) * 8
    if hp:
        alpha = math.exp(-2 * math.pi * hp / SR)
        prev_x, prev_y, out = 0.0, 0.0, np.zeros_like(x)
        for i in range(len(x)):
            y = alpha * (prev_y + x[i] - prev_x)
            out[i], prev_x, prev_y = y, x[i], y
        x = out * 1.5
    return vol * x * env(len(x), attack, release)

def mix(*tracks):
    n = max(len(tr) for tr in tracks)
    out = np.zeros(n)
    for tr in tracks:
        out[: len(tr)] += tr
    return out

def cat(*tracks):
    return np.concatenate(tracks)

def silence(dur):
    return np.zeros(int(SR * dur))

def normalize(x, peak=0.72):
    m = np.max(np.abs(x))
    return x * (peak / m) if m > 1e-9 else x

def wrap_loop(x, tail_s=0.2):
    """Fold the release tail into the head for click-free looping."""
    n = int(tail_s * SR)
    x = x.copy()
    x[:n] += x[-n:]
    return x[:-n]

def write_wav(path, x):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    x = np.clip(x, -1, 1)
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes((x * 32767).astype("<i2").tobytes())
    print("WAV", path)

def write_ogg(path, x, quality=4):
    tmp = path + ".tmp.wav"
    write_wav(tmp, x)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", tmp,
                    "-c:a", "libvorbis", "-q:a", str(quality), path], check=True)
    os.remove(tmp)
    print("OGG", path)

def midi(f):
    return 440.0 * 2 ** ((f - 69) / 12)

# ------------------------------------------------------------- music

def kick(dur=0.16, vol=0.9):
    return normalize(sweep(130, 42, dur, kind="sine", attack=0.001, release=0.08) * vol, 0.9)

def snare(vol=0.55):
    return normalize(mix(noise(0.14, 0.8, hp=1500, release=0.1), sine(190, 0.1, 0.4, release=0.08)) * vol, 0.6)

def hat(vol=0.25, open_=False):
    d = 0.12 if open_ else 0.035
    return normalize(noise(d, 0.7, hp=7000, release=0.02 if not open_ else 0.1) * vol, 0.3)

def place(buf, start_s, x):
    i = int(start_s * SR)
    end = i + len(x)
    if end > len(buf):
        x = x[: len(buf) - i]
        end = len(buf)
    buf[i:end] += x

def build_combat_theme():
    """Original loopable combat theme — A minor, 140 BPM, 16 bars (27.43s).
    Role: mid-intensity battle energy that never masks command/impact cues."""
    bpm = 140.0
    beat = 60.0 / bpm
    loop = 16 * 4 * beat
    buf = np.zeros(int(SR * loop))
    A, C, D, E, F, G = 57, 60, 62, 64, 53, 55          # midi numbers (A3 etc.)
    prog = [[45, 57, 60], [41, 53, 57], [43, 55, 59], [40, 52, 55]]  # Am F G E
    # bass: driving 8ths, root with octave pop on last 8th of each bar
    for bar in range(16):
        root = prog[(bar // 4) % 4][0]
        for e in range(8):
            f = midi(root + (12 if e == 7 else 0))
            place(buf, (bar * 4 + e * 0.5) * beat, sweep(f, f, 0.20, 0.30, kind="saw", release=0.1))
    # chord stabs on off-beats
    for bar in range(16):
        chord = prog[(bar // 4) % 4]
        for beat_off in (1.0, 2.5):
            for n in chord[1:]:
                place(buf, (bar * 4 + beat_off) * beat,
                      sweep(midi(n), midi(n), 0.22, 0.10, kind="square", release=0.15))
    # pad: soft sustained root+fifth each 4 bars
    for seg in range(4):
        chord = prog[seg]
        for n in (chord[0] + 12, chord[2] + 12):
            place(buf, seg * 8 * beat, sweep(midi(n), midi(n), 8 * beat, 0.055, kind="tri", attack=0.6, release=1.2))
    # lead melody (phrase of 8 bars, then variation ending upward)
    lead = [
        (0.0, 0.75, 69), (0.75, 0.25, 72), (1.0, 1.0, 76), (2.0, 1.0, 72),
        (3.0, 0.75, 71), (3.75, 0.25, 72), (4.0, 1.5, 69), (6.0, 1.0, 64),
        (7.0, 1.0, 67),
        (8.0, 0.75, 69), (8.75, 0.25, 72), (9.0, 1.0, 76), (10.0, 1.0, 79),
        (11.0, 0.75, 76), (11.75, 0.25, 74), (12.0, 1.5, 72), (14.0, 1.0, 71),
        (15.0, 1.0, 72),
    ]
    for start_b, dur_b, note in lead:
        place(buf, start_b * beat, sweep(midi(note), midi(note), dur_b * beat * 0.95, 0.16,
                                         kind="tri", attack=0.02, release=0.15))
    # sparkle arpeggio 16ths (quiet)
    for bar in range(16):
        chord = prog[(bar // 4) % 4]
        for s in range(16):
            if s % 2 == 0:
                n = chord[1 + (s // 4) % 2] + 12
                place(buf, (bar * 4 + s * 0.25) * beat, sine(midi(n), 0.09, 0.045, release=0.06))
    # drums
    for bar in range(16):
        for b in range(4):
            place(buf, (bar * 4 + b) * beat, kick(vol=0.75 if b in (0, 2) else 0.55))
            if b in (1, 3):
                place(buf, (bar * 4 + b) * beat, snare())
        for h in range(8):
            place(buf, (bar * 4 + h * 0.5) * beat, hat(open_=(h == 3 or h == 7)))
    # final fill into loop seam (last bar): snare roll 16ths
    for s in range(16):
        place(buf, (15 * 4 + s * 0.25) * beat, snare(vol=0.2 + 0.02 * s))
    buf = np.tanh(buf * 1.4) * 0.85
    buf = wrap_loop(normalize(buf, 0.82), tail_s=0.25)
    return buf

def stinger_encounter():
    """Riser + heavy hit + rising third — 'battle begins'."""
    a = mix(noise(0.9, 0.35, hp=400, attack=0.5, release=0.2),
            sweep(220, 880, 0.9, 0.12, kind="saw", attack=0.4, release=0.2))
    hit = mix(kick(0.3, 1.0), noise(0.2, 0.5, lp=900, release=0.15),
              sweep(midi(69), midi(69), 0.5, 0.2, release=0.4),
              sweep(midi(76), midi(76), 0.5, 0.15, attack=0.01, release=0.4))
    return normalize(cat(silence(0.65), a, hit), 0.8)

def stinger_victory():
    """Bright original fanfare: I–V–vi–IV-style rising triad flourish."""
    notes = [(0.0, 64), (0.12, 64), (0.24, 64), (0.45, 60), (0.7, 64), (0.95, 67), (1.25, 72)]
    buf = silence(2.4)
    for start, n in notes:
        place(buf, start, mix(sweep(midi(n), midi(n), 0.6, 0.3, kind="tri", release=0.5),
                              sweep(midi(n + 12), midi(n + 12), 0.45, 0.1, kind="sine", release=0.4)))
    place(buf, 1.25, kick(0.25, 0.5))
    return normalize(buf, 0.8)

def stinger_defeat():
    """Descending minor fall, low and heavy."""
    buf = silence(2.6)
    for i, (start, n) in enumerate([(0.0, 64), (0.4, 62), (0.8, 60), (1.3, 57)]):
        place(buf, start, sweep(midi(n), midi(n) * 0.98, 0.7, 0.28, kind="tri", release=0.5))
    place(buf, 1.3, kick(0.5, 0.7))
    place(buf, 1.3, noise(0.6, 0.2, lp=500, release=0.5))
    return normalize(buf, 0.8)

def build_ambience():
    """Soft domestic room tone + sparse toy music-box plinks; 8s loop."""
    buf = silence(8.0)
    place(buf, 0, noise(8.0, 0.05, lp=300, attack=1.0, release=1.0))
    rng = np.random.default_rng(77)
    plinks = [(1.2, 88), (3.4, 93), (5.1, 86), (6.9, 91)]
    for start, n in plinks:
        place(buf, start, sine(midi(n), 0.8, 0.06, attack=0.01, release=0.7))
        place(buf, start + 0.02, sine(midi(n) * 2, 0.5, 0.02, attack=0.01, release=0.4))
    _ = rng
    return wrap_loop(normalize(buf, 0.5), tail_s=1.0)

# ------------------------------------------------------------- SFX

def sfx_library():
    out = {}
    # UI (also routed to UI bus in-engine)
    out["ui_move"] = sine(660, 0.06, 0.5, release=0.03)
    out["ui_confirm"] = cat(sine(523, 0.07, 0.5), sine(784, 0.1, 0.55, release=0.06))
    out["ui_cancel"] = cat(sine(440, 0.07, 0.5), sine(330, 0.1, 0.5, release=0.06))
    out["ui_deny"] = sweep(140, 110, 0.16, 0.5, kind="square", release=0.06)
    out["ui_open"] = sweep(300, 620, 0.16, 0.4, release=0.06)
    out["ui_close"] = sweep(620, 300, 0.16, 0.4, release=0.06)
    out["ui_target"] = sine(880, 0.05, 0.45, release=0.02) + 0.4 * sine(1320, 0.05, 0.2, release=0.02)
    out["ui_party"] = cat(sine(392, 0.08, 0.45), sine(523, 0.1, 0.5, release=0.05))
    out["ui_pause"] = cat(sine(494, 0.09, 0.45), silence(0.02), sine(392, 0.12, 0.45, release=0.06))
    # Jayze — bright steel
    out["jayze_attack"] = normalize(mix(noise(0.22, 0.5, hp=900, attack=0.05, release=0.1),
                                        sweep(500, 1800, 0.2, 0.25, release=0.1)), 0.7)
    out["jayze_ability"] = normalize(cat(noise(0.35, 0.45, hp=600, attack=0.15, release=0.15),
                                         sweep(300, 1500, 0.3, 0.3, release=0.12),
                                         noise(0.25, 0.6, lp=1800, release=0.15),
                                         mix(sine(620, 0.4, 0.3, release=0.35), sine(930, 0.35, 0.2, release=0.3))), 0.75)
    # Kip — small car
    out["kip_shoot"] = normalize(cat(sweep(700, 180, 0.05, 0.7, release=0.03),
                                     sweep(320, 950, 0.1, 0.5, kind="square", release=0.05)), 0.7)
    out["kip_ram"] = normalize(cat(sweep(70, 165, 0.42, 0.5, kind="saw", attack=0.05, release=0.1)
                                   + 0.3 * sweep(105, 250, 0.42, 0.3, kind="square", release=0.1),
                                   kick(0.22, 0.9), noise(0.18, 0.5, lp=700, release=0.12)), 0.78)
    # Rallo — stone & wing
    sw = lambda f0, f1, d: noise(d, 0.5, hp=f0, attack=0.03, release=0.05)
    out["rallo_claw"] = normalize(cat(sw(1200, 0, 0.1), silence(0.03), sw(1500, 0, 0.1),
                                      silence(0.02), sw(900, 0, 0.14)), 0.7)
    out["rallo_ability"] = normalize(mix(sweep(920, 380, 0.55, 0.45, kind="tri", attack=0.05, release=0.2)
                                         + 0.25 * sweep(1390, 570, 0.55, 0.2, kind="sine", release=0.2),
                                         noise(0.5, 0.2, hp=2500, attack=0.1, release=0.3)), 0.7)
    # Jonnie — heavy machinery
    out["jonnie_attack"] = normalize(cat(sweep(55, 130, 0.32, 0.5, kind="square", attack=0.04, release=0.08),
                                         kick(0.3, 1.0),
                                         mix(sine(420, 0.3, 0.3, release=0.25), noise(0.22, 0.4, lp=1200, release=0.15))), 0.8)
    out["jonnie_ability"] = normalize(mix(sine(523, 0.5, 0.28, release=0.42),
                                          sine(659, 0.45, 0.22, release=0.38),
                                          sine(784, 0.4, 0.18, release=0.34),
                                          sine(1046, 0.35, 0.12, release=0.3)), 0.7)
    out["jonnie_brace"] = normalize(mix(sine(1150, 0.18, 0.4, release=0.14),
                                        sine(1720, 0.14, 0.2, release=0.12),
                                        noise(0.16, 0.3, lp=1600, release=0.1),
                                        kick(0.16, 0.5)), 0.7)
    # impacts & reactions
    out["impact_light"] = normalize(mix(sweep(220, 90, 0.1, 0.7, release=0.05),
                                        noise(0.07, 0.5, lp=1000, release=0.04)), 0.72)
    out["impact_heavy"] = normalize(mix(sine(392, 0.22, 0.5, release=0.2),
                                        sine(522, 0.2, 0.35, release=0.18),
                                        noise(0.14, 0.5, lp=1400, release=0.1),
                                        kick(0.2, 0.8)), 0.8)
    out["guard_block"] = normalize(mix(sine(1240, 0.16, 0.4, release=0.14),
                                       sine(1860, 0.12, 0.18, release=0.1),
                                       noise(0.08, 0.25, hp=2000, release=0.05)), 0.66)
    out["hit_react"] = normalize(mix(sweep(300, 140, 0.16, 0.55, release=0.08),
                                     noise(0.1, 0.35, lp=800, release=0.06)), 0.68)
    out["evade"] = normalize(noise(0.2, 0.45, hp=1100, attack=0.04, release=0.12), 0.6)
    out["ko_down"] = normalize(cat(kick(0.3, 0.9), noise(0.5, 0.4, lp=600, attack=0.02, release=0.4),
                                   sweep(500, 120, 0.5, 0.35, release=0.4)), 0.78)
    out["telegraph_warn"] = normalize(cat(sine(740, 0.1, 0.4, release=0.02), silence(0.06),
                                          sine(740, 0.1, 0.4, release=0.02), silence(0.04),
                                          sweep(740, 990, 0.14, 0.35, release=0.1)), 0.6)
    out["enemy_attack"] = normalize(cat(noise(0.16, 0.5, hp=700, attack=0.04, release=0.08),
                                        noise(0.16, 0.55, lp=900, release=0.1)), 0.72)
    out["projectile"] = normalize(sweep(260, 820, 0.2, 0.4, kind="saw", release=0.1)
                                  + 0.3 * sweep(390, 1230, 0.2, 0.3, release=0.1), 0.6)
    out["heal"] = normalize(mix(sine(659, 0.4, 0.3, release=0.35), sine(880, 0.35, 0.22, release=0.3)), 0.62)
    out["stagger"] = normalize(mix(sweep(200, 90, 0.3, 0.5, kind="square", release=0.15),
                                   noise(0.2, 0.3, lp=900, release=0.15)), 0.7)
    return out

# ------------------------------------------------------------- main

def main():
    os.makedirs(SFX_DIR, exist_ok=True)
    os.makedirs(UI_DIR, exist_ok=True)
    os.makedirs(MUS_DIR, exist_ok=True)
    for name, x in sfx_library().items():
        sub = UI_DIR if name.startswith("ui_") else SFX_DIR
        write_wav(os.path.join(sub, name + ".wav"), normalize(x, 0.7))
    write_ogg(os.path.join(MUS_DIR, "combat_theme.ogg"), build_combat_theme())
    write_ogg(os.path.join(MUS_DIR, "encounter_start.ogg"), stinger_encounter())
    write_ogg(os.path.join(MUS_DIR, "victory.ogg"), stinger_victory())
    write_ogg(os.path.join(MUS_DIR, "defeat.ogg"), stinger_defeat())
    write_ogg(os.path.join(MUS_DIR, "ambience.ogg"), build_ambience())
    print("AUDIO BUILD COMPLETE")

if __name__ == "__main__":
    main()
