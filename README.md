# Witch Game 0.3 — Witch Home (Xogot / Godot 4.x)

A playable 2.5D brawler/RPG prototype for iPad. The starting screen is a **cold, dark forest** with a **warmly lit witch cottage** at its centre. Walk to the door and interact to enter a **warm interior**, then interact with the exit to return to the forest. The existing slime, magic, health, XP and jump mechanics remain.

## Controls

| iPad | Keyboard | Action |
| --- | --- | --- |
| UP / DOWN / LEFT / RIGHT | WASD or arrows | Walk around the arena |
| JUMP | Space | Jump with separate ground depth |
| CAST | J | Shoot green magic |
| USE | E | Enter/exit the cottage near the door |

**Important:** Release USE between transitions. The entrance trigger is near the front of the door on the forest floor; inside, approach the centre exit door.

## Character animation in this prototype

The existing illustrated witch PNG is animated **procedurally** in code:
* `idle`: breathing and gentle sway;
* `walk`: cyclic bobbing and tilting;
* `jump`: squash/stretch with the independently simulated jump height.

This is deliberately a **first animation pass**, **not** a finished hand-drawn 4–8-frame sprite sheet. Replacing these with polished hand-drawn sprite animations is a later art task.

## Visuals

Environment, cabin, interior, glow, fog and furniture are stylized primitives drawn in `game.gd`. These are functional art placeholders for the approved dark cinematic forest + warm-light direction, not final painted backgrounds. Staff glow uses translucent circles, not dynamic lighting/shadows.

## Testing on iPad

Import `https://github.com/ZakharMig/Witch-game` as a new project in Xogot (main branch) and run. Test movement in 4 directions, jumping, spells, USE at the cottage door, and USE inside to exit. If Xogot asks to update Godot format, keep a backup. The last known-good v0.2 was saved in branch `backup/v0.2-working`.
