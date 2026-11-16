# Witch Game — 2D Action RPG (Godot 4 / Xogot)

## Version 0.2 — brawler arena

A small playable prototype for the Xogot editor on iPad. Inspired by classic side-view beat-'em-up movement: walk along the arena floor in four directions while jumping independently.

### Controls
- **iPad**: LEFT / RIGHT / UP / DOWN on-screen buttons; JUMP and CAST on the right. Multi-touch supported.
- **Keyboard**: WASD or arrow keys to move, Space to jump, J to cast.
- **Combat**: green projectile flies left or right; it hits the slime only if aligned by depth.
- **RPG basics**: health bar, experience and level.

### Artwork
`art/witch.svg` is an original, hand-drawn-style **temporary illustrated sprite**, referencing the agreed simple witch costume (dark pointed hat, maroon cape, cream blouse, brown corset, green magical staff). It is not the final frame-by-frame animated character. Walking uses temporary bob animation and idle uses gentle breathing.

### Structure
- `project.godot` — engine configuration
- `main.tscn` — main scene
- `game.gd` — game logic, controls, rendering
- `art/witch.svg` — transparent vector witch artwork

### Known limitations
- First Xogot 4.7 test is still required; the previous v0.1 was confirmed working.
- The witch is currently a single illustration, not an authored sprite sheet.
- The slime is static; damage to the player, inventory, quests, collisions and animations are future work.
- This is a pseudo-3D arena with Y-depth sorting; not a platformer with multiple physical floors.

### How to update Xogot
Download the current `main` branch from GitHub using Xogot's **Download from GitHub**, or import a new ZIP from the repository. If Xogot keeps an older local project, create a fresh import to avoid editing the wrong copy.

Version 0.1 remains available in the Git history; v0.2 is in the next commit.
