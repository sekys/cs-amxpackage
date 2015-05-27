#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <engine>
#include <xs>

#define fm_drop_to_floor(%1) engfunc(EngFunc_DropToFloor,%1)
#define fm_find_ent_by_class(%1,%2) engfunc(EngFunc_FindEntityByString, %1, "classname", %2)
#define NEXT_THINK 	0.1

new arg[4], sprite_line, vykresluj[2]

// Konstanty
new const EV_INT_NAME[37][] = {
	"EV_INT_gamestate",
	"EV_INT_oldbuttons",
	"EV_INT_groupinfo",
	"EV_INT_iuser1",
	"EV_INT_iuser2",
	"EV_INT_iuser3",
	"EV_INT_iuser4",
	"EV_INT_weaponanim",
	"EV_INT_pushmsec",
	"EV_INT_bInDuck",
	"EV_INT_flTimeStepSound",
	"EV_INT_flSwimTime",
	"EV_INT_flDuckTime",
	"EV_INT_iStepLeft",
	"EV_INT_movetype",
	"EV_INT_solid",
	"EV_INT_skin",
	"EV_INT_body",
	"EV_INT_effects",
	"EV_INT_light_level",
	"EV_INT_sequence",
	"EV_INT_gaitsequence",
	"EV_INT_modelindex",
	"EV_INT_playerclass",
	"EV_INT_waterlevel",
	"EV_INT_watertype",
	"EV_INT_spawnflags",
	"EV_INT_flags",
	"EV_INT_colormap",
	"EV_INT_team",
	"EV_INT_fixangle",
	"EV_INT_weapons",
	"EV_INT_rendermode",
	"EV_INT_renderfx",
	"EV_INT_button",
	"EV_INT_impulse",
	"EV_INT_deadflag" }

new const EV_FL_NAME[37][] = {
	"EV_FL_impacttime",
	"EV_FL_starttime",
	"EV_FL_idealpitch",
	"EV_FL_pitch_speed",
	"EV_FL_ideal_yaw",
	"EV_FL_yaw_speed",
	"EV_FL_ltime",
	"EV_FL_nextthink",
	"EV_FL_gravity",
	"EV_FL_friction",
	"EV_FL_frame",
	"EV_FL_animtime",
	"EV_FL_framerate",
	"EV_FL_health",
	"EV_FL_frags",
	"EV_FL_takedamage",
	"EV_FL_max_health",
	"EV_FL_teleport_time",
	"EV_FL_armortype",
	"EV_FL_armorvalue",
	"EV_FL_dmg_take",
	"EV_FL_dmg_save",
	"EV_FL_dmg",
	"EV_FL_dmgtime",
	"EV_FL_speed",
	"EV_FL_air_finished",
	"EV_FL_pain_finished",
	"EV_FL_radsuit_finished",
	"EV_FL_scale",
	"EV_FL_renderamt",
	"EV_FL_maxspeed",
	"EV_FL_fov",
	"EV_FL_flFallVelocity",
	"EV_FL_fuser1",
	"EV_FL_fuser2",
	"EV_FL_fuser3",
	"EV_FL_fuser4" }

new const EV_VEC_NAME[23][] = {
	"EV_VEC_origin",
	"EV_VEC_oldorigin",
	"EV_VEC_velocity",
	"EV_VEC_basevelocity",
	"EV_VEC_clbasevelocity",
	"EV_VEC_movedir",
	"EV_VEC_angles",
	"EV_VEC_avelocity",
	"EV_VEC_punchangle",
	"EV_VEC_v_angle",
	"EV_VEC_endpos",
	"EV_VEC_startpos",
	"EV_VEC_absmin",
	"EV_VEC_absmax",
	"EV_VEC_mins",
	"EV_VEC_maxs",
	"EV_VEC_size",
	"EV_VEC_rendercolor",
	"EV_VEC_view_ofs",
	"EV_VEC_vuser1",
	"EV_VEC_vuser2",
	"EV_VEC_vuser3",
	"EV_VEC_vuser4" }

new const EV_ENT_NAME[11][] = {
	"EV_ENT_chain",
	"EV_ENT_dmg_inflictor",
	"EV_ENT_enemy",
	"EV_ENT_aiment",
	"EV_ENT_owner",
	"EV_ENT_groundentity",
	"EV_ENT_pContainingEntity",
	"EV_ENT_euser1",
	"EV_ENT_euser2",
	"EV_ENT_euser3",
	"EV_ENT_euser4" }

new const EV_SZ_NAME[13][] = {
	"EV_SZ_classname",
	"EV_SZ_globalname",
	"EV_SZ_model",
	"EV_SZ_target",
	"EV_SZ_targetname",
	"EV_SZ_netname",
	"EV_SZ_message",
	"EV_SZ_noise",
	"EV_SZ_noise1",
	"EV_SZ_noise2",
	"EV_SZ_noise3",
	"EV_SZ_viewmodel",
	"EV_SZ_weaponmodel" }

new const EV_BYTE_NAME[6][] = {
	"EV_BYTE_controller1",
	"EV_BYTE_controller2",
	"EV_BYTE_controller3",
	"EV_BYTE_controller4",
	"EV_BYTE_blending1",
	"EV_BYTE_blending2" }
	
public plugin_init()
{
	register_plugin("Entity","2.1","Seky")
	
	register_clcmd ( "ent_del", "vymaz", ADMIN_RCON, "<IDcislo> Odstrani entitu podla cisla alebo mieritka" );
	register_clcmd ( "ent_use", "pouzi", ADMIN_RCON, "<IDcislo> Pouzije entitu podla cisla alebo mieritka." );
	register_clcmd ( "ent_get", "ukaz", ADMIN_RCON, "Ukaze ID entity podla mieritka." );
	register_clcmd ( "ent_set", "nastav", ADMIN_RCON, "Nastavy vlastnosti na entitu." );
	register_clcmd ( "ent_see", "vykresli", ADMIN_RCON, "Nastavy vlastnosti na entitu." );
	
	register_clcmd ( "ent_create", "create", ADMIN_RCON, "Vytvori entitu." );
	register_clcmd ( "ent_ja", "ja", ADMIN_RCON, "Ukaze ID hraca" );
	register_clcmd ( "ent_range", "range", ADMIN_RCON, "Najde entity vo vzdialenosti." );
	register_clcmd ( "ent_radius", "range", ADMIN_RCON, "Najde entity vo vzdialenosti." );
	register_clcmd ( "ent_find", "find", ADMIN_RCON, "najde entitu podla mena." );
	
	register_clcmd ( "ent_damage", "damage", ADMIN_RCON, "Sprav damage" );
}
public plugin_precache() {
	sprite_line = precache_model("sprites/dot.spr")
}
public range(id,level,cid)
{
	if (!cmd_access(id,level,cid,2))
		return PLUGIN_HANDLED
	
	read_argv( 1, arg, 4)
	new Float:Radius, ent = -1, Float:vecSrc[3], classname[33]
	Radius = str_to_float(arg)
	pev(id, pev_origin, vecSrc);
	
	while((ent = engfunc(EngFunc_FindEntityInSphere, ent, vecSrc, Radius)) != 0)
	{
		pev(ent, pev_classname, classname, 32)
		console_print(id, "Entita %d - %s", ent, classname)
	}
	
	return PLUGIN_CONTINUE
}
public find(id,level,cid)
{
	if (!cmd_access(id,level,cid,2))
		return PLUGIN_HANDLED
	
	new ent = -1, classname[33]
	read_argv( 1, classname, 32)

	while((ent = fm_find_ent_by_class(ent, classname)))
	{
		console_print(id, "Entita %d", ent)
	}
		
	return PLUGIN_CONTINUE
}
public ja(id,level,cid)
{
	if (!cmd_access(id,level,cid,0))
		return PLUGIN_HANDLED
	
	client_print(id,print_chat,"[ENT] Tvoja entita je %d a userid je %d.^n", id, get_user_userid(id))		
	return PLUGIN_CONTINUE
}
public create(id,level,cid)
{
	if (!cmd_access(id,level,cid,2))
		return PLUGIN_HANDLED
	
	new meno[33], Float:xorigin[3]
	read_argv(1, meno, 32)
	get_user_hitpoint(id,xorigin);	
	
	if(engfunc(EngFunc_PointContents,xorigin) == CONTENTS_SKY)
	{
		client_print(id,print_chat,"[END] Ukazujes nebo.^n");
		return PLUGIN_HANDLED;
	}
	
	new ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"));
	set_pev(ent, pev_classname, meno);
	engfunc(EngFunc_SetOrigin, ent, xorigin);
	set_pev(ent, pev_movetype, MOVETYPE_FLY);
	set_pev(ent, pev_solid, SOLID_BBOX);
	fm_drop_to_floor(ent);
	
	client_print(id,print_chat,"[END] Vytvorena entita %d ^n", ent);
	return PLUGIN_CONTINUE
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
public vymaz(id,level,cid)
{
	if (!cmd_access(id,level,cid,2))
		return PLUGIN_HANDLED
	
	read_argv( 1, arg, 4)
	new cislo = str_to_num(arg)
	if(cislo==0) {
		new tarukaz,body,tauth[32]
		
		get_user_aiming(id,tarukaz,body,99999)
		get_user_authid(tarukaz,tauth,31)
		
		if(equali(tauth,"STEAM_",6)) {
			client_print(id,print_chat,"[ENT] Nemozes odstranit hraca!^n",tarukaz)
		} else if (is_user_bot(tarukaz)) {
			client_print(id,print_chat,"[ENT] Nemozes odstranit buta!^n",tarukaz)
		} else if (tarukaz == 0) {
			client_print(id,print_chat,"[ENT] Na nic sa nepozeras !^n")
		} else {
			remove_entity(tarukaz)
			client_print(id,print_chat,"[ENT] Odstranena entita %d.^n",tarukaz)
		}		
	} else {
		if(pev_valid(cislo))
		{
			remove_entity(cislo)
			client_print(id,print_chat,"[ENT] Odstranena entita %d .^n",cislo)	
		} else {
			client_print(id,print_chat,"[ENT] Entita nieje validna^n")
		}
	}
	return PLUGIN_CONTINUE
}
public pouzi(id,level,cid)
{
	if (!cmd_access(id,level,cid,2))
		return PLUGIN_HANDLED
		
	read_argv ( 1, arg,4)
	new cislo = str_to_num(arg)
	if(cislo==0) {
		new tarukaz,body,tauth[32]
		get_user_aiming(id,tarukaz,body,99999)
		get_user_authid(tarukaz,tauth,31)
		if(equali(tauth,"STEAM_",6)) {
			client_print(id,print_chat,"[ENT] Nemozes odstranit hraca!^n",tarukaz)
		} else if (is_user_bot(tarukaz)) {
			client_print(id,print_chat,"[ENT] Nemozes odstranit buta!^n",tarukaz)
		} else if (tarukaz == 0) {
			client_print(id,print_chat,"[ENT] Na nic sa nepozeras^n")
		} else {
			fake_touch(tarukaz,id);
			force_use(id,tarukaz);
			client_print(id,print_chat,"[ENT] Pouzita entita %d.^n",tarukaz)
		}		
	} else {
		if(pev_valid(cislo))
		{
			fake_touch(cislo,id);
			force_use(id,cislo);
			client_print(id,print_chat,"[ENT] Pouzita entita %d.^n",cislo)
		} else {
			client_print(id,print_chat,"[ENT] Entita nieje validna^n")
		}
	}
	return PLUGIN_CONTINUE
}
public vykresli(id,level,cid)
{
	if (!cmd_access(id,level,cid,2))
		return PLUGIN_HANDLED
		
	read_argv ( 1, arg,4)
	vykresluj[1] = 0; // stopneme
	new cislo = str_to_num(arg)
	if(cislo==0) {
		new body
		get_user_aiming(id,cislo,body,99999)	
	}
	if(!pev_valid(cislo)){
		client_print(id,print_chat,"[ENT] Entita nieje validna^n")
		return PLUGIN_CONTINUE
	}
	vykresluj[0] = id;
	vykresluj[1] = cislo;
	think_see()
	return PLUGIN_CONTINUE
}
public think_see()
{
	if(pev_valid(vykresluj[1])) {
		static i;
		i++;
		if(i > 5) {
			ukaz_radius(vykresluj[0], vykresluj[1]);
			i = 0;
		}	
		UTIL_debug(vykresluj[0], vykresluj[1], NEXT_THINK);
		set_task(NEXT_THINK, "think_see");	
	}
}
stock ukaz_radius(id, ent)
{
	// Vypocet
	static Float:temp[3], Float:postava[3]
	pev(ent, pev_origin, temp);
	pev(id, pev_origin, postava);

	set_hudmessage(255, 0, 0, 0.5, 0.2, 0, 0.1, 0.5, 0.0, 0.0, 4) 
	show_hudmessage(id, "Radius: %i", floatround(get_distance_f(temp, postava)))
}
stock UTIL_debug(const id, const ent, const Float:cas = 0.01)
{
	static 	Float: ent_min[3],Float: ent_max[3],Float: id_ori[3],
			e_min[3],e_max[3],ori[3],ents[3];	
	
	entity_get_vector(ent,EV_VEC_absmin,ent_min)
	entity_get_vector(ent,EV_VEC_absmax,ent_max)	
	entity_get_vector(id,EV_VEC_origin,id_ori);
	
	for(new i=0;i<3;i++) {
		e_min[i]=floatround(ent_min[i])
		e_max[i]=floatround(ent_max[i])
		ori[i]=floatround(id_ori[i])
		ents[i]=(e_min[i]+e_max[i])/2
	}
	Create_Line(id, ori, ents, cas)
	Create_Box(id, e_min, e_max, cas)
}
stock Create_Box(const id,const mins[3], const maxs[3], const Float:cas)
{
	DrawLine(id,maxs[0], maxs[1], maxs[2], mins[0], maxs[1], maxs[2], cas)
	DrawLine(id,maxs[0], maxs[1], maxs[2], maxs[0], mins[1], maxs[2], cas)
	DrawLine(id,maxs[0], maxs[1], maxs[2], maxs[0], maxs[1], mins[2], cas)

	DrawLine(id,mins[0], mins[1], mins[2], maxs[0], mins[1], mins[2], cas)
	DrawLine(id,mins[0], mins[1], mins[2], mins[0], maxs[1], mins[2], cas)
	DrawLine(id,mins[0], mins[1], mins[2], mins[0], mins[1], maxs[2], cas)

	DrawLine(id,mins[0], maxs[1], maxs[2], mins[0], maxs[1], mins[2], cas)
	DrawLine(id,mins[0], maxs[1], mins[2], maxs[0], maxs[1], mins[2], cas)
	DrawLine(id,maxs[0], maxs[1], mins[2], maxs[0], mins[1], mins[2], cas)
	DrawLine(id,maxs[0], mins[1], mins[2], maxs[0], mins[1], maxs[2], cas)
	DrawLine(id,maxs[0], mins[1], maxs[2], mins[0], mins[1], maxs[2], cas)
	DrawLine(id,mins[0], mins[1], maxs[2], mins[0], maxs[1], maxs[2], cas)
}
stock DrawLine(const id, const x1, const y1, const z1, const x2, const y2, const z2, const Float:cas) 
{
	static start[3], stop[3]
	start[0]=(x1)
	start[1]=(y1)
	start[2]=(z1)
	stop[0]=(x2)
	stop[1]=(y2)
	stop[2]=(z2)
	Create_Line(id,start, stop, cas)
}
stock Create_Line(const id,const start[3], const stop[3], const Float:cas)
{
	message_begin(MSG_ONE,SVC_TEMPENTITY,{0,0,0},id)
	write_byte(0)
	write_coord(start[0])
	write_coord(start[1])
	write_coord(start[2])
	write_coord(stop[0])
	write_coord(stop[1])
	write_coord(stop[2])
	write_short(sprite_line)
	write_byte(1)
	write_byte(5)
	write_byte(floatround(cas*10))
	write_byte(3)
	write_byte(0)
	write_byte(255)	// RED
	write_byte(0)	// GREEN
	write_byte(0)	// BLUE					
	write_byte(250)	// brightness
	write_byte(5)
	message_end()
}
public ukaz(id,level,cid)
{
	if (!cmd_access(id,level,cid,2))
		return PLUGIN_HANDLED
	
	//Vypis ID
	read_argv ( 1, arg,4)
	new victim = str_to_num(arg)
	if(victim==0) {
		new bodypart
		get_user_aiming(id,victim,bodypart,99999)	
	} else {
		if(!pev_valid(victim))
		{
			client_print(id,print_chat,"[ENT] Entita nieje validna^n")
			return PLUGIN_CONTINUE
		}
	}
	
	if (victim == 0) {
		client_print(id,print_chat,"[ENT] Ziadna entita!^n")
		return PLUGIN_CONTINUE
	} else {
		client_print(id,print_chat,"[ENT] Entity ID je %d.^n",victim)
	}
	
	// Pokracuje podoroboym vypisom
		
	  new i, EV_INT_VALUE, Float:EV_FL_VALUE, Float:EV_VEC_VALUE[3], EV_ENT_VALUE, EV_SZ_VALUE[32], EV_BYTE_VALUE
	  console_print(id, "Entity %d", victim)

	  for(i=EV_INT_gamestate ; i<=EV_INT_deadflag ; i++)
	    if((EV_INT_VALUE = entity_get_int(victim, i)) != 0)
	      console_print(id, "%s = %d", EV_INT_NAME[i], EV_INT_VALUE)

	  for(i=EV_FL_impacttime ; i<=EV_FL_fuser4 ; i++)
	    if((EV_FL_VALUE = entity_get_float(victim, i)) != 0.0)
	      console_print(id, "%s = %f", EV_FL_NAME[i], EV_FL_VALUE)

	  for(i=EV_VEC_origin ; i<=EV_VEC_vuser4 ; i++)
	  {
	    entity_get_vector(victim, i, EV_VEC_VALUE)
	    if((EV_VEC_VALUE[0] != 0) || (EV_VEC_VALUE[1] != 0) || (EV_VEC_VALUE[2] != 0))
	      console_print(id, "%s = (%f,%f,%f)", EV_VEC_NAME[i], EV_VEC_VALUE[0], EV_VEC_VALUE[1], EV_VEC_VALUE[2])
	  }

	  for(i=EV_ENT_chain ; i<=EV_ENT_euser4 ; i++)
	    if((EV_ENT_VALUE = entity_get_edict(victim, i)) != 0)
	      console_print(id, "%s = %d", EV_ENT_NAME[i], EV_ENT_VALUE)

	  for(i=EV_SZ_classname ; i<=EV_SZ_weaponmodel ; i++)
	  {
	    entity_get_string(victim, i, EV_SZ_VALUE, 32)
	    if(strlen(EV_SZ_VALUE) != 0)
	      console_print(id, "%s = %s", EV_SZ_NAME[i], EV_SZ_VALUE)
	  }

	  for(i=EV_BYTE_controller1 ; i<=EV_BYTE_blending2 ; i++)
	    if((EV_BYTE_VALUE = entity_get_byte(victim, i)) != 0)
	      console_print(id, "%s = %d", EV_BYTE_NAME[i], EV_BYTE_VALUE)
		  
		  
	return PLUGIN_CONTINUE
}
public nastav(id,level,cid)
{
	if (!cmd_access(id,level,cid,4))
		return PLUGIN_HANDLED
	
	// Ukazovac 
	read_argv ( 1, arg, 4)
	new cislo = str_to_num(arg)
	if(cislo==0) {
		new tarukaz,body,tauth[32]
		get_user_aiming(id,tarukaz,body,99999)
		get_user_authid(tarukaz,tauth,31)

		if (tarukaz == 0) {
			client_print(id,print_chat,"[ENT] Na nic sa nepozeras^n")
			return PLUGIN_HANDLED
		} else {
			cislo = tarukaz
		}		
	} else {
		if(!pev_valid(cislo))
		{
			client_print(id,print_chat,"[ENT] Entita nieje validna^n")
			return PLUGIN_HANDLED
		}
	}
		
	// Aku premennu ???
	new premenna[65], i, uspech = -1
	read_argv (2, premenna, 64)
			
	// Typ premennej	
	if( containi(premenna, "_FL_") > -1 ) 								// float
	{
		for(i=0; i < sizeof EV_FL_NAME; i++)
		{
			if(equal(premenna, EV_FL_NAME[i]))
			{
				uspech = i
				break
			}
		}
		if(uspech == -1)
		{
			client_print(id,print_chat,"[ENT] Neznamy typ premennej.")
			return PLUGIN_HANDLED
		}
		
		new fl_hodnota_temp[33]
		read_argv(3, fl_hodnota_temp, 32)
		new Float:fl_hodnota = str_to_float(fl_hodnota_temp)		
		
		entity_set_float(cislo, uspech, fl_hodnota)
		client_print(id,print_chat,"[ENT] %d - %s - %f", cislo, premenna, fl_hodnota)
	} else if(containi(premenna, "_VEC_") > -1 || equal(premenna, "ORIGIN") || equal(premenna, "SIZE")) { 	// vektor

		new vec_hodnota_temp[3][33], Float:vec_hodnota[3]
		read_argv(3, vec_hodnota_temp[0], 32)
		read_argv(4, vec_hodnota_temp[1], 32)
		read_argv(5, vec_hodnota_temp[2], 32)
			
		vec_hodnota[0] = str_to_float(vec_hodnota_temp[0])		
		vec_hodnota[1] = str_to_float(vec_hodnota_temp[1])		
		vec_hodnota[2] = str_to_float(vec_hodnota_temp[2])
		
		if( equal(premenna, "ORIGIN"))
		{
			entity_set_origin (cislo, vec_hodnota )
			client_print(id,print_chat,"[ENT] %d - %s - %f , %f , %f", cislo, premenna, vec_hodnota[0], vec_hodnota[1], vec_hodnota[2])
		} else if(equal(premenna, "SIZE")) {		
			
			new vec_hodnota_temp_max[3][33], Float:vec_hodnota_max[3]
			read_argv(6, vec_hodnota_temp_max[0], 32)
			read_argv(7, vec_hodnota_temp_max[1], 32)
			read_argv(8, vec_hodnota_temp_max[2], 32)
			
			vec_hodnota_max[0] = str_to_float(vec_hodnota_temp_max[0])		
			vec_hodnota_max[1] = str_to_float(vec_hodnota_temp_max[1])		
			vec_hodnota_max[2] = str_to_float(vec_hodnota_temp_max[2])
									
			entity_set_size ( cislo, vec_hodnota, vec_hodnota_max ) 
			client_print(id,print_chat,"[ENT] %d - %s MIN %f , %f , %f MAX %f , %f , %f", cislo, premenna, vec_hodnota[0], vec_hodnota[1], vec_hodnota[2], vec_hodnota_max[0], vec_hodnota_max[1], vec_hodnota_max[2])
		} else {	
			for(i=0; i < sizeof EV_VEC_NAME; i++)
			{
				if(equal(premenna, EV_VEC_NAME[i]))
				{
					uspech = i
					break
				}
			}
			if(uspech == -1)
			{
				client_print(id,print_chat,"[ENT] Neznamy typ premennej.")
				return PLUGIN_HANDLED
			}
						
			entity_set_vector(cislo, uspech, vec_hodnota ) 
			client_print(id,print_chat,"[ENT] %d - %s - %f , %f , %f", cislo, premenna, vec_hodnota[0], vec_hodnota[1], vec_hodnota[2])
		}	
	} else if( containi(premenna, "_BYTE_") > -1 ) { 					// bool
		for(i=0; i < sizeof EV_BYTE_NAME; i++)
		{
			if(equal(premenna, EV_BYTE_NAME[i]))
			{
				uspech = i
				break
			}
		}
		if(uspech == -1)
		{
			client_print(id,print_chat,"[ENT] Neznamy typ premennej.")
			return PLUGIN_HANDLED
		}
		
		new bo_hodnota_temp[4], bool:bo_hodnota
		read_argv(4, bo_hodnota_temp, 3)
		new temp = str_to_num(bo_hodnota_temp)
		bo_hodnota = (temp) ? true : false
		entity_set_byte ( cislo, uspech, bo_hodnota ) 
		client_print(id,print_chat,"[ENT] %d - %s - %s", cislo, premenna, (bo_hodnota) ? "TRUE" : "FALSE")
	} else if( containi(premenna, "_SZ_") > -1 ||  equal(premenna, "MODEL") ) { 																	// string
		
		new hodnota[129]
		read_argv(3, hodnota , 128)	
		
		if( equal(premenna, "MODEL") )
		{
			entity_set_model( cislo, hodnota ) 
			client_print(id,print_chat,"[ENT] %d - %s - %s", cislo, premenna, hodnota)
		} else {	
			for(i=0; i < sizeof EV_SZ_NAME; i++)
			{
				if(equal(premenna, EV_SZ_NAME[i]))
				{
					uspech = i
					break
				}
			}
			if(uspech == -1)
			{
				client_print(id,print_chat,"[ENT] Neznamy typ premennej.")
				return PLUGIN_HANDLED
			}
		
			entity_set_string ( cislo, uspech, hodnota ) 
			client_print(id,print_chat,"[ENT] %d - %s - %s", cislo, premenna, hodnota)
		}
	} else if(containi(premenna, "_INT_") > -1) { 																				// integer
		for(i=0; i < sizeof EV_INT_NAME; i++)
		{
			if(equal(premenna, EV_INT_NAME[i]))
			{
				uspech = i
				break
			}
		}
		if(uspech == -1)
		{
			client_print(id,print_chat,"[ENT] Neznamy typ premennej.")
			return PLUGIN_HANDLED
		}
		
		
		new int_hodnota_temp[33]
		read_argv(3, int_hodnota_temp, 32)
		new int_hodnota = str_to_num(int_hodnota_temp)		
		entity_set_int (cislo, uspech, int_hodnota ) 
		client_print(id,print_chat,"[ENT] %d - %s - %d", cislo, premenna, int_hodnota)
	} else if(containi(premenna, "_ENT_") > -1) { 																				// integer
		for(i=0; i < sizeof EV_ENT_NAME; i++)
		{
			if(equal(premenna, EV_ENT_NAME[i]))
			{
				uspech = i
				break
			}
		}
		if(uspech == -1)
		{
			client_print(id,print_chat,"[ENT] Neznamy typ premennej.")
			return PLUGIN_HANDLED
		}
		
		
		new int_hodnota_temp[33]
		read_argv(3, int_hodnota_temp, 32)
		new int_hodnota = str_to_num(int_hodnota_temp)		
		entity_set_edict(cislo, uspech, int_hodnota ) 
		client_print(id,print_chat,"[ENT] %d - %s - %d", cislo, premenna, int_hodnota)
	} else {
		client_print(id,print_chat,"[ENT] Neznamy typ premennej.")
	}	
	// Nastavene....
	  
	return PLUGIN_CONTINUE
}
public damage(id, level, cid)
{
	if (!cmd_access(id,level,cid,4)) {
		return PLUGIN_HANDLED
	}
	
	new parameter[32]
	read_argv( 1, parameter, sizeof parameter - 1)
	new ciel = cmd_target (id, parameter, 3);

	if (!ciel)
    {
        client_print(id, print_console, "(!) Hrac nenajdeny");
        return PLUGIN_HANDLED;
    }
	new fl_hodnota_temp[33]
	read_argv(2, fl_hodnota_temp, 32)
	new Float:fl_hodnota = str_to_float(fl_hodnota_temp)	
	
	new int_hodnota_temp[33]
	read_argv(3, int_hodnota_temp, 32)
	new int_hodnota = str_to_num(int_hodnota_temp)	
	
		
	fakedamage(ciel, "weapon_test", fl_hodnota, int_hodnota)
	return PLUGIN_CONTINUE
}