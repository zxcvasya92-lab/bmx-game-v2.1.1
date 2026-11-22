extends "res://scripts/physics.gd"
# Ввод, виртуальные кнопки, меню, твики, диагностика, запуск и главный цикл.

func load_settings() -> void:
	var cf := ConfigFile.new()
	if cf.load("user://bmx.cfg") == OK:
		assist_bal = cf.get_value("s", "assist_bal", true)
		assist_land = cf.get_value("s", "assist_land", true)
		invert_y = cf.get_value("s", "invert_y", false)
		show_labels = cf.get_value("s", "show_labels", true)
		ui_opacity = cf.get_value("s", "ui_opacity", 0.55)
		ui_scale = cf.get_value("s", "ui_scale", 1.0)
		flips_on = cf.get_value("s", "flips_on", true)
		rider_ik = cf.get_value("s", "rider_ik", true)
		diag_on = cf.get_value("s", "diag_on", true)
		grind_on = cf.get_value("s", "grind_on", true)
		stance = cf.get_value("s", "stance", 1)

func save_settings() -> void:
	var cf := ConfigFile.new()
	cf.set_value("s", "assist_bal", assist_bal)
	cf.set_value("s", "assist_land", assist_land)
	cf.set_value("s", "invert_y", invert_y)
	cf.set_value("s", "show_labels", show_labels)
	cf.set_value("s", "ui_opacity", ui_opacity)
	cf.set_value("s", "ui_scale", ui_scale)
	cf.set_value("s", "flips_on", flips_on)
	cf.set_value("s", "rider_ik", rider_ik)
	cf.set_value("s", "diag_on", diag_on)
	cf.set_value("s", "grind_on", grind_on)
	cf.set_value("s", "stance", stance)
	cf.save("user://bmx.cfg")

func add_ctrl(key: String, kind: String, pos: Vector2, caption: String) -> void:
	ctrls[key] = {"kind": kind, "pos": pos, "dpos": pos, "scale": 1.0, "caption": caption,
		"down": false, "touch": -1, "off": Vector2.ZERO}

func default_layout() -> void:
	ctrls = {}
	add_ctrl("L", "rect", Vector2(0.085, 0.065), "поджатие")
	add_ctrl("R", "rect", Vector2(0.915, 0.065), "руки")
	add_ctrl("dpad", "dpad", Vector2(0.12, 0.60), "")
	add_ctrl("stick", "stick", Vector2(0.25, 0.80), "руль · вес")
	add_ctrl("stick2", "stick", Vector2(0.75, 0.80), "вращения · флипы")
	add_ctrl("triangle", "circle", Vector2(0.891, 0.492), "тормоз / слайд")
	add_ctrl("square", "circle", Vector2(0.839, 0.583), "опо вип / бар")
	add_ctrl("circle", "circle", Vector2(0.942, 0.583), "вип / бар")
	add_ctrl("cross", "circle", Vector2(0.891, 0.675), "разгон / хоп")
	add_ctrl("select", "rect", Vector2(0.44, 0.94), "")
	add_ctrl("start", "rect", Vector2(0.56, 0.94), "")

func reset_layout() -> void:
	for key in ctrls:
		var c: Dictionary = ctrls[key]
		c["pos"] = c["dpos"]
		c["scale"] = 1.0
	save_layout()

func load_layout() -> void:
	default_layout()
	var cf := ConfigFile.new()
	if cf.load("user://layout.cfg") != OK:
		return
	for key in ctrls:
		var c: Dictionary = ctrls[key]
		var p: Vector2 = c["pos"]
		p.x = cf.get_value("l", str(key) + "_x", p.x)
		p.y = cf.get_value("l", str(key) + "_y", p.y)
		c["pos"] = p
		c["scale"] = cf.get_value("l", str(key) + "_s", 1.0)

func save_layout() -> void:
	var cf := ConfigFile.new()
	for key in ctrls:
		var c: Dictionary = ctrls[key]
		var p: Vector2 = c["pos"]
		cf.set_value("l", str(key) + "_x", p.x)
		cf.set_value("l", str(key) + "_y", p.y)
		cf.set_value("l", str(key) + "_s", c["scale"])
	cf.save("user://layout.cfg")

func ctrl_center(key: String) -> Vector2:
	var c: Dictionary = ctrls[key]
	var p: Vector2 = c["pos"]
	return p * vp_size()

func ctrl_radius(key: String) -> float:
	var c: Dictionary = ctrls[key]
	var kind: String = c["kind"]
	var base := 40.0
	if kind == "dpad":
		base = 80.0
	elif kind == "stick":
		base = 62.0
	return base * float(c["scale"]) * ui_scale

func ctrl_halfsize(key: String) -> Vector2:
	var c: Dictionary = ctrls[key]
	var base := Vector2(40, 15)
	if key == "L" or key == "R":
		base = Vector2(70, 27)
	return base * float(c["scale"]) * ui_scale

func ctrl_hit(key: String, p: Vector2) -> bool:
	var c: Dictionary = ctrls[key]
	var kind: String = c["kind"]
	var cc := ctrl_center(key)
	if kind == "rect":
		var hs := ctrl_halfsize(key) + Vector2(8, 8)
		return absf(p.x - cc.x) <= hs.x and absf(p.y - cc.y) <= hs.y
	var r := ctrl_radius(key)
	if kind == "stick":
		r *= 1.25
	return p.distance_to(cc) <= r

func is_down(key: String) -> bool:
	var c: Dictionary = ctrls[key]
	return bool(c["down"])

func release_all() -> void:
	touch_role.clear()
	for key in ctrls:
		var c: Dictionary = ctrls[key]
		c["down"] = false
		c["touch"] = -1
		c["off"] = Vector2.ZERO
	stick_vec["stick"] = Vector2.ZERO
	stick_vec["stick2"] = Vector2.ZERO
	dpad_dir = Vector2.ZERO
	pedal_release("L")
	pedal_release("R")
	kb_hop = false

func show_screen(n: int) -> void:
	menu_screen = n
	menu_panel.visible = menu_open and n == 0
	settings_panel.visible = menu_open and n == 1
	help_panel.visible = menu_open and n == 2

func _on_open_settings() -> void:
	show_screen(1)

func _on_open_help() -> void:
	show_screen(2)

func _on_back() -> void:
	show_screen(0)

func toggle_menu() -> void:
	if edit_mode:
		return
	menu_open = not menu_open
	show_screen(0)
	if menu_open:
		release_all()

func enter_edit() -> void:
	edit_mode = true
	menu_open = false
	show_screen(0)
	edit_bar.visible = true
	edit_sel = ""
	edit_drag = -1
	release_all()

func exit_edit() -> void:
	edit_mode = false
	edit_bar.visible = false
	edit_drag = -1
	menu_open = true
	show_screen(0)
	save_layout()

func edit_scale(f: float) -> void:
	if edit_sel == "":
		return
	var c: Dictionary = ctrls[edit_sel]
	c["scale"] = clampf(float(c["scale"]) * f, 0.5, 2.5)
	save_layout()

func pedal_press(side: String) -> void:
	if pedal_down[side]:
		return
	pedal_down[side] = true
	if mode == AIR:
		if side == "L":
			foot_air_l = true
		else:
			foot_air_r = true
	var v := -1 if side == "L" else 1
	var val := 1.3 if v != pedal_last else 0.3
	pedal_kick += val
	pedal_tap += val
	pedal_last = v

func pedal_release(side: String) -> void:
	pedal_down[side] = false
	if side == "L":
		foot_air_l = false
	else:
		foot_air_r = false

func ctrl_press(key: String) -> void:
	match key:
		"start":
			toggle_menu()
		"select":
			respawn(true)

func ctrl_release(key: String) -> void:
	var c: Dictionary = ctrls[key]
	c["touch"] = -1
	c["down"] = false
	c["off"] = Vector2.ZERO
	if key == "L":
		pedal_release("L")
	elif key == "R":
		pedal_release("R")
	elif key == "stick" or key == "stick2":
		stick_vec[key] = Vector2.ZERO
	elif key == "dpad":
		dpad_dir = Vector2.ZERO

func ctrl_update(key: String, p: Vector2) -> void:
	var c: Dictionary = ctrls[key]
	var kind: String = c["kind"]
	var cc := ctrl_center(key)
	if kind == "stick":
		var R := ctrl_radius(key)
		var d := p - cc
		if d.length() > R:
			d = d / d.length() * R
		c["off"] = d
		stick_vec[key] = deadzone(Vector2(d.x / R, -d.y / R))
	elif kind == "dpad":
		var r := ctrl_radius(key)
		var d2 := p - cc
		var v := Vector2.ZERO
		if d2.x > r * 0.28:
			v.x = 1.0
		elif d2.x < -r * 0.28:
			v.x = -1.0
		if -d2.y > r * 0.28:
			v.y = 1.0
		elif -d2.y < -r * 0.28:
			v.y = -1.0
		dpad_dir = v

func gui_blocks(p: Vector2) -> bool:
	for pnl in [menu_panel, settings_panel, help_panel]:
		var pc := pnl as PanelContainer
		if pc != null and pc.visible and pc.get_global_rect().has_point(p):
			return true
	if edit_bar.visible and edit_bar.get_global_rect().has_point(p):
		return true
	return false

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		if t.pressed:
			touch_down(t.index, t.position)
		else:
			touch_up(t.index)
	elif event is InputEventScreenDrag:
		var d := event as InputEventScreenDrag
		touch_move(d.index, d.position)

func touch_down(idx: int, p: Vector2) -> void:
	if gui_blocks(p):
		return
	if edit_mode:
		for key in HIT_ORDER:
			if ctrl_hit(key, p):
				edit_sel = key
				edit_drag = idx
				edit_off = ctrl_center(key) - p
				return
		return
	if menu_open:
		return
	for key in HIT_ORDER:
		if ctrl_hit(key, p):
			var c: Dictionary = ctrls[key]
			if int(c["touch"]) != -1:
				continue
			c["touch"] = idx
			c["down"] = true
			touch_role[idx] = key
			ctrl_press(key)
			ctrl_update(key, p)
			return

func touch_move(idx: int, p: Vector2) -> void:
	if edit_mode:
		if idx == edit_drag and edit_sel != "":
			var c: Dictionary = ctrls[edit_sel]
			var np := (p + edit_off) / vp_size()
			np.x = clampf(np.x, 0.03, 0.97)
			np.y = clampf(np.y, 0.04, 0.96)
			c["pos"] = np
		return
	var key: String = touch_role.get(idx, "")
	if key == "stick" or key == "stick2" or key == "dpad":
		ctrl_update(key, p)

func touch_up(idx: int) -> void:
	if edit_mode:
		if idx == edit_drag:
			edit_drag = -1
			save_layout()
		return
	var key: String = touch_role.get(idx, "")
	if key == "":
		return
	touch_role.erase(idx)
	ctrl_release(key)

func on_cross_press() -> void:
	if mode == GROUND and not sliding:
		mash_n += 1
		mash_t = 0.7
		if hop_armed:
			pedal_tap += 1.8
		else:
			pedal_kick += 1.1
			crank_w += 6.0
	elif mode == AIR:
		if held_L and air_t > 0.1 and crank_rem <= 0.0 and hH_ok():
			crank_rem = TAU
	elif mode == GRIND:
		gr_jump_req = true

func hH_ok() -> bool:
	return py - terrain_h(px, pz) > 0.4

func on_circle_press() -> void:
	if mode == GROUND and not sliding and held_L and in_ly > 0.4 and absf(spd) > 1.5:
		start_footjam()
		return
	if mode == GROUND and not sliding and held_R and th > 0.25 and bar_rem <= 0.0 and bar_cool <= 0.0:
		bar_rem = TAU
		bar_dir = -1.0 if in_lx < 0.0 else 1.0
		bar_chicken = true
		return
	if mode != AIR or air_t < 0.08 or not hH_ok():
		return
	# Круг: родное направление по стойке
	if held_L and tw_rem <= 0.0 and tw_cool <= 0.0:
		tw_rem = TAU
		tw_dir = float(stance)
		tw_footjam = false
	elif held_R and bar_rem <= 0.0 and bar_cool <= 0.0:
		bar_rem = TAU
		bar_dir = float(stance)
		bar_chicken = false

func on_square_press() -> void:
	if mode != AIR or air_t < 0.08 or not hH_ok():
		return
	# Квадрат: опо-вариант (в обратную сторону) — вип с L, бар с R
	if held_L and tw_rem <= 0.0 and tw_cool <= 0.0:
		tw_rem = TAU
		tw_dir = -float(stance)
		tw_footjam = false
	elif held_R and bar_rem <= 0.0 and bar_cool <= 0.0:
		bar_rem = TAU
		bar_dir = -float(stance)
		bar_chicken = false

func on_tri_press() -> void:
	if mode == GROUND and not sliding and spd < -0.8:
		start_slide()

func poll_input(dt: float) -> void:
	var paused := menu_open or edit_mode
	# --- клавиатура (физические клавиши — работают при любой раскладке)
	var kL := Input.is_physical_key_pressed(KEY_Q)
	var kR := Input.is_physical_key_pressed(KEY_E)
	var kX := Input.is_physical_key_pressed(KEY_SPACE)
	var kO := Input.is_physical_key_pressed(KEY_X)
	var kT := Input.is_physical_key_pressed(KEY_C)
	var kS := Input.is_physical_key_pressed(KEY_Z)
	var rr := Input.is_physical_key_pressed(KEY_R)
	if rr and not kr and not paused:
		respawn(true)
	kr = rr
	var esc := Input.is_physical_key_pressed(KEY_ESCAPE)
	if esc and not kesc:
		toggle_menu()
	kesc = esc
	var tx := 0.0
	var ty := 0.0
	var tcx := 0.0
	var tcy := 0.0
	if Input.is_physical_key_pressed(KEY_D):
		tx += 1.0
	if Input.is_physical_key_pressed(KEY_A):
		tx -= 1.0
	if Input.is_physical_key_pressed(KEY_W):
		ty += 1.0
	if Input.is_physical_key_pressed(KEY_S):
		ty -= 1.0
	if Input.is_physical_key_pressed(KEY_RIGHT):
		tcx += 1.0
	if Input.is_physical_key_pressed(KEY_LEFT):
		tcx -= 1.0
	if Input.is_physical_key_pressed(KEY_UP):
		tcy += 1.0
	if Input.is_physical_key_pressed(KEY_DOWN):
		tcy -= 1.0
	kb_lx = damp(kb_lx, tx, 16.0, dt)
	kb_ly = damp(kb_ly, ty, 16.0, dt)
	kb_rx = damp(kb_rx, tcx, 16.0, dt)
	kb_ry = damp(kb_ry, tcy, 16.0, dt)
	dpad_dig.x = damp(dpad_dig.x, dpad_dir.x, 16.0, dt)
	dpad_dig.y = damp(dpad_dig.y, dpad_dir.y, 16.0, dt)
	# --- геймпад: LB/LT — L, RB/RT — R, A — Крест, B — Круг, Y — Треугольник, X — Квадрат
	var pl := Vector2.ZERO
	var pr := Vector2.ZERO
	var gL := false
	var gR := false
	var gX := false
	var gO := false
	var gT := false
	var gS := false
	var pads := Input.get_connected_joypads()
	if pads.size() > 0:
		var j: int = pads[0]
		pl = deadzone(Vector2(Input.get_joy_axis(j, JOY_AXIS_LEFT_X), -Input.get_joy_axis(j, JOY_AXIS_LEFT_Y)))
		pr = deadzone(Vector2(Input.get_joy_axis(j, JOY_AXIS_RIGHT_X), -Input.get_joy_axis(j, JOY_AXIS_RIGHT_Y)))
		gL = Input.is_joy_button_pressed(j, JOY_BUTTON_LEFT_SHOULDER) or Input.get_joy_axis(j, JOY_AXIS_TRIGGER_LEFT) > 0.5
		gR = Input.is_joy_button_pressed(j, JOY_BUTTON_RIGHT_SHOULDER) or Input.get_joy_axis(j, JOY_AXIS_TRIGGER_RIGHT) > 0.5
		gX = Input.is_joy_button_pressed(j, JOY_BUTTON_A)
		gO = Input.is_joy_button_pressed(j, JOY_BUTTON_B)
		gT = Input.is_joy_button_pressed(j, JOY_BUTTON_Y)
		gS = Input.is_joy_button_pressed(j, JOY_BUTTON_X)
		var ps := Input.is_joy_button_pressed(j, JOY_BUTTON_START)
		if ps and not pad_start:
			toggle_menu()
		pad_start = ps
		var pk := Input.is_joy_button_pressed(j, JOY_BUTTON_BACK)
		if pk and not pad_back and not paused:
			respawn(true)
		pad_back = pk
	# --- сводим экранные кнопки, клавиатуру и геймпад
	var hL := is_down("L") or kL or gL
	var hR := is_down("R") or kR or gR
	var hX := is_down("cross") or kX or gX
	var hO := is_down("circle") or kO or gO
	var hT := is_down("triangle") or kT or gT
	var hS := is_down("square") or kS or gS
	var air := mode == AIR
	if hL and not held_L and air:
		armed_L = true
	if not hL:
		armed_L = false
	if hR and not held_R and air:
		armed_R = true
	if not hR:
		armed_R = false
	var ev_x := hX and not held_X
	var ev_o := hO and not held_O
	var ev_t := hT and not held_T
	var ev_s := hS and not held_S
	held_L = hL
	held_R = hR
	held_X = hX
	held_O = hO
	held_T = hT
	held_S = hS
	# L зажатая в воздухе — поджатие байка (приземляться можно)
	hand_l_off = false
	hand_r_off = false
	foot_l_off = false
	foot_r_off = false
	tuck_on = hL and air
	brake_held = hT
	xup_held = hR and hX and air
	pedal_both_t = 0.0
	if not paused:
		if ev_x:
			on_cross_press()
		if ev_o:
			on_circle_press()
		if ev_t:
			on_tri_press()
		if ev_s:
			on_square_press()
	var sl: Vector2 = stick_vec["stick"]
	var sr: Vector2 = stick_vec["stick2"]
	in_lx = clampf(kb_lx + sl.x + dpad_dig.x + pl.x, -1.0, 1.0)
	in_ly = clampf(kb_ly + sl.y + dpad_dig.y + pl.y, -1.0, 1.0) * (-1.0 if invert_y else 1.0)
	in_rx = clampf(kb_rx + sr.x + pr.x, -1.0, 1.0)
	in_ry = clampf(kb_ry + sr.y + pr.y, -1.0, 1.0)

# =====================================================================
# МЕНЮ, РЕДАКТОР РАСКЛАДКИ, ОТРИСОВКА
# =====================================================================

func make_check(text: String, state: bool, cb: Callable) -> Button:
	var b := Button.new()
	b.toggle_mode = true
	b.button_pressed = state
	b.custom_minimum_size = Vector2(0, 62)
	b.add_theme_font_size_override("font_size", 22)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.text = text + (":  ВКЛ" if state else ":  ВЫКЛ")
	b.toggled.connect(_on_toggle_btn.bind(b, text, cb))
	return b

func make_button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 62)
	b.add_theme_font_size_override("font_size", 22)
	b.pressed.connect(cb)
	return b

func make_slider(text: String, mn: float, mx: float, val: float, cb: Callable) -> HBoxContainer:
	var h := HBoxContainer.new()
	var l := Label.new()
	l.text = text
	l.custom_minimum_size = Vector2(340, 0)
	l.add_theme_font_size_override("font_size", 21)
	h.add_child(l)
	var sl := HSlider.new()
	sl.min_value = mn
	sl.max_value = mx
	sl.step = 0.05
	sl.value = val
	sl.custom_minimum_size = Vector2(300, 52)
	sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	style_slider(sl)
	sl.value_changed.connect(cb)
	h.add_child(sl)
	return h

func _on_bal(v: bool) -> void:
	assist_bal = v
	save_settings()

func _on_land(v: bool) -> void:
	assist_land = v
	save_settings()

func _on_inv(v: bool) -> void:
	invert_y = v
	save_settings()

func _on_labels(v: bool) -> void:
	show_labels = v
	save_settings()

func _on_opacity(v: float) -> void:
	ui_opacity = v
	save_settings()

func _on_uiscale(v: float) -> void:
	ui_scale = v
	save_settings()

func _on_minus() -> void:
	edit_scale(0.9)

func _on_plus() -> void:
	edit_scale(1.1)

func _on_reset_layout() -> void:
	reset_layout()

func make_menu_panel(width: float, height: float) -> VBoxContainer:
	var pnl := PanelContainer.new()
	pnl.visible = false
	pnl.anchor_left = 0.5
	pnl.anchor_right = 0.5
	pnl.anchor_top = 0.5
	pnl.anchor_bottom = 0.5
	pnl.grow_horizontal = Control.GROW_DIRECTION_BOTH
	pnl.grow_vertical = Control.GROW_DIRECTION_BOTH
	ui.add_child(pnl)
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(width, height)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	pnl.add_child(sc)
	sc.get_v_scroll_bar().custom_minimum_size = Vector2(30, 0)
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.custom_minimum_size = Vector2(width - 50.0, 0)
	vb.add_theme_constant_override("separation", 10)
	sc.add_child(vb)
	var t := Label.new()
	vb.add_child(t)
	vb.set_meta("panel", pnl)
	vb.set_meta("title", t)
	return vb

func menu_title(vb: VBoxContainer, text: String) -> void:
	var t := vb.get_meta("title") as Label
	t.text = text
	t.add_theme_font_size_override("font_size", 34)

func build_ui() -> void:
	ui = CanvasLayer.new()
	add_child(ui)
	hud = Control.new()
	hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(hud)
	hud.draw.connect(_on_hud_draw)
	var vs := vp_size()
	var mw := minf(1180.0, vs.x - 60.0)
	var mh := minf(640.0, vs.y - 40.0)
	# --- главное меню (Start) ---
	var vm := make_menu_panel(minf(760.0, vs.x - 60.0), minf(560.0, vs.y - 40.0))
	menu_panel = vm.get_meta("panel") as PanelContainer
	menu_title(vm, "МЕНЮ")
	vm.add_child(make_button("Продолжить", toggle_menu))
	vm.add_child(make_button("Настройки", _on_open_settings))
	vm.add_child(make_button("Расположение кнопок", enter_edit))
	vm.add_child(make_button("Справка", _on_open_help))
	# --- настройки ---
	var vb := make_menu_panel(mw, mh)
	settings_panel = vb.get_meta("panel") as PanelContainer
	menu_title(vb, "НАСТРОЙКИ")
	vb.add_child(make_button("Назад", _on_back))
	stance_btn = make_button(stance_text(), _on_stance)
	vb.add_child(stance_btn)
	vb.add_child(make_button("Сбросить расположение кнопок", _on_reset_layout))
	vb.add_child(make_slider("Прозрачность кнопок", 0.15, 1.0, ui_opacity, _on_opacity))
	vb.add_child(make_slider("Общий размер кнопок", 0.6, 1.6, ui_scale, _on_uiscale))
	vb.add_child(make_check("Подписи под кнопками", show_labels, _on_labels))
	vb.add_child(make_check("Помощь баланса мануала", assist_bal, _on_bal))
	vb.add_child(make_check("Помощь приземления", assist_land, _on_land))
	vb.add_child(make_check("Инверсия вертикали левого стика", invert_y, _on_inv))
	vb.add_child(make_check("Флипы (правый стик вверх/вниз)", flips_on, _on_flips))
	vb.add_child(make_check("Райдер по скелету (IK), выкл = запечённая поза", rider_ik, _on_rik))
	vb.add_child(make_check("Гринд: автозахват рейлы", grind_on, _on_grind))
	vb.add_child(make_check("Диагностика модели на экране", diag_on, _on_diag))
	var th_lab := Label.new()
	th_lab.text = "ФИЗИКА И АНИМАЦИИ"
	th_lab.add_theme_font_size_override("font_size", 28)
	vb.add_child(th_lab)
	for t in TWEAKS:
		vb.add_child(make_tweak_slider(t))
	vb.add_child(make_button("Сбросить физику и анимации", _on_reset_tweaks))
	vb.add_child(make_button("Назад", _on_back))
	# --- справка ---
	var vh := make_menu_panel(mw, mh)
	help_panel = vh.get_meta("panel") as PanelContainer
	menu_title(vh, "СПРАВКА")
	vh.add_child(make_button("Назад", _on_back))
	var lab := Label.new()
	lab.text = HELP_TEXT
	lab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lab.custom_minimum_size = Vector2(mw - 90.0, 0)
	lab.add_theme_font_size_override("font_size", 19)
	vh.add_child(lab)
	vh.add_child(make_button("Назад", _on_back))
	# --- панель редактора раскладки ---
	edit_bar = PanelContainer.new()
	edit_bar.visible = false
	edit_bar.anchor_left = 0.5
	edit_bar.anchor_right = 0.5
	edit_bar.offset_top = 8.0
	edit_bar.grow_horizontal = Control.GROW_DIRECTION_BOTH
	ui.add_child(edit_bar)
	var hb := HBoxContainer.new()
	edit_bar.add_child(hb)
	edit_lbl = Label.new()
	edit_lbl.custom_minimum_size = Vector2(380, 0)
	edit_lbl.add_theme_font_size_override("font_size", 20)
	hb.add_child(edit_lbl)
	hb.add_child(make_button("−", _on_minus))
	hb.add_child(make_button("+", _on_plus))
	hb.add_child(make_button("Сброс", _on_reset_layout))
	hb.add_child(make_button("Готово", exit_edit))

func draw_ctrl(key: String, f: Font) -> void:
	var c: Dictionary = ctrls[key]
	var kind: String = c["kind"]
	var down: bool = c["down"]
	var cc := ctrl_center(key)
	var A := maxf(ui_opacity, 0.5) if edit_mode else ui_opacity
	var fill := Color(1, 1, 1, (0.5 if down else 0.2) * A)
	var line := Color(1, 1, 1, 0.85 * A)
	var ta := minf(1.0, A + 0.3)
	var cap: String = c["caption"]
	var cap_y := cc.y
	if kind == "rect":
		var hs := ctrl_halfsize(key)
		var rc := Rect2(cc - hs, hs * 2.0)
		if key == "L" or key == "R":
			if mode == AIR and ((key == "L" and foot_l_off) or (key == "R" and hand_r_off)):
				line = Color(0.6, 0.95, 0.5, 0.95)
		hud.draw_rect(rc, fill, true)
		hud.draw_rect(rc, line, false, 2.5)
		var txt := key if (key == "L" or key == "R") else key.to_upper()
		var fs := int(hs.y * 0.85)
		hud.draw_string(f, Vector2(cc.x - hs.x, cc.y + fs * 0.36), txt, HORIZONTAL_ALIGNMENT_CENTER, hs.x * 2.0, fs, Color(1, 1, 1, ta))
		cap_y = cc.y + hs.y + 13.0
	elif kind == "circle":
		var r := ctrl_radius(key)
		if key == "cross" and hop_armed:
			line = Color(1.0, 0.65, 0.15, 0.95)
		hud.draw_circle(cc, r, fill)
		hud.draw_arc(cc, r, 0.0, TAU, 40, line, 2.5)
		var s := r * 0.42
		if key == "cross":
			var col := Color(0.45, 0.65, 1.0, ta)
			hud.draw_line(cc + Vector2(-s, -s), cc + Vector2(s, s), col, 4.0)
			hud.draw_line(cc + Vector2(-s, s), cc + Vector2(s, -s), col, 4.0)
		elif key == "circle":
			hud.draw_arc(cc, s * 1.05, 0.0, TAU, 28, Color(1.0, 0.4, 0.4, ta), 4.0)
		elif key == "square":
			hud.draw_rect(Rect2(cc - Vector2(s, s) * 0.95, Vector2(s, s) * 1.9), Color(1.0, 0.55, 0.85, ta), false, 4.0)
		elif key == "triangle":
			var pts := PackedVector2Array([cc + Vector2(0, -s * 1.1), cc + Vector2(s * 1.0, s * 0.8), cc + Vector2(-s * 1.0, s * 0.8), cc + Vector2(0, -s * 1.1)])
			hud.draw_polyline(pts, Color(0.5, 0.95, 0.55, ta), 4.0)
		cap_y = cc.y + r + 13.0
	elif kind == "dpad":
		var r := ctrl_radius(key)
		var a := r * 0.36
		var plus := PackedVector2Array([
			cc + Vector2(-a, -r), cc + Vector2(a, -r), cc + Vector2(a, -a), cc + Vector2(r, -a),
			cc + Vector2(r, a), cc + Vector2(a, a), cc + Vector2(a, r), cc + Vector2(-a, r),
			cc + Vector2(-a, a), cc + Vector2(-r, a), cc + Vector2(-r, -a), cc + Vector2(-a, -a)])
		hud.draw_colored_polygon(plus, Color(1, 1, 1, 0.2 * A))
		var outline := plus.duplicate()
		outline.append(plus[0])
		hud.draw_polyline(outline, line, 2.5)
		var dirs := [Vector2(0, -1), Vector2(0, 1), Vector2(-1, 0), Vector2(1, 0)]
		for di in range(4):
			var dv: Vector2 = dirs[di]
			var pv := Vector2(-dv.y, dv.x)
			var on := (dpad_dir.x != 0.0 and dv.x == dpad_dir.x) or (dpad_dir.y != 0.0 and dv.y == -dpad_dir.y)
			var ac := Color(1, 1, 1, (0.95 if on else 0.55) * ta)
			hud.draw_colored_polygon(PackedVector2Array([cc + dv * r * 0.84, cc + dv * r * 0.56 + pv * a * 0.6, cc + dv * r * 0.56 - pv * a * 0.6]), ac)
		cap_y = cc.y + r + 13.0
	elif kind == "stick":
		var r := ctrl_radius(key)
		hud.draw_circle(cc, r, Color(1, 1, 1, 0.1 * A))
		hud.draw_arc(cc, r, 0.0, TAU, 48, line, 2.5)
		var off: Vector2 = c["off"]
		hud.draw_circle(cc + off, r * 0.47, Color(1, 1, 1, (0.55 if down else 0.3) * A))
		hud.draw_arc(cc + off, r * 0.47, 0.0, TAU, 28, line, 2.0)
		cap_y = cc.y + r + 13.0
	if (show_labels or edit_mode) and cap != "":
		hud.draw_string(f, Vector2(cc.x - 70, cap_y), cap, HORIZONTAL_ALIGNMENT_CENTER, 140, 11, Color(1, 1, 1, 0.75 * ta))
	if edit_mode and edit_sel == key:
		var yel := Color(1.0, 0.9, 0.3, 0.95)
		if kind == "rect":
			var hs2 := ctrl_halfsize(key)
			hud.draw_rect(Rect2(cc - hs2, hs2 * 2.0).grow(6.0), yel, false, 3.0)
		else:
			var r2 := ctrl_radius(key)
			hud.draw_arc(cc, r2 + 7.0, 0.0, TAU, 48, yel, 3.0)

func _on_hud_draw() -> void:
	var s := vp_size()
	var f := ThemeDB.fallback_font
	for key in ctrls:
		draw_ctrl(key, f)
	# табло
	var iy := 72.0
	hud.draw_rect(Rect2(10, iy, 250, 78), Color(0.04, 0.07, 0.1, 0.6), true)
	hud.draw_string(f, Vector2(20, iy + 22), "BMX STREET  прототип 2.4", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color.WHITE)
	var speed := absf(spd) if mode == GROUND else Vector2(wvx, wvz).length()
	var label := "Земля"
	if mode == BAIL:
		label = "Бейл"
	elif mode == AIR:
		label = "Воздух"
	elif mode == GRIND:
		label = "Гринд"
	elif th > 0.05:
		label = "Мануал"
	elif th < -0.05:
		label = "Ноуз-мануал"
	elif spd < -0.5:
		label = "Фэйки"
	if sliding:
		label = "Слайд"
	hud.draw_string(f, Vector2(20, iy + 44), "%d км/ч · %s" % [int(roundf(speed * 3.6)), label], HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(0.85, 0.92, 1))
	hud.draw_string(f, Vector2(20, iy + 66), "Очки: %d" % score, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color(1, 0.9, 0.5))
	if diag_on and not menu_open and not edit_mode:
		for di in range(diag_text.size()):
			var dl := String(diag_text[di])
			hud.draw_string_outline(f, Vector2(10, iy + 100 + di * 16), dl, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, 3, Color(0, 0, 0, 0.8))
			hud.draw_string(f, Vector2(10, iy + 100 + di * 16), dl, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 1, 0.7))
	# комбо
	if not combo_items.is_empty():
		var ct := " + ".join(PackedStringArray(combo_items))
		if combo_items.size() > 1:
			ct += "  ×%.2f" % combo_mult()
		hud.draw_string_outline(f, Vector2(0, 118), ct, HORIZONTAL_ALIGNMENT_CENTER, s.x, 20, 5, Color(0, 0, 0, 0.8))
		hud.draw_string(f, Vector2(0, 118), ct, HORIZONTAL_ALIGNMENT_CENTER, s.x, 20, Color.WHITE)
		var pt := str(int(roundf(combo_pts * combo_mult())))
		hud.draw_string_outline(f, Vector2(0, 150), pt, HORIZONTAL_ALIGNMENT_CENTER, s.x, 30, 6, Color(0, 0, 0, 0.8))
		hud.draw_string(f, Vector2(0, 150), pt, HORIZONTAL_ALIGNMENT_CENTER, s.x, 30, Color(1, 0.9, 0.4))
	# всплывающая надпись
	if toast_t > 0.0:
		var tc := Color(0.55, 1, 0.55) if toast_good else Color(1, 0.45, 0.4)
		tc.a = clampf(toast_t / 0.4, 0.0, 1.0)
		var oc := Color(0, 0, 0, tc.a * 0.8)
		hud.draw_string_outline(f, Vector2(0, s.y * 0.32), toast_text, HORIZONTAL_ALIGNMENT_CENTER, s.x, 30, 7, oc)
		hud.draw_string(f, Vector2(0, s.y * 0.32), toast_text, HORIZONTAL_ALIGNMENT_CENTER, s.x, 30, tc)
	if hint_t > 0.0 and not menu_open and not edit_mode:
		hud.draw_string_outline(f, Vector2(0, s.y - 64), "Start — меню, настройки и расположение кнопок", HORIZONTAL_ALIGNMENT_CENTER, s.x, 16, 4, Color(0, 0, 0, 0.7))
		hud.draw_string(f, Vector2(0, s.y - 64), "Start — меню, настройки и расположение кнопок", HORIZONTAL_ALIGNMENT_CENTER, s.x, 16, Color(1, 1, 1, 0.85))
	# шкалы баланса и толчка ногами (рядом с райдером)
	var bar_h := 154.0
	var bx := s.x * 0.5 + 190.0
	var by := s.y * 0.5 - 80.0
	if mode == GROUND and absf(th) > 0.03:
		hud.draw_rect(Rect2(bx, by, 16, bar_h), Color(0.04, 0.07, 0.1, 0.55), true)
		var band_b := (0.55 - 0.14) / 1.3 * bar_h
		var band_h := 0.28 / 1.3 * bar_h
		hud.draw_rect(Rect2(bx, by + bar_h - band_b - band_h, 16, band_h), Color(0.4, 0.9, 0.4, 0.5), true)
		var mk := clampf(absf(th) / 1.3, 0.0, 1.0) * bar_h
		hud.draw_rect(Rect2(bx - 3, by + bar_h - mk - 3, 22, 6), Color.WHITE, true)
	if hop_armed and mode == GROUND:
		var pxb := bx - 30.0
		hud.draw_rect(Rect2(pxb, by, 16, bar_h), Color(0.04, 0.07, 0.1, 0.55), true)
		var fh := clampf(hop_push / PUSH_MAX, 0.0, 1.0) * bar_h
		hud.draw_rect(Rect2(pxb, by + bar_h - fh, 16, fh), Color(1.0, 0.65, 0.15, 0.9), true)
		hud.draw_string(f, Vector2(pxb - 14, by + bar_h + 16), "толчок", HORIZONTAL_ALIGNMENT_CENTER, 44, 12, Color(1, 0.85, 0.5))

func tv(key: String) -> float:
	return float(tweaks[key])

func init_tweaks() -> void:
	tweaks = {}
	for t in TWEAKS:
		tweaks[t[0]] = t[4]

func load_tweaks() -> void:
	init_tweaks()
	var cf := ConfigFile.new()
	if cf.load("user://tweaks.cfg") == OK:
		for t in TWEAKS:
			tweaks[t[0]] = cf.get_value("t", t[0], t[4])
	apply_tweaks()

func save_tweaks() -> void:
	var cf := ConfigFile.new()
	for t in TWEAKS:
		cf.set_value("t", t[0], tweaks[t[0]])
	cf.save("user://tweaks.cfg")

func apply_tweaks() -> void:
	G = tv("gravity")
	MAXS = tv("max_speed")
	PUSH_BOOST = tv("push_boost")
	PUSH_DECAY = tv("push_decay")
	hop_win = tv("hop_win")
	k_jump = tv("jump")
	k_pedal = tv("pedal")
	k_drag = tv("drag")
	k_steer = tv("steer")
	k_spin = tv("spin")
	k_barspin = tv("barspin")
	k_whip = tv("whip")
	k_flip = tv("flip")
	k_anim = tv("anim")
	k_combo = tv("combo")
	k_cam = tv("cam")
	k_tuck = tv("tuck")
	k_cam_side = tv("cam_side")
	k_cam_h = tv("cam_h")

func make_tweak_slider(t: Array) -> HBoxContainer:
	var key: String = t[0]
	var h := HBoxContainer.new()
	var l := Label.new()
	l.text = t[1]
	l.custom_minimum_size = Vector2(380, 0)
	l.add_theme_font_size_override("font_size", 20)
	h.add_child(l)
	var sl := HSlider.new()
	sl.min_value = t[2]
	sl.max_value = t[3]
	sl.step = t[5]
	sl.value = tv(key)
	sl.custom_minimum_size = Vector2(260, 52)
	sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	style_slider(sl)
	h.add_child(sl)
	var vl := Label.new()
	vl.custom_minimum_size = Vector2(84, 0)
	vl.text = "%.2f" % tv(key)
	vl.add_theme_font_size_override("font_size", 20)
	h.add_child(vl)
	sl.value_changed.connect(_on_tweak.bind(key, vl))
	tweak_sliders[key] = sl
	return h

func _on_tweak(v: float, key: String, vl: Label) -> void:
	tweaks[key] = v
	vl.text = "%.2f" % v
	apply_tweaks()
	save_tweaks()

func _on_reset_tweaks() -> void:
	for t in TWEAKS:
		var sl: HSlider = tweak_sliders[t[0]]
		sl.value = t[4]
	init_tweaks()
	apply_tweaks()
	save_tweaks()

func _on_flips(v: bool) -> void:
	flips_on = v
	save_settings()

func _on_rik(v: bool) -> void:
	rider_ik = v
	save_settings()

func _on_diag(v: bool) -> void:
	diag_on = v
	save_settings()

func fin(v: Vector3) -> bool:
	return is_finite(v.x) and is_finite(v.y) and is_finite(v.z)

func update_diag() -> void:
	var lines: Array = []
	lines.append("Байк: " + ("модель OK" if (bike_inst != null and n_fork != null) else "НЕТ модели или узлов"))
	lines.append("Поз: x=%.0f z=%.0f h=%.1f, карта: %s" % [px, pz, py, "город" if hf_ok else "парк (город не загрузился)"])
	if rider_inst == null:
		lines.append("Райдер: сцена не загружена")
	else:
		var st := "Skeleton3D НЕ НАЙДЕН"
		if skel != null:
			st = "Skeleton3D OK, костей %d" % skel.get_bone_count()
		lines.append("Райдер: " + st + (" · IK вкл" if rider_ik else " · IK выкл"))
		for mi in rider_inst.find_children("*", "MeshInstance3D", true, false):
			var m3 := mi as MeshInstance3D
			if m3.mesh != null:
				var ab := m3.get_aabb()
				var sk_ok := m3.get_node_or_null(m3.skeleton) != null
				lines.append("mesh %s: поверхностей %d, skin=%s, skel=%s, AABB %.1f x %.1f x %.1f" % [m3.name, m3.mesh.get_surface_count(), str(m3.skin != null), str(sk_ok), ab.size.x, ab.size.y, ab.size.z])
		if skel != null and rider_ik:
			for nm in ["Head", "L_Foot", "R_Foot", "L_Hand", "R_Hand"]:
				var p := bpos(nm)
				if fin(p):
					lines.append("%s: %.2f %.2f %.2f" % [nm, p.x, p.y, p.z])
				else:
					lines.append(nm + ": NaN!")
	if skel != null:
		var hk := kx("Head")
		var hi: int = sk_idx[hk]
		var ir := skel.get_bone_rest(hi).origin
		var br: Vector3 = rest_local[hk].origin
		lines.append("rest Head: движок %.2f %.2f %.2f / запечено %.2f %.2f %.2f" % [ir.x, ir.y, ir.z, br.x, br.y, br.z])
		var sg := skel.global_transform
		lines.append("skel node: %.2f %.2f %.2f, scale %.2f, скин подменён: %s" % [sg.origin.x, sg.origin.y, sg.origin.z, sg.basis.get_scale().x, str(skin_fixed)])
	diag_text = lines

func _on_grind(v: bool) -> void:
	grind_on = v
	save_settings()

func _on_stance() -> void:
	stance = -stance
	stance_btn.text = stance_text()
	save_settings()

func style_slider(sl: HSlider) -> void:
	var t := dot_tex()
	sl.add_theme_icon_override("grabber", t)
	sl.add_theme_icon_override("grabber_highlight", t)
	sl.add_theme_icon_override("grabber_disabled", t)
	var tr := StyleBoxFlat.new()
	tr.bg_color = Color(1, 1, 1, 0.25)
	tr.set_corner_radius_all(6)
	tr.content_margin_top = 9
	tr.content_margin_bottom = 9
	sl.add_theme_stylebox_override("slider", tr)
	var ga := StyleBoxFlat.new()
	ga.bg_color = Color(0.45, 0.85, 0.5, 0.95)
	ga.set_corner_radius_all(6)
	ga.content_margin_top = 9
	ga.content_margin_bottom = 9
	sl.add_theme_stylebox_override("grabber_area", ga)
	sl.add_theme_stylebox_override("grabber_area_highlight", ga)

func _on_toggle_btn(v: bool, b: Button, text: String, cb: Callable) -> void:
	b.text = text + (":  ВКЛ" if v else ":  ВЫКЛ")
	cb.call(v)

# =====================================================================
# ЗАПУСК И ГЛАВНЫЙ ЦИКЛ
# =====================================================================
func _ready() -> void:
	get_viewport().mesh_lod_threshold = 0.0
	load_settings()
	load_tweaks()
	load_layout()
	build_environment()
	if not build_map():
		build_ground()
		build_park()
	build_bike()
	build_ui()
	respawn(true)

func _process(delta: float) -> void:
	var dt := minf(delta, 0.05)
	poll_input(dt)
	if not (menu_open or edit_mode):
		acc_t += dt
		var n := 0
		while acc_t >= FIXED and n < 12:
			physics(FIXED)
			acc_t -= FIXED
			n += 1
		if n >= 12:
			acc_t = 0.0
		update_gameplay(dt)
	pose_visuals(dt)
	update_camera(dt)
	if toast_t > 0.0:
		toast_t -= dt
	if hint_t > 0.0:
		hint_t -= dt
	diag_t -= dt
	if diag_on and diag_t <= 0.0:
		update_diag()
		diag_t = 0.5
	if edit_mode:
		var nm := "Перетаскивайте кнопки пальцем"
		if edit_sel != "":
			nm = "Выбрано: " + String(KEY_RU[edit_sel])
		edit_lbl.text = nm
	hud.queue_redraw()
