# Witch Game v0.10 — Unified Comic Art

Godot 4 / Xogot iPad 2.5D beat-'em-up witch RPG prototype.

## Visual update
- `art/forest_comic_v010.webp` is a clean 1920 × 1080 comic-style dark fantasy exterior (no character or interface baked into the backdrop). The background includes a cottage, moonlit forest and wide dark arena with a warm-to-cool depth gradient.
- `art/witch_anim_comic_v010.webp` is a 1280 × 1280 **4 × 4 atlas** of separate idle / walk / jump / cast animation poses. Hair has auburn accents, and the cape/outfit now use a violet-burgundy comic palette. The atlas has real alpha transparency; pale fringe pixels and floor lines have been removed/cleaned around the figure. For best results, import with filtering suited to painted sprites.
- Comic-style UI adds a cropped witch portrait, red health and blue XP bars, darker ink panels and gold-rimmed touch controls.
- The slime is re-inked in emerald/jade tones and uses the existing bounce animation.
- Existing chimney smoke and foreground swaying vegetation continue as separate in-game animated elements.

## Unchanged working functionality
Four-direction movement, jump height separate from ground depth, staff casts, enemy chase/hit/XP/defeat/retry, cottage interaction and healing, interior scene.

## Xogot test
Import `https://github.com/ZakharMig/Witch-game` from `main` as a new project on iPad. Check (1) the backdrop is fully visible (not cropped), (2) witch has no light/white border, (3) walk/jump/cast frames switch, (4) smoke/plants move, (5) attack/HP and USE at the door still work.

The previously user-tested v0.9 is saved in `backup/v0.9-working`. **v0.10 still requires a test in Xogot**; source files being present on GitHub is not a runtime test.


## Version 0.11 — witch animations

Three high-resolution 2048×2048 PNG atlases (4×4 cells of 512×512) replace the old displayed witch: `art/witch_idle_v011.png`, `art/witch_walk_v011.png`, and `art/witch_attack_v011.png`. Each atlas has 16 original GIF frames and transparency; the old character artwork remains in the repository as backup. The attack maintains individually timed frames, with a faster magical strike and projectile release aligned to the strike. Jump currently displays a static pose of the new witch until jump frames are supplied. Original GIFs are ~307–315 px per frame; enlarging them does not recreate detail missing from those GIFs. Open `project.godot` in Xogot after refreshing the project from GitHub.
