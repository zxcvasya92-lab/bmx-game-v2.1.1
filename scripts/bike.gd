extends "res://scripts/world.gd"
# Байк и райдер: модель, поза, IK, камера, рейл-данные парка.

func build_park() -> void:
	m_ledge = mat("9aa3a9")
	m_ramp = mat("8d979e")
	m_edge = StandardMaterial3D.new()
	m_edge.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m_edge.albedo_color = Color("2b3238")
	add_box(-9, -5, 2.6, 3, 0.35)
	add_box(-9, -10, 2.6, 3, 0.6)
	add_box(-9, -15, 2.6, 3, 0.9)
	add_box(6, -8, 2.2, 16, 0.28)
	add_ramp(0, -16, PI / 2, 4.5, 4, 1.3)
	add_ramp(0, -28, PI / 2, 5, 5, 1.1, "curve", 1.4)
	add_box(0, -34.5, 5, 8, 1.1)
	add_ramp(0, -41, -PI / 2, 5, 5, 1.1, "curve", 1.4)
	add_ramp(12, -8, 0, 4.2, 6, 2.2, "quarter")
	add_box(16.5, -8, 4.8, 6, 2.2)
	add_ramp(-16, -30, PI / 2, 4, 3, 1.0)
	add_ramp(-18, -24, -PI / 2, 4, 3, 1.0)
	add_box(20, -30, 4, 4, 0.45)
	add_box(20, -36, 4, 4, 0.75)
	# рейлы: ровная прямо по курсу со старта (пег справа ложится на неё) и наклонная
	add_rail(0.158, 0.55, -1.0, 0.158, 0.55, -11.0)
	add_rail(-5.158, 0.95, 4.0, -5.158, 0.5, -10.0)

# =====================================================================
# БАЙК И РАЙДЕР
# =====================================================================
func make_seg(parent: Node3D, r: float, material: Material, rad: int = 8) -> MeshInstance3D:
	var cm := CylinderMesh.new()
	cm.top_radius = r
	cm.bottom_radius = r
	cm.height = 1.0
	cm.radial_segments = rad
	cm.rings = 1
	var m := MeshInstance3D.new()
	m.mesh = cm
	m.material_override = material
	parent.add_child(m)
	return m

func place_seg(m: MeshInstance3D, a: Vector3, b: Vector3) -> void:
	var d := b - a
	var l := d.length()
	if l < 0.00001:
		m.visible = false
		return
	m.visible = true
	d = d / l
	var q := Quaternion(Vector3(0, 1, 0), d)
	m.transform = Transform3D(Basis(q) * Basis.from_scale(Vector3(1.0, l, 1.0)), (a + b) * 0.5)

func tube(parent: Node3D, a: Vector3, b: Vector3, r: float, material: Material) -> MeshInstance3D:
	var m := make_seg(parent, r, material)
	place_seg(m, a, b)
	return m

func make_sphere(parent: Node3D, r: float, material: Material, pos: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0
	sm.radial_segments = 14
	sm.rings = 8
	var m := MeshInstance3D.new()
	m.mesh = sm
	m.material_override = material
	m.position = pos
	parent.add_child(m)
	return m

func make_box(parent: Node3D, size: Vector3, material: Material, pos: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var bm := BoxMesh.new()
	bm.size = size
	var m := MeshInstance3D.new()
	m.mesh = bm
	m.material_override = material
	m.position = pos
	parent.add_child(m)
	return m

func make_wheel(parent: Node3D, x: float, y: float) -> Node3D:
	var g := Node3D.new()
	g.position = Vector3(x, y, 0)
	parent.add_child(g)
	var tm := TorusMesh.new()
	tm.inner_radius = 0.24
	tm.outer_radius = 0.36
	tm.rings = 30
	tm.ring_segments = 10
	var tire := MeshInstance3D.new()
	tire.mesh = tm
	tire.material_override = m_rubber
	tire.rotation.x = PI / 2.0
	g.add_child(tire)
	var rm := TorusMesh.new()
	rm.inner_radius = 0.288
	rm.outer_radius = 0.312
	rm.rings = 26
	rm.ring_segments = 6
	var rim := MeshInstance3D.new()
	rim.mesh = rm
	rim.material_override = m_metal
	rim.rotation.x = PI / 2.0
	g.add_child(rim)
	make_sphere(g, 0.05, m_metal)
	for i in range(4):
		var a := float(i) * PI / 4.0
		tube(g, Vector3(cos(a) * 0.3, sin(a) * 0.3, 0), Vector3(-cos(a) * 0.3, -sin(a) * 0.3, 0), 0.007, m_metal)
	return g

func find3d(nm: String) -> Node3D:
	if bike_inst == null:
		return null
	return bike_inst.find_child(nm, true, false) as Node3D

func m_of(n: Node3D) -> Vector3:
	return bike_holder.to_local(n.global_position)

func rest_of(nm: String) -> Transform3D:
	return rt[nm]

func bi(nm: String) -> int:
	return int(bones[nm])

func rest_len(a: String, b: String) -> float:
	return (gb(kx(b), false).origin - gb(kx(a), false).origin).length()

func build_bike() -> void:
	root = Node3D.new()
	add_child(root)
	body = Node3D.new()
	root.add_child(body)
	frame = Node3D.new()
	body.add_child(frame)
	bike_holder = Node3D.new()
	bike_holder.rotation.y = -PI / 2.0
	frame.add_child(bike_holder)
	rider_holder = Node3D.new()
	rider_holder.rotation.y = -PI / 2.0
	body.add_child(rider_holder)
	var bs = load(BIKE_SCENE)
	if bs is PackedScene:
		bike_inst = (bs as PackedScene).instantiate()
		bike_holder.add_child(bike_inst)
		n_fork = find3d("forks_front")
		n_bars = find3d("handlebars")
		n_wheel_f = find3d("wheel_front")
		n_wheel_r = find3d("wheel_rear")
		n_chain = find3d("chainset")
		n_ped_l = find3d("Pedal_l")
		n_ped_r = find3d("Pedal_r")
		var grip := find3d("bargrip")
		var ok := n_fork != null and n_bars != null and n_wheel_f != null and n_wheel_r != null
		ok = ok and n_chain != null and n_ped_l != null and n_ped_r != null and grip != null
		if ok:
			rt["forks_front"] = n_fork.transform
			rt["handlebars"] = n_bars.transform
			rt["wheel_front"] = n_wheel_f.transform
			rt["wheel_rear"] = n_wheel_r.transform
			rt["chainset"] = n_chain.transform
			rt["Pedal_l"] = n_ped_l.transform
			rt["Pedal_r"] = n_ped_r.transform
			var wf := m_of(n_wheel_f)
			var wr := m_of(n_wheel_r)
			var yoff := WHEEL_R - (wf.y + wr.y) * 0.5
			bike_holder.position.y = yoff
			PEG_H = yoff - 0.178
			CRANK_H = yoff - 0.21
			rider_holder.position.y = yoff
			FRONT_X = -wf.z
			C_VEC = Vector3(-wr.z, 0, 0)
			C_VEC_F = Vector3(-wf.z, 0, 0)
			WHEELBASE = absf(wf.z - wr.z)
			FORK_X = -m_of(n_fork).z
			bb_M = m_of(n_chain)
			BB_X = -bb_M.z
			ped_l_rest = m_of(n_ped_l)
			ped_r_rest = m_of(n_ped_r)
			bar_pivot_M = m_of(n_bars)
			grip_rest_R = m_of(grip)
			# задняя часть (рама, заднее колесо, кривошип) отдельной группой — для випа
			var par_n := n_chain.get_parent() as Node3D
			rear_group = Node3D.new()
			par_n.add_child(rear_group)
			n_chassis = find3d("chassis")
			if n_chassis != null:
				for rn in [n_chassis, n_wheel_r, n_chain]:
					(rn as Node3D).reparent(rear_group, true)
			else:
				rear_group.queue_free()
				rear_group = null
			# ось рулевой колонки: от колеса вдоль вилки вверх
			steer_axis_M = (m_of(n_fork) - wf).normalized()
			var hbs := bike_holder.global_transform.basis
			var pfn := n_fork.get_parent() as Node3D
			axis_fork = (pfn.global_transform.basis.inverse() * (hbs * steer_axis_M)).normalized()
			var pbn := n_bars.get_parent() as Node3D
			axis_bars = (pbn.global_transform.basis.inverse() * (hbs * steer_axis_M)).normalized()
		else:
			push_warning("В bmx.glb не найдены нужные узлы")
			n_fork = null
	else:
		push_warning("Не найден " + BIKE_SCENE)
	if bike_inst == null or n_fork == null:
		var fb := make_box(frame, Vector3(1.0, 0.3, 0.12), mat("e64a37"), Vector3(0.0, 0.4, 0.0))
		fb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	var rs = load(RIDER_SCENE)
	if rs is PackedScene:
		rider_inst = (rs as PackedScene).instantiate()
		rider_holder.add_child(rider_inst)
		var sks := rider_inst.find_children("*", "Skeleton3D", true, false)
		if sks.size() > 0:
			skel = sks[0] as Skeleton3D
		for mi in rider_inst.find_children("*", "MeshInstance3D", true, false):
			var m3 := mi as MeshInstance3D
			m3.extra_cull_margin = 2.0
			m3.custom_aabb = AABB(Vector3(-3, -3, -3), Vector3(6, 6, 6))
			m3.visible = true
		if skel != null:
			init_rider()
	else:
		push_warning("Не найден " + RIDER_SCENE)
	rider_home = rider_holder.transform
	if n_fork == null:
		skel = null

func init_rider() -> void:
	bake_init()
	sk_idx.clear()
	for k in range(BONE_NAMES.size()):
		sk_idx.append(skel.find_bone(String(BONE_NAMES[k])))
	for nm in ["Pelvis", "Spine", "Spine1", "Neck", "Head", "L_UpperArm", "L_ForeArm", "L_Hand",
			"R_UpperArm", "R_ForeArm", "R_Hand", "L_Thigh", "L_Calf", "L_Foot", "L_Toe0",
			"R_Thigh", "R_Calf", "R_Foot", "R_Toe0"]:
		if int(sk_idx[kx(nm)]) < 0:
			push_warning("В скелете райдера нет кости " + nm)
			skel = null
			return
	blen["sp1"] = rest_len("Spine", "Spine1")
	blen["sp2"] = rest_len("Spine1", "Neck")
	blen["neck"] = rest_len("Neck", "Head")
	blen["thigh"] = rest_len("L_Thigh", "L_Calf")
	blen["calf"] = rest_len("L_Calf", "L_Foot")
	blen["uarm"] = rest_len("L_UpperArm", "L_ForeArm")
	blen["farm"] = rest_len("L_ForeArm", "L_Hand")
	var ppos := gb(kx("Pelvis"), false).origin
	pelvis_off = rider_holder.to_local(skel.global_transform * ppos)
	# если импортёр отдал пустые bind-позы скина (бывает в сборке), подставляем запечённые
	for mi in rider_inst.find_children("*", "MeshInstance3D", true, false):
		var m3 := mi as MeshInstance3D
		if m3.skin == null:
			continue
		var zero_n := 0
		for k in range(m3.skin.get_bind_count()):
			var bp := m3.skin.get_bind_pose(k)
			if bp.origin.length() < 0.00001 and (bp.basis.x - Vector3(1, 0, 0)).length() < 0.0001:
				zero_n += 1
		if zero_n >= 20:
			var ns := Skin.new()
			for k in range(BONE_NAMES.size()):
				var m: Array = BONE_IBM[k]
				var bs := Basis(Vector3(float(m[0]), float(m[1]), float(m[2])), Vector3(float(m[3]), float(m[4]), float(m[5])), Vector3(float(m[6]), float(m[7]), float(m[8])))
				ns.add_named_bind(String(BONE_NAMES[k]), Transform3D(bs, Vector3(float(m[9]), float(m[10]), float(m[11]))))
			m3.skin = ns
			skin_fixed = true

func kx(nm: String) -> int:
	return int(bone_ix[nm])

func bake_init() -> void:
	rest_local.clear()
	bone_ix.clear()
	for k in range(BONE_NAMES.size()):
		var r: Array = BONE_REST[k]
		var q := Quaternion(float(r[3]), float(r[4]), float(r[5]), float(r[6]))
		var bs := Basis(q) * Basis.from_scale(Vector3(float(r[7]), float(r[8]), float(r[9])))
		rest_local.append(Transform3D(bs, Vector3(float(r[0]), float(r[1]), float(r[2]))))
		bone_ix[BONE_NAMES[k]] = k

func gb(k: int, use_pov: bool) -> Transform3D:
	var bs: Basis = rest_local[k].basis
	if use_pov and pov.has(k):
		bs = pov[k]
	var rl: Transform3D = rest_local[k]
	var t := Transform3D(bs, rl.origin)
	var p: int = BONE_PARENT[k]
	if p < 0:
		return t
	return gb(p, use_pov) * t

func apply_pose() -> void:
	var gd := {}
	for k in range(BONE_NAMES.size()):
		var i: int = sk_idx[k]
		if i >= 0:
			gd[i] = gb(k, true)
	for k in range(BONE_NAMES.size()):
		var i: int = sk_idx[k]
		if i < 0:
			continue
		var g: Transform3D = gd[i]
		var loc := g
		var p := skel.get_bone_parent(i)
		if p >= 0 and gd.has(p):
			var pg: Transform3D = gd[p]
			loc = pg.affine_inverse() * g
		skel.set_bone_pose_position(i, loc.origin)
		skel.set_bone_pose_rotation(i, loc.basis.orthonormalized().get_rotation_quaternion())
		skel.set_bone_pose_scale(i, loc.basis.get_scale())

func bpos(nm: String) -> Vector3:
	return gb(kx(nm), true).origin

func set_bone_global_basis(k: int, nb: Basis) -> void:
	var p: int = BONE_PARENT[k]
	var pb := Basis.IDENTITY
	if p >= 0:
		pb = gb(p, true).basis
	pov[k] = (pb.inverse() * nb).orthonormalized()

func aim_bone(nm: String, child: String, target: Vector3) -> void:
	var k := kx(nm)
	var gp := gb(k, true)
	var cp := gb(kx(child), true)
	var cur := cp.origin - gp.origin
	var want := target - gp.origin
	if cur.length() < 0.0001 or want.length() < 0.0001:
		return
	var q := Quaternion(cur.normalized(), want.normalized())
	set_bone_global_basis(k, Basis(q) * gp.basis)

func twist_bone(nm: String, axis: Vector3, ang: float) -> void:
	var k := kx(nm)
	var gp := gb(k, true)
	set_bone_global_basis(k, Basis(axis.normalized(), ang) * gp.basis)

func pedal_pos(right: bool, a: float) -> Vector3:
	var rest := ped_r_rest if right else ped_l_rest
	var rel := rest - bb_M
	return Vector3(rest.x, bb_M.y + rel.y * cos(a) - rel.z * sin(a), bb_M.z + rel.y * sin(a) + rel.z * cos(a))

func foot_off_target(side: float, other_amt: float, sup: float, hip: Vector3) -> Vector3:
	var can := hip + Vector3(-side * 0.12, -0.35, -0.45)
	var tuck := hip + Vector3(side * 0.14, -0.45, 0.30)
	var ext := hip + Vector3(side * 0.12, -0.05, 0.93)
	var both := tuck.lerp(ext, sup)
	return can.lerp(both, clampf(other_amt, 0.0, 1.0))

func leg_ik(prefix: String, side: float, ankle_m: Vector3, toe_m: Vector3, to_skel: Transform3D) -> void:
	var thigh := prefix + "_Thigh"
	var calf := prefix + "_Calf"
	var foot := prefix + "_Foot"
	var toe := prefix + "_Toe0"
	var pole := to_skel.basis * Vector3(side * 0.25, 0.1, -1.0)
	var res: Array = ik2(bpos(thigh), to_skel * ankle_m, float(blen["thigh"]), float(blen["calf"]), pole)
	var j: Vector3 = res[0]
	var e: Vector3 = res[1]
	aim_bone(thigh, calf, j)
	aim_bone(calf, foot, e)
	aim_bone(foot, toe, to_skel * toe_m)

func arm_ik(prefix: String, side: float, grip_m: Vector3, to_skel: Transform3D) -> void:
	var up := prefix + "_UpperArm"
	var fa := prefix + "_ForeArm"
	var hd := prefix + "_Hand"
	var pole := to_skel.basis * Vector3(side * 0.7, -0.4, 0.3)
	var res: Array = ik2(bpos(up), to_skel * grip_m, float(blen["uarm"]), float(blen["farm"]), pole)
	var j: Vector3 = res[0]
	var e: Vector3 = res[1]
	aim_bone(up, fa, j)
	aim_bone(fa, hd, e)

func pose_rider() -> void:
	var tuck_off := Vector3(0.0, TUCK_H * tuck_amt, 0.0)
	var hy := 0.68 - rig_crouch * 0.22 - rig_man * 0.14
	var hz := 0.36 - rig_ly * 0.18 + rig_man * 0.12
	var hip := Vector3(0.0, hy, hz)
	var ta := 0.8 + rig_ly * 0.35 + rig_crouch * 0.3 + tuck_amt * 0.15
	rider_inst.position = hip - pelvis_off
	pov.clear()
	var to_skel := skel.global_transform.affine_inverse() * rider_holder.global_transform
	var up_s := (to_skel.basis * Vector3.UP).normalized()
	# позвоночник: наклон вперёд, скрутка, голова
	var a1 := ta * 0.55
	var s1 := hip + Vector3(0.0, cos(a1), -sin(a1)) * float(blen["sp1"])
	aim_bone("Spine", "Spine1", to_skel * s1)
	var nk := s1 + Vector3(0.0, cos(ta), -sin(ta)) * float(blen["sp2"])
	aim_bone("Spine1", "Neck", to_skel * nk)
	twist_bone("Spine1", up_s, rig_tors * 0.5)
	var hd_dir := (to_skel.basis * Vector3(0.0, cos(ta * 0.35), -sin(ta * 0.35))).normalized()
	aim_bone("Neck", "Head", bpos("Neck") + hd_dir * float(blen["neck"]))
	# голова: смотрит вперёд (запечённая ориентация), поворот только по взгляду
	var h0 := gb(kx("Head"), false).basis
	set_bone_global_basis(kx("Head"), Basis(up_s, rig_head) * h0)
	# ноги на педалях (при поджатии байк поднят вместе с педалями)
	var ped_r := pedal_pos(true, crank_a) + tuck_off
	var ped_l := pedal_pos(false, crank_a) + tuck_off
	var ank_r := ped_r + Vector3(0.0, 0.09, 0.12)
	var ank_l := ped_l + Vector3(0.0, 0.09, 0.12)
	var toe_r := ped_r + Vector3(0.0, 0.05, -0.04)
	var toe_l := ped_l + Vector3(0.0, 0.05, -0.04)
	# вип: ноги убираются с педалей, пока рама прокручивается
	var wt := whip_amt
	var tk_r := hip + Vector3(0.14, -0.45, 0.25)
	var tk_l := hip + Vector3(-0.14, -0.45, 0.25)
	ank_r = ank_r.lerp(tk_r, wt)
	toe_r = toe_r.lerp(tk_r + Vector3(0.0, -0.04, -0.15), wt)
	ank_l = ank_l.lerp(tk_l, wt)
	toe_l = toe_l.lerp(tk_l + Vector3(0.0, -0.04, -0.15), wt)
	# рокет менуал: ноги на заднем пеге/оси, hang 5: на переднем
	var rp_m := Vector3(PEG_LAT, -0.155, -C_VEC.x)
	var rl_m := Vector3(-0.11, -0.155, -C_VEC.x)
	var fp_m := Vector3(PEG_LAT, -0.155, -FRONT_X)
	var fl_m := Vector3(-0.11, -0.155, -FRONT_X)
	ank_r = ank_r.lerp(rp_m + Vector3(0.0, 0.09, 0.12), rock_amt)
	toe_r = toe_r.lerp(rp_m + Vector3(0.0, 0.05, -0.04), rock_amt)
	ank_l = ank_l.lerp(rl_m + Vector3(0.0, 0.09, 0.12), rock_amt)
	toe_l = toe_l.lerp(rl_m + Vector3(0.0, 0.05, -0.04), rock_amt)
	ank_r = ank_r.lerp(fp_m + Vector3(0.0, 0.09, 0.12), hang_amt)
	toe_r = toe_r.lerp(fp_m + Vector3(0.0, 0.05, -0.04), hang_amt)
	ank_l = ank_l.lerp(fl_m + Vector3(0.0, 0.09, 0.12), hang_amt)
	toe_l = toe_l.lerp(fl_m + Vector3(0.0, 0.05, -0.04), hang_amt)
	# футджем: правая нога упирается в переднюю покрышку
	ank_r = ank_r.lerp(Vector3(0.10, 0.27, -0.30), fj_amt)
	toe_r = toe_r.lerp(Vector3(0.10, 0.22, -0.45), fj_amt)
	leg_ik("R", 1.0, ank_r, toe_r, to_skel)
	leg_ik("L", -1.0, ank_l, toe_l, to_skel)
	# руки на грипсах (во время бара и випа отпускают руль)
	var rot := Basis(steer_axis_M, rig_steer + bar_angle + xup_amt * 1.5)
	var grip_r := bar_pivot_M + rot * (grip_rest_R - bar_pivot_M) + tuck_off
	var grip_l_rest := Vector3(-grip_rest_R.x, grip_rest_R.y, grip_rest_R.z)
	var grip_l := bar_pivot_M + rot * (grip_l_rest - bar_pivot_M) + tuck_off
	grip_r += Vector3(0.25 * hr_amt, 0.40 * hr_amt, 0.05 * hr_amt)
	grip_l += Vector3(-0.25 * hl_amt, 0.40 * hl_amt, 0.05 * hl_amt)
	arm_ik("R", 1.0, grip_r, to_skel)
	arm_ik("L", -1.0, grip_l, to_skel)
	apply_pose()

func ik2(A: Vector3, T: Vector3, l1: float, l2: float, pole: Vector3) -> Array:
	var d := T - A
	var dist := maxf(d.length(), 0.05)
	d = d / dist
	var maxd := l1 + l2 - 0.002
	if dist > maxd:
		dist = maxd
	var E := A + d * dist
	var a := (l1 * l1 - l2 * l2 + dist * dist) / (2.0 * dist)
	var h := sqrt(maxf(l1 * l1 - a * a, 0.0))
	var p := pole - d * pole.dot(d)
	if p.length_squared() < 0.000001:
		p = Vector3(0, 0, 1)
	p = p.normalized()
	var J := A + d * a + p * h
	return [J, E]

# =====================================================================
# ПОЗА, КАМЕРА
# =====================================================================

func spin_node(n: Node3D, nm: String, ang: float) -> void:
	if n == null:
		return
	var r := rest_of(nm)
	n.transform = Transform3D(r.basis * Basis(Vector3(1, 0, 0), ang), r.origin)

func steer_node(n: Node3D, nm: String, ang: float, axis: Vector3) -> void:
	if n == null:
		return
	var r := rest_of(nm)
	n.transform = Transform3D(Basis(axis, ang) * r.basis, r.origin)

func pose_visuals(dt: float) -> void:
	var ad := dt * k_anim
	root.position = Vector3(px, py, pz)
	root.rotation = Vector3(0, yaw, 0)
	var rl := tumble * tum_dir if mode == BAIL else roll
	body.basis = Basis(Vector3(0, 0, 1), pitch) * Basis(Vector3(1, 0, 0), rl)
	var m := clampf(absf(th) / 0.1, 0.0, 1.0) if (mode == GROUND or (mode == GRIND and gr_kind == 0)) else 0.0
	var cv := C_VEC_F if th < 0.0 else C_VEC
	if mode == GRIND:
		cv = Vector3(FRONT_X if th < 0.0 else C_VEC.x, PEG_H, 0.0)
	if m > 0.0:
		var qg := Basis(Vector3(0, 0, 1), gp)
		body.position = ((qg * cv) - (body.basis * cv)) * m
	else:
		body.position = Vector3.ZERO
	# сальто: вращение вокруг центра масс, а не вокруг точки на земле
	var piv_t := clampf((absf(pitch) - 0.5) / 0.5, 0.0, 1.0) if mode == AIR else 0.0
	piv_amt = damp(piv_amt, piv_t, 20.0, dt)
	if piv_amt > 0.001:
		var pvt := Vector3(0.0, 0.85, 0.0)
		body.position = (pvt - body.basis * pvt) * piv_amt
	# вип: рама крутится вокруг рулевой оси
	tuck_amt = damp(tuck_amt, 1.0 if (tuck_on and mode == AIR) else 0.0, 12.0 if tuck_on else 22.0, ad)
	var tuck_v := Vector3(0.0, TUCK_H * tuck_amt, 0.0)
	if rear_group != null:
		frame.transform = Transform3D(Basis.IDENTITY, tuck_v)
		var wa := Basis(axis_fork, tw_ang)
		var piv := rest_of("forks_front").origin
		rear_group.transform = Transform3D(wa, piv - wa * piv)
	else:
		var wb := Basis(Vector3(0, 1, 0), tw_ang)
		var wpv := Vector3(FORK_X, 0.0, 0.0)
		frame.transform = Transform3D(wb, wpv - wb * wpv + tuck_v)
	# колёса, кривошипы, руль
	wheel_a -= ws * dt / WHEEL_R
	spin_node(n_wheel_f, "wheel_front", wheel_a)
	spin_node(n_wheel_r, "wheel_rear", wheel_a)
	crank_w *= exp(-1.8 * dt)
	crank_a -= crank_w * dt
	if crank_rem <= 0.0 and absf(crank_w) < 0.6:
		var tgt_c := roundf((crank_a + PI * 0.5) / TAU) * TAU - PI * 0.5
		if stance < 0:
			tgt_c = roundf((crank_a - PI * 0.5) / TAU) * TAU + PI * 0.5
		var crank_rate := 4.0
		crank_a = damp(crank_a, tgt_c, crank_rate, dt)
	if not rider_ik:
		crank_a = -PI * 0.5
		crank_w = 0.0
	spin_node(n_chain, "chainset", crank_a)
	if n_ped_l != null:
		var rl_t := rest_of("Pedal_l")
		n_ped_l.transform = Transform3D(Basis(Vector3(1, 0, 0), -crank_a) * rl_t.basis, rl_t.origin)
		var rr_t := rest_of("Pedal_r")
		n_ped_r.transform = Transform3D(Basis(Vector3(1, 0, 0), -crank_a) * rr_t.basis, rr_t.origin)
	var steer_t := steer_ang if mode == GROUND else (-in_lx * 0.15)
	rig_steer = damp(rig_steer, steer_t, 14.0, ad)
	xup_amt = damp(xup_amt, 1.0 if xup_held else 0.0, 12.0, ad)
	steer_node(n_fork, "forks_front", rig_steer, axis_fork)
	steer_node(n_bars, "handlebars", rig_steer + bar_angle + xup_amt * 1.5, axis_bars)
	# позы райдера
	rig_ly = damp(rig_ly, in_ly, 14.0, ad)
	rig_head = damp(rig_head, -in_rx * 1.15, 14.0, ad)
	rig_tors = damp(rig_tors, -in_rx * 0.6, 9.0, ad)
	var cr_t := 0.0
	if hop_armed and mode == GROUND:
		cr_t = 0.45 + 0.25 * clampf(hop_push / PUSH_MAX, 0.0, 1.0)
	rig_crouch = damp(rig_crouch, cr_t, 10.0, ad)
	var man_t := clampf(th / 0.5, 0.0, 1.0) if (mode == GROUND and th > 0.0) else 0.0
	rig_man = damp(rig_man, man_t, 10.0, ad)
	whip_amt = damp(whip_amt, 1.0 if (tw_rem > 0.0 or (sliding and sl_kind == 2)) else 0.0, 14.0, ad)
	rock_amt = damp(rock_amt, 1.0 if (held_L and th > 0.25 and mode == GROUND) else 0.0, 12.0, ad)
	hang_amt = damp(hang_amt, 1.0 if (held_L and th < -0.25 and mode == GROUND) else 0.0, 12.0, ad)
	fj_amt = damp(fj_amt, 1.0 if (sliding and sl_kind == 2) else 0.0, 12.0, ad)
	hl_amt = damp(hl_amt, 1.0 if bar_rem > 0.0 else 0.0, 14.0, ad)
	hr_amt = damp(hr_amt, 1.0 if bar_rem > 0.0 else 0.0, 14.0, ad)
	if skel != null:
		if rider_free:
			pose_limp()
		elif rider_ik:
			pose_rider()
		else:
			rider_inst.position = Vector3.ZERO
			pov.clear()
			apply_pose()

func update_camera(dt: float) -> void:
	var vx := wvx
	var vz := wvz
	if mode == GROUND and not sliding:
		var f := dir_of(yaw)
		vx = f.x * spd
		vz = f.y * spd
	var sp := Vector2(vx, vz).length()
	var tgt := cam_yaw
	if sp > 1.5:
		tgt = atan2(-vz, vx)
	elif mode == GROUND:
		tgt = yaw
	cam_yaw += wrapf(tgt - cam_yaw, -PI, PI) * (1.0 - exp(-3.2 * dt))
	var dist := (5.2 + sp * 0.07) * k_cam
	var cx := cos(cam_yaw)
	var cz := -sin(cam_yaw)
	# камера левее по ходу движения (левый вектор = (cz, -cx)) и ниже
	var want_x := px - cx * dist + cz * k_cam_side
	var want_z := pz - cz * dist - cx * k_cam_side
	var want_y := k_cam_h + py * 0.65
	var k := 1.0 - exp(-8.0 * dt)
	cam_pos.x += (want_x - cam_pos.x) * k
	cam_pos.z += (want_z - cam_pos.z) * k
	cam_pos.y += (want_y - cam_pos.y) * (1.0 - exp(-5.0 * dt))
	cam_look = Vector3(px + cx * 2.0, py * 0.8 + 1.1, pz + cz * 2.0)
	cam.look_at_from_position(cam_pos, cam_look, Vector3.UP)
	cam.fov = damp(cam.fov, 62.0 + minf(sp, 13.0) * 1.3, 3.0, dt)

func add_rail(ax: float, ay: float, az: float, bx: float, by: float, bz: float) -> void:
	var r := Rail.new()
	r.ax = ax
	r.ay = ay
	r.az = az
	r.by = by
	var hl := Vector2(bx - ax, bz - az)
	r.rlen = hl.length()
	var dn := hl / r.rlen
	r.dx = dn.x
	r.dz = dn.y
	rails.append(r)
	var rm := mat("cfd4d9", 0.3, 0.75)
	var pm := mat("5b646b", 0.6, 0.3)
	tube(self, Vector3(ax, ay - 0.03, az), Vector3(bx, by - 0.03, bz), 0.03, rm)
	var n := int(r.rlen / 2.5) + 1
	for i in range(n + 1):
		var t := r.rlen * float(i) / float(n)
		var x := ax + r.dx * t
		var z := az + r.dz * t
		var h := rail_h(r, t)
		tube(self, Vector3(x, 0.0, z), Vector3(x, h - 0.03, z), 0.022, pm)
		make_box(self, Vector3(0.28, 0.03, 0.28), pm, Vector3(x, 0.015, z))

func pose_limp() -> void:
	pov.clear()
	var to_skel := skel.global_transform.affine_inverse() * rider_holder.global_transform
	var amp := 1.0 if rf_ground_t <= 0.0 else exp(-1.4 * rf_ground_t)
	var ph := rf_t * 11.0
	for si in range(2):
		var side := 1.0 if si == 0 else -1.0
		var pre := "R" if si == 0 else "L"
		var upa := pre + "_UpperArm"
		var fa := pre + "_ForeArm"
		var hd := pre + "_Hand"
		var th1 := pre + "_Thigh"
		var calf := pre + "_Calf"
		var foot := pre + "_Foot"
		var du := Vector3(side * 0.9, -0.15 + 0.6 * amp * sin(ph + side), -0.15 + 0.5 * amp * cos(ph * 1.3 + side)).normalized()
		aim_bone(upa, fa, bpos(upa) + (to_skel.basis * du).normalized() * float(blen["uarm"]))
		var df := Vector3(side * 0.6, -0.4 + 0.7 * amp * sin(ph * 1.2 + side * 2.0), -0.3 + 0.5 * amp * cos(ph + side)).normalized()
		aim_bone(fa, hd, bpos(fa) + (to_skel.basis * df).normalized() * float(blen["farm"]))
		var dt1 := Vector3(side * (0.35 + 0.2 * amp * sin(ph * 0.9 + side)), -0.9, -0.2 * amp * cos(ph + side)).normalized()
		aim_bone(th1, calf, bpos(th1) + (to_skel.basis * dt1).normalized() * float(blen["thigh"]))
		var dc := Vector3(side * 0.15, -0.9, 0.35 * amp * sin(ph * 1.1 + side)).normalized()
		aim_bone(calf, foot, bpos(calf) + (to_skel.basis * dc).normalized() * float(blen["calf"]))
	apply_pose()
