extends Node2D

# Witch Game v0.2 — 2.5D beat-'em-up arena for Xogot / Godot 4.
# Ground position and jump height are deliberately separate.
const WALK_SPEED := 245.0
const ARENA_TOP := 410.0
const ARENA_BOTTOM := 585.0
const JUMP_POWER := 540.0
const GRAVITY := 1280.0

var hero := Vector2(170, 510)
var jump_height := 0.0
var jump_velocity := 0.0
var facing := 1
var moving := false
var walk_clock := 0.0
var jump_was_down := false

var health := 100
var xp := 0
var level := 1
var enemy := Vector2(875, 510)
var enemy_hp := 3
var enemy_alive := true
var attack_flash := 0.0
var attack_cooldown := 0.0
var hit_flash := 0.0
var touch_points: Dictionary = {}
var witch_texture: Texture2D

func _ready() -> void:
    witch_texture = load("res://art/witch.png") as Texture2D
    queue_redraw()

func _process(delta: float) -> void:
    var axis := Vector2.ZERO
    if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
        axis.x -= 1.0
    if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
        axis.x += 1.0
    if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
        axis.y -= 1.0
    if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
        axis.y += 1.0

    var touch_axis := Vector2.ZERO
    var touch_jump := false
    var touch_cast := false
    for pos in touch_points.values():
        var p: Vector2 = pos
        if p.distance_to(Vector2(80, 630)) < 55:
            touch_axis.x -= 1.0
        if p.distance_to(Vector2(230, 630)) < 55:
            touch_axis.x += 1.0
        if p.distance_to(Vector2(155, 560)) < 55:
            touch_axis.y -= 1.0
        if p.distance_to(Vector2(155, 695)) < 55:
            touch_axis.y += 1.0
        if p.distance_to(Vector2(980, 635)) < 72:
            touch_jump = true
        if p.distance_to(Vector2(1150, 635)) < 72:
            touch_cast = true

    axis += touch_axis
    moving = axis.length_squared() > 0.001
    if moving:
        axis = axis.normalized()
        if absf(axis.x) > 0.05:
            facing = 1 if axis.x > 0.0 else -1
        hero += axis * WALK_SPEED * delta
        walk_clock += delta * 11.0
    hero.x = clampf(hero.x, 65.0, 1215.0)
    hero.y = clampf(hero.y, ARENA_TOP, ARENA_BOTTOM)

    var jump_down := touch_jump or Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_K)
    if jump_down and not jump_was_down and jump_height <= 0.0:
        jump_velocity = JUMP_POWER
    jump_was_down = jump_down
    if jump_height > 0.0 or jump_velocity > 0.0:
        jump_height += jump_velocity * delta
        jump_velocity -= GRAVITY * delta
        if jump_height <= 0.0:
            jump_height = 0.0
            jump_velocity = 0.0

    attack_flash = maxf(0.0, attack_flash - delta)
    attack_cooldown = maxf(0.0, attack_cooldown - delta)
    hit_flash = maxf(0.0, hit_flash - delta)
    if (touch_cast or Input.is_key_pressed(KEY_J)) and attack_cooldown <= 0.0:
        cast_spell()
    queue_redraw()

func cast_spell() -> void:
    attack_flash = 0.22
    attack_cooldown = 0.43
    # Attacks only hit enemies on approximately the same depth lane.
    if enemy_alive and absf(hero.y - enemy.y) < 52.0 and absf(hero.x - enemy.x) < 185.0 and (enemy.x - hero.x) * facing > -10.0 and jump_height < 135.0:
        enemy_hp -= 1
        hit_flash = 0.18
        if enemy_hp <= 0:
            enemy_alive = false
            xp += 25
            if xp >= level * 50:
                xp -= level * 50
                level += 1

func _input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        if event.pressed:
            touch_points[event.index] = event.position
        else:
            touch_points.erase(event.index)
    elif event is InputEventScreenDrag:
        touch_points[event.index] = event.position
    elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not OS.has_feature("mobile"):
        if event.pressed:
            touch_points[-1] = event.position
        else:
            touch_points.erase(-1)
    elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not OS.has_feature("mobile"):
        touch_points[-1] = event.position

func _draw() -> void:
    var font := ThemeDB.fallback_font
    draw_rect(Rect2(0, 0, 1280, 720), Color("#1d2a3e"))
    draw_circle(Vector2(1060, 108), 59, Color("#d6d5ad"))
    draw_circle(Vector2(1060, 108), 51, Color("#eee8c3"))
    # Distant forest
    for i in range(11):
        var x := float(i) * 140.0 - 20.0
        draw_rect(Rect2(x, 245, 28, 185), Color("#1b3032"))
        draw_circle(Vector2(x + 15, 265), 72, Color("#263f3c"))
        draw_circle(Vector2(x - 15, 310), 62, Color("#304943"))
    # Walkable arena: the character can move both up and down here.
    draw_colored_polygon(PackedVector2Array([
        Vector2(0, 400), Vector2(1280, 400),
        Vector2(1280, 720), Vector2(0, 720)
    ]), Color("#574b45"))
    draw_rect(Rect2(0, 400, 1280, 9), Color("#68765c"))
    for i in range(28):
        var gx := float((i * 193 + 37) % 1280)
        var gy := 427.0 + float((i * 79) % 260)
        draw_line(Vector2(gx, gy), Vector2(gx + 22, gy + 4), Color("#766758"), 2)
    for i in range(8):
        var px := float(i * 184 + 30)
        draw_circle(Vector2(px, 405), 19, Color("#405a42"))
        draw_circle(Vector2(px + 28, 405), 16, Color("#4d6545"))

    # Draw actors by ground Y, not by their jump height.
    if hero.y < enemy.y:
        draw_hero()
        if enemy_alive:
            draw_enemy()
    else:
        if enemy_alive:
            draw_enemy()
        draw_hero()

    # UI
    draw_rect(Rect2(18, 18, 278, 75), Color("#16222d"))
    draw_string(font, Vector2(32, 45), "WITCH  LVL %d" % level, HORIZONTAL_ALIGNMENT_LEFT, -1, 23, Color.WHITE)
    draw_rect(Rect2(32, 57, 210, 14), Color("#493038"))
    draw_rect(Rect2(32, 57, health * 2.1, 14), Color("#d75f75"))
    draw_string(font, Vector2(266, 70), str(health), HORIZONTAL_ALIGNMENT_RIGHT, -1, 18, Color.WHITE)
    draw_string(font, Vector2(30, 116), "XP: %d    Find the slime in the arena" % xp, HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color.WHITE)
    if not enemy_alive:
        draw_string(font, Vector2(495, 290), "VICTORY! +25 XP", HORIZONTAL_ALIGNMENT_LEFT, -1, 33, Color("#ffe1a4"))

    draw_control(Vector2(80, 630), "<", font)
    draw_control(Vector2(230, 630), ">", font)
    draw_control(Vector2(155, 560), "^", font)
    draw_control(Vector2(155, 695), "v", font)
    draw_control(Vector2(980, 635), "JUMP", font, 58)
    draw_control(Vector2(1150, 635), "CAST", font, 58)

func draw_hero() -> void:
    var bob := sin(walk_clock) * 3.0 if moving and jump_height == 0.0 else 0.0
    draw_set_transform(hero, 0.0, Vector2(1.15, 0.27))
    draw_circle(Vector2.ZERO, 43.0 - minf(jump_height * 0.06, 12.0), Color(0.04, 0.06, 0.07, 0.44))
    draw_set_transform(Vector2.ZERO)
    if witch_texture:
        draw_set_transform(hero + Vector2(0, -jump_height + bob), 0.0, Vector2(facing, 1))
        draw_texture_rect(witch_texture, Rect2(-60, -204, 120, 204), false)
        draw_set_transform(Vector2.ZERO)
    else:
        # Emergency fallback if the sprite file has not imported yet.
        draw_circle(hero + Vector2(0, -jump_height - 83), 20, Color("#e2b59c"))
        draw_colored_polygon(PackedVector2Array([
            hero + Vector2(-28, -jump_height - 105),
            hero + Vector2(28, -jump_height - 105),
            hero + Vector2(0, -jump_height - 170)
        ]), Color("#302438"))
        draw_rect(Rect2(hero.x - 45, hero.y - jump_height - 111, 90, 9), Color("#302438"))
        draw_colored_polygon(PackedVector2Array([
            hero + Vector2(-26, -jump_height - 61),
            hero + Vector2(25, -jump_height - 61),
            hero + Vector2(39, -jump_height - 2),
            hero + Vector2(-36, -jump_height - 2)
        ]), Color("#783e51"))
    if attack_flash > 0.0:
        var c := hero + Vector2(facing * 93, -jump_height - 95)
        draw_arc(c, 49, -1.2, 2.5, 28, Color("#a4ffc2"), 8.0)
        draw_circle(c + Vector2(facing * 20, 0), 16, Color(0.4, 1.0, 0.6, attack_flash / 0.22))

func draw_enemy() -> void:
    draw_set_transform(enemy, 0.0, Vector2(1.0, 0.25))
    draw_circle(Vector2.ZERO, 34, Color(0.03, 0.05, 0.05, 0.45))
    draw_set_transform(Vector2.ZERO)
    var col := Color("#e4a7ce") if hit_flash > 0.0 else Color("#ad5686")
    draw_circle(enemy + Vector2(0, -30), 31, col)
    draw_rect(Rect2(enemy.x - 31, enemy.y - 30, 62, 30), col)
    draw_circle(enemy + Vector2(-12, -35), 5, Color.WHITE)
    draw_circle(enemy + Vector2(12, -35), 5, Color.WHITE)
    draw_rect(Rect2(enemy.x - 40, enemy.y - 79, 80, 7), Color("#4b2a38"))
    draw_rect(Rect2(enemy.x - 40, enemy.y - 79, 80.0 * float(enemy_hp) / 3.0, 7), Color("#f48eac"))

func draw_control(center: Vector2, label: String, font: Font, radius: float = 44.0) -> void:
    draw_circle(center, radius, Color(0.08, 0.12, 0.17, 0.76))
    draw_arc(center, radius, 0, TAU, 40, Color("#a4b5bb"), 2.5)
    draw_string(font, center + Vector2(-radius + 6, 8), label, HORIZONTAL_ALIGNMENT_CENTER, (radius - 6) * 2.0, 20, Color.WHITE)
