extends Node2D

# Witch Game v0.7 — original-witch raster keyframes (Godot 4 / Xogot).
# Preserve the existing witch.png silhouette and colours while animating poses.
const VIEW_W := 1280.0
const VIEW_H := 720.0
const MIN_X := 65.0
const MAX_X := 1215.0
const MIN_Y := 450.0
const MAX_Y := 615.0
const MOVE_SPEED := 245.0
const JUMP_SPEED := 510.0
const GRAVITY := 1300.0
const CAST_SPEED := 680.0
const CAST_RANGE_Y := 48.0
const WITCH_TEXTURE: Texture2D = preload("res://art/witch.png")
const FOREST_ART: Texture2D = preload("res://art/forest_painted_v06.webp")
const INTERIOR_ART: Texture2D = preload("res://art/interior_v04.svg")
const STAFF_GLOW: Texture2D = preload("res://art/staff_glow.svg")

var witch_position := Vector2(260, 550) # Ground coordinates (X, depth).
var jump_height := 0.0
var jump_velocity := 0.0
var facing := 1
var moving := false
var elapsed := 0.0
var hp := 100
var xp := 0
var level := 1

var slime_position := Vector2(930, 548)
var slime_hp := 3
var slime_alive := true
var cast_cooldown := 0.0
var cast_flash := 0.0
var spells: Array[Dictionary] = []
var touches: Dictionary = {} # finger index -> active control
var mouse_control := ""
var indoors := false
var use_was_down := false
var jump_was_down := false
var anim_state := "idle"
var anim_clock := 0.0
var cast_anim_timer := 0.0
var idle_frames: Array[Texture2D] = []
var walk_frames: Array[Texture2D] = []
var jump_frames: Array[Texture2D] = []
var cast_frames: Array[Texture2D] = []
var door_pos := Vector2(633, 472)
var exit_pos := Vector2(640, 487)
var enter_spawn := Vector2(640, 535)
var exit_spawn := Vector2(640, 550)

func _ready() -> void:
    _build_animation_frames()
    queue_redraw()

func _build_animation_frames() -> void:
    # Build a lightweight frame atlas once, from the SAME original witch image.
    # This is a first pose-based sprite animation pass, not hand-painted redraws.
    var source := WITCH_TEXTURE.get_image()
    source.convert(Image.FORMAT_RGBA8)
    for i in range(4):
        idle_frames.append(_make_pose(source, "idle", i, 4))
    for i in range(6):
        walk_frames.append(_make_pose(source, "walk", i, 6))
    for i in range(4):
        jump_frames.append(_make_pose(source, "jump", i, 4))
    for i in range(4):
        cast_frames.append(_make_pose(source, "cast", i, 4))

func _make_pose(source: Image, state: String, index: int, count: int) -> Texture2D:
    # Small independent shifts for head, cloak, boots, body and staff.
    # Each pose is stored as its own raster texture and played by frame index.
    var phase := TAU * float(index) / float(count)
    var step := sin(phase)
    var side := cos(phase)
    var head_shift := 0.0
    var cape_shift := 0.0
    var left_leg_shift := 0.0
    var right_leg_shift := 0.0
    var staff_shift := 0.0
    var body_shift := 0.0
    match state:
        "idle":
            head_shift = side * 0.8
            cape_shift = step * 1.8 + side * 0.8
            staff_shift = step * 1.2
            body_shift = side * 1.0
        "walk":
            head_shift = step * 1.2 + side * 0.8
            cape_shift = step * 4.0 + side * 1.5
            left_leg_shift = step * 5.0 + side * 1.3
            right_leg_shift = -step * 5.0 + side * 1.3
            staff_shift = -step * 1.8
            body_shift = -absf(side) * 2.0
        "jump":
            match index:
                0:
                    left_leg_shift = -2.0
                    right_leg_shift = 2.0
                    cape_shift = -3.0
                    body_shift = -2.0
                1:
                    left_leg_shift = 5.0
                    right_leg_shift = -5.0
                    cape_shift = -6.0
                    body_shift = -3.0
                    staff_shift = 2.0
                2:
                    left_leg_shift = -4.0
                    right_leg_shift = 5.0
                    cape_shift = 6.0
                    staff_shift = 3.0
                3:
                    left_leg_shift = -2.0
                    right_leg_shift = 2.0
                    cape_shift = 2.0
                    body_shift = 2.0
        "cast":
            match index:
                0:
                    staff_shift = -3.0
                    cape_shift = -2.0
                    head_shift = -1.0
                1:
                    staff_shift = 4.0
                    cape_shift = 3.0
                    head_shift = 1.0
                2:
                    staff_shift = 6.0
                    cape_shift = 5.0
                    head_shift = 1.5
                3:
                    staff_shift = 1.0
                    cape_shift = 1.0

    var w := source.get_width()
    var h := source.get_height()
    var pose := Image.create(w, h, false, Image.FORMAT_RGBA8)
    pose.fill(Color.TRANSPARENT)
    for y in range(h):
        for x in range(w):
            var fx := float(x)
            var fy := float(y)
            var shift_x := 0.0
            var shift_y := 0.0
            # The original 90x154 image has a hat/head above y=60.
            if y < 62:
                shift_x += head_shift * clampf((68.0 - fy) / 45.0, 0.0, 1.0)
            # Loose cape occupies the left-hand part of the sprite.
            if y > 55 and x < 48:
                shift_x += cape_shift * clampf((48.0 - fx) / 42.0, 0.0, 1.0) * clampf((fy - 55.0) / 70.0, 0.0, 1.0)
            # Opposing foot motion creates a visible walk cycle.
            if y > 101:
                var leg_weight := clampf((fy - 101.0) / 48.0, 0.0, 1.0)
                if x < 47:
                    shift_x += left_leg_shift * leg_weight
                else:
                    shift_x += right_leg_shift * leg_weight
            # The staff sits at the right edge of the original PNG.
            if x > 64 and y < 138:
                shift_x += staff_shift * clampf((fx - 64.0) / 24.0, 0.0, 1.0)
            if y > 52 and y < 114:
                shift_y += body_shift * (1.0 - absf(fy - 83.0) / 31.0)
            var src_x := x - roundi(shift_x)
            var src_y := y - roundi(shift_y)
            if src_x >= 0 and src_x < w and src_y >= 0 and src_y < h:
                pose.set_pixel(x, y, source.get_pixel(src_x, src_y))
    return ImageTexture.create_from_image(pose)

func _process(delta: float) -> void:
    elapsed += delta
    var motion := Vector2.ZERO
    if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT) or _has_control("left"):
        motion.x -= 1.0
    if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT) or _has_control("right"):
        motion.x += 1.0
    if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP) or _has_control("up"):
        motion.y -= 1.0
    if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN) or _has_control("down"):
        motion.y += 1.0

    moving = motion.length_squared() > 0.0
    if moving:
        motion = motion.normalized()
        witch_position += motion * MOVE_SPEED * delta
        witch_position.x = clampf(witch_position.x, MIN_X, MAX_X)
        witch_position.y = clampf(witch_position.y, MIN_Y, MAX_Y)
        if motion.x != 0.0:
            facing = 1 if motion.x > 0.0 else -1

    var jumping := Input.is_key_pressed(KEY_SPACE) or _has_control("jump")
    if jump_height <= 0.0 and jumping and not jump_was_down:
        jump_velocity = JUMP_SPEED
    jump_was_down = jumping
    if jump_height > 0.0 or jump_velocity > 0.0:
        jump_height += jump_velocity * delta
        jump_velocity -= GRAVITY * delta
        if jump_height <= 0.0:
            jump_height = 0.0
            jump_velocity = 0.0

    var using := Input.is_key_pressed(KEY_E) or _has_control("use")
    if using and not use_was_down and jump_height <= 0.0 and _near_door():
        indoors = not indoors
        witch_position = enter_spawn if indoors else exit_spawn
        spells.clear()
    use_was_down = using
    cast_cooldown = maxf(0.0, cast_cooldown - delta)
    cast_flash = maxf(0.0, cast_flash - delta)
    cast_anim_timer = maxf(0.0, cast_anim_timer - delta)
    if (Input.is_key_pressed(KEY_J) or _has_control("cast")) and cast_cooldown <= 0.0:
        _cast()

    for i in range(spells.size() - 1, -1, -1):
        var spell := spells[i]
        spell["x"] = float(spell["x"]) + float(spell["dir"]) * CAST_SPEED * delta
        if not indoors and slime_alive and absf(float(spell["x"]) - slime_position.x) < 40.0 and absf(float(spell["depth"]) - slime_position.y) < CAST_RANGE_Y:
            slime_hp -= 1
            spells.remove_at(i)
            if slime_hp <= 0:
                slime_alive = false
                xp += 25
                if xp >= level * 50:
                    xp -= level * 50
                    level += 1
            continue
        if float(spell["x"]) < -30.0 or float(spell["x"]) > VIEW_W + 30.0:
            spells.remove_at(i)

    var next_state := "cast" if cast_anim_timer > 0.0 else ("jump" if jump_height > 0.0 or jump_velocity > 0.0 else ("walk" if moving else "idle"))
    if next_state != anim_state:
        anim_state = next_state
        anim_clock = 0.0
    else:
        anim_clock += delta
    queue_redraw()

func _cast() -> void:
    cast_cooldown = 0.40
    cast_flash = 0.2
    cast_anim_timer = 0.36
    spells.append({"x": witch_position.x + facing * 42.0, "depth": witch_position.y, "dir": facing, "altitude": jump_height})

func _has_control(control: String) -> bool:
    if mouse_control == control:
        return true
    return touches.values().has(control)

func _input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        if event.pressed:
            touches[event.index] = _control_at(event.position)
        else:
            touches.erase(event.index)
    elif event is InputEventScreenDrag:
        touches[event.index] = _control_at(event.position)
    elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        mouse_control = _control_at(event.position) if event.pressed else ""
    elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
        mouse_control = _control_at(event.position)

func _control_at(point: Vector2) -> String:
    # Button areas are in viewport coordinates.
    if point.distance_to(Vector2(160, 510)) < 58.0:
        return "up"
    if point.distance_to(Vector2(160, 656)) < 58.0:
        return "down"
    if point.distance_to(Vector2(80, 583)) < 58.0:
        return "left"
    if point.distance_to(Vector2(240, 583)) < 58.0:
        return "right"
    if point.distance_to(Vector2(1000, 625)) < 72.0:
        return "jump"
    if point.distance_to(Vector2(1100, 486)) < 50.0:
        return "use"
    if point.distance_to(Vector2(1170, 625)) < 72.0:
        return "cast"
    return ""

func _draw() -> void:
    var font := ThemeDB.fallback_font
    if indoors:
        _draw_interior()
    else:
        _draw_forest()

    # Draw characters in order of their ground Y (pseudo-depth sorting).
    if not indoors and slime_alive and slime_position.y <= witch_position.y:
        _draw_slime()
    _draw_witch()
    if not indoors and slime_alive and slime_position.y > witch_position.y:
        _draw_slime()

    for spell in spells:
        var pos := Vector2(float(spell["x"]), float(spell["depth"]) - float(spell["altitude"]) - 87.0)
        draw_circle(pos, 25, Color(0.23, 0.98, 0.53, 0.27))
        draw_circle(pos, 15, Color("#84f994"))
        draw_circle(pos + Vector2(-5, -5), 6, Color("#eeffd0"))

    # On-screen HUD
    draw_rect(Rect2(15, 14, 315, 105), Color(0.06, 0.11, 0.16, 0.87))
    draw_string(font, Vector2(28, 45), "WITCH   LVL %d" % level, HORIZONTAL_ALIGNMENT_LEFT, -1, 25, Color.WHITE)
    draw_rect(Rect2(30, 55, 226, 15), Color("#4d2938"))
    draw_rect(Rect2(30, 55, float(hp) * 2.26, 15), Color("#d46c74"))
    draw_string(font, Vector2(293, 69), "%d HP" % hp, HORIZONTAL_ALIGNMENT_RIGHT, -1, 16, Color.WHITE)
    draw_string(font, Vector2(29, 100), "XP: %d   %s" % [xp, "WITCH HOME" if indoors else "DARK FOREST"], HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#dbe9e0"))
    if _near_door() and jump_height <= 0.0:
        draw_string(font, witch_position + Vector2(-80, -205), "E / USE: %s" % ("EXIT" if indoors else "ENTER"), HORIZONTAL_ALIGNMENT_LEFT, 190, 20, Color("#ffe1a2"))
    if not indoors and not slime_alive:
        draw_string(font, Vector2(465, 230), "VICTORY! +25 XP", HORIZONTAL_ALIGNMENT_LEFT, -1, 36, Color("#ffe2a1"))
    draw_string(font, Vector2(465, 49), "WASD: move   SPACE: jump   J: cast   E: use", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#ecede0"))

    _draw_button(Vector2(160, 510), "UP", "up", 50)
    _draw_button(Vector2(160, 656), "DOWN", "down", 50)
    _draw_button(Vector2(80, 583), "LEFT", "left", 50)
    _draw_button(Vector2(240, 583), "RIGHT", "right", 50)
    _draw_button(Vector2(1000, 625), "JUMP", "jump", 64)
    _draw_button(Vector2(1170, 625), "CAST", "cast", 64)
    _draw_button(Vector2(1100, 486), "USE", "use", 46)

func _draw_witch() -> void:
    # The ground shadow remains anchored during jumps.
    draw_ground_ellipse(witch_position + Vector2(0, 2), 46, 12, Color(0.07, 0.08, 0.11, 0.42))
    var frame_texture: Texture2D = WITCH_TEXTURE
    var pose_index := 0
    match anim_state:
        "idle":
            pose_index = int(anim_clock / 0.26) % idle_frames.size()
            frame_texture = idle_frames[pose_index]
        "walk":
            pose_index = int(anim_clock / 0.085) % walk_frames.size()
            frame_texture = walk_frames[pose_index]
        "jump":
            if jump_velocity > 190.0:
                pose_index = 1
            elif jump_velocity < -190.0:
                pose_index = 2
            else:
                pose_index = 3
            frame_texture = jump_frames[pose_index]
        "cast":
            pose_index = clampi(int((0.36 - cast_anim_timer) / 0.09), 0, cast_frames.size() - 1)
            frame_texture = cast_frames[pose_index]
    var screen_pos := witch_position + Vector2(0.0, -jump_height)
    var sprite_size := Vector2(134.0, 201.0)
    draw_set_transform(screen_pos, 0.0, Vector2(float(facing), 1.0))
    draw_texture_rect(frame_texture, Rect2(-sprite_size.x / 2.0, -sprite_size.y, sprite_size.x, sprite_size.y), false)
    draw_set_transform(Vector2.ZERO)
    var orb_offset := Vector2(float(facing) * 52.0, -165.0)
    if anim_state == "cast":
        orb_offset += Vector2(float(facing) * 5.0, -2.0)
    var light_pos := screen_pos + orb_offset
    var light_radius := 92.0 + sin(elapsed * 4.2) * 4.0
    draw_texture_rect(STAFF_GLOW, Rect2(light_pos - Vector2.ONE * light_radius, Vector2.ONE * light_radius * 2.0), false)
    draw_circle(light_pos, 3.0, Color("#ffdbaa"))
    if cast_flash > 0.0:
        draw_arc(light_pos, 22.0, 0, TAU, 30, Color("#afff91"), 4.0)

func draw_ground_ellipse(center: Vector2, rx: float, ry: float, color: Color) -> void:
    draw_set_transform(center, 0, Vector2(rx / ry, 1.0))
    draw_circle(Vector2.ZERO, ry, color)
    draw_set_transform(Vector2.ZERO)

func _draw_slime() -> void:
    draw_ground_ellipse(slime_position + Vector2(0, 3), 43, 10, Color(0, 0, 0, 0.35))
    draw_circle(slime_position + Vector2(0, -24), 31, Color("#a84c83"))
    draw_rect(Rect2(slime_position.x - 30, slime_position.y - 29, 60, 30), Color("#a84c83"))
    draw_circle(slime_position + Vector2(-11, -32), 5, Color.WHITE)
    draw_circle(slime_position + Vector2(11, -32), 5, Color.WHITE)
    draw_rect(Rect2(slime_position.x - 36, slime_position.y - 74, 72, 7), Color("#4d2a37"))
    draw_rect(Rect2(slime_position.x - 36, slime_position.y - 74, float(slime_hp) * 24.0, 7), Color("#f6a1c0"))

func _draw_button(center: Vector2, caption: String, control: String, radius: float) -> void:
    var active := _has_control(control)
    var tint := Color(0.16, 0.31, 0.30, 0.86) if active else Color(0.10, 0.15, 0.21, 0.73)
    draw_circle(center, radius, tint)
    draw_arc(center, radius, 0, TAU, 40, Color("#b9c3c8"), 2.4)
    var font := ThemeDB.fallback_font
    draw_string(font, center + Vector2(-radius + 5, 7), caption, HORIZONTAL_ALIGNMENT_CENTER, (radius - 5) * 2, 19, Color.WHITE)

func _near_door() -> bool:
    var target := exit_pos if indoors else door_pos
    return absf(witch_position.x - target.x) < 90.0 and absf(witch_position.y - target.y) < 73.0

func _warm_glow(pos: Vector2, radius: float, alpha: float) -> void:
    for i in range(5, 0, -1):
        var t := float(i) / 5.0
        draw_circle(pos, radius * t, Color(1.0, 0.62, 0.26, alpha * (1.0 - t) * 0.55))

# Painted SVG environment textures are imported as Godot textures.
# Gameplay, collision/depth and door interactions remain in this script.
func _draw_forest() -> void:
    # Full-frame 1920x1080 painted exterior, no player or UI baked in.
    draw_texture_rect(FOREST_ART, Rect2(0.0, 0.0, VIEW_W, VIEW_H), false)
    # Subtle moving mist across the walkable foreground, not the cottage.
    for k in range(3):
        var drift := sin(elapsed * (0.22 + float(k) * 0.06) + float(k) * 1.8) * 25.0
        draw_rect(Rect2(drift - 35.0, 474.0 + float(k) * 61.0, VIEW_W + 70.0, 14.0), Color(0.59, 0.72, 0.73, 0.018))

func _draw_interior() -> void:
    draw_texture_rect(INTERIOR_ART, Rect2(0.0, 0.0, VIEW_W, VIEW_H), false)
