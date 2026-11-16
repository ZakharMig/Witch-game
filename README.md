# Witch Game v0.5 — Painted Cottage Art Test (Godot 4 / Xogot)

This update introduces the **first actual raster-painted exterior artwork**: `art/forest_painted_v05.webp`, cut from an original generated fantasy painting to exclude the painted-in witch and user-interface controls. The editable player, HUD and touch controls are still rendered by the game engine. The warm-lit cottage door is aligned near the existing entrance trigger (x≈640), so walking up to the door and pressing USE should still work.

To keep download and startup lightweight on the iPad, the first painted asset is deliberately compressed (400 × 225 pixels). This is a **visual direction prototype**, not the final full-resolution background. As a consequence, it may look somewhat soft at 1280 × 720. The v0.4 vector forest is still kept in `art/forest_v04.svg` as a backup. The interior still uses `art/interior_v04.svg`; high-resolution repainting of the interior is future work.

The rest of the v0.4 mechanics have been retained: 4-direction brawler movement, separate jump height, procedural idle/walk/jump, magic against the slime, XP, and cabin entrance/exit. Subtle animated cool-colour mist has been added to the exterior foreground.

## iPad test
Import the main branch from https://github.com/ZakharMig/Witch-game into Xogot, run the game, confirm the painting has loaded, test UP/DOWN/LEFT/RIGHT, JUMP, CAST, USE at the cottage door and USE again inside.

Keyboard: WASD/arrows, Space jump, J spell, E enter/exit.

Last known working v0.4: branch `backup/v0.4-working`. Any runtime compatibility issues should be reported with a screenshot.
