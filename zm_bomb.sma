#include <amxmod>
#include <amxmisc> 
#include <fakemeta>
#include <xs>
#include <zombieplague>
#include <Vexd_Utilities>

#define TASK_TAHAJ 			200
#define TASK_BOMB 			202
#define OWNER				pev_iuser2
#define RemoveEntity(%1)	engfunc(EngFunc_RemoveEntity,%1)
#define fm_create_entity(%1) engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, %1))

//----------------------------------------------------------------------------------------------
#define SPEED 		300.0	// px za sec
#define RADIUS 		500.0	// vzdialenost tahania ale a aj zabijania
#define T_DAMAGE 	3000.0	// kolko zoberie zombikom
#define CT_DAMAGE 	100.0	// kolko zoberie ct
#define V_MODEL		"models/zombie_plague/v_pipe.mdl"
#define P_MODEL		"models/zombie_plague/p_pipe.mdl"
#define CENA		30
#define ENT_CLASS_NAME	"seky_bomb"

new menu_bomba, cvar_cas,  bool:hrac_ma_bombu[33], bomba_sa_pouziva, Float:pocet,
	msgScreenShake, g_msgDamage, g_msgDeathMsg, g_msgScoreInfo,
	gSpriteSmoke, gSpriteWhite, gSpriteFire, sprFlare6

new const zvuk[] = "zombie_plague/beep.wav"
new const vybuch[] = "weapons/c4_explode1.wav"
//new const vybuch[] = "weapons/explode3.wavv"

//----------------------------------------------------------------------------------------------
public plugin_init()
{
	register_plugin("L4D Bomb", "1.0", "Seky")
	register_clcmd("amx_set_bomb", "cmd_bomb", ADMIN_RCON, "-");	
	menu_bomba 		= zp_register_extra_item("L4D Bomb", CENA, ZP_TEAM_HUMAN)
	cvar_cas 		= register_cvar("zp_c4timer", "20")
	msgScreenShake  = get_user_msgid("ScreenShake")
	g_msgDamage 	= get_user_msgid("Damage");
	g_msgDeathMsg 	= get_user_msgid("DeathMsg");
	g_msgScoreInfo	= get_user_msgid("ScoreInfo");
	
	register_event("CurWeapon", "weaponChange","be","1=1")
	register_forward(FM_CmdStart, "ak_klikne")
}
public plugin_precache()
{
	precache_model(V_MODEL)
	precache_model(P_MODEL)
	precache_sound(zvuk)
	precache_sound(vybuch)
	gSpriteSmoke = precache_model("sprites/steam1.spr")
	gSpriteWhite = precache_model("sprites/white.spr")
	gSpriteFire = precache_model("sprites/explode1.spr")
	sprFlare6 = precache_model("sprites/Flare6.spr")
}
//
//	 Nakupime
//
public cmd_bomb(id, level, cid)
{
	if (!cmd_access(id,level,cid,1)) {
		return PLUGIN_HANDLED
	}
	if(kontrola_bomby(id) == 1)
	{
		daj_bombu(id)
	}
}
public client_disconnect(id)
{
	hrac_ma_bombu[id] = false
}
public zp_round_ended(winteam)
{
	for ( new id = 0; id < 33; id++ ) {
		hrac_ma_bombu[id] = false
	}
	remove_task(TASK_TAHAJ)
	remove_task(TASK_BOMB)
	pocet = 0.0
	if(bomba_sa_pouziva) {
		RemoveEntity(bomba_sa_pouziva);
	}
	bomba_sa_pouziva = 0
}
public zp_extra_item_selected(id, itemid)
{
	if (itemid == menu_bomba)
	{
		new bodov = zp_get_user_ammo_packs(id)
		if(kontrola_bomby(id) == 1)
		{
			if(hrac_ma_bombu[id])
			{
				new i, iWeapon, iWeapons[32], zbran[32]
				get_user_weapons(id, iWeapons, i) 
				for(--i; i>=0; i--) 
				{ 
					iWeapon = iWeapons[i] 
				}

				if (iWeapon == CSW_C4) {
					client_print(id, print_chat, "[G/L ZP] Uz mas bombu.")
					//zp_set_user_ammo_packs(id,bodov + CENA)	
					//vrat_body(id,  CENA)
					return PLUGIN_HANDLED;
				} else {
					daj_bombu(id)
				}
			} else {	
				daj_bombu(id)
				//zp_set_user_ammo_packs(id,bodov - CENA)
			}
		} else {
			// vratime body
			//zp_set_user_ammo_packs(id,bodov + CENA)	
			//vrat_body(id,  CENA)
			return PLUGIN_HANDLED;
		}
	}
}
stock vrat_body(id, kolko)
{
	if(get_user_flags(id) & ADMIN_LEVEL_F ) {
		kolko = floatround( float(kolko) * 0.5 , floatround_floor );	
	}
	zp_set_user_ammo_packs(id,zp_get_user_ammo_packs(id) + kolko)
}
stock kontrola_bomby(id)
{
	if (!is_user_connected(id))
	{
		client_print(id, print_chat, "[G/L ZP] Nemozes si kupit bombu lebo niesi uplne pripojeny.")
		return 0
	}	
	if (!is_user_alive(id))
	{
		client_print(id, print_chat, "[G/L ZP] Nemozes si kupit bombu lebo si mrtvy.")
		return 0
	}	
	if(zp_is_survivor_round()) {
		client_print(id, print_chat, "[G/L ZP] V tomto kole nemozes si kupit bombu.")
		return 0
	}	
	if(zp_is_nemesis_round()) {
		client_print(id, print_chat, "[G/L ZP] V tomto kole nemozes si kupit bombu.")
		return 0
	}
	if(zp_get_user_zombie(id)) {
		client_print(id, print_chat, "[G/L ZP] Nemozes si kupit bombu lebo si zombie.")
		return 0
	}

	return 1
}
stock daj_bombu(id)
{	
	hrac_ma_bombu[id] = true 
	fm_give_item(id, "weapon_c4")

	return PLUGIN_CONTINUE
}
stock fm_give_item(index, const item[]) 
{
	new ent = fm_create_entity(item)
	if (!pev_valid(ent))
		return 0

	new Float:origin[3]
	pev(index, pev_origin, origin)
	set_pev(ent, pev_origin, origin)
	set_pev(ent, pev_spawnflags, pev(ent, pev_spawnflags) | SF_NORESPAWN)
	dllfunc(DLLFunc_Spawn, ent)

	new save = pev(ent, pev_solid)
	dllfunc(DLLFunc_Touch, ent, index)
	if (pev(ent, pev_solid) != save)
		return ent

	engfunc(EngFunc_RemoveEntity, ent)

	return -1
}
public switchmodel(id)
{
	if ( !is_user_alive(id) || !hrac_ma_bombu[id]  ) return
	
	new clip, ammo, zbran = get_user_weapon(id, clip, ammo)
	if (zbran == CSW_C4) {
		Entvars_Set_String(id, EV_SZ_viewmodel, V_MODEL)
	
	}
}
public weaponChange(id)
{
	if ( !hrac_ma_bombu[id] ) return

	//new clip, ammo, wpnid = get_user_weapon(id,clip,ammo)
	new zbran = read_data(2)
	if ( zbran == CSW_C4 ) switchmodel(id)
}
//
// Ak klikni ,co sa stane.....
//
public ak_klikne(id, uc_handle, seed)
{	
	if ( !is_user_alive(id) || !hrac_ma_bombu[id] )
		return	
					
	static cmd,type

	if ( get_user_weapon(id, cmd, type) != CSW_C4 )
		return
	
	if ( (cmd = get_uc(uc_handle, UC_Buttons)) & IN_ATTACK )
	{
		cmd &= ~IN_ATTACK
		set_uc(uc_handle, UC_Buttons, cmd)

		if(zp_get_user_zombie(id)) {
			client_print(id, print_chat, "[G/L ZP] Nemozes pouzit BOMBU lebo si zombie.")
			return	
		}	
		if(bomba_sa_pouziva) {
			client_print(id, print_chat, "[G/L ZP] Nemozes pouzit BOMBU lebo ju uz niekto pouziva.")
			return	
		}	
		vytvor_nacitanie(id)
		hrac_ma_bombu[id] = false
		return
	}
}
stock vytvor_nacitanie(id)
{
	message_begin( MSG_ONE, 108, {0,0,0}, id );
	write_byte(1); 	// cas
	write_byte(0);
	message_end();

	set_task(1.2, "spawn_bombu", id);
	return PLUGIN_CONTINUE;
}
public spawn_bombu(id)
{
	new Float:vektor[3]
	entity_get_vector(id, EV_VEC_origin, vektor)
	bomba_sa_pouziva = create_entity("info_target");
	//vector[2] = vector[2] + 10.0
	
	// Vlastnosti
	entity_set_origin(bomba_sa_pouziva, vektor);
	entity_set_string(bomba_sa_pouziva, EV_SZ_classname, ENT_CLASS_NAME)
	entity_set_model(bomba_sa_pouziva, P_MODEL)
	entity_set_float(bomba_sa_pouziva, EV_FL_renderamt, 100.0)
	entity_set_int(bomba_sa_pouziva, EV_INT_effects, 32);
	entity_set_int(bomba_sa_pouziva, EV_INT_solid, SOLID_TRIGGER);
	entity_set_int(bomba_sa_pouziva, EV_INT_movetype, MOVETYPE_TOSS);
	entity_set_int(bomba_sa_pouziva, EV_INT_renderfx, kRenderFxGlowShell)
	entity_set_int(bomba_sa_pouziva, EV_INT_rendermode, kRenderNormal)
	set_pev(bomba_sa_pouziva, OWNER, id);
	set_pev(bomba_sa_pouziva, pev_health, 10000.0);
	// Akcia
	set_task(0.1, "tahaj_hracov", TASK_TAHAJ, _, _, "b")
	engclient_cmd(id, "drop", "weapon_c4")
	bomba_proccess()
}
public bomba_proccess()
{
// Pocitame
	//client_print(0, print_chat, "process")	// log
	new Float:CAS = float(get_pcvar_num(cvar_cas))
	
	if(pocet > CAS)	{								//100%
		vybuch_bomby()
	} else if ( pocet > CAS * 0.8) {				// 80%
		pocet = pocet + 0.3
		set_task(0.3, "bomba_proccess", TASK_BOMB)	
	} else if ( pocet > CAS * 0.6) {				// 66%
		pocet = pocet + 0.5
		set_task(0.5, "bomba_proccess", TASK_BOMB)
	} else if ( pocet > CAS * 0.3) { 				// 33%		
		pocet = pocet + 1.0
		set_task(1.0, "bomba_proccess", TASK_BOMB)
	} else {										// 0%
		pocet = pocet + 3.0
		set_task(3.0, "bomba_proccess", TASK_BOMB)
	}	
// Zvuk
	emit_sound(bomba_sa_pouziva, CHAN_ITEM, zvuk, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
// Efeky
	efekt_sprite()
	
	return PLUGIN_CONTINUE
}
public tahaj_hracov()
{	
	new Float:bomba_vektor[3], num_bomba_vektor[3], obet_vektor[3], vzdialenost, Float:cas
	entity_get_vector(bomba_sa_pouziva, EV_VEC_origin, bomba_vektor)
	FVecIVec(bomba_vektor, num_bomba_vektor);
	
	new players[32], playerCount, victim
	get_players(players, playerCount, "ah")
	
	for ( new i = 0; i < playerCount; i++ ) {
		victim = players[i]
		if( is_user_alive(victim))
		{
			if(zp_get_user_zombie(victim) || zp_get_user_nemesis(victim))
			{
				get_user_origin(victim, obet_vektor)
				vzdialenost = get_distance(num_bomba_vektor, obet_vektor)

				if ( vzdialenost < 1000 ) {
					cas = vzdialenost / SPEED

					obet_vektor[0] = (num_bomba_vektor[0] - obet_vektor[0]) / cas
					obet_vektor[1] = (num_bomba_vektor[1] - obet_vektor[1]) / cas
					obet_vektor[2] = (num_bomba_vektor[2] - obet_vektor[2]) / cas
					Entvars_Set_Vector(victim, EV_VEC_velocity, obet_vektor)
					//client_print(0, print_chat, "tahaj")	// log
				}
			}
		}
	}
}	
stock efekt_sprite()
{
	new Float:bomba_vektor[3]
	entity_get_vector(bomba_sa_pouziva, EV_VEC_origin, bomba_vektor)
	
	//Create origin variable
	new origin[3];
	
	//Make float origins from integer origins
	FVecIVec(bomba_vektor,origin);
	
	//Get blast color
	new Float:rgbF[3], rgb[3];
	rgb[0] =255
	rgb[1] =0
	rgb[2] =0
	
	//Finally create blast
	
	//smallest ring
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY);
	write_byte(TE_BEAMCYLINDER);
	write_coord(origin[0]);
	write_coord(origin[1]);
	write_coord(origin[2]);
	write_coord(origin[0]);
	write_coord(origin[1]);
	write_coord(origin[2] + 385);
	write_short(sprFlare6);
	write_byte(0);
	write_byte(0);
	write_byte(4);
	write_byte(60);
	write_byte(0);
	write_byte(rgb[0]);
	write_byte(rgb[1]);
	write_byte(rgb[2]);
	write_byte(100);
	write_byte(0);
	message_end();
	
	// medium ring
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY);
	write_byte(TE_BEAMCYLINDER);
	write_coord(origin[0]);
	write_coord(origin[1]);
	write_coord(origin[2]);
	write_coord(origin[0]);
	write_coord(origin[1]);
	write_coord(origin[2] + 470);
	write_short(sprFlare6);
	write_byte(0);
	write_byte(0);
	write_byte(4);
	write_byte(60);
	write_byte(0);
	write_byte(rgb[0]);
	write_byte(rgb[1]);
	write_byte(rgb[2]);
	write_byte(100);
	write_byte(0);
	message_end();

	// largest ring
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY);
	write_byte(TE_BEAMCYLINDER);
	write_coord(origin[0]);
	write_coord(origin[1]);
	write_coord(origin[2]);
	write_coord(origin[0]);
	write_coord(origin[1]);
	write_coord(origin[2] + 555);
	write_short(sprFlare6);
	write_byte(0);
	write_byte(0);
	write_byte(4);
	write_byte(60);
	write_byte(0);
	write_byte(rgb[0]);
	write_byte(rgb[1]);
	write_byte(rgb[2]);
	write_byte(100);
	write_byte(0);
	message_end();
	
	//Create nice light effect
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY);
	write_byte(TE_DLIGHT);
	write_coord(origin[0]);
	write_coord(origin[1]);
	write_coord(origin[2]);
	write_byte(floatround(240.0/5.0));
	write_byte(rgb[0]);
	write_byte(rgb[1]);
	write_byte(rgb[2]);
	write_byte(8);
	write_byte(60);
	message_end();
}
stock triast_obrazovku(id, Float:amplitude, Float:duration, Float:frequency)
{
	if ( !is_user_connected(id) ) return 0;

	new amp, dura, freq;
	amp = clamp(floatround(amplitude * float(1<<12)), 0, 0xFFFF);
	dura = clamp(floatround(duration * float(1<<12)), 0, 0xFFFF);
	freq = clamp(floatround(frequency * float(1<<8)), 0, 0xFFFF);

	message_begin(MSG_ONE_UNRELIABLE, msgScreenShake, _, id);
	write_short(amp);	// amplitude
	write_short(dura);	// duration
	write_short(freq);	// frequency
	message_end();
	return 1;
}
stock vybuch_bomby()
{
// Misc
	remove_task(TASK_TAHAJ)
// zvuk
	engfunc(EngFunc_EmitSound, bomba_sa_pouziva, CHAN_WEAPON, vybuch, 1.0, ATTN_NORM, 0, PITCH_NORM)
//explozia efekt
	new Float:bomba_vektor[3]
	entity_get_vector(bomba_sa_pouziva, EV_VEC_origin, bomba_vektor)
	explode_effect(bomba_vektor)
// explozia akcia
	CreateDamage()
// Cvar	
	pocet = 0.0
	RemoveEntity(bomba_sa_pouziva);
	bomba_sa_pouziva = 0
}
stock explode_effect(Float:vec1[3])
{
	// blast circles
	engfunc(EngFunc_MessageBegin, MSG_BROADCAST, SVC_TEMPENTITY, vec1, 0)
	write_byte(TE_BEAMCYLINDER)	// 21
	engfunc(EngFunc_WriteCoord, vec1[0])
	engfunc(EngFunc_WriteCoord, vec1[1])
	engfunc(EngFunc_WriteCoord, vec1[2] + 16)
	engfunc(EngFunc_WriteCoord, vec1[0])
	engfunc(EngFunc_WriteCoord, vec1[1])
	engfunc(EngFunc_WriteCoord, vec1[2] + 1936)
	write_short(gSpriteWhite)
	write_byte(0)		// startframe
	write_byte(0)		// framerate
	write_byte(2)		// life
	write_byte(20)		// width
	write_byte(0)		// noise
	write_byte(188)		// r
	write_byte(220)		// g
	write_byte(255)		// b
	write_byte(255)		// brightness
	write_byte(0)		// speed
	message_end()

	// Explosion2
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_EXPLOSION2)	// 12
	engfunc(EngFunc_WriteCoord, vec1[0])
	engfunc(EngFunc_WriteCoord, vec1[1])
	engfunc(EngFunc_WriteCoord, vec1[2])
	write_byte(188)		// scale in 0.1's
	write_byte(10)		// framerate
	message_end()

	// Explosion
	engfunc(EngFunc_MessageBegin, MSG_BROADCAST, SVC_TEMPENTITY, vec1, 0)
	write_byte(TE_EXPLOSION)	// 3
	engfunc(EngFunc_WriteCoord, vec1[0])
	engfunc(EngFunc_WriteCoord, vec1[1])
	engfunc(EngFunc_WriteCoord, vec1[2])
	write_short(gSpriteFire)
	write_byte(60)		// scale in 0.1's
	write_byte(10)		// framerate
	write_byte(TE_EXPLFLAG_NONE)		// flags
	message_end()

	// Smoke
	engfunc(EngFunc_MessageBegin, MSG_BROADCAST, SVC_TEMPENTITY, vec1, 0)
	write_byte(TE_SMOKE)		// 5
	engfunc(EngFunc_WriteCoord, vec1[0])
	engfunc(EngFunc_WriteCoord, vec1[1])
	engfunc(EngFunc_WriteCoord, vec1[2])
	write_short(gSpriteSmoke)
	write_byte(10)		// scale in 0.1's
	write_byte(10)		// framerate
	message_end()
}
stock CreateDamage()
{
	new iCurrent 		= 	bomba_sa_pouziva
	new Float:T_DmgMAX 	= 	T_DAMAGE
	new Float:CT_DmgMAX = 	CT_DAMAGE
	new Float:Radius 	= 	RADIUS
	new bodov_cvar 		=	get_cvar_num("zp_human_damage_reward")
	// Get given parameters	
	new Float:vecSrc[3];
	pev(iCurrent, pev_origin, vecSrc);

	new AtkID =pev(iCurrent,OWNER);

	new ent = -1;
	new Float:tmpdmg = T_DmgMAX;

	new Float:kickback = 0.0;
	
	// Needed for doing some nice calculations :P
	new Float:Tabsmin[3], Float:Tabsmax[3];
	new Float:vecSpot[3];
	new Float:Aabsmin[3], Float:Aabsmax[3];
	new Float:vecSee[3];
	new trRes;
	new Float:flFraction;
	new Float:vecEndPos[3];
	new Float:distance;
	new Float:origin[3], Float:vecPush[3];
	new Float:invlen;
	new Float:velocity[3];
	new iHitHP;
	// Calculate falloff
	new Float:falloff, Float:falloff_T, Float:falloff_CT;
	if (Radius > 0.0)
	{
		falloff_T = T_DmgMAX / Radius;
		falloff_CT = CT_DmgMAX / Radius;
	} else {
		falloff_T = 1.0;
		falloff_CT = 1.0;
	}
	new classname[32]
	new bodov
	
	// Find monsters and players inside a specifiec radius
	while((ent = engfunc(EngFunc_FindEntityInSphere, ent, vecSrc, Radius)) != 0)
	{
		if(!pev_valid(ent)) continue;
		if(!(pev(ent, pev_flags) & (FL_CLIENT | FL_FAKECLIENT | FL_MONSTER)))
		{
			/*
			// Dalsi barel moze byt - vybuch sa siri dalej
			pev(ent, pev_classname, classname, sizeof classname - 1 )
			//client_print(0, print_chat, "hladam entity %s", classname)	// log
			if ( equal(classname, "amxx_barel") )
			{
				//client_print(0, print_chat, "najdena entita" )	// log
				set_task(random_float(0.5,1.5), "task_vybuchu_dalseho", ent)		
			}
			// Entity is not a player or monster, ignore it
			// Entity is not a player or monster, ignore it*/
			continue;
		}
		if(!pev_user_alive(ent)) continue;
		// Reset data
		kickback = 1.0;
		if(zp_get_user_zombie(ent))
		{
			tmpdmg = T_DmgMAX;
			falloff = falloff_T
		} else {
			tmpdmg = CT_DmgMAX;
			falloff = falloff_CT
		}
		
		// The following calculations are provided by Orangutanz, THANKS!
		// We use absmin and absmax for the most accurate information
		pev(ent, pev_absmin, Tabsmin);
		pev(ent, pev_absmax, Tabsmax);
		xs_vec_add(Tabsmin,Tabsmax,Tabsmin);
		xs_vec_mul_scalar(Tabsmin,0.5,vecSpot);
		
		pev(iCurrent, pev_absmin, Aabsmin);
		pev(iCurrent, pev_absmax, Aabsmax);
		xs_vec_add(Aabsmin,Aabsmax,Aabsmin);
		xs_vec_mul_scalar(Aabsmin,0.5,vecSee);
		
		engfunc(EngFunc_TraceLine, vecSee, vecSpot, 0, iCurrent, trRes);
		get_tr2(trRes, TR_flFraction, flFraction);
		// Explosion can 'see' this entity, so hurt them! (or impact through objects has been enabled xD)
		if (flFraction >= 0.9 || get_tr2(trRes, TR_pHit) == ent)
		{
			// Work out the distance between impact and entity
			get_tr2(trRes, TR_vecEndPos, vecEndPos);
			
			distance = get_distance_f(vecSrc, vecEndPos) * falloff;
			tmpdmg -= distance;
			if(tmpdmg < 0.0)
				tmpdmg = 0.0;
			
			// Kickback Effect
			if(kickback != 0.0)
			{
				xs_vec_sub(vecSpot,vecSee,origin);
				
				invlen = 1.0/get_distance_f(vecSpot, vecSee);

				xs_vec_mul_scalar(origin,invlen,vecPush);
				pev(ent, pev_velocity, velocity)
				xs_vec_mul_scalar(vecPush,tmpdmg,vecPush);
				xs_vec_mul_scalar(vecPush,kickback,vecPush);
				xs_vec_add(velocity,vecPush,velocity);
				
				if(tmpdmg < 60.0)
				{
					xs_vec_mul_scalar(velocity,12.0,velocity);
				} else {
					xs_vec_mul_scalar(velocity,4.0,velocity);
				}
				
				if(velocity[0] != 0.0 || velocity[1] != 0.0 || velocity[2] != 0.0)
				{
					// There's some movement todo :)
					set_pev(ent, pev_velocity, velocity)
				}
			}
											
			iHitHP = pev_user_health(ent) - floatround(tmpdmg)		
			if(iHitHP <= 0)
			{
				bodov = floatround(pev_user_health(ent) / float(bodov_cvar))
				set_score(AtkID,ent,1,iHitHP)
			} else {
					bodov = floatround(tmpdmg / float(bodov_cvar))
					//set_pev(Player,pev_health,iHitHP)
					triast_obrazovku(ent, 30.0, 6.0, 4.0)
					set_user_health(ent, iHitHP)
					engfunc(EngFunc_MessageBegin,MSG_ONE_UNRELIABLE,g_msgDamage,{0.0,0.0,0.0},ent);
					write_byte(floatround(tmpdmg))
					write_byte(floatround(tmpdmg))
					write_long(DMG_BULLET)
					engfunc(EngFunc_WriteCoord,vecSrc[0])
					engfunc(EngFunc_WriteCoord,vecSrc[1])
					engfunc(EngFunc_WriteCoord,vecSrc[2])
					message_end()
			}	
			if(bodov < 0)
			{
				bodov = 0
			}
			zp_set_user_ammo_packs(AtkID, zp_get_user_ammo_packs(AtkID) + bodov)
			//client_print(0, print_chat, "%d %d")	// log
		}
	}
	
	return
}
public task_vybuchu_dalseho(ent)
{
	set_pev(ent,pev_health, 30.0);
}
stock bool:pev_user_alive(ent)
{
	new deadflag = pev(ent,pev_deadflag);
	if(deadflag != DEAD_NO)
		return false;
	return true;
}
stock pev_user_health(id)
{
	new Float:health
	pev(id,pev_health,health)
	return floatround(health)
}
stock set_score(id,target,hitscore,HP){

	new idfrags = pev_user_frags(id) + hitscore// get_user_frags(id) + hitscore	
	set_user_frags(id,idfrags)
	//set_user_frags(id, idfrags)
	//entity_set_float(id, EV_FL_frags, float(idfrags))
	
	new tarfrags = pev_user_frags(target) + 1 //get_user_frags(target) + 1
	set_user_frags(target,tarfrags)
	//set_user_frags(target,tarfrags)
	//entity_set_float(target, EV_FL_frags, float(tarfrags))
	
	new idteam = int:cs_get_user_team(id)
	new iddeaths = cs_get_user_deaths(id)


	message_begin(MSG_ALL, g_msgDeathMsg, {0, 0, 0} ,0)
	write_byte(id)
	write_byte(target)
	write_byte(0)
	write_string(ENT_CLASS_NAME)
	message_end()

	message_begin(MSG_ALL, g_msgScoreInfo)
	write_byte(id)
	write_short(idfrags)
	write_short(iddeaths)
	write_short(0)
	write_short(idteam)
	message_end()

	set_msg_block(g_msgDeathMsg, BLOCK_ONCE)

	//entity_set_float(target, EV_FL_health,float(HP))
	set_user_health(target, HP)
	//set_pev(target,pev_health,HP)

}/*
stock set_user_frags(index, frags)
{
	set_pev(index, pev_frags, float(frags))

	return 1
}*/

stock pev_user_frags(index)
{
	new Float:frags;
	pev(index,pev_frags,frags);
	return floatround(frags);
}






//
//
//
//			 Efekty
//
//
//
//








fx_extra_blood(origin[3])
{
	new x, y, z

	for(new i = 0; i < 3; i++) {
		x = random_num(-15,15)
		y = random_num(-15,15)
		z = random_num(-20,25)
		for(new j = 0; j < 2; j++) {
			message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
			write_byte(TE_BLOODSPRITE)
			write_coord(origin[0]+(x*j))
			write_coord(origin[1]+(y*j))
			write_coord(origin[2]+(z*j))
			write_short(spr_blood_spray)
			write_short(spr_blood_drop)
			write_byte(BLOOD_COLOR_RED) // color index
			write_byte(15) // size
			message_end()
		}
	}
}

fx_headshot(origin[3])
{
	new iFlags = get_gore_flags()

	new Sprays = 1

	if (iFlags&GORE_EXTRA || iFlags&GORE_EXTRA_HS) {
		if (equali(mod_name,"dod"))	Sprays = 4
		else 					Sprays = 8
	}

	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(TE_BLOODSPRITE)
	write_coord(origin[0])
	write_coord(origin[1])
	write_coord(origin[2]+40)
	write_short(spr_blood_spray)
	write_short(spr_blood_drop)
	write_byte(BLOOD_COLOR_RED) // color index
	write_byte(15) // size
	message_end()

	// Blood sprays
	for (new i = 0; i < Sprays; i++) {
		message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
		write_byte(TE_BLOODSTREAM)
		write_coord(origin[0])
		write_coord(origin[1])
		write_coord(origin[2]+40)
		write_coord(random_num(-30,30)) // x
		write_coord(random_num(-30,30)) // y
		write_coord(random_num(80,300)) // z
		write_byte(BLOOD_STREAM_RED) // color
		write_byte(random_num(100,200)) // speed
		message_end()
	}
}
fx_blood(origin[3],origin2[3],HitPlace)
{
	//Crash Checks
	if (HitPlace < 0 || HitPlace > 7) HitPlace = 0
	new rDistance = get_distance(origin,origin2) ? get_distance(origin,origin2) : 1

	new rX = ((origin[0]-origin2[0]) * 300) / rDistance
	new rY = ((origin[1]-origin2[1]) * 300) / rDistance
	new rZ = ((origin[2]-origin2[2]) * 300) / rDistance

	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(TE_BLOODSTREAM)
	write_coord(origin[0]+Offset[HitPlace][0])
	write_coord(origin[1]+Offset[HitPlace][1])
	write_coord(origin[2]+Offset[HitPlace][2])
	write_coord(rX) // x
	write_coord(rY) // y
	write_coord(rZ) // z
	write_byte(BLOOD_STREAM_RED) // color
	write_byte(random_num(100,200)) // speed
	message_end()
}

fx_bleed(origin[3])
{
	// Blood spray
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(TE_BLOODSTREAM)
	write_coord(origin[0])
	write_coord(origin[1])
	write_coord(origin[2]+10)
	write_coord(random_num(-360,360)) // x
	write_coord(random_num(-360,360)) // y
	write_coord(-10) // z
	write_byte(BLOOD_STREAM_RED) // color
	write_byte(random_num(50,100)) // speed
	message_end()
}

fx_blood_small(origin[3],num)
{
	if (equali(mod_name,"esf")) return

	// Write Small splash decal
	for (new j = 0; j < num; j++) {
		message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
		write_byte(TE_WORLDDECAL)
		write_coord(origin[0]+random_num(-100,100))
		write_coord(origin[1]+random_num(-100,100))
		write_coord(origin[2]-36)
		write_byte(blood_small_red[random_num(0,BLOOD_SM_NUM - 1)]) // index
		message_end()
	}
}

fx_blood_large(origin[3],num)
{
	if (equali(mod_name,"esf")) return

	// Write Large splash decal
	for (new i = 0; i < num; i++) {
		message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
		write_byte(TE_WORLDDECAL)
		write_coord(origin[0]+random_num(-50,50))
		write_coord(origin[1]+random_num(-50,50))
		write_coord(origin[2]-36)
		write_byte(blood_large_red[random_num(0,BLOOD_LG_NUM - 1)]) // index
		message_end()
	}
}

fx_gib_explode(origin[3],origin2[3])
{
	new flesh[2]
	flesh[0] = mdl_gib_flesh
	flesh[1] = mdl_gib_meat
	new mult, gibtime = 400 //40 seconds

	if (equali(mod_name,"esf"))		mult = 400
	else if (equali(mod_name,"ts"))	mult = 140
	else							mult = 80

	new rDistance = get_distance(origin,origin2) ? get_distance(origin,origin2) : 1
	new rX = ((origin[0]-origin2[0]) * mult) / rDistance
	new rY = ((origin[1]-origin2[1]) * mult) / rDistance
	new rZ = ((origin[2]-origin2[2]) * mult) / rDistance
	new rXm = rX >= 0 ? 1 : -1
	new rYm = rY >= 0 ? 1 : -1
	new rZm = rZ >= 0 ? 1 : -1

	// Gib explosions

	// Head
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(TE_MODEL)
	write_coord(origin[0])
	write_coord(origin[1])
	write_coord(origin[2]+40)
	write_coord(rX + (rXm * random_num(0,80)))
	write_coord(rY + (rYm * random_num(0,80)))
	write_coord(rZ + (rZm * random_num(80,200)))
	write_angle(random_num(0,360))
	write_short(mdl_gib_head)
	write_byte(0) // bounce
	write_byte(gibtime) // life
	message_end()

	// Parts
	for(new i = 0; i < 4; i++) {
		message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
		write_byte(TE_MODEL)
		write_coord(origin[0])
		write_coord(origin[1])
		write_coord(origin[2])
		write_coord(rX + (rXm * random_num(0,80)))
		write_coord(rY + (rYm * random_num(0,80)))
		write_coord(rZ + (rZm * random_num(80,200)))
		write_angle(random_num(0,360))
		write_short(flesh[random_num(0,1)])
		write_byte(0) // bounce
		write_byte(gibtime) // life
		message_end()
	}

	if (!equali(mod_name,"dod")) {

		// Spine
		message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
		write_byte(TE_MODEL)
		write_coord(origin[0])
		write_coord(origin[1])
		write_coord(origin[2]+30)
		write_coord(rX + (rXm * random_num(0,80)))
		write_coord(rY + (rYm * random_num(0,80)))
		write_coord(rZ + (rZm * random_num(80,200)))
		write_angle(random_num(0,360))
		write_short(mdl_gib_spine)
		write_byte(0) // bounce
		write_byte(gibtime) // life
		message_end()

		// Lung
		for(new i = 0; i <= 1; i++) {
			message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
			write_byte(TE_MODEL)
			write_coord(origin[0])
			write_coord(origin[1])
			write_coord(origin[2]+10)
			write_coord(rX + (rXm * random_num(0,80)))
			write_coord(rY + (rYm * random_num(0,80)))
			write_coord(rZ + (rZm * random_num(80,200)))
			write_angle(random_num(0,360))
			write_short(mdl_gib_lung)
			write_byte(0) // bounce
			write_byte(gibtime) // life
			message_end()
		}

		//Legs
		for(new i = 0; i <= 1; i++) {
			message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
			write_byte(TE_MODEL)
			write_coord(origin[0])
			write_coord(origin[1])
			write_coord(origin[2]-10)
			write_coord(rX + (rXm * random_num(0,80)))
			write_coord(rY + (rYm * random_num(0,80)))
			write_coord(rZ + (rZm * random_num(80,200)))
			write_angle(random_num(0,360))
			write_short(mdl_gib_legbone)
			write_byte(0) // bounce
			write_byte(gibtime) // life
			message_end()
		}
	}

	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(TE_BLOODSPRITE)
	write_coord(origin[0])
	write_coord(origin[1])
	write_coord(origin[2]+20)
	write_short(spr_blood_spray)
	write_short(spr_blood_drop)
	write_byte(BLOOD_COLOR_RED) // color index
	write_byte(10) // size
	message_end()
}
/*
#define fm_precache_model(%1) 		engfunc(EngFunc_PrecacheModel,%1)
#define fm_precache_sound(%1) 		engfunc(EngFunc_PrecacheSound,%1)
#define fm_remove_entity(%1) 		engfunc(EngFunc_RemoveEntity, %1)
#define fm_drop_to_floor(%1) 		engfunc(EngFunc_DropToFloor,%1)
#define fm_find_ent_by_class(%1,%2) 	engfunc(EngFunc_FindEntityByString, %1, "classname", %2)
#define fm_set_user_gravity(%1,%2) 	set_pev(%1,pev_gravity,%2)
*/