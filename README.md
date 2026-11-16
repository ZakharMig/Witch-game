# Witch Game v0.7 — Painted Witch Animation (Godot 4 / Xogot)

This release adds a **true, pre-rendered 16-frame character animation atlas** at `art/witch_anim_v07.webp` (1280 × 1280, alpha background, 4 columns × 4 rows, 320 × 320 per frame). Each frame depicts a separately painted pose, rather than procedurally stretching a single still sprite.

Rows in the atlas:
- **Idle (4 poses):** cloak/hair shifts and subtle breathing.
- **Walk (4 poses):** alternating strides and swinging cape; looped at 9 fps.
- **Jump (4 poses):** crouch, rise, midair, landing; selected by vertical jump velocity.
- **Cast (4 poses):** ready, raise staff, release, recovery; uses the existing spell timer.

The illustrated witch has the same general pointed hat, burgundy cloak, equipment and staff concept, but the new hand-painted character art is a refreshed interpretation, *not* a pixel-exact duplicate of the previous sprite. The original `art/witch.png` is retained for comparison. Art direction can be refined after the iPad test.

To reduce iPad load, the character atlas is compressed WebP with transparency, and **does not build or edit 18 sprite textures pixel-by-pixel at startup**. Code draws the selected atlas region each frame.

Forest exterior remains the full-res version 0.6 painting (`art/forest_painted_v06.webp`). Interior, HUD, controller, 4-direction movement, jump height, green spells and the house USE interaction remain unchanged.

**Controls:** iPad arrows, JUMP, CAST, USE; keyboard WASD/arrows, Space, J, E.

**Test:** import `https://github.com/ZakharMig/Witch-game` (main branch) into Xogot. Check that the witch displays correctly with no checkerboard, loops idle and walking, changes pose during jump and casts, and all prior gameplay remains. If an issue occurs, v0.6 is saved as `backup/v0.6-working`. Runtime test on Xogot is not yet performed.
