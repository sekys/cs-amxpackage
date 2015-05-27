#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <fakemeta>
#include <xs>
#include <zombieplague.inc>
#include <Vexd_Utilities>
#include <hamsandwich>

// The sizes of models
#define PALLET_MINS Float:{ -12.320000, -12.450000, 0.000000 }
#define PALLET_MAXS Float:{  12.960000, 12.450000, 42.770000 }
#define OWNER				pev_iuser2

#define RADIUS 		300.0	// vzdialenost tahania ale a aj zabijania
#define T_DAMAGE 	500.0	// kolko zoberie zombikom
#define CT_DAMAGE 	30.0	// kolko zoberie ct
#define B_DISTANCE 	600		//stavba

#define MIN_HP 		50		// hp vybuchu

// from fakemeta util by VEN
#define fm_find_ent_by_class(%1,%2) engfunc(EngFunc_FindEntityByString, %1, "classname", %2)
#define fm_remove_entity(%1) engfunc(EngFunc_RemoveEntity, %1)
// this is mine
#define fm_drop_to_floor(%1) engfunc(EngFunc_DropToFloor,%1)

// cvarG
new  maxpallets, phealth
new palletscout = 0;
new g_ExplosionMdl, g_SmokeMdl, g_msgDamage, g_msgDeathMsg, g_msgScoreInfo
new const g_models[][] =
{
	"models/zombie_plague/barel.mdl"
}

new const g_item_name[] = { "Barel" }
const g_item_bolsas = 4
new g_itemid_bolsas

public plugin_init() 
{

	register_plugin("[G/L ZP] Extra: SandBags", "1.2", "LARP")
	// register_clcmd("amx_set_barel", "cmd_barel", ADMIN_RCON, "-");
	// register_clcmd("amx_barel", "cmd_barel_user");

	g_itemid_bolsas = zp_register_extra_item(g_item_name, g_item_bolsas, ZP_TEAM_HUMAN)

	maxpallets = register_cvar("zp_barel_limit","30"); // max number of pallets with bags
	phealth = register_cvar("zp_barel_health","60"); // set the health to a pallet with bags
	g_msgDamage 	= get_user_msgid("Damage");
	g_msgDeathMsg 	= get_user_msgid("DeathMsg");
	g_msgScoreInfo	= get_user_msgid("ScoreInfo");
	
	/* Game Events */
	register_logevent("event_newround", 2, "1=Round_Start")
	//register_event("HLTV","event_newround", "a","1=0", "2=0"); // it's called every on new round
	register_forward(FM_Think, "ltm_Think" );
}


public plugin_precache()
{
	for(new i;i < sizeof g_models;i++)
		engfunc(EngFunc_PrecacheModel,g_models[i]);
		
	g_ExplosionMdl = precache_model("sprites/zerogxplode.spr")
	g_SmokeMdl = precache_model("sprites/steam1.spr")	
}
public ltm_Think( i_Ent )
{
	if ( !pev_valid( i_Ent ) )
		return FMRES_IGNORED;
		
	new EntityName[32];
	pev( i_Ent, pev_classname, EntityName, 31);

	if ( !equal( EntityName, "amxx_barel" ) )
		return FMRES_IGNORED;
	
	if(pev_user_health(i_Ent) > MIN_HP)
		return FMRES_IGNORED;
		
	
	CreateDamage_2(i_Ent)
	return FMRES_IGNORED;
}	
stock place_palletwbags(id)
{	
	new Float:xorigin[3];
	get_user_hitpoint(id,xorigin);	

	if(engfunc(EngFunc_PointContents,xorigin) == CONTENTS_SKY)
	{
		client_print(id,print_chat,"[G/L ZP] Tam nemozes postavit barel!");
		vrat_body(id, g_item_bolsas)
		return PLUGIN_HANDLED;
	}
	if( palletscout == get_pcvar_num(maxpallets) )
	{
		client_print(id,print_chat,"[G/L ZP] Dosiahnuty maximalny pocet barelov!");
		vrat_body(id, g_item_bolsas)
		return PLUGIN_HANDLED;
	}
	new ciel, docasne
	get_user_aiming(id, ciel, docasne, 9999)
	if( ciel > 0)
	{
		if(is_user_alive(ciel)) {
			client_print(id,print_chat,"[G/L ZP] Nemozes dat barel na hraca !");
			vrat_body(id, g_item_bolsas)
			return PLUGIN_HANDLED;
		}
	}
	
	new temp[3], hrac_vector[3]
	get_user_origin(id, hrac_vector)
	temp[0] = floatround(xorigin[0]);
	temp[1] = floatround(xorigin[1]);
	temp[2] = floatround(xorigin[2]);
		
	if(get_distance(temp, hrac_vector) > B_DISTANCE)
	{
		client_print(id,print_chat,"[G/L ZP] Barel stavias priliz daleko!");
		vrat_body(id, g_item_bolsas)
		return PLUGIN_HANDLED;
	}
	
		
	// create a new entity 
	new ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "func_breakable"));	
	// set a name to the entity
	set_pev(ent, pev_classname,"amxx_barel");
	// set model		
	engfunc(EngFunc_SetModel,ent,g_models[random(sizeof g_models)]);
		
	// set sizes
	new Float:p_mins[3], Float:p_maxs[3];
	p_mins = PALLET_MINS;
	p_maxs = PALLET_MAXS;
	engfunc(EngFunc_SetSize, ent, p_mins, p_maxs);
	set_pev(ent, pev_mins, p_mins);
	set_pev(ent, pev_maxs, p_maxs );
	set_pev(ent, pev_absmin, p_mins);
	set_pev(ent, pev_absmax, p_maxs );
	DispatchKeyValue(ent, "material", "6")
	
	// set the rock of origin where is user placed
	engfunc(EngFunc_SetOrigin, ent, xorigin);	
	// make the rock solid
	set_pev(ent,pev_solid, SOLID_BBOX); // touch on edge, block
	// set the movetype
	set_pev(ent, pev_movetype, MOVETYPE_FLY); // no gravity, but still collides with stuff
	// now the damage stuff, to set to take it or no
	// if you set the cvar "pallets_wbags_health" 0, you can't destroy a pallet with bags
	// else, if you want to make it destroyable, just set the health > 0 and will be
	// destroyable.

	set_pev(ent,pev_health,get_pcvar_float(phealth));
	set_pev(ent,pev_takedamage, DAMAGE_YES);
	set_pev(ent, pev_dmg, T_DAMAGE);
	set_pev(ent, OWNER, id)
	
	static Float:rvec[3];
	pev(id,pev_v_angle,rvec);	
	rvec[0] = 0.0;	
	set_pev(ent,pev_angles,rvec);
	
	// drop entity to floor
	fm_drop_to_floor(ent);
	
	// num ..
	palletscout++;
	
	client_print(id, print_chat, "[G/L ZP] Barel postaveny.")
	return PLUGIN_HANDLED;
}
stock vrat_body(id, kolko)
{
	if(get_user_flags(id) & ADMIN_LEVEL_F ) {
		kolko = floatround( float(kolko) * 0.5 , floatround_floor );	
	}
	zp_set_user_ammo_packs(id,zp_get_user_ammo_packs(id) +  kolko)
}	
/* ====================================================
get_user_hitpoin stock . Was maked by P34nut, and is 
like get_user_aiming but is with floats and better :o
====================================================*/	
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
public event_newround()
{
	remove_allpalletswbags();	
}
stock remove_allpalletswbags()
{
	new pallets = -1;
	while((pallets = fm_find_ent_by_class(pallets, "amxx_barel")))
		fm_remove_entity(pallets);
		
	palletscout = 0;
}

public zp_extra_item_selected(player, itemid)
{	
	if (itemid == g_itemid_bolsas) {
		client_print(player, print_chat, "[G/L ZP] Barel je mimo prevadzky, opravuje sa.")
		return PLUGIN_HANDLED;
		place_palletwbags(player);
	}
}
public cmd_barel(id, level, cid)
{
	if (!cmd_access(id,level,cid,1)) {
		return PLUGIN_HANDLED
	}
	place_palletwbags(id);
}
public cmd_barel_user(id, level, cid)
{
	if (!cmd_access(id,level,cid,1)) {
		return PLUGIN_HANDLED
	}
	if(zp_get_user_zombie(id))	{
		return PLUGIN_HANDLED;
	}	
	new kolko
	if(get_user_flags(id) & ADMIN_LEVEL_F ) {
		kolko = floatround( float(g_item_bolsas) * 0.5 );	
	} else {
		kolko = g_item_bolsas
	}
	if(kolko <= zp_get_user_ammo_packs(id))
	{
		place_palletwbags(id);
		zp_set_user_ammo_packs(id,zp_get_user_ammo_packs(id) -  kolko)
	} else {
		client_print(id, print_chat, "[G/L ZP] Nedostatok bodov")
	}
	return PLUGIN_CONTINUE
}
stock CreateDamage_2(iCurrent)
{
	palletscout--;
	
	new Float:T_DmgMAX 	= 	T_DAMAGE
	new Float:CT_DmgMAX = 	CT_DAMAGE
	new Float:Radius 	= 	RADIUS
	new bodov_cvar 		=	get_cvar_num("zp_human_damage_reward")
	// Get given parameters	
	new Float:vecSrc[3];
	pev(iCurrent, pev_origin, vecSrc);

	new AtkID = pev(iCurrent, OWNER);

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
	new bodov
	
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
	
	// Find monsters and players inside a specifiec radius
	while((ent = engfunc(EngFunc_FindEntityInSphere, ent, vecSrc, Radius)) != 0)
	{
		if(!pev_valid(ent)) continue;
		if(!(pev(ent, pev_flags) & (FL_CLIENT | FL_FAKECLIENT | FL_MONSTER)))
		{			
			// Dalsi barel moze byt - vybuch sa siri dalej
			pev(ent, pev_classname, classname, sizeof classname - 1 )
			//client_print(0, print_chat, "hladam entity %s", classname)	// log
			if ( equal(classname, "amxx_barel") )
			{
				// equal(classname, "amxx_barel") || | equal(classname, "func_breakable") || equal(classname, "func_pushable")
				//client_print(0, print_chat, "najdena entita" )	// log
				set_task(random_float(0.5,1.5), "task_vybuchu_dalseho", ent)
				//set_pev(ent, pev_health, 20.0);
			}
			// Entity is not a player or monster, ignore it
			continue;
		}
		if(!pev_user_alive(ent)) continue;
		// Reset data
		kickback = 1.0;
		if(zp_get_user_zombie(ent) ) // || zp_get_user_nemesis(ent)
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
					fm_set_user_health(ent, iHitHP)
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
	make_explosion(iCurrent,  g_ExplosionMdl, g_SmokeMdl)
	RemoveEntity(iCurrent);
	
	return
}
stock bool:pev_user_alive(ent){ return (pev(ent,pev_deadflag) != DEAD_NO) ? false : true; }
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
	write_string("Barel")
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
	//set_user_health(target, HP)
	fm_set_user_health(target, HP)

}
stock pev_user_frags(index)
{
	new Float:frags;
	pev(index,pev_frags,frags);
	return floatround(frags);
}
stock make_explosion(id,  ExplosionMdl, SmokeMdl = false, BeamCilinderMdl = false) {
	
	new Float:bomba_vektor[3], origin[3];
	entity_get_vector(id, EV_VEC_origin, bomba_vektor)
	FVecIVec(bomba_vektor,origin);
	
	// Explosion
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(3) // TE_EXPLOSION
	write_coord(origin[0]) // startorigin
	write_coord(origin[1])
	write_coord(origin[2] + 5)
	write_short(ExplosionMdl) // sprite
	write_byte(random_num(0,20) + 20)
	write_byte(12)
	write_byte(0)
	message_end()
	
	if(SmokeMdl) {
		// Smoke
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(5) // TE_SMOkE
		write_coord(origin[0]) // startorigin
		write_coord(origin[1])
		write_coord(origin[2] + 15)
		write_short(SmokeMdl) // sprite
		write_byte(60)
		write_byte(10)
		message_end()
	}
		
	if(BeamCilinderMdl) {
		//BeamCilinder
		message_begin( MSG_BROADCAST,SVC_TEMPENTITY,origin )
		write_byte ( 21 ) //TE_BEAMCYLINDER
		write_coord( origin[0] )
		write_coord( origin[1] )
		write_coord( origin[2] )
		write_coord( origin[0] )
		write_coord( origin[1] )
		write_coord( origin[2]+200 )
		write_short( BeamCilinderMdl )
		write_byte ( 0 )
		write_byte ( 1 )
		write_byte ( 6 )
		write_byte ( 8 )
		write_byte ( 1 )
		write_byte ( 255 )
		write_byte ( 255 )
		write_byte ( 192 )
		write_byte ( 128 )
		write_byte ( 5 )
		message_end()
	}
	return true
}
stock set_user_frags(index, frags)
{
	set_pev(index, pev_frags, float(frags))
	return 1
}
stock fm_set_user_health(index, health)
{
	health > 0 ? set_pev(index, pev_health, float(health)) : dllfunc(DLLFunc_ClientKill, index);
	return 1;
}
public task_vybuchu_dalseho(ent)
{
	if(pev_valid(ent))
	{
		//client_print(0, print_chat, "najdena entita" )
		//set_pev(ent, pev_health, 20.0);
		CreateDamage_2(ent)
	}
}

/*
stock fm_velocity_by_aim(iIndex, Float:fDistance, Float:fVelocity[3], Float:fViewAngle[3])
{
	//new Float:fViewAngle[3]
	pev(iIndex, pev_v_angle, fViewAngle)
	fVelocity[0] = floatcos(fViewAngle[1], degrees) * fDistance
	fVelocity[1] = floatsin(fViewAngle[1], degrees) * fDistance
	fVelocity[2] = floatcos(fViewAngle[0]+90.0, degrees) * fDistance
	return 1
}

stock fm_find_ent_by_owner(index, const classname[], owner, jghgtype = 0)
{
	new strtype[11] = "classname", ent = index
	switch (jghgtype)
	{
		case 1: copy(strtype, 6, "target")
		case 2: copy(strtype, 10, "targetname")
	}
	while ((ent = engfunc(EngFunc_FindEntityByString, ent, strtype, classname)) && pev(ent, pev_owner) != owner) {}
	return ent
}*/