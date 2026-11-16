extends Node2D

# Witch Game: first playable placeholder prototype (Godot 4 / Xogot)
const GROUND := 590.0
const SPEED := 260.0
const GRAVITY := 1250.0
const JUMP_SPEED := -540.0

var hero := Vector2(170, GROUND)
var velocity_y := 0.0
var facing := 1
var health := 100
var xp := 0
var level := 1
var enemy_x := 890.0
var enemy_hp := 3
var enemy_alive := true
var attack_flash := 0.0
var attack_cooldown := 0.0
var touch_left := false
var touch_right := false
var touch_jump := false
var touch_attack := false

func _ready() -> void:
    queue_redraw()

func _process(delta: float) -> void:
    var direction := 0.0
    if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT) or touch_left:
        direction -= 1.0
    if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT) or touch_right:
        direction += 1.0
    if direction != 0.0:
        facing = int(sign(direction))
    hero.x = clampf(hero.x + direction * SPEED * delta, 55.0, 1220.0)
    if (Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_SPACE) or touch_jump) and hero.y >= GROUND:
        velocity_y = JUMP_SPEED
    velocity_y += GRAVITY * delta
    hero.y = minf(GROUND, hero.y + velocity_y * delta)
    if hero.y >= GROUND:
        velocity_y = 0.0
    attack_flash = maxf(0.0, attack_flash - delta)
    attack_cooldown = maxf(0.0, attack_cooldown - delta)
    if (Input.is_key_pressed(KEY_J) or touch_attack) and attack_cooldown <= 0.0:
        attack()
    queue_redraw()

func attack() -> void:
    attack_flash = 0.18
    attack_cooldown = 0.42
    if enemy_alive and absf(hero.x - enemy_x) < 170.0 and (enemy_x - hero.x) * facing > -15.0 and absf(hero.y - GROUND) < 110.0:
        enemy_hp -= 1
        if enemy_hp <= 0:
            enemy_alive = false
            xp += 25
            if xp >= level * 50:
                xp -= level * 50
                level += 1

func _input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        update_touch(event.position, event.pressed)
    elif event is InputEventScreenDrag:
        update_touch(event.position, true)
    elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        update_touch(event.position, event.pressed)

func update_touch(pos: Vector2, pressed: bool) -> void:
    # Large bottom-screen hit areas for iPad controls.
    if not pressed:
        touch_left = false
        touch_right = false
        touch_jump = false
        touch_attack = false
        return
    if pos.y > 560.0:
        touch_left = pos.x < 145.0
        touch_right = pos.x >= 145.0 and pos.x < 305.0
        touch_jump = pos.x > 870.0 and pos.x < 1065.0
        touch_attack = pos.x >= 1065.0

func _draw() -> void:
    var font := ThemeDB.fallback_font
    # Night forest and path
    draw_rect(Rect2(0, 0, 1280, 720), Color("#263448"))
    draw_circle(Vector2(1060, 110), 58, Color("#d5d2a0"))
    for i in range(9):
        var tx := float(i) * 165.0 + 35.0
        draw_rect(Rect2(tx, 270, 35, 320), Color("#27372f"))
        draw_circle(Vector2(tx + 18, 265), 85, Color("#344f42"))
        draw_circle(Vector2(tx - 25, 325), 65, Color("#3b5d4a"))
    draw_rect(Rect2(0, GROUND + 4, 1280, 130), Color("#655344"))
    draw_rect(Rect2(0, GROUND, 1280, 8), Color("#96a36b"))
    for i in range(15):
        draw_line(Vector2(i * 90 + 17, 626), Vector2(i * 90 + 38, 630), Color("#84715b"), 3)
    # Witch: simple hand-drawn-style placeholder (not final artwork)
    draw_circle(hero + Vector2(0, -82), 20, Color("#e2b59c"))
    draw_colored_polygon(PackedVector2Array([hero + Vector2(-28, -105), hero + Vector2(28, -105), hero + Vector2(0, -170)]), Color("#302438"))
    draw_rect(Rect2(hero.x - 45, hero.y - 111, 90, 9), Color("#302438"))
    draw_colored_polygon(PackedVector2Array([hero + Vector2(-26, -61), hero + Vector2(25, -61), hero + Vector2(39, -2), hero + Vector2(-36, -2)]), Color("#783e51"))
    draw_line(hero + Vector2(30 * facing, -60), hero + Vector2(46 * facing, -135), Color("#6b4d35"), 7)
    draw_circle(hero + Vector2(46 * facing, -137), 13, Color("#7cdc91"))
    draw_circle(hero + Vector2(7 * facing, -85), 3, Color("#262535"))
    # Spell hit effect
    if attack_flash > 0.0:
        draw_arc(hero + Vector2(facing * 93, -78), 54, -1.0, 2.4, 32, Color("#9af5af"), 10.0)
        draw_circle(hero + Vector2(facing * 120, -78), 18, Color(0.4, 1.0, 0.6, attack_flash / 0.18))
    # Slime opponent
    if enemy_alive:
        draw_circle(Vector2(enemy_x, GROUND - 26), 32, Color("#a94b80"))
        draw_rect(Rect2(enemy_x - 32, GROUND - 28, 64, 30), Color("#a94b80"))
        draw_circle(Vector2(enemy_x - 12, GROUND - 32), 5, Color.WHITE)
        draw_circle(Vector2(enemy_x + 12, GROUND - 32), 5, Color.WHITE)
        draw_rect(Rect2(enemy_x - 40, GROUND - 78, 80, 7), Color("#5a2c39"))
        draw_rect(Rect2(enemy_x - 40, GROUND - 78, 80.0 * enemy_hp / 3.0, 7), Color("#f681a8"))
    # HUD
    draw_rect(Rect2(18, 18, 270, 72), Color("#18242d"))
    draw_string(font, Vector2(32, 45), "WITCH   LVL %d" % level, HORIZONTAL_ALIGNMENT_LEFT, -1, 23, Color.WHITE)
    draw_rect(Rect2(32, 55, 212, 15), Color("#432f36"))
    draw_rect(Rect2(32, 55, health * 2.12, 15), Color("#d86170"))
    draw_string(font, Vector2(260, 69), "%d" % health, HORIZONTAL_ALIGNMENT_RIGHT, -1, 17, Color.WHITE)
    draw_string(font, Vector2(30, 116), "XP: %d    Defeat the slime!" % xp, HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color.WHITE)
    if not enemy_alive:
        draw_string(font, Vector2(510, 245), "VICTORY! +25 XP", HORIZONTAL_ALIGNMENT_LEFT, -1, 34, Color("#ffe1a4"))
    # On-screen controls
    for item in [[Vector2(80, 652), "<"], [Vector2(235, 652), ">"], [Vector2(975, 652), "JUMP"], [Vector2(1155, 652), "CAST"]]:
        draw_circle(item[0], 62, Color(0.08, 0.12, 0.17, 0.68))
        draw_arc(item[0], 62, 0, TAU, 48, Color("#9fafb6"), 3.0)
        draw_string(font, item[0] + Vector2(-37, 8), item[1], HORIZONTAL_ALIGNMENT_CENTER, 74, 23, Color.WHITE)
