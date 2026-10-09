#!/usr/bin/env python3
"""Generate all audio for Water Sort with pure synthesis (no external assets).

Apothecary identity: warm room tone, glass clinks, liquid glugs (pitch varies
with fill level at runtime via playback rate), cork pops, brass chimes.
44.1kHz mono 16-bit WAV.
"""
import math
import os
import wave
import numpy as np

SR = 44100
OUT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                   'assets', 'audio')
os.makedirs(OUT, exist_ok=True)

rng = np.random.default_rng(42)


def save(name, sig):
    sig = np.clip(sig, -1, 1)
    sig = (sig * 0.7 * 32767).astype(np.int16)
    with wave.open(os.path.join(OUT, name), 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(sig.tobytes())
    print('wrote', name, f'{len(sig)/SR:.2f}s')


def env_ad(n, a, d, peak=1.0):
    e = np.ones(n)
    na = max(1, int(a * SR))
    nd = max(1, int(d * SR))
    e[:na] = np.linspace(0, 1, na)
    if nd >= n:
        e *= np.linspace(1, 0, n)
    else:
        e[n - nd:] = np.linspace(1, 0, nd)
    return e * peak


def tone(freq, dur, peak=0.7, attack=0.004, harmonics=(1.0, 0.35, 0.12)):
    n = int(dur * SR)
    t = np.arange(n) / SR
    sig = np.zeros(n)
    for i, h in enumerate(harmonics):
        sig += h * np.sin(2 * math.pi * freq * (i + 1) * t)
    sig *= env_ad(n, attack, dur - attack, peak)
    return sig


def seq(notes, note_dur, gap=0.0, peak=0.6, harm=(1.0, 0.4, 0.15)):
    total = int((note_dur + gap) * len(notes) * SR)
    sig = np.zeros(total)
    for i, f in enumerate(notes):
        t = tone(f, note_dur, peak, harmonics=harm)
        s = int(i * (note_dur + gap) * SR)
        sig[s:s + len(t)] += t
    return sig


# --- SFX -----------------------------------------------------------------
# click: brass button tick (short metallic snap)
n = int(0.07 * SR)
t = np.arange(n) / SR
click = (rng.standard_normal(n) * np.exp(-t * 240) * 0.5
         + np.sin(2 * math.pi * 2400 * t) * np.exp(-t * 200) * 0.5
         + np.sin(2 * math.pi * 1200 * t) * np.exp(-t * 150) * 0.3)
save('click.wav', click)

# clink: dull glass clink for invalid moves (inharmonic partials, fast decay)
n = int(0.4 * SR)
t = np.arange(n) / SR
clink = np.zeros(n)
for f, a, dec in [(2620, 0.55, 34), (3471, 0.30, 40), (5230, 0.18, 52),
                  (880, 0.25, 20)]:
    clink += a * np.sin(2 * math.pi * f * t) * np.exp(-t * dec)
clink += rng.standard_normal(n) * np.exp(-t * 300) * 0.12
save('clink.wav', clink)

# pour: liquid glug — three little bloops (playback rate varies with fill)
def bloop(f0, f1, dur, peak=0.7):
    n = int(dur * SR)
    t = np.arange(n) / SR
    f = f0 + (f1 - f0) * (t / dur)
    phase = 2 * math.pi * np.cumsum(f) / SR
    return np.sin(phase) * env_ad(n, 0.01, dur - 0.01, peak)

pour = np.concatenate([
    bloop(420, 190, 0.14, 0.75),
    np.zeros(int(0.03 * SR)),
    bloop(360, 160, 0.15, 0.7),
    np.zeros(int(0.03 * SR)),
    bloop(300, 140, 0.18, 0.65),
])
save('pour.wav', pour)

# pop: cork pop — airy burst + low thump
n = int(0.14 * SR)
t = np.arange(n) / SR
pop = (rng.standard_normal(n) * np.exp(-t * 90) * 0.8
       + np.sin(2 * math.pi * 280 * t) * np.exp(-t * 45) * 0.7
       + np.sin(2 * math.pi * 140 * t) * np.exp(-t * 30) * 0.4)
save('pop.wav', pop)

# chime: brass chime arpeggio for 3-star victory
chime = seq([523.25, 659.25, 783.99, 1046.5, 1318.5], 0.22, 0.04, peak=0.55,
            harm=(1.0, 0.5, 0.22, 0.08))
save('chime.wav', chime)

# start: cork pop + rising two-note (level start)
n2 = int(0.14 * SR)
start = np.concatenate([pop[:n2],
                        np.zeros(int(0.02 * SR)),
                        seq([392.0, 523.25], 0.16, 0.02, peak=0.5)])
save('start.wav', start)

# undo: soft wooden creak + slide down
n = int(0.22 * SR)
t = np.arange(n) / SR
creak = np.sin(2 * math.pi * (300 - 160 * t / (n / SR)) * t) * np.exp(-t * 14)
creak += rng.standard_normal(n) * np.exp(-t * 60) * 0.06
save('undo.wav', creak * 0.8)


# --- MUSIC ---------------------------------------------------------------
def pad_chord(freqs, dur, peak=0.10):
    """Warm soft pad: detuned sines with slow swell."""
    n = int(dur * SR)
    t = np.arange(n) / SR
    sig = np.zeros(n)
    for f in freqs:
        sig += (np.sin(2 * math.pi * f * t)
                + 0.4 * np.sin(2 * math.pi * f * 2.003 * t)
                + 0.2 * np.sin(2 * math.pi * f * 0.5 * t))
    swell = np.sin(np.pi * t / dur) ** 0.7
    return sig * swell * peak / max(1, len(freqs))


def pluck(freq, dur, peak=0.16):
    n = int(dur * SR)
    t = np.arange(n) / SR
    sig = (np.sin(2 * math.pi * freq * t)
           + 0.35 * np.sin(2 * math.pi * freq * 2 * t)
           + 0.12 * np.sin(2 * math.pi * freq * 3 * t))
    return sig * np.exp(-t * 5.5) * peak


# Menu music: warm room tone, gentle 12s loop (Am - F - C - G whispers)
dur = 12.0
n = int(dur * SR)
t = np.arange(n) / SR
music = np.zeros(n)
# faint room tone
music += 0.012 * rng.standard_normal(n)
chords = [[220.0, 261.63, 329.63],      # Am
          [174.61, 220.0, 261.63],      # F
          [130.81, 164.81, 196.0, 261.63],  # C
          [196.0, 246.94, 293.66]]     # G
for i, ch in enumerate(chords):
    s = int(i * 3.0 * SR)
    seg = pad_chord(ch, 3.4, peak=0.10)
    e = min(n, s + len(seg))
    music[s:e] += seg[:e - s]
# sparse plucked melody, crossfades at loop point
for tm, f in [(1.0, 440.0), (4.2, 523.25), (7.1, 392.0), (10.0, 329.63)]:
    s = int(tm * SR)
    seg = pluck(f, 1.6)
    e = min(n, s + len(seg))
    music[s:e] += seg[:e - s]
# loop crossfade: blend last 1s into first 1s
fade = int(1.0 * SR)
music[:fade] = (music[:fade] * np.linspace(0, 1, fade)
                + music[-fade:] * np.linspace(1, 0, fade))
music = music[:-fade]
save('music_menu.wav', music)

# Gameplay music: 16s loop, slightly more present + soft wooden knocks
dur = 16.0
n = int(dur * SR)
t = np.arange(n) / SR
music = np.zeros(n)
music += 0.010 * rng.standard_normal(n)
chords = [[220.0, 277.18, 329.63],      # A
          [174.61, 220.0, 293.66],      # Fmaj7-ish
          [146.83, 174.61, 220.0],      # Dm
          [164.81, 196.0, 246.94, 293.66]]  # Em9-ish
for i, ch in enumerate(chords):
    s = int(i * 4.0 * SR)
    seg = pad_chord(ch, 4.5, peak=0.09)
    e = min(n, s + len(seg))
    music[s:e] += seg[:e - s]
for tm, f in [(0.5, 440.0), (3.8, 554.37), (6.5, 493.88), (9.2, 587.33),
              (12.0, 440.0), (14.2, 329.63)]:
    s = int(tm * SR)
    seg = pluck(f, 1.4, peak=0.13)
    e = min(n, s + len(seg))
    music[s:e] += seg[:e - s]
# soft wooden knocks as gentle pulse
for tm in [2.0, 6.0, 10.0, 14.0]:
    nn = int(0.09 * SR)
    tt = np.arange(nn) / SR
    knock = (np.sin(2 * math.pi * 190 * tt) * np.exp(-tt * 40) * 0.10
             + rng.standard_normal(nn) * np.exp(-tt * 200) * 0.03)
    s = int(tm * SR)
    music[s:s + nn] += knock
fade = int(1.0 * SR)
music[:fade] = (music[:fade] * np.linspace(0, 1, fade)
                + music[-fade:] * np.linspace(1, 0, fade))
music = music[:-fade]
save('music_game.wav', music)

print('done')
