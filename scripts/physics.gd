extends "res://scripts/tricks.gd"
# Физика: земля, воздух, бейл, слайды, гринды, футджем, падение райдера.

# =====================================================================
# ФИЗИКА
# =====================================================================
func bail(msg: String) -> void:
	if mode == BAIL:
		return
	if mode == GROUND:
		var f := dir_of(yaw)
		var sl := slope_along(px, pz, yaw)
		var ca := 1.0 / sqrt(1.0 + sl * sl)
		wvx = f.x * spd * ca
		wvz = f.y * spd * ca
		vy = maxf(vy_g, 0.0)
	mode = BAIL
	bail_t = 0.0
	sliding = false
	tw_ang = 0.0
	tw_rem = 0.0
	flip_rem = 0.0
	tum_dir = -1.0 if randf() < 0.5 else 1.0
	tumble = 0.0
	th = 0.0
	om = 0.0
	nose_acc = 0.0
	hop_armed = false
	hop_push = 0.0
	show_toast("БЕЙЛ · " + msg, false)
	reset_combo()
	start_rider_fall()

func respawn(full: bool) -> void:
	if rider_free:
		rider_free = false
		rider_holder.reparent(body, false)
		rider_holder.transform = rider_home
	var x0 := SPAWN_X
	var z0 := SPAWN_Z
	var b0 := SPAWN_B
	if not full:
		x0 = safe_x
		z0 = safe_z
		b0 = safe_b
	px = x0
	pz = z0
	yaw = b0
	py = terrain_h(x0, z0)
	spd = 0.0
	vy = 0.0
	wvx = 0.0
	wvz = 0.0
	mode = GROUND
	th = 0.0
	om = 0.0
	pitch = 0.0
	pitch_w = 0.0
	tw_ang = 0.0
	tw_rem = 0.0
	flip_rem = 0.0
	xup_amt = 0.0
	sliding = false
	crank_rem = 0.0
	gp = 0.0
	roll = 0.0
	vy_g = 0.0
	ws = 0.0
	spin_w = 0.0
	spin_acc = 0.0
	nose_acc = 0.0
	air_t = 0.0
	tumble = 0.0
	bar_angle = 0.0
	bar_rem = 0.0
	if full:
		safe_x = SPAWN_X
		safe_z = SPAWN_Z
		safe_b = SPAWN_B
		reset_combo()
	hop_armed = false
	hop_peak = 0.0
	hop_push = 0.0
	cam_yaw = b0
	cam_pos = Vector3(x0 - cos(b0) * 5.0, 3.0, z0 + sin(b0) * 5.0)

func start_air(nx: float, nz: float, y: float) -> void:
	mode = AIR
	alley_air = false
	px = nx
	pz = nz
	py = y
	air_t = 0.0
	hop_t = 999.0
	spin_acc = 0.0
	take_y = y
	bar_count = 0
	bar_cool = 0.0
	var vh := Vector2(wvx, wvz).length()
	mair = atan2(-wvz, wvx) if vh > 0.5 else yaw
	var f0 := dir_of(yaw)
	takeoff_fakie = vh > 1.0 and (wvx * f0.x + wvz * f0.y) < 0.0
	spin_w = -in_rx * 5.5 if absf(in_rx) > 0.3 else 0.0
	nose_acc = 0.0
	pitch = gp + th
	pitch_w = 0.0
	noh_t = 0.0
	oneh_t = 0.0
	om = 0.0
	tw_rem = 0.0
	tw_ang = 0.0
	tw_count = 0
	tw_cool = 0.0
	flip_rem = 0.0
	flip_cool = 0.0
	flip_hold = 0.0
	flip_back = 0
	flip_front = 0
	xup_t = 0.0
	noft_t = 0.0
	sup_t = 0.0
	cancan_t = 0.0
	table_t = 0.0
	foot_air_l = false
	foot_air_r = false
	crank_rem = 0.0
	crank_count = 0
	fj_count = 0
	tw_footjam = false
	chick_count = 0
	bar_chicken = false
	tw_opo_count = 0
	bar_opo_count = 0

func pop_hop(power: float) -> void:
	var f := dir_of(yaw)
	var sl := slope_along(px, pz, yaw)
	var ca := 1.0 / sqrt(1.0 + sl * sl)
	# толчок ногами: накопленный заряд от нажатий L/R добавляет скорость прыжка
	if held_X:
		hop_push = maxf(hop_push, 1.8)
	var boost := clampf(hop_push / PUSH_MAX, 0.0, 1.0) * PUSH_BOOST
	# акселерейт: стик вниз-вверх и долбёжка крестом даёт ещё и ускорение
	if mash_n >= 3:
		add_trick("Акселерейт", 60.0)
		show_toast("Акселерейт!", true)
	mash_n = 0
	vy = (2.5 + 2.4 * power + boost + maxf(vy_g, 0.0) * 0.5) * k_jump
	wvx = f.x * spd * ca
	wvz = f.y * spd * ca
	start_air(px, pz, py + 0.001)
	# алей-уп: L зажат и левый стик отклонён в сторону — банихоп боком в эту сторону (курс байка не меняется)
	if held_L and absf(in_lx) > 0.45:
		var rt := Vector2(sin(yaw), cos(yaw))
		var lat := (2.2 + 1.2 * power) * minf(1.0, absf(in_lx)) * signf(in_lx)
		wvx += rt.x * lat
		wvz += rt.y * lat
		alley_air = true
		show_toast("Алей-уп!", true)
	pitch = gp + th * 0.8
	pitch_w = 0.0
	hop_t = 0.0
	th = 0.0
	om = 0.0
	rig_crouch = -0.4 - 0.25 * (boost / PUSH_BOOST)
	hop_push = 0.0
	if boost > 0.35:
		show_toast("Высокий банихоп!", true)

func land_now(nx: float, nz: float, hN: float) -> void:
	px = nx
	pz = nz
	py = hN
	var f := dir_of(yaw)
	var sl := slope_along(nx, nz, yaw)
	var ca := 1.0 / sqrt(1.0 + sl * sl)
	var gpn := atan(sl)
	var v_along := wvx * f.x + wvz * f.y
	var vh := Vector2(wvx, wvz).length()
	var m := atan2(-wvz, wvx)
	var e_face := absf(wrap_half(yaw - m))
	# алей-уп: боковой снос от прыжка не считаем приземлением боком
	var alley := alley_air
	alley_air = false
	if alley:
		e_face = 0.0
	if flip_rem != 0.0 and absf(flip_rem) < 0.45:
		pitch -= TAU * flip_dir
		if flip_dir > 0.0:
			flip_back += 1
		else:
			flip_front += 1
		flip_rem = 0.0
	var err := pitch - gpn
	var vn := (-sl * v_along + vy) / sqrt(1.0 + sl * sl)
	var impact := maxf(0.0, -vn)
	# недокрученный 360 + Треугольник + правый стик в сторону вращения: докрутим слайдом
	var spin_abs := absf(spin_acc)
	var rescue := false
	if held_T and vh > 1.5 and spin_abs >= SPIN_SLIDE_MIN and spin_abs <= TAU - SPIN_SLIDE_GAP:
		if absf(in_rx) > 0.4 and in_rx * spin_acc < 0.0:
			rescue = true
	var why := ""
	if vh > 1.5 and e_face > 0.7 and not rescue:
		why = "боком"
	elif err < -1.05:
		why = "через руль"
	elif err > 1.05:
		why = "назад через заднее"
	elif impact > 13.5:
		why = "слишком жёстко"
	var stick_ok := (err > 0.0 and in_ly < -0.4) or (err < 0.0 and in_ly > 0.4)
	if why == "" and absf(err) > MANUAL_LAND_MIN and not stick_ok:
		why = "не удержал мануал"
	if why == "" and tw_rem > 0.35:
		why = "посреди тейлвипа"
	if why != "":
		py = hN
		bail("приземление " + why)
		return
	mode = GROUND
	spd = v_along / ca * (1.0 - 0.25 * sin(minf(e_face, 1.2)))
	th = clampf(err, -1.1, 1.0) if (absf(err) > 0.12 and stick_ok) else 0.0
	om = 0.0
	gp = gpn
	pitch = gpn + th
	vy_g = 0.0
	vy = 0.0
	ws = spd
	rig_crouch = clampf(impact / 9.0, 0.0, 1.0) * 0.9
	var air := air_t
	var n := int(roundf(absf(spin_acc) / PI))
	if air > 0.25:
		if n >= 1:
			var opo := signf(spin_acc) != float(stance)
			var snm := spin_name(n)
			var spts := spin_pts(n)
			if opo:
				snm = "Опо " + snm
				spts *= 1.25
			add_air_trick(snm, spts)
		if bar_count > 0:
			add_air_trick("Барспин ×%d" % bar_count if bar_count > 1 else "Барспин", 100.0 * bar_count)
		if bar_opo_count > 0:
			add_air_trick("Опо бар ×%d" % bar_opo_count if bar_opo_count > 1 else "Опо бар", 130.0 * bar_opo_count)
		if chick_count > 0:
			add_trick("Чикенбар ×%d" % chick_count if chick_count > 1 else "Чикенбар", 220.0 * chick_count)
		if alley:
			add_air_trick("Алей-уп", 100.0)
		if air > 0.8:
			add_trick("Эйр %.1fс" % air, roundf(air * 60.0))
		if hN - take_y > 0.3:
			add_trick("На препятствие", 80.0)
		if tw_count > 0:
			add_air_trick("Вип" + (" ×%d" % tw_count if tw_count > 1 else ""), 350.0 * tw_count)
		if tw_opo_count > 0:
			add_air_trick("Опо вип" + (" ×%d" % tw_opo_count if tw_opo_count > 1 else ""), 420.0 * tw_opo_count)
		if fj_count > 0:
			add_air_trick("Футджем вип" + (" ×%d" % fj_count if fj_count > 1 else ""), 420.0 * fj_count)
		if crank_count > 0:
			add_air_trick("Кренкфлип" + (" ×%d" % crank_count if crank_count > 1 else ""), 260.0 * crank_count)
		if flip_back > 0:
			add_air_trick("Бэкфлип" + (" ×%d" % flip_back if flip_back > 1 else ""), 500.0 * flip_back)
		if flip_front > 0:
			add_air_trick("Фронтфлип" + (" ×%d" % flip_front if flip_front > 1 else ""), 450.0 * flip_front)
		if xup_t > 0.3:
			add_air_trick("Икс-ап", 90.0)
	noh_t = 0.0
	oneh_t = 0.0
	tw_ang = 0.0
	tw_rem = 0.0
	flip_rem = 0.0
	crank_rem = 0.0
	if rescue:
		start_spin_slide(TAU - spin_abs, signf(spin_acc), m, vh)
	if not combo_items.is_empty():
		combo_idle = 0.0
	bar_angle = 0.0
	bar_rem = 0.0

func ground_step(dt: float) -> void:
	if sliding:
		slide_step(dt)
		return
	# чикенбар: руль крутится на земле, пока переднее колесо поднято
	bar_cool -= dt
	if bar_rem > 0.0:
		var bd := minf(bar_rem, 18.0 * k_barspin * dt)
		bar_angle += bd * bar_dir
		bar_rem -= bd
		if bar_rem <= 0.0:
			bar_cool = 0.25
			bar_angle = 0.0
			if bar_chicken:
				add_trick("Чикенбар", 220.0)
				show_toast("Чикенбар!", true)
			bar_chicken = false
	# плавный доворот после выхода из слайда
	if exit_t > 0.0:
		exit_t -= dt
		yaw += wrapf(exit_yaw - yaw, -PI, PI) * (1.0 - exp(-16.0 * dt))
	var f := dir_of(yaw)
	var sl := slope_along(px, pz, yaw)
	var ca := 1.0 / sqrt(1.0 + sl * sl)
	var sa := sl * ca
	spd -= G * sa * dt
	var ly := in_ly
	# банихоп: потянул назад, затем резко вперёд
	if ly < -0.55:
		hop_since = 0.0
		hop_armed = true
	else:
		hop_since += dt
		if hop_since > hop_win:
			hop_armed = false
			hop_peak = 0.0
	if hop_armed:
		hop_peak = maxf(hop_peak, th)
		# толчок ногами: нажатия педалей при отведённом весе копят заряд
		hop_push = minf(hop_push + pedal_tap, PUSH_MAX)
		hop_push = maxf(0.0, hop_push - PUSH_DECAY * dt)
	else:
		hop_push = 0.0
	pedal_tap = 0.0
	if kb_hop:
		kb_hop = false
		pop_hop(0.55)
		return
	if hop_armed and ly > 0.35 and hop_since < hop_win and th < 0.95:
		var power := clampf(0.25 + hop_peak / 0.6 * 0.75, 0.25, 1.0)
		hop_armed = false
		hop_peak = 0.0
		pop_hop(power)
		return
	# мануал как балансировка перевёрнутого маятника
	var lean := -ly
	var BAL := 0.55
	var K := 7.0 * (0.5 if assist_bal else 1.0)
	var sgn := 0.0
	if absf(th) > 0.0001:
		sgn = signf(th)
	elif lean > 0.0:
		sgn = 1.0
	elif lean < 0.0:
		sgn = -1.0
	if sgn == 0.0:
		th = 0.0
		om = 0.0
	else:
		var acc := K * (th - sgn * BAL) + 13.0 * lean - 1.8 * om
		if absf(th) <= 0.0001 and sgn * acc <= 0.0:
			th = 0.0
			om = 0.0
		else:
			om += acc * dt
			var nt := th + om * dt
			if nt * sgn < 0.0:
				th = 0.0
				om = 0.0
			else:
				th = nt
	if th > 1.3:
		bail("мануал: перевернулся назад")
		return
	if th < -1.2:
		bail("перелетел через руль")
		return
	# разгон: поочерёдные нажатия L/R; обе вместе — тормоз
	if absf(th) < 0.4 and pedal_kick > 0.0:
		var room := (1.0 - clampf(spd / MAXS, 0.0, 1.0)) if spd >= 0.0 else 1.0
		spd += pedal_kick * room * k_pedal
	pedal_kick = 0.0
	if (pedal_both_t > 0.25 or brake_held) and not hop_armed:
		var br := 9.0 * dt
		spd = maxf(0.0, spd - br) if spd > 0.0 else minf(0.0, spd + br)
	var drag := (0.3 + 0.008 * spd * spd) * k_drag * dt
	spd = maxf(0.0, spd - drag) if spd > 0.0 else minf(0.0, spd + drag)
	spd = clampf(spd, -8.0, MAXS)
	# руление: кинематическая модель велосипеда (колёсная база, угол руля)
	var hand_k := 1.0
	if hand_l_off and hand_r_off:
		hand_k = 0.15
	elif hand_l_off or hand_r_off:
		hand_k = 0.55
	var slow := 0.6 if absf(th) > 0.1 else 1.0
	steer_ang = -in_lx * 0.6 / (1.0 + absf(spd) * 0.14) * hand_k * k_steer
	# L зажат: руль не поворачиваем, байк наклоняется в сторону стика
	if held_L:
		steer_ang = 0.0
	var yaw_rate := spd * tan(steer_ang) / WHEELBASE * slow
	yaw += yaw_rate * dt
	# ноуз-пивот
	if th < -0.25:
		spin_w = clampf(spin_w + (-in_rx * 19.0 - spin_w * 2.0) * dt, -11.0, 11.0)
		var dB := spin_w * dt
		if dB != 0.0:
			var cx := px + f.x * FRONT_X
			var cz := pz + f.y * FRONT_X
			yaw += dB
			nose_acc += dB
			var f2 := dir_of(yaw)
			px = cx - f2.x * FRONT_X
			pz = cz - f2.y * FRONT_X
		spd *= exp(-0.9 * dt)
	else:
		spin_w = 0.0
	if th > -0.12 and nose_acc != 0.0:
		var nn := int(roundf(absf(nose_acc) / PI))
		if nn >= 1:
			add_trick("Ноуз-пивот %d" % (nn * 180), roundf(spin_pts(nn) * 0.8))
		nose_acc = 0.0
	f = dir_of(yaw)
	# движение
	var step_h := spd * ca * dt
	var nx := px + f.x * step_h
	var nz := pz + f.y * step_h
	var hN := maxf(terrain_h(nx, nz), rail_wall(nx, nz))
	if hN > py + 0.38:
		if absf(spd) > 8.0:
			bail("врезался в препятствие")
			return
		spd = -spd * 0.3 if absf(spd) > 1.5 else 0.0
		vy_g = 0.0
		return
	var y_free := py + maxf(vy_g, 0.0) * dt - 0.5 * G * dt * dt
	if hN < y_free - 0.012 and (vy_g > 0.6 or py - hN > 0.15):
		wvx = f.x * spd * ca
		wvz = f.y * spd * ca
		vy = vy_g if vy_g > 0.6 else minf(vy_g, 0.0)
		start_air(nx, nz, maxf(hN, y_free))
		return
	# вертикальную скорость берём из уклона, а не из скачка высоты: ступенька не работает как трамплин
	var rise := hN - py
	var tv_slope := spd * sa
	# низкая ступенька/бордюр (резкий скачок высоты на малом подъёме) — не пандус: взлёта нет
	var lim_v := 0.8
	if is_low_step(px, pz, f):
		tv_slope = 0.0
		lim_v = 0.4
	var tv_step := clampf(rise / dt, tv_slope - lim_v, tv_slope + lim_v)
	if rise > 0.2:
		spd *= 0.92
		rig_crouch = maxf(rig_crouch, 0.35)
	vy_g = damp(vy_g, tv_step, 60.0, dt)
	px = nx
	pz = nz
	py = hN
	if absf(px) > LIM:
		px = clampf(px, -LIM, LIM)
		spd *= -0.3
	if absf(pz) > LIM:
		pz = clampf(pz, -LIM, LIM)
		spd *= -0.3
	gp = damp(gp, atan(sl), 25.0, dt)
	pitch = gp + th
	ws = spd
	var roll_tgt := clampf(-atan(spd * yaw_rate / G), -0.6, 0.6)
	if held_L:
		roll_tgt = in_lx * LEAN_L
	roll = damp(roll, roll_tgt, 8.0, dt)
	safe_t += dt
	if safe_t > 0.7 and absf(sl) < 0.12 and absf(th) < 0.05 and absf(spd) > 0.3:
		safe_x = px
		safe_z = pz
		safe_b = yaw
		safe_t = 0.0

func air_step(dt: float) -> void:
	air_t += dt
	hop_t += dt
	var gm := 1.0
	if tuck_on and vy > 0.0:
		gm = 1.0 - k_tuck
	vy -= G * gm * dt
	var a := -in_rx * 19.0 * k_spin - spin_w * 1.6
	var hh := py - terrain_h(px, pz)
	if assist_land and vy < 0.0:
		var w := clampf((1.5 - hh) / 1.0, 0.0, 1.0) * (1.0 - 0.85 * absf(in_rx))
		if w > 0.0:
			var e := wrap_half(yaw - mair)
			a += w * (-e * 40.0 - spin_w * 7.0)
	spin_w = clampf(spin_w + a * dt, -13.0 * k_spin, 13.0 * k_spin)
	var dB := spin_w * dt
	yaw += dB
	spin_acc += dB
	# барспин
	bar_cool -= dt
	if bar_rem > 0.0:
		var d := minf(bar_rem, 18.0 * k_barspin * dt)
		bar_angle += d * bar_dir
		bar_rem -= d
		if bar_rem <= 0.0:
			if bar_chicken:
				chick_count += 1
			elif bar_dir * float(stance) < 0.0:
				bar_opo_count += 1
			else:
				bar_count += 1
			bar_chicken = false
			bar_cool = 0.25
			bar_angle = 0.0
	# тейлвип (Треугольник в воздухе)
	if tw_rem > 0.0:
		var dw := minf(tw_rem, 13.0 * k_whip * dt)
		tw_ang += dw * tw_dir
		tw_rem -= dw
		if tw_rem <= 0.0:
			tw_rem = 0.0
			if tw_footjam:
				fj_count += 1
			elif tw_dir * float(stance) < 0.0:
				tw_opo_count += 1
			else:
				tw_count += 1
			tw_ang = 0.0
			tw_cool = 0.2
	else:
		tw_cool -= dt
	# кренкфлип: L + Крест в воздухе
	if crank_rem > 0.0:
		var dc := minf(crank_rem, 16.0 * dt)
		crank_a -= dc
		crank_rem -= dc
		if crank_rem <= 0.0:
			crank_rem = 0.0
			crank_count += 1
	# R + Крест — икс-ап
	if xup_held:
		xup_t += dt
	# тангаж
	var vh := Vector2(wvx, wvz).length()
	var traj := atan2(vy, maxf(vh, 2.0))
	var kick_t := 0.35 * (1.0 - hop_t / 0.22) if hop_t < 0.22 else 0.0
	var tgt := clampf(traj, -0.9, 0.9) * 0.45 + (-in_ly) * 0.75 + kick_t
	if bar_chicken and bar_rem > 0.0:
		tgt += 0.45
	if assist_land and vy < 0.0:
		var w2 := clampf((0.9 - hh) / 0.6, 0.0, 1.0) * 0.7 * (1.0 - absf(in_ly) * 0.8)
		if w2 > 0.0:
			tgt = tgt + (atan(slope_along(px, pz, yaw)) + 0.04 - tgt) * w2
	# флипы: правый стик вверх (фронтфлип) или вниз (бэкфлип) и удержать
	flip_cool -= dt
	if flips_on and flip_rem == 0.0 and flip_cool <= 0.0 and air_t > 0.12 and hh > 0.9 and absf(in_ry) > 0.75:
		flip_hold += dt
		if flip_hold > 0.12:
			flip_dir = 1.0 if in_ry < 0.0 else -1.0
			flip_rem = TAU * flip_dir
			flip_hold = 0.0
	else:
		flip_hold = 0.0
	if flip_rem == 0.0:
		pitch_w += (28.0 * (tgt - pitch) - 8.0 * pitch_w) * dt
		pitch += pitch_w * dt
	else:
		var df := minf(absf(flip_rem), 10.0 * k_flip * dt)
		pitch += df * flip_dir
		flip_rem -= df * flip_dir
		pitch_w = 0.0
		if absf(flip_rem) < 0.0001:
			flip_rem = 0.0
			pitch -= TAU * flip_dir
			flip_cool = 0.3
			if flip_dir > 0.0:
				flip_back += 1
			else:
				flip_front += 1
	roll = damp(roll, in_lx * 0.45, 6.0, dt)
	ws *= exp(-0.2 * dt)
	# перемещение
	var nx := px + wvx * dt
	var nz := pz + wvz * dt
	var ny := py + vy * dt
	var hN := terrain_h(nx, nz)
	if hN > ny + 0.38:
		var sp := Vector2(wvx, wvz).length()
		wvx *= -0.2
		wvz *= -0.2
		nx = px
		nz = pz
		hN = terrain_h(nx, nz)
		if sp > 8.0:
			py = ny
			bail("врезался в воздухе")
			return
		mair = atan2(-wvz, wvx)
	if absf(nx) > LIM:
		nx = clampf(nx, -LIM, LIM)
		wvx *= -0.3
	if absf(nz) > LIM:
		nz = clampf(nz, -LIM, LIM)
		wvz *= -0.3
	if grind_on and grind_check(nx, ny, nz):
		return
	if ny <= hN:
		land_now(nx, nz, hN)
		return
	px = nx
	pz = nz
	py = ny

func bail_step(dt: float) -> void:
	bail_t += dt
	vy -= G * dt
	px += wvx * dt
	pz += wvz * dt
	py += vy * dt
	var h := terrain_h(px, pz)
	if py <= h:
		py = h
		vy = 0.0
		var k := exp(-3.5 * dt)
		wvx *= k
		wvz *= k
	px = clampf(px, -LIM, LIM)
	pz = clampf(pz, -LIM, LIM)
	tumble = damp(tumble, 1.45, 5.0, dt)
	pitch = damp(pitch, 0.0, 4.0, dt)
	ws *= exp(-2.0 * dt)
	if bail_t > 2.6:
		respawn(false)

func physics(dt: float) -> void:
	if rider_free:
		rider_fall_step(dt)
	mash_t -= dt
	gr_cool -= dt
	if mash_t <= 0.0:
		mash_n = 0
	if mode != GROUND:
		pedal_kick = 0.0
		pedal_tap = 0.0
		kb_hop = false
	if mode == BAIL:
		bail_step(dt)
	elif mode == GROUND:
		ground_step(dt)
	elif mode == GRIND:
		grind_step(dt)
	else:
		air_step(dt)

func update_gameplay(dt: float) -> void:
	if mode == GROUND:
		var styled := held_L and not sliding
		if th > 0.25:
			if not has_manual:
				has_manual = true
				combo_items.append("Мануал")
			if styled:
				if not has_rocket:
					has_rocket = true
					combo_items.append("Рокет менуал")
				combo_pts += 130.0 * dt
			else:
				combo_pts += 90.0 * dt
			combo_idle = 0.0
		elif th < -0.25:
			if not has_nose:
				has_nose = true
				combo_items.append("Ноуз-мануал")
			if styled:
				if not has_hang5:
					has_hang5 = true
					combo_items.append("Hang 5")
				combo_pts += 150.0 * dt
			else:
				combo_pts += 110.0 * dt
			combo_idle = 0.0
		elif not combo_items.is_empty():
			combo_idle += dt
			if combo_idle > k_combo:
				bank_combo()

func start_slide() -> void:
	var f := dir_of(yaw)
	sl_spd = absf(spd)
	sl_mv = atan2(-(f.y * spd), f.x * spd)
	sl_side = -1.0 if in_lx > 0.2 else 1.0
	var tgt := sl_mv + sl_side * PI * 0.5
	sl_steer = signf(wrapf(tgt - yaw, -PI, PI)) * 1.45
	sl_kind = 0
	sl_t = 0.0
	sliding = true
	hop_armed = false
	th = 0.0
	om = 0.0
	show_toast("Слайд!", true)

func end_slide(steered: bool) -> void:
	sliding = false
	sl_kind = 0
	exit_yaw = sl_mv
	exit_t = 0.3
	if steered:
		spd = maxf(sl_spd * 0.9, 3.5)
		add_trick("Фейки слайд", 300.0)
		show_toast("Фейки слайд!", true)
	else:
		spd = maxf(sl_spd * 0.7, 2.5)
		add_trick("Слайд", 120.0)

func slide_step(dt: float) -> void:
	if sl_kind == 1:
		spin_slide_step(dt)
		return
	if sl_kind == 2:
		footjam_step(dt)
		return
	sl_t += dt
	var f := dir_of(sl_mv)
	sl_spd = maxf(0.0, sl_spd - 4.5 * dt)
	var nx := px + f.x * sl_spd * dt
	var nz := pz + f.y * sl_spd * dt
	var hN := terrain_h(nx, nz)
	if hN > py + 0.38:
		end_slide(false)
		return
	if hN < py - 0.15:
		wvx = f.x * sl_spd
		wvz = f.y * sl_spd
		vy = 0.0
		sliding = false
		start_air(nx, nz, py)
		return
	px = nx
	pz = nz
	py = hN
	wvx = f.x * sl_spd
	wvz = f.y * sl_spd
	var tgt := sl_mv + sl_side * PI * 0.5
	yaw += wrapf(tgt - yaw, -PI, PI) * (1.0 - exp(-12.0 * dt))
	steer_ang = damp(steer_ang, sl_steer, 20.0, dt)
	spd = -sl_spd
	ws = -sl_spd * 0.4
	gp = damp(gp, atan(slope_along(px, pz, sl_mv)), 25.0, dt)
	pitch = gp
	if sl_t > 0.25 and absf(in_lx) > 0.4:
		end_slide(true)
	elif (sl_t > 0.2 and not held_T) or sl_spd < 0.5:
		end_slide(false)

func start_spin_slide(rem: float, dir: float, mv: float, speed: float) -> void:
	sl_kind = 1
	sl_mv = mv
	sl_spd = speed
	sl_rot_rem = rem * dir
	sl_steer = dir * 1.2
	sl_t = 0.0
	sliding = true
	hop_armed = false
	th = 0.0
	om = 0.0
	show_toast("360 слайдом!", true)

func spin_slide_step(dt: float) -> void:
	sl_t += dt
	var f := dir_of(sl_mv)
	sl_spd = maxf(0.0, sl_spd - 3.0 * dt)
	var nx := px + f.x * sl_spd * dt
	var nz := pz + f.y * sl_spd * dt
	var hN := terrain_h(nx, nz)
	if hN > py + 0.38:
		sliding = false
		sl_kind = 0
		spd = 0.0
		return
	if hN < py - 0.15:
		wvx = f.x * sl_spd
		wvz = f.y * sl_spd
		vy = 0.0
		sliding = false
		sl_kind = 0
		start_air(nx, nz, py)
		return
	px = nx
	pz = nz
	py = hN
	wvx = f.x * sl_spd
	wvz = f.y * sl_spd
	var dyaw := signf(sl_rot_rem) * minf(absf(sl_rot_rem), 7.5 * dt)
	yaw += dyaw
	sl_rot_rem -= dyaw
	steer_ang = damp(steer_ang, sl_steer, 20.0, dt)
	spd = sl_spd
	ws = sl_spd * 0.5
	gp = damp(gp, atan(slope_along(px, pz, sl_mv)), 25.0, dt)
	pitch = gp
	if absf(sl_rot_rem) < 0.02:
		sliding = false
		sl_kind = 0
		yaw = sl_mv
		spd = sl_spd
		add_trick("360 слайдом", 200.0)
		show_toast("360 слайдом!", true)

func grind_contact(r: Rail, pp: Vector2, y: float) -> bool:
	var rel := pp - Vector2(r.ax, r.az)
	var d := Vector2(r.dx, r.dz)
	var t := rel.dot(d)
	var lat := rel.x * d.y - rel.y * d.x
	if t < 0.0 or t > r.rlen or absf(lat) > 0.1:
		return false
	var rh := rail_h(r, t)
	return y > rh - 0.08 and y < rh + 0.18

func grind_check(nx: float, ny: float, nz: float) -> bool:
	if gr_cool > 0.0 or vy > 1.0:
		return false
	var f := dir_of(yaw)
	var right := Vector2(sin(yaw), cos(yaw))
	var base := Vector2(nx, nz)
	for ri in range(rails.size()):
		var r: Rail = rails[ri]
		if r.ledge:
			continue
		var d := Vector2(r.dx, r.dz)
		var along := f.dot(d)
		# пеги (только справа): байк должен лечь вдоль рейлы
		if absf(along) >= GRIND_ALIGN:
			for k in range(2):
				var pgx := FRONT_X if k == 0 else C_VEC.x
				if grind_contact(r, base + f * pgx + right * PEG_LAT, ny + PEG_H):
					start_grind(ri, along, nx, ny, nz, 0, 1.0)
					return true
		# каретка: рейла под центром байка, угол захода любой, но нужна скорость вдоль рейлы
		var vd := Vector2(wvx, wvz).dot(d)
		if absf(vd) >= 1.5 and grind_contact(r, base + f * BB_X, ny + CRANK_H):
			start_grind(ri, along, nx, ny, nz, 1, 0.0)
			return true
	return ledge_check(nx, ny, nz)

func ledge_ok(q: Vector2, nn: Vector2, ht: float) -> bool:
	var hin := terrain_h(q.x + nn.x * 0.15, q.y + nn.y * 0.15)
	var hout := terrain_h(q.x - nn.x * 0.3, q.y - nn.y * 0.3)
	return absf(hin - ht) < 0.07 and hout < ht - 0.2

func ledge_check(nx: float, ny: float, nz: float) -> bool:
	var f := dir_of(yaw)
	var right := Vector2(sin(yaw), cos(yaw))
	var base := Vector2(nx, nz)
	var pts: Array[Vector2] = [base, base + f * FRONT_X, base + f * C_VEC.x]
	for q in pts:
		if terrain_h(q.x, q.y) > ny - 0.06:
			return false
	var yp := ny + PEG_H
	var vh := Vector2(wvx, wvz)
	for k in range(2):
		var pgx := FRONT_X if k == 0 else C_VEC.x
		for sd: float in [1.0, -1.0]:
			var p := base + f * pgx + right * (PEG_LAT * sd)
			var ht := terrain_h(p.x, p.y)
			if yp < ht - 0.15 or yp > ht + 0.12:
				continue
			var g := Vector2(terrain_h(p.x + 0.3, p.y) - terrain_h(p.x - 0.3, p.y), terrain_h(p.x, p.y + 0.3) - terrain_h(p.x, p.y - 0.3))
			if g.length() < 0.25:
				continue
			var nn := g.normalized()
			var h1 := terrain_h(p.x - nn.x * 0.45, p.y - nn.y * 0.45)
			var h2 := terrain_h(p.x - nn.x * 0.9, p.y - nn.y * 0.9)
			if ht - h1 < 0.2 or h1 - h2 > 0.12:
				continue
			var d := Vector2(-nn.y, nn.x)
			var along := f.dot(d)
			if absf(along) < GRIND_ALIGN or absf(vh.dot(d)) < 1.5:
				continue
			# ребро: идём наружу от пега до обрыва
			var s_out := 0.0
			while s_out < 0.6 and terrain_h(p.x - nn.x * s_out, p.y - nn.y * s_out) > ht - 0.1:
				s_out += 0.05
			var e := p - nn * (s_out - 0.025)
			var lo := 0.0
			while lo < 30.0 and ledge_ok(e - d * (lo + 0.25), nn, ht):
				lo += 0.25
			var hi := 0.0
			while hi < 30.0 and ledge_ok(e + d * (hi + 0.25), nn, ht):
				hi += 0.25
			if lo + hi < 1.2:
				continue
			if ledge_idx < 0:
				var nr := Rail.new()
				nr.ledge = true
				rails.append(nr)
				ledge_idx = rails.size() - 1
			var r: Rail = rails[ledge_idx]
			r.ax = e.x - d.x * lo
			r.az = e.y - d.y * lo
			r.ay = ht
			r.by = ht
			r.dx = d.x
			r.dz = d.y
			r.rlen = lo + hi
			start_grind(ledge_idx, along, nx, ny, nz, 0, sd)
			return true
	return false

func start_grind(ri: int, along: float, nx: float, ny: float, nz: float, kind: int, side: float) -> void:
	var r: Rail = rails[ri]
	gr_rail = ri
	gr_kind = kind
	gr_side = side
	gr_lat = PEG_LAT if kind == 0 else 0.0
	gr_h = PEG_H if kind == 0 else CRANK_H
	gr_style = 0
	var d := Vector2(r.dx, r.dz)
	var vd := Vector2(wvx, wvz).dot(d)
	if kind == 0:
		gr_face = 1.0 if along >= 0.0 else -1.0
		gr_dir = signf(vd) if absf(vd) > 0.3 else gr_face
		gr_fakie = gr_dir != gr_face
		var fv := d * gr_face
		var yt := atan2(-fv.y, fv.x)
		var right := Vector2(sin(yt), cos(yt))
		var c := Vector2(nx, nz) + right * (gr_side * gr_lat) - Vector2(r.ax, r.az)
		gr_t = clampf(c.dot(d), 0.0, r.rlen)
	else:
		# каретка: курс байка не меняем, едем вдоль рейлы с той скоростью, что вдоль неё была
		gr_face = 1.0 if along >= 0.0 else -1.0
		gr_dir = 1.0 if vd >= 0.0 else -1.0
		var fh := dir_of(yaw)
		gr_fakie = fh.dot(d * gr_dir) < 0.0
		var c2 := Vector2(nx, nz) + fh * BB_X - Vector2(r.ax, r.az)
		gr_t = clampf(c2.dot(d), 0.0, r.rlen)
	gr_spd = absf(vd)
	gr_time = 0.0
	gr_jump_req = false
	gr_pull = false
	mode = GRIND
	px = nx
	pz = nz
	py = ny
	vy = 0.0
	th = 0.0
	om = 0.0
	spin_w = 0.0
	hop_armed = false
	var gname := "Пег-гринд" if kind == 0 else "Гринд на каретке"
	if gr_fakie:
		gname = "Фейки гринд" if kind == 0 else "Фейки гринд на каретке"
	if not combo_items.has(gname):
		add_trick(gname, 0.0)
	combo_idle = 0.0
	show_toast(gname + "!", true)

func grind_step(dt: float) -> void:
	var r: Rail = rails[gr_rail]
	gr_time += dt
	gr_spd = maxf(0.0, gr_spd - 0.9 * dt)
	gr_t += gr_dir * gr_spd * dt
	var dv := Vector2(r.dx, r.dz) * gr_dir
	var tc := clampf(gr_t, 0.0, r.rlen)
	var rp: Vector2
	var slope := 0.0
	var roll_t := 0.14
	if gr_kind == 0:
		# пеги: байк выравнивается вдоль рейлы
		var fv := Vector2(r.dx, r.dz) * gr_face
		var yaw_t := atan2(-fv.y, fv.x)
		slope = (r.by - r.ay) / r.rlen * gr_face
		# L + стик вниз — айс пик (задний пег, нос вверх), L + стик вверх — туз пик (передний пег)
		# R + стик вниз — фибл (задний пег, переднее колесо над рейлой), R + стик вверх — смит (передний пег, заднее колесо над рейлой)
		var sty := 0
		if held_L and in_ly < -0.5:
			sty = 1
		elif held_L and in_ly > 0.5:
			sty = 2
		elif held_R and in_ly < -0.5:
			sty = 3
		elif held_R and in_ly > 0.5:
			sty = 4
		if sty != 0 and sty != gr_style:
			var sn: String = ["", "Айс пик", "Туз пик", "Фибл", "Смит"][sty]
			if not combo_items.has(sn):
				add_trick(sn, 0.0)
			show_toast(sn + "!", true)
		gr_style = sty
		var th_t := 0.0
		var yaw_off := 0.0
		var peg_x := 0.0
		if sty == 1:
			th_t = 0.55
		elif sty == 2:
			th_t = -0.5
		elif sty == 3:
			th_t = 0.15
			yaw_off = -gr_side * GRIND_CROSS
			peg_x = C_VEC.x
		elif sty == 4:
			th_t = -0.15
			yaw_off = gr_side * GRIND_CROSS
			peg_x = FRONT_X
		th = damp(th, th_t, 10.0, dt)
		yaw += wrapf(yaw_t + yaw_off - yaw, -PI, PI) * (1.0 - exp(-14.0 * dt))
		# пег-контакт лежит на рейле: центр байка считаем от текущего курса
		var right := Vector2(sin(yaw), cos(yaw))
		rp = Vector2(r.ax, r.az) + Vector2(r.dx, r.dz) * tc - dir_of(yaw) * peg_x - right * (gr_side * gr_lat)
	else:
		# каретка: угол байка остаётся таким, каким зашли; рейла под кареткой
		var fh := dir_of(yaw)
		rp = Vector2(r.ax, r.az) + Vector2(r.dx, r.dz) * tc - fh * BB_X
		slope = (r.by - r.ay) / r.rlen * fh.dot(Vector2(r.dx, r.dz))
		roll_t = 0.0
	var k := 1.0 - exp(-25.0 * dt)
	px += (rp.x - px) * k
	pz += (rp.y - pz) * k
	py = rail_h(r, tc) - gr_h
	wvx = dv.x * gr_spd
	wvz = dv.y * gr_spd
	spd = -gr_spd if gr_fakie else gr_spd
	ws = spd
	gp = damp(gp, atan(slope), 20.0, dt)
	pitch = gp + th
	roll = damp(roll, roll_t, 8.0, dt)
	var rate := 160.0 if gr_kind == 0 else 200.0
	if gr_style != 0:
		rate += 70.0
	if gr_fakie:
		rate *= 1.35
	combo_pts += rate * clampf(gr_spd / 0.8, 0.0, 1.0) * dt
	combo_idle = 0.0
	if in_ly < -0.55:
		gr_pull = true
	if gr_jump_req or (gr_pull and in_ly > 0.3):
		end_grind(true)
		return
	# без скорости остаёмся на рейле/грани; сходим только прыжком или в конце рейлы
	if gr_t <= 0.0 or gr_t >= r.rlen:
		end_grind(false)

func end_grind(jump: bool) -> void:
	var r: Rail = rails[gr_rail]
	var dv := Vector2(r.dx, r.dz) * gr_dir
	wvx = dv.x * gr_spd
	wvz = dv.y * gr_spd
	vy = 3.2 * k_jump if jump else 0.3
	gr_cool = 0.4
	gr_jump_req = false
	start_air(px, pz, py + 0.001)
	th = 0.0
	if jump:
		hop_t = 0.0
		rig_crouch = -0.3

func start_rider_fall() -> void:
	if rider_inst == null or rider_free:
		return
	var gt := rider_holder.global_transform
	rf_basis = gt.basis.orthonormalized()
	rf_com = gt * RF_COM
	var m := Vector3(wvx, 0.0, wvz)
	if m.length() < 0.5:
		var f := dir_of(yaw)
		m = Vector3(f.x, 0.0, f.y)
	m = m.normalized()
	rf_vel = Vector3(wvx, maxf(vy, 0.0) + 2.5, wvz) + m * 1.5
	var ax := Vector3(m.z, 0.0, -m.x)
	var sgn := 1.0 if pitch < 0.3 else -1.0
	rf_w = ax * sgn * (5.0 + randf() * 4.0) + Vector3(0.0, randf_range(-3.0, 3.0), 0.0)
	rf_t = 0.0
	rf_ground_t = 0.0
	rider_holder.reparent(self, true)
	rider_free = true

func rider_fall_step(dt: float) -> void:
	rf_t += dt
	rf_vel.y -= G * dt
	rf_com += rf_vel * dt
	var h := terrain_h(rf_com.x, rf_com.z)
	var on_ground := false
	if rf_com.y < h + RF_R:
		rf_com.y = h + RF_R
		on_ground = true
		if rf_vel.y < -1.5:
			rf_vel.y *= -0.25
			rf_w *= 0.6
		else:
			rf_vel.y = 0.0
	if on_ground:
		rf_ground_t += dt
		var k := exp(-3.0 * dt)
		rf_vel.x *= k
		rf_vel.z *= k
		rf_w *= exp(-5.0 * dt)
	rf_com.x = clampf(rf_com.x, -LIM, LIM)
	rf_com.z = clampf(rf_com.z, -LIM, LIM)
	var wl := rf_w.length()
	if wl > 0.001:
		rf_basis = (Basis(rf_w / wl, wl * dt) * rf_basis).orthonormalized()
	if rf_ground_t > 0.25:
		# ложимся: верх тела становится горизонтальным в ту сторону, куда он уже наклонён
		var u := rf_basis.y
		var hd := Vector3(u.x, 0.0, u.z)
		if hd.length() < 0.15:
			hd = Vector3(rf_vel.x, 0.0, rf_vel.z)
		if hd.length() < 0.1:
			hd = Vector3(1.0, 0.0, 0.0)
		hd = hd.normalized()
		var target := (Basis(Quaternion(u, hd)) * rf_basis).orthonormalized()
		var qs := Quaternion(rf_basis).slerp(Quaternion(target), 1.0 - exp(-5.0 * dt))
		rf_basis = Basis(qs)
	rider_holder.global_transform = Transform3D(rf_basis, rf_com - rf_basis * RF_COM)

func start_footjam() -> void:
	var f := dir_of(yaw)
	sl_kind = 2
	sl_mv = atan2(-(f.y * spd), f.x * spd)
	sl_spd = absf(spd)
	fj_sign = 1.0 if spd >= 0.0 else -1.0
	fj_yaw0 = yaw
	fj_dir = -1.0 if in_lx > 0.2 else 1.0
	if absf(in_lx) <= 0.2:
		fj_dir = float(stance)
	fj_front = Vector2(px, pz) + f * FRONT_X
	sl_t = 0.0
	sliding = true
	hop_armed = false
	th = 0.0
	om = 0.0
	show_toast("Футджем вип!", true)

func footjam_step(dt: float) -> void:
	sl_t += dt
	var p := clampf(sl_t / FJ_DUR, 0.0, 1.0)
	var e := p * p * (3.0 - 2.0 * p)
	var mvf := dir_of(sl_mv)
	sl_spd = maxf(0.0, sl_spd - 3.5 * dt)
	fj_front += mvf * sl_spd * dt
	yaw = fj_yaw0 + PI * fj_dir * e
	tw_ang = TAU * fj_dir * e
	var f2 := dir_of(yaw)
	var nc := fj_front - f2 * FRONT_X
	var hN := terrain_h(nc.x, nc.y)
	if hN > py + 0.38:
		sliding = false
		sl_kind = 0
		tw_ang = 0.0
		spd = 0.0
		return
	px = nc.x
	pz = nc.y
	py = hN
	wvx = mvf.x * sl_spd
	wvz = mvf.y * sl_spd
	spd = -sl_spd * fj_sign
	ws = sl_spd * 0.3
	steer_ang = damp(steer_ang, 0.0, 10.0, dt)
	gp = damp(gp, atan(slope_along(px, pz, yaw)), 25.0, dt)
	pitch = gp
	if p >= 1.0:
		end_footjam()

func end_footjam() -> void:
	sliding = false
	sl_kind = 0
	tw_ang = 0.0
	yaw = fj_yaw0 + PI * fj_dir
	spd = -fj_sign * maxf(sl_spd * 0.8, 2.0)
	add_trick("Футджем вип", 380.0)
	show_toast("Футджем вип!", true)

func stance_text() -> String:
	return "Стойка: правая нога вперёд" if stance > 0 else "Стойка: левая нога вперёд"
