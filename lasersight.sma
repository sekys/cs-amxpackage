#include <amxmodx>
#include <fakemeta_util>
#include <zombieplague>
#include <xs>

#define BEAM_ENTPOINT	1

new g_sniperid, laserbodka, laser_mod[33], 
	maxplayers, laser_ent[33], beamSprIndex
/*
	Mod :
	-2 nema laser
	-1 ziadna farba
	0 cervena
	1 modra
	2 zelena
*/
static const cena = 4;
static const Float:vlastnosti[][3] = 
{ 	//hore doprava sirka farba
	{7.0, 8.0, 2.0 }, // primary
	{5.0, 6.0, 1.0 }, // secondary 
	{5.0, 6.0, 1.0 }
};
static const Float:farba[][3] = 
{ 	//hore doprava sirka farba
	{255.0, 45.0, 10.0}, // primary
	{0.0, 60.0, 231.0 }, // secondary 
	{0.0, 0.0, 255.0 }
};
static const beamSprName[]	= "sprites/laserbeam.spr";

public plugin_init()
{
	register_plugin("[ZP] Laser", "1.0", "Seky");
	register_event("CurWeapon", "vybera_zbran", "be", "1=1")
	register_forward(FM_PlayerPreThink, "player_prethink");
	register_forward(FM_ClientConnect, "client_connect");
	g_sniperid = zp_register_extra_item("Laser", cena, ZP_TEAM_HUMAN)
	maxplayers = get_maxplayers();
}

public plugin_precache()
{
	beamSprIndex = precache_model(beamSprName);
	laserbodka	= precache_model("sprites/dot.spr");
}
public zp_extra_item_selected(id, itemid)
{
	if (itemid == g_sniperid) {
		if(laser_mod[id] != -2) {
			vrat_body(id, cena)
		} else {
			laser_mod[id] = 0;
			beam_create(id);
		}
	}
	return PLUGIN_CONTINUE;
}
public zp_round_ended(winteam)
{
	for(new i = 1; i <= maxplayers; i++) {		
		if(!is_user_alive(i)) continue;	
		if(laser_mod[i] != -2)	{
			beam_remove(i)
		}
	}
	return PLUGIN_CONTINUE;
}
/*
public zp_round_started(gamemode, id) 
{	
	for(new i = 1; i <= maxplayers; i++) {		
		if(!is_user_alive(i))
			continue;
			
		if(laser_mod[i] != -2)	{
			beam_create(i);
		}
	}
	return PLUGIN_CONTINUE;
}
*/
stock vrat_body(const id, kolko)
{
	if(get_user_flags(id) & ADMIN_LEVEL_F ) {
		kolko = floatround( float(kolko) * 0.5 , floatround_floor );	
	}
	zp_set_user_ammo_packs(id,zp_get_user_ammo_packs(id) +  kolko)
}

// Show laser sight
public player_prethink(id)
{	
	if(laser_mod[id] == -2)  return PLUGIN_CONTINUE;
	if(!is_user_alive(id) || zp_get_user_zombie(id) || laser_mod[id] == -1 ) {
		beam_remove(id)
		return PLUGIN_CONTINUE;
	}		
	if(!laser_ent[id]) {
		beam_create(id)
	}
		
	static Float:v_angle[3], Float:origin[3], Float:view_ofs[3], Float:weaponOrigin[3],
	Float:v_forward[3], Float:endPosition[3], Float:mins[3], Float:maxs[3];
	
	// get gun position
	pev(id, pev_origin, origin);
	pev(id, pev_view_ofs, view_ofs);
	xs_vec_add(origin, view_ofs, weaponOrigin);
	
	// gun in wall
	if(engfunc(EngFunc_PointContents,weaponOrigin) == CONTENTS_SOLID) endPosition = weaponOrigin;
	else
	{
		// make direction vectors
		pev(id, pev_v_angle, v_angle);
		engfunc(EngFunc_MakeVectors,v_angle);
		
		// get 8192.0 units forward of gun position
		global_get(glb_v_forward, v_forward);
		xs_vec_mul_scalar(v_forward, 8192.0, v_forward);
		xs_vec_add(weaponOrigin, v_forward, endPosition);

		// trace line from start to end
		engfunc(EngFunc_TraceLine, weaponOrigin, endPosition, DONT_IGNORE_MONSTERS, id, 0);
		get_tr2(0, TR_vecEndPos, endPosition);
	}

	// calculate mins and maxs
	for(new i=0;i<3;i++) {
		mins[i] = floatmin(endPosition[i],origin[i]) - endPosition[i];
		maxs[i] = floatmax(endPosition[i],origin[i]) - endPosition[i];
	}
	engfunc(EngFunc_SetSize, laser_ent[id], mins, maxs);
	engfunc(EngFunc_SetOrigin, laser_ent[id], endPosition);
	/*client_print(0, print_chat, "__%d %f %f %f ", laser_mod[id], 
	endPosition[0], endPosition[1] , endPosition[2]
	) //log*/
	set_pev(laser_ent[id], pev_scale, vlastnosti[laser_mod[id]][2] )// vlastnosti[laser_mod[id]][2] / 10.0 );
	set_pev(laser_ent[id], pev_rendercolor, farba[laser_mod[id]]);
		
	return PLUGIN_CONTINUE;
}
public client_connect(id) {
	laser_mod[id] = -2;
}
public vybera_zbran(const id) {
	if(laser_mod[id]==-2) return PLUGIN_CONTINUE	
	new WeaponID = read_data(2)
	
	switch(WeaponID) {
		case CSW_XM1014, CSW_MAC10, CSW_FAMAS, CSW_MP5NAVY, 
			 CSW_GALI, CSW_M249, CSW_M3, CSW_M4A1, CSW_TMP, CSW_AK47, 
			 CSW_P90 :  laser_mod[id] = 0;
			
		case CSW_ELITE, CSW_UMP45, CSW_USP, CSW_GLOCK18, CSW_DEAGLE, CSW_P228 :
			laser_mod[id] = 1; 
						
		default : laser_mod[id] = -1;	
	}
	return PLUGIN_CONTINUE
}
stock beam_create(id)
{
	new ent = engfunc(EngFunc_CreateNamedEntity,engfunc(EngFunc_AllocString, "beam"));

	set_pev(ent, pev_flags, pev(ent,pev_flags) | FL_CUSTOMENTITY);
	
	set_pev(ent, pev_body, 0); // noise
	set_pev(ent, pev_scale, 1.0 ); // ); // width
	set_pev(ent, pev_animtime, 30); // scroll rate
	set_pev(ent, pev_renderamt, 75.0); // brightness

	set_pev(ent, pev_rendercolor, farba[0]);
	
	set_pev(ent, pev_rendermode, BEAM_ENTPOINT&0x0F); // type
	set_pev(ent, pev_aiment, id); // set start point
	set_pev(ent, pev_skin,(id & 0x0FFF) | ((1/*iAttachment*/&0xF)<<12)); // set start attachment
		
	set_pev(ent, pev_model, engfunc(EngFunc_AllocString, beamSprName));
	set_pev(ent, pev_modelindex, beamSprIndex);
	
	laser_ent[id] = ent;
}
stock beam_remove(id)
{
	if(pev_valid(laser_ent[id])) {
		set_pev(laser_ent[id], pev_flags, pev(laser_ent[id],pev_flags) | FL_KILLME);
	}
	laser_ent[id] = 0;
}