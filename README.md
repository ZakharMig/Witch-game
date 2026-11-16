# Witch Game v0.8 — first combat loop (Godot 4 / Xogot)

Based on the tested v0.7 witch animation and v0.6 painted forest.

## New gameplay
- The forest slime **chases** the witch across both horizontal and depth coordinates when nearby.
- Touching the slime causes **12 HP damage**, brief knockback, and **0.75 seconds of invulnerability** so the player cannot lose all HP in one frame.
- Jumping above the slime's reach avoids contact damage.
- Green magic still damages the slime only when the witch and the enemy are approximately aligned on the same depth lane; successful hits briefly flash and knock the slime back.
- After three hits, the slime is defeated and awards **25 XP**.
- If HP reaches zero, a **YOU WERE DEFEATED** overlay appears. Tap **RETRY / USE** (or keyboard E) to restart the fight at full HP, keeping already earned XP.
- Entering the cottage and leaving it still works. **Entering the cottage restores 35 HP**, up to 100.
- Slime bounces visually while moving and flashes when hit.

## Controls
iPad: four direction arrows, JUMP, CAST, USE. Keyboard: WASD / arrows, Space, J, E.

## Testing on iPad
Import the updated **main** branch from https://github.com/ZakharMig/Witch-game into Xogot. Check four-direction movement, animation, jumping to evade a slime, taking HP damage, dealing three magic hits, XP reward, death and retry, and entering/exiting the house. Note the slime may take a moment to reach you from the right side of the level.

This version retains the same painted exterior, interior, witch atlas and on-screen controls. The verified v0.7 code is preserved in `backup/v0.7-working`. The update still needs a real Xogot runtime test.
