extends Node2D

# Witch Game v0.9 — comic forest, chimney smoke and swaying foliage (Godot 4 / Xogot).
# The former witch.png asset is retained as a fallback art reference.
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
const SLIME_SPEED := 78.0
const SLIME_CHASE_RANGE := 540.0
const ENEMY_TOUCH_DAMAGE := 12
const ENEMY_ATTACK_COOLDOWN := 1.35
const PLAYER_INVULNERABLE_TIME := 0.75
const WITCH_ATLAS: Texture2D = preload("res://art/witch_anim_v07.webp")
const FRAME_EDGE := 320.0
const FOREST_ART: Texture2D = preload("res://art/forest_comic_v09.webp")
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
var slime_attack_timer := 0.65
var slime_hit_timer := 0.0
var player_hurt_timer := 0.0
var player_defeated := false
var victory_timer := 0.0
var respawn_hint := 0.0
var slime_walk_clock := 0.0
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
var door_pos := Vector2(623, 461)
var exit_pos := Vector2(640, 487)
var enter_spawn := Vector2(640, 535)
var exit_spawn := Vector2(640, 550)

func _ready() -> void:
    # Painted poses are pre-rendered; no per-pixel texture rebuild on iPad.
    queue_redraw()

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

    if player_defeated:
        motion = Vector2.ZERO
    moving = motion.length_squared() > 0.0
    if moving:
        motion = motion.normalized()
        witch_position += motion * MOVE_SPEED * delta
        witch_position.x = clampf(witch_position.x, MIN_X, MAX_X)
        witch_position.y = clampf(witch_position.y, MIN_Y, MAX_Y)
        if motion.x != 0.0:
            facing = 1 if motion.x > 0.0 else -1

    var jumping := Input.is_key_pressed(KEY_SPACE) or _has_control("jump")
    if jump_height <= 0.0 and jumping and not jump_was_down and not player_defeated:
        jump_velocity = JUMP_SPEED
    jump_was_down = jumping
    if jump_height > 0.0 or jump_velocity > 0.0:
        jump_height += jump_velocity * delta
        jump_velocity -= GRAVITY * delta
        if jump_height <= 0.0:
            jump_height = 0.0
            jump_velocity = 0.0

    var using := Input.is_key_pressed(KEY_E) or _has_control("use")
    if using and not use_was_down and jump_height <= 0.0:
        if player_defeated:
            _restart_encounter()
        elif _near_door():
            indoors = not indoors
            witch_position = enter_spawn if indoors else exit_spawn
            spells.clear()
            if indoors:
                hp = mini(100, hp + 35)
    use_was_down = using
    cast_cooldown = maxf(0.0, cast_cooldown - delta)
    cast_flash = maxf(0.0, cast_flash - delta)
    cast_anim_timer = maxf(0.0, cast_anim_timer - delta)
    player_hurt_timer = maxf(0.0, player_hurt_timer - delta)
    slime_hit_timer = maxf(0.0, slime_hit_timer - delta)
    slime_attack_timer = maxf(0.0, slime_attack_timer - delta)
    victory_timer = maxf(0.0, victory_timer - delta)
    respawn_hint = maxf(0.0, respawn_hint - delta)
    if not indoors and slime_alive and not player_defeated:
        _update_slime(delta)
    if not player_defeated and (Input.is_key_pressed(KEY_J) or _has_control("cast")) and cast_cooldown <= 0.0:
        _cast()

    for i in range(spells.size() - 1, -1, -1):
        var spell := spells[i]
        spell["x"] = float(spell["x"]) + float(spell["dir"]) * CAST_SPEED * delta
        if not indoors and slime_alive and absf(float(spell["x"]) - slime_position.x) < 40.0 and absf(float(spell["depth"]) - slime_position.y) < CAST_RANGE_Y:
            slime_hp -= 1
            slime_hit_timer = 0.16
            slime_attack_timer = maxf(slime_attack_timer, 0.35)
            slime_position.x = clampf(slime_position.x + float(spell["dir"]) * 24.0, MIN_X, MAX_X)
            spells.remove_at(i)
            if slime_hp <= 0:
                slime_alive = false
                victory_timer = 2.4
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

func _update_slime(delta: float) -> void:
    # The slime navigates across the same 2.5D ground plane as the witch.
    var separation := witch_position - slime_position
    if separation.length() < SLIME_CHASE_RANGE and separation.length() > 50.0:
        slime_position += separation.normalized() * SLIME_SPEED * delta
        slime_position.x = clampf(slime_position.x, MIN_X, MAX_X)
        slime_position.y = clampf(slime_position.y, MIN_Y, MAX_Y)
        slime_walk_clock += delta * 9.0
    if absf(separation.x) < 49.0 and absf(separation.y) < 38.0 and jump_height < 30.0 and slime_attack_timer <= 0.0 and player_hurt_timer <= 0.0:
        hp = maxi(0, hp - ENEMY_TOUCH_DAMAGE)
        player_hurt_timer = PLAYER_INVULNERABLE_TIME
        slime_attack_timer = ENEMY_ATTACK_COOLDOWN
        var push_direction := 1.0 if separation.x >= 0.0 else -1.0
        witch_position.x = clampf(witch_position.x + push_direction * 28.0, MIN_X, MAX_X)
        if hp <= 0:
            player_defeated = true
            respawn_hint = 3.0

func _restart_encounter() -> void:
    # Respawn at the cottage; XP is retained as this is a small gameplay prototype.
    hp = 100
    player_defeated = false
    indoors = false
    witch_position = Vector2(335.0, 550.0)
    jump_height = 0.0
    jump_velocity = 0.0
    slime_position = Vector2(960.0, 548.0)
    slime_hp = 3
    slime_alive = true
    slime_attack_timer = 0.9
    player_hurt_timer = 0.0
    cast_anim_timer = 0.0
    spells.clear()
    victory_timer = 0.0

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

    # Plants are foreground objects: animated separately from the static art.
    if not indoors:
        _draw_swaying_plants()

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
    if victory_timer > 0.0 and not indoors:
        draw_string(font, Vector2(465, 230), "VICTORY! +25 XP", HORIZONTAL_ALIGNMENT_LEFT, -1, 36, Color("#ffe2a1"))
    if player_defeated:
        draw_rect(Rect2(365, 275, 552, 140), Color(0.08, 0.04, 0.09, 0.82))
        draw_string(font, Vector2(465, 335), "YOU WERE DEFEATED", HORIZONTAL_ALIGNMENT_LEFT, 400, 32, Color("#ffc8ca"))
        draw_string(font, Vector2(480, 386), "PRESS USE TO TRY AGAIN", HORIZONTAL_ALIGNMENT_LEFT, 360, 21, Color.WHITE)
    draw_string(font, Vector2(465, 49), "WASD: move   SPACE: jump   J: cast   E: use", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#ecede0"))

    _draw_button(Vector2(160, 510), "UP", "up", 50)
    _draw_button(Vector2(160, 656), "DOWN", "down", 50)
    _draw_button(Vector2(80, 583), "LEFT", "left", 50)
    _draw_button(Vector2(240, 583), "RIGHT", "right", 50)
    _draw_button(Vector2(1000, 625), "JUMP", "jump", 64)
    _draw_button(Vector2(1170, 625), "CAST", "cast", 64)
    _draw_button(Vector2(1100, 486), "RETRY" if player_defeated else "USE", "use", 46)

func _draw_witch() -> void:
    # 4x4 hand-painted keyframe atlas. Source frame = 320x320 px.
    # Ground coordinate and airborne height remain independent.
    draw_ground_ellipse(witch_position + Vector2(0.0, 2.0), 46.0, 12.0, Color(0.07, 0.08, 0.11, 0.42))
    var atlas_row := 0
    var atlas_col := 0
    match anim_state:
        "walk":
            atlas_row = 1
            atlas_col = int(anim_clock * 9.0) % 4
        "jump":
            atlas_row = 2
            if jump_velocity > 260.0:
                atlas_col = 0
            elif jump_velocity > 70.0:
                atlas_col = 1
            elif jump_velocity > -170.0:
                atlas_col = 2
            else:
                atlas_col = 3
        "cast":
            atlas_row = 3
            atlas_col = clampi(int((0.36 - cast_anim_timer) / 0.09), 0, 3)
        _:
            atlas_row = 0
            atlas_col = int(anim_clock * 3.5) % 4
    var screen_pos := witch_position + Vector2(0.0, -jump_height)
    if player_hurt_timer > 0.0 and int(elapsed * 18.0) % 2 == 0:
        return
    var sprite_size := Vector2(232.0, 224.0)
    var source_rect := Rect2(float(atlas_col) * FRAME_EDGE, float(atlas_row) * FRAME_EDGE, FRAME_EDGE, FRAME_EDGE)
    draw_set_transform(screen_pos, 0.0, Vector2(float(facing), 1.0))
    draw_texture_rect_region(WITCH_ATLAS, Rect2(-sprite_size.x * 0.5, -sprite_size.y, sprite_size.x, sprite_size.y), source_rect)
    draw_set_transform(Vector2.ZERO)

    # The warm moving staff light follows the pose (front of the character).
    var orb_offset := Vector2(float(facing) * 35.0, -163.0)
    if anim_state == "cast" and atlas_col >= 1:
        orb_offset = Vector2(float(facing) * 71.0, -151.0)
    var light_pos := screen_pos + orb_offset
    var light_radius := 92.0 + sin(elapsed * 4.2) * 4.0
    draw_texture_rect(STAFF_GLOW, Rect2(light_pos - Vector2.ONE * light_radius, Vector2.ONE * light_radius * 2.0), false)
    if cast_flash > 0.0:
        draw_arc(light_pos, 22.0, 0.0, TAU, 30, Color("#afff91"), 4.0)

func draw_ground_ellipse(center: Vector2, rx: float, ry: float, color: Color) -> void:
    draw_set_transform(center, 0, Vector2(rx / ry, 1.0))
    draw_circle(Vector2.ZERO, ry, color)
    draw_set_transform(Vector2.ZERO)

func _draw_slime() -> void:
    draw_ground_ellipse(slime_position + Vector2(0, 3), 43, 10, Color(0, 0, 0, 0.35))
    # A squash-and-stretch bounce differentiates the enemy from scenery.
    var bounce := absf(sin(slime_walk_clock)) * 10.0
    var body_tint := Color("#f4c1e3") if slime_hit_timer > 0.0 else Color("#a84c83")
    var centre := slime_position + Vector2(0.0, -26.0 - bounce)
    draw_set_transform(centre, 0.0, Vector2(1.0 + bounce / 60.0, 1.0 - bounce / 85.0))
    draw_circle(Vector2.ZERO, 31.0, body_tint)
    draw_rect(Rect2(-30.0, -2.0, 60.0, 27.0), body_tint)
    draw_circle(Vector2(-11.0, -8.0), 5.0, Color.WHITE)
    draw_circle(Vector2(11.0, -8.0), 5.0, Color.WHITE)
    draw_circle(Vector2(-10.0, -8.0), 2.2, Color("#27202d"))
    draw_circle(Vector2(12.0, -8.0), 2.2, Color("#27202d"))
    draw_set_transform(Vector2.ZERO)
    draw_rect(Rect2(slime_position.x - 36.0, slime_position.y - 88.0 - bounce, 72.0, 7.0), Color("#4d2a37"))
    draw_rect(Rect2(slime_position.x - 36.0, slime_position.y - 88.0 - bounce, float(slime_hp) * 24.0, 7.0), Color("#f6a1c0"))

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
    # Clean 16:9 inked/cartoon exterior: no baked character or controls.
    draw_texture_rect(FOREST_ART, Rect2(0.0, 0.0, VIEW_W, VIEW_H), false)
    _draw_chimney_smoke()
    # Thin cold air drifts over the path without hiding the warm window light.
    for k in range(3):
        var drift := sin(elapsed * (0.20 + float(k) * 0.07) + float(k) * 1.9) * 22.0
        draw_rect(Rect2(drift - 30.0, 488.0 + float(k) * 58.0, VIEW_W + 60.0, 11.0), Color(0.52, 0.68, 0.73, 0.012))

func _draw_chimney_smoke() -> void:
    # Screen-space chimney on the right-hand roof. Each puff travels up and drifts.
    # Drawn behind actors/HUD so the background itself stays clean.
    for i in range(11):
        var phase := fposmod(elapsed * 0.20 + float(i) / 11.0, 1.0)
        var px := 866.0 + phase * 34.0 + sin(phase * 8.0 + elapsed * 0.9 + float(i)) * 9.0
        var py := 91.0 - phase * 159.0
        var radius := 8.0 + phase * 24.0
        var fade := sin(phase * PI) * 0.21
        draw_circle(Vector2(px, py), radius * 1.35, Color(0.27, 0.35, 0.48, fade * 0.42))
        draw_circle(Vector2(px - 3.0, py - 2.0), radius, Color(0.72, 0.77, 0.85, fade))
        draw_circle(Vector2(px - 6.0, py - 5.0), radius * 0.43, Color(0.87, 0.89, 0.94, fade * 0.43))

func _draw_swaying_plants() -> void:
    # Foreground leaves are drawn after the witch, reinforcing arena depth.
    # Clumps stay at the bottom corners so they never obscure the doorway.
    for side in range(2):
        var base_x := 40.0 if side == 0 else 1240.0
        var direction := 1.0 if side == 0 else -1.0
        for clump in range(4):
            var foot := Vector2(base_x + direction * float(clump) * 56.0, 726.0 + float(clump % 2) * 13.0)
            for blade in range(5):
                var phase := elapsed * (1.15 + float(blade) * 0.12) + float(clump) * 0.9 + float(blade) * 1.3
                var bend := sin(phase) * (5.0 + float(blade) * 1.4)
                var height := 36.0 + float((clump + blade) % 3) * 15.0
                var direction_x := (float(blade) - 2.0) * 10.0 + bend
                var tip := foot + Vector2(direction_x, -height)
                var left := foot + Vector2(-7.0, 0.0)
                var right := foot + Vector2(7.0, 0.0)
                var color := Color("#27434d") if blade % 2 == 0 else Color("#526657")
                draw_colored_polygon(PackedVector2Array([left, tip, right]), color)
                draw_line(foot, tip, Color(0.63, 0.65, 0.43, 0.24), 1.0)
            for leaf in range(3):
                var sway := sin(elapsed * 1.05 + float(leaf) * 0.7 + float(clump)) * 6.0
                var dx := direction * float(leaf * 10 + 4)
                var tip := foot + Vector2(dx + sway - 12.0, -26.0 - float(leaf) * 10.0)
                draw_colored_polygon(PackedVector2Array([
                    foot + Vector2(dx - 10.0, -12.0),
                    tip,
                    foot + Vector2(dx + 13.0, -8.0)
                ]), Color("#683144") if leaf % 2 == 0 else Color("#873950"))

func _draw_interior() -> void:
    draw_texture_rect(INTERIOR_ART, Rect2(0.0, 0.0, VIEW_W, VIEW_H), false)
