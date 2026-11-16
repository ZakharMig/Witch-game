# Witch Game v0.4 — Dark Forest Art Pass

Godot 4 / Xogot iPad playable 2.5D witch adventure.

## v0.4 artwork
- New dark forest environment in `art/forest_v04.svg`: crooked trunks and branches, moonlit cold mist, mossy ground, textured witch cottage, roof and window details.
- New warm interior environment in `art/interior_v04.svg`: timber beams, detailed shelves/books, large fireplace and cauldron.
- Smooth radial glow texture in `art/staff_glow.svg` following the witch's staff.
- All three are **vector-painted prototype art** rather than photorealistic raster illustrations. The next art pass can replace them with hand-painted high-resolution PNGs.
- Current witch motion is procedural idle / walk / jump, not hand-drawn sprite-sheet frames.

## Controls
iPad: four arrows to move, JUMP to jump, CAST for green magic, USE at the door to enter/exit.
Keyboard: WASD/arrows, Space to jump, J to cast, E to use.

## Testing
Import the `main` branch of `https://github.com/ZakharMig/Witch-game` in Xogot as a fresh project (or update its imported files). Walk to the cottage door and tap USE, then walk to the interior door and tap USE to return. Verify movement in all four directions, jump and spell. Check rendering of SVG scenery and staff light in Godot 4.7.

The last known working v0.3 remains available in the `backup/v0.3-working` branch; if SVG import is unsupported in Xogot or a parser error appears, revert to that backup while troubleshooting.
