extends Node2D

# Witch Game v0.2 — four-direction brawler arena + independent jump.
# The witch sprite is original SVG vector artwork and can later be swapped
# for hand-drawn frame animations.
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

func _ready() -> void:
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

    moving = motion.length_squared() > 0.0
    if moving:
        motion = motion.normalized()
        witch_position += motion * MOVE_SPEED * delta
        witch_position.x = clampf(witch_position.x, MIN_X, MAX_X)
        witch_position.y = clampf(witch_position.y, MIN_Y, MAX_Y)
        if motion.x != 0.0:
            facing = 1 if motion.x > 0.0 else -1

    if jump_height <= 0.0 and (Input.is_key_pressed(KEY_SPACE) or _has_control("jump")):
        jump_velocity = JUMP_SPEED
    if jump_height > 0.0 or jump_velocity > 0.0:
        jump_height += jump_velocity * delta
        jump_velocity -= GRAVITY * delta
        if jump_height <= 0.0:
            jump_height = 0.0
            jump_velocity = 0.0

    cast_cooldown = maxf(0.0, cast_cooldown - delta)
    cast_flash = maxf(0.0, cast_flash - delta)
    if (Input.is_key_pressed(KEY_J) or _has_control("cast")) and cast_cooldown <= 0.0:
        _cast()

    for i in range(spells.size() - 1, -1, -1):
        var spell := spells[i]
        spell["x"] = float(spell["x"]) + float(spell["dir"]) * CAST_SPEED * delta
        if slime_alive and absf(float(spell["x"]) - slime_position.x) < 40.0 and absf(float(spell["depth"]) - slime_position.y) < CAST_RANGE_Y:
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

    queue_redraw()

func _cast() -> void:
    cast_cooldown = 0.40
    cast_flash = 0.2
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
    if point.distance_to(Vector2(1170, 625)) < 72.0:
        return "cast"
    return ""

func _draw() -> void:
    var font := ThemeDB.fallback_font
    draw_rect(Rect2(0, 0, VIEW_W, VIEW_H), Color("#27394e"))
    draw_circle(Vector2(1090, 105), 56.0, Color("#eddfb9"))
    draw_circle(Vector2(1090, 105), 61.0, Color(0.9, 0.9, 0.65, 0.10))

    # Distant forest, then continuous brawler floor with depth cues.
    for i in range(11):
        var tx := float(i) * 135.0 - 30.0
        draw_rect(Rect2(tx, 210, 31, 240), Color("#263c35"))
        draw_circle(Vector2(tx + 10, 270), 88.0, Color("#355346"))
        draw_circle(Vector2(tx - 28, 335), 72.0, Color("#466b57"))
    draw_colored_polygon(PackedVector2Array([Vector2(0, 415), Vector2(1280, 415), Vector2(1280, 720), Vector2(0, 720)]), Color("#66564b"))
    draw_line(Vector2(0, 421), Vector2(1280, 421), Color("#94a678"), 6.0)
    for depth in [460.0, 520.0, 580.0, 640.0, 700.0]:
        draw_line(Vector2(0, depth), Vector2(1280, depth), Color("#8c7760"), 1.5)
    for i in range(23):
        var px := 30.0 + float(i % 12) * 115.0
        var py := 465.0 + float(i / 12) * 100.0
        draw_line(Vector2(px, py), Vector2(px + 17, py + 3), Color("#ad9777"), 2.0)

    # Draw characters in order of their ground Y (pseudo-depth sorting).
    if slime_alive and slime_position.y <= witch_position.y:
        _draw_slime()
    _draw_witch()
    if slime_alive and slime_position.y > witch_position.y:
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
    draw_string(font, Vector2(29, 100), "XP: %d    GREEN SPELL (J)" % xp, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#dbe9e0"))
    if not slime_alive:
        draw_string(font, Vector2(465, 230), "VICTORY! +25 XP", HORIZONTAL_ALIGNMENT_LEFT, -1, 36, Color("#ffe2a1"))
    draw_string(font, Vector2(465, 49), "WASD: move   SPACE: jump   J: cast", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#ecede0"))

    _draw_button(Vector2(160, 510), "UP", "up", 50)
    _draw_button(Vector2(160, 656), "DOWN", "down", 50)
    _draw_button(Vector2(80, 583), "LEFT", "left", 50)
    _draw_button(Vector2(240, 583), "RIGHT", "right", 50)
    _draw_button(Vector2(1000, 625), "JUMP", "jump", 64)
    _draw_button(Vector2(1170, 625), "CAST", "cast", 64)

func _draw_witch() -> void:
    # Shadow stays on ground when the character jumps.
    draw_ellipse(witch_position + Vector2(0, 2), 46, 12, Color(0.07, 0.08, 0.11, 0.42))
    var bob := sin(elapsed * 11.0) * 4.0 if moving and jump_height <= 0.0 else sin(elapsed * 2.4) * 1.5
    var sprite_size := Vector2(124, 186)
    var screen_pos := witch_position + Vector2(0, -jump_height + bob)
    # Mirror character horizontally while keeping the ground anchor fixed.
    draw_set_transform(screen_pos, 0.0, Vector2(float(facing), 1.0))
    draw_texture_rect(WITCH_TEXTURE, Rect2(-sprite_size.x / 2.0, -sprite_size.y, sprite_size.x, sprite_size.y), false)
    draw_set_transform(Vector2.ZERO)
    if cast_flash > 0.0:
        draw_arc(screen_pos + Vector2(facing * 44, -91), 28.0, 0, TAU, 30, Color("#afff91"), 5.0)

func draw_ellipse(center: Vector2, rx: float, ry: float, color: Color) -> void:
    draw_set_transform(center, 0, Vector2(rx / ry, 1.0))
    draw_circle(Vector2.ZERO, ry, color)
    draw_set_transform(Vector2.ZERO)

func _draw_slime() -> void:
    draw_ellipse(slime_position + Vector2(0, 3), 43, 10, Color(0, 0, 0, 0.35))
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
