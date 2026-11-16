# Witch Game 0.7 — Witch Animation Prototype (Godot 4 / Xogot)

## What changed
- The **original Witch sprite** (`art/witch.png`) is preserved exactly as the character's source, so the witch's silhouette, hat, cape, staff, colours and costume are not replaced by a different illustration.
- At startup, Godot generates and caches **18 distinct raster pose textures** from the existing 90×154 witch PNG, with independent pixel-region shifts for cloak, head, feet, torso and staff. These are real frame textures selected in an animation sequence, not simply whole-character rotation.
- Four animation states: idle (4 frames), walking (6 frames), jumping (4 poses), casting (4 poses). The casting pose is timed with spell creation. The staff glow follows the approximate crystal position.
- Forest exterior, cabin, interior, 4-direction brawler movement, independent jump height, spell combat, XP, door USE and touch controls are unchanged.

## Important artistic limitation
This is a **first frame-based animation prototype generated from the existing sprite**, NOT 18 hand-drawn fully redrawn animation frames. It preserves the character faithfully and tests frame timing/animation states, but movement is still limited by the single source illustration. A future professional animation pass should use separately drawn key poses for legs, hands, fabric, staff and hair.

## Controls and iPad test
- iPad: LEFT/RIGHT/UP/DOWN, JUMP, CAST, USE.
- Keyboard: WASD/arrows, Space, J, E.
- Import the `main` branch of https://github.com/ZakharMig/Witch-game into Xogot. Test that the witch's cape/legs subtly animate in walking, her pose changes in the air, she has breathing/cloth motion at rest, and she moves the staff when casting.
- Verify the forest, cottage, entry/exit, and combat are still working.

Last known working version v0.6: `backup/v0.6-working`. Xogot runtime verification of v0.7 is still pending.
