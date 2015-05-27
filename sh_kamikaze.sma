#include <amxmodx>
#include <zombieplague>
#include <hamsandwich>
#include <fakemeta>
#include <cstrike>
#include <fun>

#define CASOVAC 13
#define DAMAGE 200
#define RADIUS 400
#define EFFECT_BLOOD 1
#define EFFECT_EXPLO 0
#define MAXPLAYERS 32
// Vlastnsti
	new const zclass_name[] = { "Kamikaze" } // name
	new const zclass_info[] = { "Samovrach HP--- Speed++" } // description
	new const zclass_clawmodel[] = { "hands_of_zombies3.mdl" } // claw model
	new const TSkins[] = { "zombie_rapido" } // model
	const zclass_health = 500 // health
	const zclass_speed = 300 // speed
	const Float:zclass_gravity = 1.0 // gravity
	const Float:zclass_knockback = 1.5 // knockback

new const gSoundCountdown[] = "buttons/blip2.wav"
new const vybuch[] = "zombie_plague/bc_die2.wav"
new const flatline[] = "fvox/flatline.wav"

new gmsgDamage, gmsgScoreInfo,gMsgSync,
	gSpriteSmoke, gSpriteWhite, gSpriteFire,g_zclass_climb,
	casovac[33]
	//casovac_povoleny[33]

//----------------------------------------------------------------------------------------------
public plugin_init()
{

	register_plugin("ZP Kamikaze", "1.0", "Seky")
	gMsgSync = CreateHudSyncObj()
	RegisterHam(Ham_Player_PreThink, "player", "cheese_player_prethink", 1)
	register_event("ResetHUD", "newround", "b");

	gmsgScoreInfo	= get_user_msgid("ScoreInfo");
	gmsgDamage 	= get_user_msgid("Damage");	
}
//----------------------------------------------------------------------------------------------
public plugin_precache()
{	
	g_zclass_climb = zp_register_zombie_class(zclass_name, zclass_info, TSkins, zclass_clawmodel, zclass_health, zclass_speed, zclass_gravity, zclass_knockback)
	gSpriteSmoke = precache_model("sprites/steam1.spr")
	gSpriteWhite = precache_model("sprites/white.spr")
	gSpriteFire = precache_model("sprites/explode1.spr")
	precache_sound(gSoundCountdown)
	precache_sound(flatline)
	precache_sound(vybuch)
}
//----------------------------------------------------------------------------------------------
public newround(id) 
{	
		casovac[id] = 13
		//casovac_povoleny[id] = 1
}
public client_disconnect(id)
{
	casovac[id] = 0
}
//----------------------------------------------------------------------------------------------
public cheese_player_prethink(id) 
{
	if(zp_is_survivor_round() || zp_is_nemesis_round() || zp_get_user_zombie_class(id) != g_zclass_climb) {
		return
	}
	if(!is_user_alive(id) || !zp_get_user_zombie(id)) {
		return 
	}
	
	if(pev(id, pev_button ) & IN_RELOAD && !(pev(id, pev_oldbuttons ) & IN_RELOAD )) {
		
	if(zp_get_user_energy(id) == 100) {
		zp_set_user_energy(id,0)
			//client_print(id,print_chat,"[G/L ZP] Uz si raz pouzil kamikaze !"); //2x
			//return
		
	//spusti odpalenie na hraca a nic viacej
		//casovac_povoleny[id] = 0
		casovac[id] = CASOVAC
		//Icon( id, 1, "dmg_gas", 0, 255, 0 );
		set_task(0.1, "odpalenie", id);
		} else {
			client_print(id,print_chat,"[G/L ZP] Nedostatok energie !");
		}
	}	
}
public odpalenie(id)
{
	if(is_user_alive(id) && zp_get_user_zombie(id)) {
	casovac[id] = casovac[id] - 1
	// ak stale zije.....12
		if ( casovac[id] > 0 ) {
			emit_sound(id, CHAN_ITEM, gSoundCountdown, VOL_NORM, ATTN_NORM, 0, PITCH_NORM) // pip zvucka
		}
		//zabije
		if ( casovac[id] <= 0 ) {
			new name[32]
			get_user_name(id, name, 31)
			set_hudmessage(0, 100, 200, 0.05, 0.65, 2, 0.02, 1.0, 0.01, 0.1, -1)
			ShowSyncHudMsg(0, gMsgSync, "%s explodoval", name)
			
			set_task(0.1, "vybuchni", id);
		}
		// inak spravy	
			else {
				// hud oznam
				set_hudmessage(0, 100, 200, 0.05, 0.65, 2, 0.02, 1.0, 0.01, 0.1, -1)
				ShowSyncHudMsg(id, gMsgSync, "Explodujes za %d", casovac[id])

				// zvuk oznam
				if ( casovac[id] == 12 ) {
					client_cmd(id, "spk ^"fvox/targetting_system^"") // iba ako ze zacina odpocet ,oznam
				}
				else if ( casovac[id] == 3) {
					//client_cmd(id, "spk ^"fvox/flatline^"") //piiiiip
					engfunc(EngFunc_EmitSound, id, CHAN_WEAPON, flatline, 1.0, ATTN_NORM, 0, PITCH_NORM)
				}	else if ( casovac[id] < 10 && casovac[id] > 3) {
					new temp[48]
					num_to_word(casovac[id], temp, 47)
					client_cmd(id, "spk ^"fvox/%s^"", temp) //odpocitava
				}
			// Spusti fukciu zase
			set_task(1.0, "odpalenie", id);
		}
	}
}

public vybuchni(id)
{
	if (!is_user_alive(id) && zp_get_user_zombie(id) ) return //len T
	//cas
		casovac[id] = 0
	//explodujuci efekt
		new Float:idOrigin[3]
		get_user_origin(id,idOrigin)
		explode_effect(idOrigin)
		
	//ine efekty
		//manage_effect_env(EFFECT_BLOOD, idOrigin, id)
		engfunc(EngFunc_EmitSound, id, CHAN_WEAPON, vybuch, 1.0, ATTN_NORM, 0, PITCH_NORM)
		
	//vybuch
	new Float:dRatio, damage2, distanceBetween
    new damradius = RADIUS
    new maxdamage = DAMAGE
	new origin1[3]
    for(new a = 1; a <= 32; a++) {
        if( is_user_alive(a) && !zp_get_user_zombie(a)  ) {

            get_user_origin(a,origin1)

            distanceBetween = get_distance(idOrigin, origin1 )
            if( distanceBetween < damradius ) {
                if ( a == id ) {
                    damage2 = maxdamage * 4
                }
                else {
                    dRatio = float(distanceBetween) / float(damradius)
                    damage2 = maxdamage - floatround( maxdamage * dRatio)
                }
                sh_extra_damage(a, id, damage2, "knife")
				cs_set_user_deaths(id, cs_get_user_deaths(id) - 1 )
				//client_print(0,print_chat,"dmg %d",damage2); // LOG
            } 
        } 
    } 
		
		
	//zabit
	set_user_health(id, get_user_health(id) - 100 )
	client_print(id,print_chat,"[G/L ZP] Zobrane 100 HP a energia!");

}
//----------------------------------------------------------------------------------------------


public sh_extra_damage(victim,attacker,damage, const wpnDescription[32])
{
	if ( !is_user_alive(victim) && zp_get_user_zombie(victim) ) return
	if ( !is_user_connected(attacker) ) return

	new health = get_user_health(victim)
	new CsArmorType:armorType
	new plrArmor = cs_get_user_armor(victim, armorType)
	new CsTeams:victimTeam = cs_get_user_team(victim)
	new CsTeams:attackerTeam = cs_get_user_team(attacker)
	
	if ( damage <= 0 ) return

		// *** Damage calculation due to armor from: multiplayer/dlls/player.cpp ***
		// *** Note: this is not exactly CS damage method because we do not have that sdk ***
		new Float:flDamage = float(damage)
		new Float:flNewDamage = flDamage * 0.2
		new Float:flArmor = (flDamage - flNewDamage) * 0.5

		// Does this use more armor than we have figured for?
		if ( flArmor > float(plrArmor) ) {
			flArmor = float(plrArmor) * ( 1 / 0.5 )
			flNewDamage = flDamage - flArmor
			plrArmor = 0
		}
		else {
			plrArmor = floatround(plrArmor - flArmor)
		}


		//*** End of damage-armor calculations ***
	

	new newHealth = health - damage
	//client_print(0,print_notify,"zivot %d ",newHealth); // LOG
	if ( newHealth < 1 ) {
		new bool:kill
		new attackerFrags = get_user_frags(attacker)

		if ( victim == attacker ) {
			kill = true
		}
		else {
			kill = true
			cs_set_user_deaths(attacker, cs_get_user_deaths(attacker) + 1 )
			//client_print(0,print_notify,"+frag %d ",attackerFrags); // LOG
			zp_set_user_ammo_packs(attacker, zp_get_user_ammo_packs(attacker) + 1)
		}
//=====================================
		if ( !kill ) return

		// Kill the victim and block the message
		set_msg_block(gmsgScoreInfo, BLOCK_ONCE)

		// Kill the victim
		dllfunc(DLLFunc_ClientKill, victim)
		
		// Log the Kill tu spravit len poskodenie
		logKill(attacker, victim, wpnDescription)

		// External plugins might use this, ie atac 3
		// This should be set to the entity that caused the
		// damage, but lets just set it to attacker for now
		set_pev(victim, pev_dmg_inflictor, attacker)

		// Make camera turn toward attacker on death, thx Emp`
		set_pev(victim, pev_iuser3, attacker)

		// ClientKill removes a frag, give it back if not self inflicted
		new victimFrags = get_user_frags(victim)
		if ( victim != attacker ) {
		
			set_user_frags(victim, get_user_frags(victim) + 1 )
			// Update victims scoreboard with correct info
			message_begin(MSG_ALL, gmsgScoreInfo)
			write_byte(victim)
			write_short(victimFrags)
			write_short(cs_get_user_deaths(victim))
			write_short(0)
			write_short(_:victimTeam)
			message_end()
		}

		// Update killers scoreboard with new info
		message_begin(MSG_ALL, gmsgScoreInfo)
		write_byte(attacker)
		write_short(attackerFrags)
		write_short(cs_get_user_deaths(attacker))
		write_short(0)
		write_short(_:attackerTeam)
		message_end()
	}
	else {
		new bool:hurt = true
//=====================================
		if ( !hurt ) return

		// External plugins might use this
		// This should be set to the entity that caused the
		// damage, but lets just set it to attacker for now
		set_pev(victim, pev_dmg_inflictor, attacker)

		set_user_health(victim, newHealth)
		//client_print(0,print_notify,"helath victim %d",newHealth); // LOG
		
		cs_set_user_armor(victim, plrArmor, armorType)

		// Slow down from damage, does not effect z vector
		// new bool:dmgStun = get_param(7) ? true : false
		//if ( is_user_bot(victim) ) return

		new Float:dmgOrigin[3]
		pev(attacker, pev_origin, dmgOrigin)

		// Damage message for showing damage bits only
		message_begin(MSG_ONE_UNRELIABLE, gmsgDamage, _, victim)
		write_byte(0)		// dmg_save
		write_byte(damage)	// dmg_take
		write_long(DMG_GENERIC)	// visibleDamageBits
		engfunc(EngFunc_WriteCoord, dmgOrigin[0])	// damageOrigin.x
		engfunc(EngFunc_WriteCoord, dmgOrigin[1])	// damageOrigin.y
		engfunc(EngFunc_WriteCoord, dmgOrigin[2])	// damageOrigin.z
		message_end()
	}
}


//===================
// MISC
logKill(id, victim, const weaponDescription[32])
{
	new namea[32], namev[32], authida[32], authidv[32], teama[16], teamv[16]

	// Info On Attacker
	get_user_name(id, namea, 31)
	get_user_team(id, teama, 15)
	get_user_authid(id, authida, 31)
	new auserid = get_user_userid(id)

	// Info On Victim
	get_user_name(victim, namev, 31)
	get_user_team(victim, teamv, 15)
	get_user_authid(victim, authidv, 31)

	// Log This Kill
	if ( id != victim ) {
		log_message("^"%s<%d><%s><%s>^" killed ^"%s<%d><%s><%s>^" with ^"%s^"",
			namea, auserid, authida, teama, namev, get_user_userid(victim), authidv, teamv, weaponDescription)
	}
	else {
		log_message("^"%s<%d><%s><%s>^" committed suicide with ^"%s^"",
			namea, auserid, authida, teama, weaponDescription)
	}
}
explode_effect(Float:vec1[3])
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

stock pev_user_health(id)
{
	new Float:health
	pev(id,pev_health,health)
	return floatround(health)
}

// stock set_user_health(id,health)
// {
	// health > 0 ? set_pev(id, pev_health, float(health)) : dllfunc(DLLFunc_ClientKill, id);
// }

//===========================
// KRV

new iSwEffectID[2]
new const sClassname[] = "classname"
new const sNamedEntEnvExplosion[] = "env_explosion"
new const sSwEffectClassname[] = "ZP_EffectEnt"
new const sNamedEntEnvBlood[] = "env_blood"

stock manage_effect_env(iEffect, Float:fOrigin[3], iUserEnt)
{
	if ( !iUserEnt )
		return 0
	new param = iSwEffectID[iEffect]
	if ( param <= MAXPLAYERS )
	{
		create_effect_entity()
		manage_effect_env(iEffect, fOrigin, iUserEnt)
	}
	set_pev(param, pev_origin, fOrigin)
	dllfunc(DLLFunc_Use, param, iUserEnt)
	set_pev(param, pev_origin, {8192.0,8192.0,8192.0})
	return 1
}
stock create_effect_entity()
{
	new iEnt = -1
	while ( (iEnt = engfunc(EngFunc_FindEntityByString, iEnt, sClassname, sSwEffectClassname)) > MAXPLAYERS )
		engfunc(EngFunc_RemoveEntity, iEnt)
	//explosion
	iEnt = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, sNamedEntEnvExplosion))
	if ( iEnt <= MAXPLAYERS )
		create_effect_entity()
	fm_set_kvd(iEnt, "iMagnitude", "100", sNamedEntEnvExplosion)//flSpriteScale = ( m_iMagnitude - 50) * 0.6;
	set_pev(iEnt, pev_spawnflags, pev(iEnt, pev_spawnflags) | SF_ENVEXPLOSION_NODAMAGE)
	set_pev(iEnt, pev_spawnflags, pev(iEnt, pev_spawnflags) | SF_ENVEXPLOSION_REPEATABLE)
	dllfunc(DLLFunc_Spawn, iEnt)
	set_pev(iEnt, pev_classname, sSwEffectClassname)
	set_pev(iEnt, pev_origin, {8192,8192,8192})
	iSwEffectID[EFFECT_EXPLO] = iEnt
	//blood	
	iEnt = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, sNamedEntEnvBlood))
	if ( iEnt <= MAXPLAYERS )
		create_effect_entity()		
	fm_set_kvd(iEnt, "color", "2", sNamedEntEnvBlood)//black/white = 0, yellow = 1, red = 2
	fm_set_kvd(iEnt, "amount", "100", sNamedEntEnvBlood)
	set_pev(iEnt, pev_spawnflags, pev(iEnt, pev_spawnflags) | SF_BLOOD_RANDOM)
	set_pev(iEnt, pev_spawnflags, pev(iEnt, pev_spawnflags) | SF_BLOOD_DECAL)
	dllfunc(DLLFunc_Spawn, iEnt)
	set_pev(iEnt, pev_classname, sSwEffectClassname)
	set_pev(iEnt, pev_origin, {8192,8192,8192})
	iSwEffectID[EFFECT_BLOOD] = iEnt
	return 1
}
stock fm_set_kvd(entity, const key[], const value[], const classname[] = "")
{
	if ( classname[0] )
		set_kvd(0, KV_ClassName, classname)
	else
	{
		new class[32]
		pev(entity, pev_classname, class, 31)
		set_kvd(0, KV_ClassName, class)
	}
	set_kvd(0, KV_KeyName, key)
	set_kvd(0, KV_Value, value)
	set_kvd(0, KV_fHandled, 0)
	return dllfunc(DLLFunc_KeyValue, entity, 0)
}