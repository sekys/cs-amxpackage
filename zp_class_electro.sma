#include <amxmodx>
#include <hamsandwich>
#include <zombieplague>
#include <fakemeta>

new bool:BeenStruck[33]=false
new gSpriteLightning, gmsgDeathMsg, pouzil[33]
new const sound[] = "zombie_plague/ectric_explosion5.wav"

// Crow Zombie Atributes
new const zclass_name[] = { "Electroshocker" } // name
new const zclass_info[] = { "HP+ KB- Elek. POWA" } // description
new const zclass_model[] = { "gl_electric" } // model  elektroshocker
new const zclass_clawmodel[] = { "duch_hand.mdl" } // claw model
const zclass_health = 1700 // health
const zclass_speed = 225 // speed
const Float:zclass_gravity = 0.7 // gravity
const Float:zclass_knockback = 1.3 // knockback
new g_zclass_crow, g_msgScoreInfo

public plugin_init()
{
	// Plugin Info
	register_plugin("[ZP] Electro", "1.0" , "Seky");
	RegisterHam(Ham_Player_PreThink, "player", "cheese_player_prethink", 1)
 
	register_event("ResetHUD","newRound","b") 
	gmsgDeathMsg = get_user_msgid("DeathMsg")
	g_msgScoreInfo = get_user_msgid("ScoreInfo")
	register_cvar("electro_radius", "400" )
	register_cvar("electro_pouzitie", "9" )
	register_cvar("electro_damage", "10" )
}
public plugin_precache() {
	g_zclass_crow = zp_register_zombie_class(zclass_name, zclass_info, zclass_model, zclass_clawmodel, zclass_health, zclass_speed, zclass_gravity, zclass_knockback)
	precache_sound(sound)
	gSpriteLightning = precache_model("sprites/lgtning.spr")
	precache_sound("ambience/deadsignal1.wav")
}
public newRound(id)
{
  pouzil[id] = get_cvar_num("electro_pouzitie")
  return PLUGIN_CONTINUE
}
public cheese_player_prethink(id) 
{			
	// Schopnost 
	if((pev(id, pev_button ) & IN_RELOAD) && !(pev(id, pev_oldbuttons ) & IN_RELOAD ))
	{
		if(zp_is_survivor_round() || zp_is_nemesis_round()) return PLUGIN_CONTINUE
		if(!is_user_alive(id) || !zp_get_user_zombie(id)) return PLUGIN_CONTINUE
		if(zp_get_user_zombie_class(id) != g_zclass_crow) return PLUGIN_CONTINUE
				
		if (!pouzil[id]) {		
			client_print(id, print_center, "Dosla ti stava.")
		} else {
			pouzil[id]--
			elektrina(id)
		}	
	}
	return PLUGIN_CONTINUE;
}
stock elektrina(id)
{
  new ElectroRadius = get_cvar_num("electro_radius")
  new OriginA[3]
  new OriginB[3]
  new players[32], inum
  new oid = id
  get_user_origin(id,OriginA)
  get_players(players,inum,"a")

  message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
  write_byte(28) //TE_ELIGHT
  write_short(id) // entity
  write_coord(OriginA[0])  // initial position
  write_coord(OriginA[1])
  write_coord(OriginA[2])
  write_coord(100)    // radius
  write_byte(230)  // red
  write_byte(230)  // green
  write_byte(0) // blue
  write_byte(10)  // life
  write_coord(0)  // decay rate
  message_end()
  playSound(id)

  for(new i = 0 ;i < inum; ++i)
  {
	if(!zp_get_user_zombie(players[i]))  
	{
		get_user_origin(players[i],OriginB)
		if(get_distance(OriginA, OriginB) < ElectroRadius && players[i]!=id)
	    {
	      BeenStruck[players[i]]=true
	      Lightning(players[i], oid)
	      LightningEffects(id,players[i])
		  LightningDamage(players[i], oid)
	    }
	}
  }
}
stock Lightning(tid, oid)
{
  new ElectroRadius = get_cvar_num("electro_radius")
  new OriginA[3], OriginB[3]
  new players[32], inum
  get_user_origin(tid,OriginA)
  get_players(players,inum,"a")
  BeenStruck[tid]=true
  for(new i = 0 ;i < inum; ++i)
  {
    if(!zp_get_user_zombie(players[i]))
	{
		get_user_origin(players[i], OriginB)
	    if(get_distance(OriginA, OriginB) < ElectroRadius && tid!=players[i] && !BeenStruck[players[i]])
	    {
	      Lightning(players[i], oid)
	      LightningEffects(tid, players[i])
		  LightningDamage(players[i], oid)
	    }
	}
  }
}
//****Damage****------------------------------------------------------------------------
stock LightningDamage(tid, majitel)
{ 
	new Float:origin1[3], Float:origin2[3]
	pev(tid, pev_origin, origin1); 
	pev(majitel, pev_origin, origin2); 
	
	new health = get_user_health(tid)
	new damage = get_cvar_num("electro_damage");
	damage = damage - floatround( damage * (get_distance_f(origin1, origin2) / float(get_cvar_num("electro_radius"))) )
	
	if(damage > 0)
	{
		if(damage > health)
		{
			new frags
			zp_set_user_ammo_packs(majitel, zp_get_user_ammo_packs(majitel) + 1)
			frags = get_user_frags(majitel) + 1
			fm_set_user_frags(majitel, frags)
			Update_ScoreInfo(majitel, frags, get_user_deaths(majitel) )
			
			message_begin(MSG_ALL, gmsgDeathMsg, {0, 0, 0} ,0)
			write_byte(majitel)
			write_byte(tid)
			write_byte(0)
			write_string(zclass_name)
			message_end()
			
			set_msg_block(gmsgDeathMsg, BLOCK_ONCE)
		}

		fm_set_user_health(tid, health - damage)
	}
}	
stock fm_set_user_frags(index, frags)
{
	set_pev(index, pev_frags, float(frags));
	return 1;
}
stock fm_set_user_health(index, health)
{
	health > 0 ? set_pev(index, pev_health, float(health)) : dllfunc(DLLFunc_ClientKill, index);
	return 1;
}				
//****Graphic****-----------------------------------------------------------------------
stock LightningEffects(id,tid)
{
  new iRed, iGreen, iBlue, iWidth, iNoise
  iRed = random_num(0,100)
  iGreen = random_num(0,100)
  iBlue = random_num(100,255)
  iWidth = random_num(10,40)
  iNoise = random_num(10,40)

  if(iRed > iBlue) iBlue = (iRed + 10)
  if(iGreen > iBlue) iBlue = (iGreen + 10)
  if(iBlue > 255) iBlue = 255

  message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
  write_byte(8) //TE_BEAMENTS
  write_short(id)  // start entity
  write_short(tid)  // entity
  write_short(gSpriteLightning) // model/sprite
  write_byte(0) // starting frame
  write_byte(15)  // frame rate in 0.1's
  write_byte(10)  // life in 0.1's
  write_byte(iWidth)  // line width in 0.1's
  write_byte(iNoise)  // noise amplitude in 0.01's
  write_byte(iRed)  // Red
  write_byte(iGreen)  // Green
  write_byte(iBlue)  // Blue
  write_byte(190)  // brightness
  write_byte(0)  // scroll speed in 0.1's
  message_end()

  new origin[3]
  get_user_origin(tid,origin)
  message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
  write_byte(27) //TE_DLIGHT  dynamic light, effect world, minor entity effect
  write_coord(origin[0]) //initial position
  write_coord(origin[1])
  write_coord(origin[2])
  write_byte(20) //radius in 10's
  write_byte(230) //color red
  write_byte(230) //color green
  write_byte(0) //color blue
  write_byte(5) //life in 10's
  write_byte(10) //decay rate in 10's
  message_end()
}
stock playSound(id)
{
  emit_sound(id, CHAN_AUTO, "ambience/deadsignal1.wav", 1.0, ATTN_NORM, 0, PITCH_HIGH)
  set_task(1.5,"stopSound", id)
}
//-****Sound Stop****--------------------------------------------------------------------
public stopSound(id)
{
  new sndStop=(1<<5)
  emit_sound(id, CHAN_AUTO, "ambience/deadsignal1.wav", 1.0, ATTN_NORM, sndStop, PITCH_NORM)
}
Update_ScoreInfo(id, frags, deaths) // Update Player's Frags and Deaths
{
	// Update scoreboard with attacker's info
	message_begin(MSG_BROADCAST, g_msgScoreInfo)
	write_byte(id) // id
	write_short(frags) // frags
	write_short(deaths) // deaths
	write_short(0) // class?
	write_short(get_user_team(id)) // team
	message_end()
}