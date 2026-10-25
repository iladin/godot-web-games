# Starfall — design

- **Pitch:** Catch falling gold stars with your orb while dodging red meteors.
- **Core loop:** Read the sky → slide under a star → avoid the meteor next to it (~1 s).
- **Controls:** keyboard — ←/→ (ui_left/ui_right) · touch — drag anywhere, orb follows your finger's x.
- **Fail / win:** 3 lives; meteor hit costs one (1 s invulnerability). Endless, chase high score.
- **Score:** 10 × combo (combo caps at x5, resets on a missed star or a hit).
- **Ramp:** spawn interval 0.85 s → 0.22 s (−0.012/s); fall speed +7 px/s per second; meteor share 25% → 55%.
- **Juice:** particle bursts, +score popups, screen shake + red flash on hit, invulnerability blink, parallax starfield.
- **Out of scope:** power-ups, audio, multiple levels.
