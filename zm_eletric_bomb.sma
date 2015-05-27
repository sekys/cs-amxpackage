#include <amxmodx>
#include <amxmisc> 
#include <zombieplague>
#include <fakemeta>
#include <hamsandwich>
#include <Vexd_Utilities>
#include <cstrike>
#include <engine>
#include <xs>

#define RemoveEntity(%1)	 engfunc(EngFunc_RemoveEntity,%1)
#define fm_create_entity(%1) engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, %1))

#define RADIUS 				100.0
#define DMG_HP 				30.0
#define PER_SECOND 			1.01
#define V_MODEL				"models/zombie_plague/v_pipe.mdl"
#define P_MODEL				"models/zombie_plague/p_pipe.mdl"
#define MODEL_SPRITE 		"sprites/spark1.spr" 
#define CENA				30
#define ENT_CLASS_NAME		"seky_ebomb"
#define UNIT_SECOND 		(1<<12) 

new const sound_elektro[] = "zombie_plague/electric_loop.wav"; //"zombie_plague/spark6.wav";
new menu_bomba,  bool:hrac_ma_bombu[33], bomba_sa_pouziva[2], 
	Float:pocet, g_msgScreenFade, ElectroSpr, bool:zasiahnuty[33],
	g_msgDeathMsg, g_msgScoreInfo, Float:casovac[33]

public plugin_init() {
	register_plugin("Electric Bomb", "1.0", "Seky")
	register_clcmd("amx_set_ebomb", "cmd_bomb", ADMIN_RCON, "-");	
	
	menu_bomba 		= zp_register_extra_item("Electric H2O Bomb ", CENA, ZP_TEAM_HUMAN)
	RegisterHam(Ham_Player_PreThink, "player", "plugin_PlayerPreThink", 1)
	register_event("CurWeapon", "weaponChange","be","1=1")
	g_msgScreenFade = get_user_msgid("ScreenFade")
	g_msgDeathMsg 	= get_user_msgid("DeathMsg");
	g_msgScoreInfo	= get_user_msgid("ScoreInfo");
}
public plugin_precache() {
	precache_model(V_MODEL)
	precache_model(P_MODEL)
	precache_sound(sound_elektro)
	ElectroSpr = precache_model(MODEL_SPRITE);
}
public cmd_bomb(id, level, cid) {
	if (!cmd_access(id,level,cid,1)) return PLUGIN_HANDLED
	return kontrola_bomby(id) ?  daj_bombu(id) : PLUGIN_CONTINUE;
}
public client_disconnect(id) { hrac_ma_bombu[id] = false; }
public zp_round_ended(winteam) {
	bomba_sa_pouziva[0] = 0;
	bomba_sa_pouziva[1] = 0;
	for ( new id = 0; id < 33; id++ ) {
		hrac_ma_bombu[id] = false;
		zasiahnuty[id] = false;
	}
}
public zp_extra_item_selected(id, itemid) {
	if (itemid != menu_bomba) return PLUGIN_HANDLED;
	static bodov;
	bodov = zp_get_user_ammo_packs(id)
	if(kontrola_bomby(id)) {
		if(hrac_ma_bombu[id]) {
			static i, iWeapon, iWeapons[32], zbran[32]
			get_user_weapons(id, iWeapons, i) 
			for(--i; i>=0; i--) {
				iWeapon = iWeapons[i];
				if (iWeapon == CSW_C4) {
					client_print(id, print_chat, "[G/L ZP] Uz mas bombu.")
					vrat_body(id,  CENA)
					return PLUGIN_HANDLED;
				}
			}
			daj_bombu(id)
		} else {	
			daj_bombu(id)
			//zp_set_user_ammo_packs(id,bodov - CENA)
		}
	} else {
		vrat_body(id,  CENA)
		return PLUGIN_HANDLED;
	}
}
stock vrat_body(id, kolko) {
	if(get_user_flags(id) & ADMIN_LEVEL_F ) {
		kolko = floatround( float(kolko) * 0.5 , floatround_floor );	
	}
	zp_set_user_ammo_packs(id,zp_get_user_ammo_packs(id) + kolko)
}
stock bool:kontrola_bomby(id) {
	if (!is_user_alive(id)) {
		client_print(id, print_chat, "[G/L ZP] Nemozes si kupit bombu lebo si mrtvy.")
		return false
	}	
	if(zp_is_survivor_round() || zp_is_nemesis_round()) {
		client_print(id, print_chat, "[G/L ZP] V tomto kole si nemozes kupit bombu.")
		return false
	}	
	if(zp_get_user_zombie(id)) {
		client_print(id, print_chat, "[G/L ZP] Nemozes si kupit bombu lebo si zombie.")
		return false
	}
	if(bomba_sa_pouziva[0]) {
		client_print(id, print_chat, "[G/L ZP] Nemozes kupit BOMBU, lebo ju uz niekto pouzil.")
		return false
	}
	return true
}
stock daj_bombu(id) {	
	hrac_ma_bombu[id] = true; 
	fm_give_item(id, "weapon_c4")
	return PLUGIN_CONTINUE
}
stock fm_give_item(index, const item[]) 
{
	new ent = fm_create_entity(item)
	if (!pev_valid(ent)) return 0;

	new Float:origin[3]
	pev(index, pev_origin, origin)
	set_pev(ent, pev_origin, origin)
	set_pev(ent, pev_spawnflags, pev(ent, pev_spawnflags) | SF_NORESPAWN)
	dllfunc(DLLFunc_Spawn, ent)

	new save = pev(ent, pev_solid)
	dllfunc(DLLFunc_Touch, ent, index)
	if (pev(ent, pev_solid) != save) return ent;
	engfunc(EngFunc_RemoveEntity, ent)
	return -1
}
public weaponChange(id) {
	if ( !hrac_ma_bombu[id]  ) return;
	if ( !is_user_alive(id) ) return;

	new zbran = read_data(2)
	if ( zbran == CSW_C4 ) {
		Entvars_Set_String(id, EV_SZ_viewmodel, V_MODEL)
	}	
}
stock ak_klikne(const id)
{	
	if ( !hrac_ma_bombu[id] ) return;		
					
	static cmd,type
	if ( get_user_weapon(id, cmd, type) != CSW_C4 ) return;
	
	if((pev(id, pev_button ) & IN_ATTACK) && !(pev(id, pev_oldbuttons ) & IN_ATTACK )) {				
		if(bomba_sa_pouziva[0]) {
			client_print(id, print_chat, "[G/L ZP] Nemozes pouzit BOMBU, lebo ju uz niekto pouzil.")
			hrac_ma_bombu[id] = false;
			return;	
		}	
		new data[2];
		data[0] = je_blizkovoda(id);
		if(!data[0]) {
			client_print(id, print_chat, "[G/L ZP] Musis stat pri vode ...")
			return;
		}		
		data[1] = id;
		vytvor_nacitanie(data);
		hrac_ma_bombu[id] = false;
	}
	return;
}
public zp_user_infected_post(id, infector) {		
	hrac_ma_bombu[id] = false;
	return PLUGIN_CONTINUE;
}

stock je_blizkovoda(id) {	
	static ent, Float:vecSrc[3], classname[33]
	pev(id, pev_origin, vecSrc);
	ent = -1
	while((ent = engfunc(EngFunc_FindEntityInSphere, ent, vecSrc, RADIUS)) != 0)
	{
		if(pev_valid(ent)) {
			pev(ent, pev_classname, classname, 32)
			if(equal(classname, "func_water")) {
				return ent;
			}
		}
	}
	return 0;
}
stock vytvor_nacitanie( const data[2]) {
	message_begin( MSG_ONE, 108, {0,0,0}, data[1] );
	write_byte(1); 	// cas
	write_byte(0);
	message_end();
	set_task(1.2, "spawn_bombu", _, data, 2);
	return PLUGIN_CONTINUE;
}
public spawn_bombu( data[2]) {
	/*
		0 - ent
		1 - id - majitel
	*/
	// Kontrola
	if(!is_user_alive(data[1]) || !pev_valid(data[0])) return
	
	// Kopirujeme potrebne udaje ....
	client_print(data[1], print_chat, "[G/L ZP] E-Bomba bola uspesne nastavena.")
	engclient_cmd(data[1], "drop", "weapon_c4")
	bomba_sa_pouziva[0] = data[0];
	bomba_sa_pouziva[1] = data[1];
	return;
}
public plugin_PlayerPreThink(const id)
{
	if(!is_user_alive(id)) return FMRES_IGNORED;
	// Este anstavenie bomby
	ak_klikne(id);
	// Pouzila sa bomba ?
	if(!bomba_sa_pouziva[0]) return FMRES_IGNORED;
	if(!bomba_think(id)) {
		zrus_glow(id);
	}
	return FMRES_IGNORED;
}
stock bomba_think(const id)
{
	// Spadol do vody ?
	if(!entity_get_int(id, EV_INT_waterlevel)) return 0;
	if(!user_ent_IsColliding( id, bomba_sa_pouziva[0]) ) return 0;
	zasah_bomby_ticrate(id);
	return 1;
}
stock zrus_glow(const id)
{
	// len ak bolo zapnute ...
	if(zasiahnuty[id]) {
		zasiahnuty[id] = false;
		fm_set_rendering(id);
	}
}
stock user_ent_IsColliding( user, entity)
{    
    static Float:abs_min[3], Float:abs_max[3];
    static Float:origin[3];
    
	pev(entity, pev_absmin, abs_min);
	pev(entity, pev_absmax, abs_max);	
	pev(user, pev_origin, origin);	

    if	( 
			(abs_min[0] < origin[0] && origin[0] < abs_max[0])
			&&
			(abs_min[1] < origin[1] && origin[1] < abs_max[1])
			&&
			(abs_min[2] < origin[2] && origin[2] < abs_max[2])
		) return 1;
    return 0;
}
stock zasah_bomby_ticrate(const id)
{
	static Float:origin[3]
	// Funkcie
	zasiahnuty[id] = true;
	pev(id, pev_origin, origin)	
	// Efekty
	ElectroEffect(id)
	ElectroRing(origin) 
	
	// Casovac pomocny ...
	if(get_gametime() - casovac[id] < PER_SECOND) {
		return PLUGIN_CONTINUE;
	}
	fm_set_rendering(id, kRenderFxGlowShell, 250, 250, 0, kRenderNormal, 25)
	casovac[id] = get_gametime();
	zasah_bomby(id);
	return PLUGIN_CONTINUE;
}
stock ElectroEffect(id)
{	
	message_begin(MSG_ONE_UNRELIABLE, g_msgScreenFade, _, id)
	write_short(UNIT_SECOND*1)
	write_short(UNIT_SECOND*1) 
	write_short(0x0000) 
	write_byte(255) 
	write_byte(255) 
	write_byte(0) 
	write_byte(100) 
	message_end()
}
stock ElectroRing(const Float:originF3[3])
{
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF3, 0)
	write_byte(TE_BEAMCYLINDER) 
	engfunc(EngFunc_WriteCoord, originF3[0]) 
	engfunc(EngFunc_WriteCoord, originF3[1]) 
	engfunc(EngFunc_WriteCoord, originF3[2]) 
	engfunc(EngFunc_WriteCoord, originF3[0])
	engfunc(EngFunc_WriteCoord, originF3[1]) 
	engfunc(EngFunc_WriteCoord, originF3[2]+100.0) 
	write_short(ElectroSpr) 
	write_byte(0)
	write_byte(0) 
	write_byte(4) 
	write_byte(60)
	write_byte(0) 
	write_byte(41) 
	write_byte(138) 
	write_byte(255) 
	write_byte(200)
	write_byte(0) 
	message_end()
}
stock fm_set_rendering(entity, fx = kRenderFxNone, r = 255, g = 255, b = 255, render = kRenderNormal, amount = 16)
{
	static Float:color[3]
	color[0] = float(r)
	color[1] = float(g)
	color[2] = float(b)
	set_pev(entity, pev_renderfx, fx)
	set_pev(entity, pev_rendercolor, color)
	set_pev(entity, pev_rendermode, render)
	set_pev(entity, pev_renderamt, float(amount))
}
stock zasah_bomby(const id)
{
	// Zasah bomby ale s casovacom ....
	engfunc(EngFunc_EmitSound, id, CHAN_AUTO, sound_elektro, 1.0, ATTN_NORM, 0, PITCH_NORM);
	sprav_dmg(id, DMG_HP);
}
stock sprav_dmg(const id, float:dmg) {
	// Zvladne to  ?
	static Float:hp
	pev(id, pev_health, hp);
	if(hp <= dmg) {
		set_score(bomba_sa_pouziva[1], id, 1)
	} else {				
		fakedamage(id, ENT_CLASS_NAME, dmg, 1024);
	}
}
stock set_score(const id, const target, const hitscore)
{
	if(!is_user_alive(id)) return PLUGIN_CONTINUE;
	
	static Float:frags;
	pev(id, pev_frags, frags);
	frags += float(hitscore);	
	zp_set_user_ammo_packs(id, zp_get_user_ammo_packs(id) + hitscore);
	set_pev(id, pev_frags, frags)
	
	message_begin(MSG_ALL, g_msgDeathMsg, {0, 0, 0} ,0)
	write_byte(id)
	write_byte(target)
	write_byte(0)
	write_string(ENT_CLASS_NAME)
	message_end()

	message_begin(MSG_ALL, g_msgScoreInfo)
	write_byte(id)
	write_short(floatround(frags))
	write_short(cs_get_user_deaths(id))
	write_short(0)
	write_short( int:cs_get_user_team(id) )
	message_end()

	set_msg_block(g_msgDeathMsg, BLOCK_ONCE)
	dllfunc(DLLFunc_ClientKill, target)
	return PLUGIN_CONTINUE;	
}