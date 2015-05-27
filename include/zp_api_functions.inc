#if defined _zp_l4d2_functions_included
  #endinput
#endif
#define _zp_l4d2_functions_included
#include <fakemeta_util>

#define PlaySound(%1,%2)	engfunc(EngFunc_EmitSound, %1, CHAN_AUTO, %2[random_num(0, sizeof %2 - 1)], 1.0, ATTN_NORM, 0, PITCH_NORM);
// 	emit_sound(id, CHAN_ITEM, sounds_idle[random_num(0, sizeof sounds_idle - 1)], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)

#define fm_precache_model(%1) 		engfunc(EngFunc_PrecacheModel,%1)
#define fm_precache_sound(%1) 		engfunc(EngFunc_PrecacheSound,%1)
#define fm_remove_entity(%1) 		engfunc(EngFunc_RemoveEntity, %1)
#define fm_find_ent_by_class(%1,%2) 	engfunc(EngFunc_FindEntityByString, %1, "classname", %2)

native zp_is_special_round()
native UTIL_set_score(const id, const target, const ammo, const frag, const type[])
native UTIL_triast_obrazovku(const id, const Float:amplitude, const Float:duration, const Float:frequency)
native UTIL_setcamera(const id, const type);
native UTIL_getcamera(const id)


forward PublicSecTimer()
forward InFrontOfWall(id)


/*
UTIL_set_speed(	const ent, const Float:speed, const Float:angle[3])
stock oznam( const msg[] , any:...)
UTIL_UserSkutocnyKoncovyBod(const id, const Float:origin[3], Float:Endorigin[3], const Float:max_distance)
stock vrat_body(id, kolko)
stock get_offset_origin_body(ent, const Float:offset[3], Float:origin[3])
stock get_speed_vector(const Float:origin1[3],const Float:origin2[3],Float:speed, Float:new_velocity[3])
stock entity_set_aim(ent,const Float:origin2[3],bone=0)
stock UTIL_JeHracBlizkoOrigin(const Float:origin[3], const Float:distance = 40.0)
stock get_user_hitpoint(id, Float:hOrigin[3])
stock fm_find_ent_by_owner(index, const classname[], owner, jghgtype = 0)
stock fm_velocity_by_aim(iIndex, Float:fDistance, Float:fVelocity[3], Float:fViewAngle[3])
stock Animacia(const id, const typ, const Float:speed)
stock UTIL_entity_size(const ent, const Float:p_mins[3], const Float:p_maxs[3])
stock UTIL_decal(const decalid, const Float:origin[3])
stock fm_set_rendering(entity, fx = kRenderFxNone, r = 255, g = 255, b = 255, render = kRenderNormal, amount = 16)
stock UTIL_normalize(Float:Vec[3])
stock UTIL_IsBSPModel(const ent)
stock UTIL_GetDecalIndex( nazov[])
stock UTIL_DolnyKoncovyBod(const id, const Float:origin[3], Float:Endorigin[3], const Float:koeficient = 300.0 )
stock set_speed(ent, Float:speed)
stock NajblizsiHrac(const hrac)
*/

stock UTIL_set_speed(	const ent, 
						const Float:speed, 
						const Float:angle[3]
) {
	static Float:new_velo[3], Float:y
	engfunc(EngFunc_DropToFloor, ent)
	pev(ent, pev_velocity, new_velo);
	angle_vector(angle, 1, new_velo);
	
	y = new_velo[0] * new_velo[0] + new_velo[1] * new_velo[1];
	if(y) y = floatsqroot(speed*speed / y);
	if(speed < 0.0) y *= -1;   
	new_velo[0] *= y;
	new_velo[1] *= y;
	if(speed < 0.0)  {
		new_velo[0] *= -1;
		new_velo[1] *= -1;
	}
	
	// Oprava bugu s gravitaciou
	engfunc(EngFunc_DropToFloor, ent)
	static Float:test[3]
	pev(ent, pev_velocity, test);	
	new_velo[2] = test[2];
	
	set_pev(ent, pev_velocity, new_velo);
	return 0;
}
stock NajblizsiHrac(const hrac) {
	new id, Float:vektor2[3], Float:origin[3], Float:vzdialenost,
		float:najm_vzdialenost = 10000.0, 
		najm_id = 0;
	
	pev(hrac, pev_origin, origin);
		
	for(id = 1; id <= get_maxplayers(); id++) {		
		if(!is_user_alive(id)) continue;
		
		// Hladame najblizsieho ....
		pev(id, pev_origin, vektor2);
		vzdialenost = get_distance_f(origin, vektor2);		
		if( vzdialenost < najm_vzdialenost) {
			najm_id = id;
			najm_vzdialenost = vzdialenost;
		}
	}
	return najm_id;
}
stock UTIL_get_speed2(ent) {
	new Float:Vel[3];
	pev(ent, pev_velocity, Vel);
	return floatround(vector_length(Vel));
}
/*
stock UTIL_set_speed2(ent, Float:speed) {
	if(!pev_valid(ent)) return 0;
	static Float:vangle[3];
	if(ent <= get_maxplayers())
	   pev(ent, pev_v_angle, vangle);
	else
	   pev(ent, pev_angles, vangle);

	static Float:new_velo[3];
	pev(ent, pev_velocity, new_velo);
	angle_vector(vangle, 1, new_velo);
	
	new Float:y;
	y = new_velo[0] * new_velo[0] + new_velo[1] * new_velo[1];

	new Float:x;
	if(y) x = floatsqroot(speed*speed / y);
	if(speed < 0.0) x *= -1;   
	new_velo[0] *= x;
	new_velo[1] *= x;

	if(speed < 0.0)  {
			new_velo[0] *= -1;
			new_velo[1] *= -1;
	}
	set_pev(ent, pev_velocity, new_velo);
	return 1;
}
*/
stock UTIL_UserSkutocnyKoncovyBod(	
	const id, 
	const Float:origin[3], 
	Float:Endorigin[3],
	const Float:max_distance
	)
{
	new Float:fAimVector[3], iTr
	pev( id, pev_v_angle, fAimVector )
	angle_vector( fAimVector, ANGLEVECTOR_FORWARD, fAimVector )
	
	// Nasobyme vektor, ...je to po aku dlzku az pojde
	fAimVector[0] = fAimVector[0] * max_distance + origin[0]
	fAimVector[1] = fAimVector[1] * max_distance + origin[1]
	fAimVector[2] = fAimVector[2] * max_distance + origin[2]
	
	// Vysledok ulozime
	iTr = create_tr2()
	engfunc( EngFunc_TraceLine, origin, fAimVector, IGNORE_MONSTERS, id, iTr )
	get_tr2( iTr, TR_vecEndPos, Endorigin)
	free_tr2( iTr )
}
stock vrat_body(id, kolko) {
	if(get_user_flags(id) & ADMIN_LEVEL_F ) {
		kolko = floatround( float(kolko) * 0.5 , floatround_floor );	
	}
	zp_set_user_ammo_packs(id,zp_get_user_ammo_packs(id) +  kolko)
}
stock get_offset_origin_body(ent, const Float:offset[3], Float:origin[3])
{	
	static Float:angle[3]
	pev(ent,pev_angles,angle)
	pev(ent,pev_origin,origin)
	
	origin[0] += floatcos(angle[1],degrees) * offset[0]
	origin[1] += floatsin(angle[1],degrees) * offset[0]
	
	origin[1] += floatcos(angle[1],degrees) * offset[1]
	origin[0] += floatsin(angle[1],degrees) * offset[1]
	return 1;
}

stock get_speed_vector(const Float:origin1[3],const Float:origin2[3],Float:speed, Float:new_velocity[3])
{
	new_velocity[0] = origin2[0] - origin1[0]
	new_velocity[1] = origin2[1] - origin1[1]
	new_velocity[2] = origin2[2] - origin1[2]
	new Float:num = floatsqroot(speed*speed / (new_velocity[0]*new_velocity[0] + new_velocity[1]*new_velocity[1] + new_velocity[2]*new_velocity[2]))
	new_velocity[0] *= num
	new_velocity[1] *= num
	new_velocity[2] *= num
}
stock entity_set_aim(ent,const Float:origin2[3],bone=0) {
	static Float:origin[3]
	origin[0] = origin2[0]
	origin[1] = origin2[1]
	origin[2] = origin2[2]
	
	static Float:ent_origin[3], Float:angles[3]
	
	if(bone)
		engfunc(EngFunc_GetBonePosition, ent, bone, ent_origin,angles)
	else
		pev(ent, pev_origin, ent_origin)
	
	origin[0] -= ent_origin[0]
	origin[1] -= ent_origin[1]
	origin[2] -= ent_origin[2]
	
	static Float:v_length
	v_length = vector_length(origin)
	
	static Float:aim_vector[3]
	aim_vector[0] = origin[0] / v_length
	aim_vector[1] = origin[1] / v_length
	aim_vector[2] = origin[2] / v_length
	
	static Float:new_angles[3]
	vector_to_angle(aim_vector,new_angles)
	
	new_angles[0] *= -1
	
	if(new_angles[1]>180.0) new_angles[1] -= 360
	if(new_angles[1]<-180.0) new_angles[1] += 360
	if(new_angles[1]==180.0 || new_angles[1]==-180.0) new_angles[1]=-179.999999
	
	set_pev(ent,pev_angles,new_angles)
	set_pev(ent,pev_fixangle,1)
	return 1;
}
stock UTIL_JeHracBlizkoOrigin(const Float:origin[3], const Float:distance = 40.0) {
	// Hladame blizko hracov ...
	new i, Float:postava[3]
	for(i=1; i <= g_maxplayers; i++) {
		if (!is_user_alive(i)) continue;
		pev(i, pev_origin, postava);
		if ( get_distance_f(origin, postava) < distance) { // najmenej 34.0
			return false;
		}
	}
	return true; // je prazdny ...
}
stock get_user_hitpoint(id, Float:hOrigin[3]) 
{
	if ( ! is_user_alive( id ))
		return 0;
    
	new Float:fOrigin[3], Float:fvAngle[3], Float:fvOffset[3], Float:fvOrigin[3], Float:feOrigin[3];
	new Float:fTemp[3];
    
	pev(id, pev_origin, fOrigin);
	pev(id, pev_v_angle, fvAngle);
	pev(id, pev_view_ofs, fvOffset);
    
	xs_vec_add(fOrigin, fvOffset, fvOrigin);
    
	engfunc(EngFunc_AngleVectors, fvAngle, feOrigin, fTemp, fTemp);
    
	xs_vec_mul_scalar(feOrigin, 9999.9, feOrigin);
	xs_vec_add(fvOrigin, feOrigin, feOrigin);
    
	engfunc(EngFunc_TraceLine, fvOrigin, feOrigin, 0, id);
	global_get(glb_trace_endpos, hOrigin);
    
	return 1;
} 
stock fm_velocity_by_aim(iIndex, Float:fDistance, Float:fVelocity[3], Float:fViewAngle[3])
{
	//new Float:fViewAngle[3]
	pev(iIndex, pev_v_angle, fViewAngle)
	fVelocity[0] = floatcos(fViewAngle[1], degrees) * fDistance
	fVelocity[1] = floatsin(fViewAngle[1], degrees) * fDistance
	fVelocity[2] = floatcos(fViewAngle[0]+90.0, degrees) * fDistance
	return 1
}
stock Animacia(const id, const typ, const Float:speed) {
	if(pev(id, pev_sequence) != typ || pev(id, pev_framerate) != speed) {
		set_pev(id, pev_sequence, typ)
		set_pev(id, pev_gaitsequence, typ)
		set_pev(id, pev_framerate, speed)
	}	
	return PLUGIN_CONTINUE;	
}
stock Animacia_PlayOneFrame(const id, const typ, const Float:frame) {
	set_pev(id, pev_sequence, typ)
	set_pev(id, pev_gaitsequence, typ)
	set_pev(id, pev_framerate, frame)
}
stock Animacia_PlayOnlyOne(	const id, 
							const typ, 
							const Float:speed,
							const Float:snimok,
							const Float:maxsnimkov							
) {
	if( maxsnimkov == snimok) return 0;	
	set_pev(id, pev_sequence, typ)
	set_pev(id, pev_gaitsequence, typ)
	set_pev(id, pev_framerate, snimok + speed)
	return 1;	
}
stock UTIL_entity_size(const ent, const Float:p_mins[3], const Float:p_maxs[3]) {
	engfunc(EngFunc_SetSize, ent, p_mins, p_maxs);
	set_pev(ent, pev_mins, p_mins);
	set_pev(ent, pev_maxs, p_maxs );
	set_pev(ent, pev_absmin, p_mins);
	set_pev(ent, pev_absmax, p_maxs );
	return PLUGIN_CONTINUE;	
}
stock UTIL_decal(const decalid, const Float:origin[3]) {
	engfunc(EngFunc_MessageBegin, MSG_PAS, SVC_TEMPENTITY, origin, 0)
	write_byte(TE_WORLDDECAL) // TE id
	engfunc(EngFunc_WriteCoord, origin[0]) // x
	engfunc(EngFunc_WriteCoord, origin[1]) // y
	engfunc(EngFunc_WriteCoord, origin[2]) // z
	write_byte(decalid)
	message_end()
	return PLUGIN_CONTINUE;	
}
stock UTIL_normalize(Float:Vec[3]) {
	new Float:v_length;
	v_length = vector_length(Vec)
	Vec[1] = Vec[0] / v_length
	Vec[1] = Vec[1] / v_length
	Vec[2] = Vec[2] / v_length
}
stock UTIL_IsBSPModel(const ent) {
	return (pev(ent, pev_solid) == SOLID_BSP || pev(ent, pev_movetype) == MOVETYPE_PUSHSTEP);
}
stock UTIL_GetDecalIndex( nazov[]) {
	return engfunc(EngFunc_DecalIndex, nazov);
}
stock oznam( const msg[] , any:...) {	
	static msgid_say;
	if(!msgid_say) {
		msgid_say = get_user_msgid("SayText");
	}
	static temp[64]
	vformat(temp, sizeof temp - 1, msg, 2)			
	
	// Ak chceme farbene musime dat FOR a pre kazdeho zvlast :(
	for(new hrac = 1; hrac <= g_maxplayers; hrac++) {								
		if(is_user_connected(hrac)) {	
			message_begin(MSG_ONE_UNRELIABLE, msgid_say, _, hrac)
			write_byte(hrac)
			write_string(temp)
			message_end()	
		}	
	}
	return PLUGIN_CONTINUE
}
stock UTIL_DolnyKoncovyBod(	const id, 
							const Float:origin[3],
							Float:Endorigin[3], 
							const Float:koeficient = 300.0 )
{	
	new iTr
	Endorigin[0] = origin[0];
	Endorigin[1] = origin[1];
	Endorigin[2] = origin[2] - koeficient; // zatial postaci ...
	iTr = create_tr2()
	engfunc( EngFunc_TraceLine, origin, Endorigin, IGNORE_MONSTERS, id, iTr )
	get_tr2( iTr, TR_vecEndPos, Endorigin)
	free_tr2( iTr )
}	