# Witch Game 0.6 — Painted Dark Forest (Godot 4 / Xogot)

This release restores the earlier working gameplay and replaces the failed low-resolution v0.5 exterior with a **full-frame, 1920 × 1080 WebP painted night-forest background** at `art/forest_painted_v06.webp`. The art contains only the environment (no baked-in witch, UI buttons or HUD), including a crooked warmly illuminated witch cottage at the centre, cold blue forest, moonlight, and a broad walkable clearing in the foreground. The image is displayed at the existing Godot viewport (1280 × 720, 16:9).

The front-door interaction anchor is aligned to the painted door near x=633, y=472 in viewport coordinates. The character still moves freely on the 2.5D arena (4 directions) and jumps separately above its ground coordinates. Green spells, enemy XP, procedural idle/walk/jump motion and the USE transition to the existing cottage interior are retained. Light mist drifts over the ground. This is a **single painted exterior backdrop**; fully separate foreground/background parallax layers and hand-drawn witch animation frames are future tasks.

## Controls
- iPad: UP, DOWN, LEFT, RIGHT, JUMP, CAST, USE.
- Keyboard: WASD/arrows, Space (jump), J (cast), E (enter/exit).
- To enter, stand near the centre cottage's door and tap USE. Indoors, move toward the exit door and tap USE again.

## iPad testing
Import or re-download `https://github.com/ZakharMig/Witch-game` from the `main` branch in Xogot. Verify that the full forest, not a magnified crop, is displayed; the witch is drawn separately at normal size; movement in both screen axes, jump and spells remain functional; and the door can be used both ways.

The last known tested state before this artwork update is saved in `backup/v0.4-before-v06`. User-side runtime testing for v0.6 is still required.
