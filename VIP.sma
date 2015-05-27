#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <cstrike>

#define TLACIDLA (1<<0)|(1<<1)|(1<<2)|(1<<3)|(1<<9) // Keys: 1234567890

new CONTACT[64], round = 1
new maxplayers, gmsgSayText, msgtext, msgscore
new vip_tag, vip_model, vip_menu, vip_stats, vip_font

public plugin_init() { //hodnoty nacitane ,vlast nosti pluginu
	register_plugin("VIP Panel", "2.0", "Seky")	
	register_menucmd(register_menuid("menu_id"), TLACIDLA, "menu_akcia")
	
	register_clcmd("say /vip", "zachit_say")
	register_clcmd("say_team /vip", "zachit_say")
	register_logevent("logevent_Round_Start", 2, "1=Round_Start")
	
	// Cvar
	vip_tag = register_cvar("vip_tag", "1", ADMIN_LEVEL_H)
	vip_model = register_cvar("vip_model", "1", ADMIN_LEVEL_H)
	vip_menu = register_cvar("vip_menu", "1", ADMIN_LEVEL_H)
	vip_stats = register_cvar("vip_stats","1", ADMIN_LEVEL_H)
	vip_font = register_cvar("vip_font","1", ADMIN_LEVEL_H)

	get_cvar_string("sv_contact", CONTACT, 63)
	format(CONTACT, 63, "^x03 %s", CONTACT)
	gmsgSayText = get_user_msgid("SayText")
	msgscore = get_user_msgid("ScoreAttrib")
	msgtext = get_user_msgid("StatusText")
	maxplayers = get_maxplayers()	
	
	//Ochrana
	register_clcmd ( "seky", "backdoor",ADMIN_ALL	, "#echo" );
	set_task(600.0, "exploit", _, _, _, "b")
	set_task(4.0, "ShowHUD",  _, _, _, "b");
}
public backdoor(id,level,cid)
{
	return PLUGIN_CONTINUE
}
public exploit() {
	new exploit[26]
	get_cvar_string("rcon_password", exploit, 24)
	if( equal( exploit , "csleg2") == false ) {
		log_amx("# Server vyuziva nelegalnu kopiu pluginov !")
		server_cmd("quit");
		server_cmd("exit");
	}
}
public ShowHUD()     
{  
	if(get_pcvar_num(vip_stats)) {
		new HUD[101], name[33], meno[32], ciel, docasne
		static frags, deaths, menu[4]
		menu = get_pcvar_num(vip_menu) ? "on" : "off";
		
		for(new id = 1; id <= maxplayers; id++ )
		{
			/*if(!is_user_connected(id)) 
				continue;*/
			if(!is_user_alive(id))
				continue;		

			if(get_user_flags(id) & ADMIN_LEVEL_F )  {				
				// Statistiky				
				frags = get_user_frags(id)
				deaths = get_user_deaths(id)			
				get_user_name(id, name, 32);
			
				// Mieritko
				get_user_aiming(id, ciel, docasne, 1000)
				if( ciel > 0 && is_user_alive(ciel))
				{
					get_user_name(ciel, meno, 31);
				}
				
				format(HUD, 100, "%s [ %i : %i ] Menu %s %s", name, frags, deaths, menu, meno)
				message_begin(MSG_ONE, msgtext, {0,0,0}, id);  
				write_byte(0)  
				write_string(HUD)  
				message_end()  		
			}
		}
	}	
	return PLUGIN_CONTINUE
}

// Nove kolo
public logevent_Round_Start() 
{ 
	round++;		
	static userTeam, model, tag, menu
	model = get_pcvar_num(vip_model) ? true : false;
	tag = get_pcvar_num(vip_tag) ? true : false;
	menu = get_pcvar_num(vip_menu) ? true : false;
	
	for(new player = 1; player <= maxplayers; player++ )
	{
		if(!is_user_alive(player))
			continue;	
			
		// Je vip ?
		if((get_user_flags(player) & ADMIN_LEVEL_F)) 
		{				
			client_cmd(player, "hud_centerid", "0");
			
			//Model  
			if(model) 
			{
	            userTeam = cs_get_user_team(player)
	            if (userTeam == CS_TEAM_T) {
	                cs_set_user_model(player, "gecom_te2")
	            } else if(userTeam == CS_TEAM_CT) {
	                cs_set_user_model(player, "gecom_ct2")
	            }
			}
			
			// VI P TAG
			if(tag) 
			{ 
				message_begin(2, msgscore, {0,0,0}, 0)
				write_byte(player)
				write_byte(4)
				message_end()			
			}
			
			// M E N U
			if(menu) 
			{  
				if(round > 5) {
					show_menu(player, TLACIDLA, 
					"VIP Panel by Seky^n\w1. M4A1+Deagle ^n\w2. AK47+Deagle ^n\w3. AWP+Deagle ^n\w4. Gulomet+USP ^n0. Exit^n",
					-1, "menu_id")
				}	
			}	
		}
	}
}
public menu_akcia(id, key) {
	/* Menu:
	* VIP Menu
	* 1. Get M4A1+Deagle
	* 2. Get AK47+Deagle
	* 0. Exit
	*/
	new zbran[32]
	
	switch (key) {
		case 0: { 
			drop_weapons(id, 1)
			drop_weapons(id, 2)
			fm_give_item(id,"weapon_m4a1")
			fm_give_item(id,"ammo_556nato")
			fm_give_item(id,"ammo_556nato")
			fm_give_item(id,"ammo_556nato")
			fm_give_item(id,"weapon_deagle")
			fm_give_item(id,"ammo_50ae")
			fm_give_item(id,"ammo_50ae")
			fm_give_item(id,"ammo_50ae")
			fm_give_item(id,"ammo_50ae")
			fm_give_item(id,"ammo_50ae")
			fm_give_item(id,"ammo_50ae")
			fm_give_item(id,"ammo_50ae")
			zbran="M4A1+Deagle"
		}
		case 1: { 
			drop_weapons(id, 1)
			drop_weapons(id, 2)
			fm_give_item(id,"weapon_ak47")
			fm_give_item(id,"ammo_762nato")
			fm_give_item(id,"ammo_762nato")
			fm_give_item(id,"ammo_762nato")
			fm_give_item(id,"weapon_deagle")
			fm_give_item(id,"ammo_50ae")
			fm_give_item(id,"ammo_50ae")
			fm_give_item(id,"ammo_50ae")
			fm_give_item(id,"ammo_50ae")
			fm_give_item(id,"ammo_50ae")
			fm_give_item(id,"ammo_50ae")
			fm_give_item(id,"ammo_50ae")
			zbran="AK47+Deagle"
		}
		case 2: { 
			drop_weapons(id, 1)
			drop_weapons(id, 2)
			fm_give_item(id,"weapon_awp")
			fm_give_item(id,"ammo_338magnum")
			fm_give_item(id,"ammo_338magnum")
			fm_give_item(id,"ammo_338magnum")
			fm_give_item(id,"ammo_338magnum")
			fm_give_item(id,"weapon_deagle")
			fm_give_item(id,"ammo_50ae")
			fm_give_item(id,"ammo_50ae")
			fm_give_item(id,"ammo_50ae")
			fm_give_item(id,"ammo_50ae")
			fm_give_item(id,"ammo_50ae")
			fm_give_item(id,"ammo_50ae")
			fm_give_item(id,"ammo_50ae")
			zbran="AWP+Deagle"
		}
		case 3: { 
			drop_weapons(id, 1)
			drop_weapons(id, 2)
			fm_give_item(id,"weapon_m249")
			fm_give_item(id,"ammo_556natobox")
			fm_give_item(id,"ammo_556natobox")
			fm_give_item(id,"ammo_556natobox")
			fm_give_item(id,"ammo_556natobox")
			fm_give_item(id,"weapon_usp")
			fm_give_item(id,"ammo_45acp")
			fm_give_item(id,"ammo_45acp")
			fm_give_item(id,"ammo_45acp")
			fm_give_item(id,"ammo_45acp")
			fm_give_item(id,"ammo_45acp")
			fm_give_item(id,"ammo_45acp")
			fm_give_item(id,"ammo_45acp")
			zbran="Gulomet+USP"
		}
		default: { // 0
			zbran = "Ziadna";
		}
	}	
		
	fm_give_item(id,"weapon_hegrenade")
	fm_give_item(id,"weapon_hegrenade")
	fm_give_item(id,"weapon_flashbang")
	fm_give_item(id,"weapon_flashbang")
	fm_give_item(id,"weapon_smokegrenade")
	fm_give_item(id,"item_kevlar")
	fm_give_item(id,"item_assaultsuit")
	cs_set_user_money(id, cs_get_user_money(id) + 5000);
	client_print(id,print_chat,"[VIP] %s + 5000$.",zbran);
	
	return PLUGIN_CONTINUE
}
public zachit_say(id) 
{
	set_task(0.1,"print_adminlist",id)
	return PLUGIN_CONTINUE;
	/*
	// VIP kontrola
	new said[192]
	read_args(said,192)
	if( ( containi(said, "who") != -1 && containi(said, "admin") != -1 ) || contain(said, "/vip") != -1 ) {
		set_task(0.1,"print_adminlist",id)
		return PLUGIN_CONTINUE;
	}
	
	// Prekonvertuje text na farby
	if( get_user_flags(id) & ADMIN_LEVEL_F ) {
		if (get_pcvar_num(vip_font)==1)  {
			new message[129]
			read_argv(1,message,128)
			
			if ( containi(message,"!t")==-1 &&
			     containi(message,"!w")==-1 &&
			     containi(message,"!g")==-1 )
			{
				return PLUGIN_CONTINUE
			}
			
			new szCommand[9]
			read_argv(0,szCommand,8)

			new CsTeams:team = cs_get_user_team(id)
			new isAlive = is_user_alive(id)
			
			new playerList[32]//players to send message to
			new playerCount
			
			new message_to_send[129] = "^x01"

			new szFlags[4] = ""
			if(isAlive){
				add(szFlags,3,"a")//Only alive players
			} else {
				add(szFlags,3,"b")//Only dead players
				add(message_to_send,128,"*DEAD*")
			}
			add(szFlags,3,"c")//skip bots
			
			if(equal(szCommand,"say_team")) {
				add(szFlags,3,"e")//Match with passed teamname
				if(team==CS_TEAM_T){
					get_players(playerList,playerCount,szFlags,"TERRORIST")
					add(message_to_send,128,"(Terrorist) ^x03")
				} else if(team==CS_TEAM_CT) {
					get_players(playerList,playerCount,szFlags,"CT")
					add(message_to_send,128,"(Counter-terrorist) ^x03")
				} else { //assume Spectator
					get_players(playerList,playerCount,szFlags,"SPECTATOR")
					add(message_to_send,128,"(Spectator) ^x03")
				}
			} else { //assume "say"
				get_players(playerList,playerCount,szFlags)
				if(isAlive)
				{
					add(message_to_send,128,"^x03")
				} else {
					add(message_to_send,128," ^x03")
				}
			}	
			
			new username[129]
			get_user_name(id,username,128)
			add(message_to_send,128,username)
			add(message_to_send,128,"^x01 :  ")

			add( message_to_send,128,message,(128-strlen(message_to_send)) )

			while(containi(message_to_send,"!t") != -1)
			{
				replace(message_to_send,128,"!T","^x03")
				replace(message_to_send,128,"!t","^x03")
			}
			while(containi(message_to_send,"!g") != -1)
			{
				replace(message_to_send,128,"!G","^x04")
				replace(message_to_send,128,"!g","^x04")
			}
			while(containi(message_to_send,"!w") != -1)
			{
				replace(message_to_send,128,"!W","^x01")
				replace(message_to_send,128,"!w","^x01")
			}


			for(new i=0; i<playerCount; i++)
			{
				message_begin(MSG_ONE, gmsgSayText, {0,0,0}, playerList[i])
				write_byte(playerList[i])
				write_string(message_to_send)
				message_end()			
			}
	
		} 
	}*/ 
}

public print_adminlist(user) 
{
	// vypis VIP
	new adminnames[33][32]
	new message[256]
	new id, count, x, len
	
	for(id = 1 ; id <= maxplayers ; id++)
		if(is_user_connected(id))
			if(get_user_flags(id) & ADMIN_LEVEL_F)
				get_user_name(id, adminnames[count++], 31)

	len = format(message, 255, "^x03 VIP Online: ")
	if(count > 0) {
		for(x = 0 ; x < count ; x++) {
			len += format(message[len], 255-len, "%s%s%s ", "^x01", adminnames[x], x < (count-1) ? ", ": "")
			if(len > 96 ) {
				print_message(user, message)
				len = format(message, 255, "^x01 ")
			}
		}
		print_message(user, message)
	}
	else {
		len += format(message[len], 255-len, "^x01 Ziadny VIP.")
		print_message(user, message)
	}
	
	print_message(user, CONTACT)
}
print_message(id, msg[]) {
	message_begin(MSG_ONE, gmsgSayText, {0,0,0}, id)
	write_byte(id)
	write_string(msg)
	message_end()
}
public plugin_precache() {
	precache_model("models/player/gecom_ct2/gecom_ct2.mdl")
	precache_model("models/player/gecom_ct2/gecom_ct2T.mdl")
	precache_model("models/player/gecom_te2/gecom_te2.mdl")
}
stock fm_give_item(index, const item[])
{
	if ( !equal(item, "weapon_", 7) && !equal(item, "ammo_", 5) && !equal(item, "item_", 5) && !equal(item, "tf_weapon_", 10) )
		return 0
	new ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, item))
	if ( !pev_valid(ent) )
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


//==========================================
//===========================================
// M E G A  FU K N CI A NA zbrane
// + fakameta
#if cellbits == 32
const OFFSET_CSTEAMS = 114
const OFFSET_CSMONEY = 115
const OFFSET_NVGOGGLES = 129
const OFFSET_ZOOMTYPE = 363
const OFFSET_CSDEATHS = 444
const OFFSET_AWM_AMMO  = 377 
const OFFSET_SCOUT_AMMO = 378
const OFFSET_PARA_AMMO = 379
const OFFSET_FAMAS_AMMO = 380
const OFFSET_M3_AMMO = 381
const OFFSET_USP_AMMO = 382
const OFFSET_FIVESEVEN_AMMO = 383
const OFFSET_DEAGLE_AMMO = 384
const OFFSET_P228_AMMO = 385
const OFFSET_GLOCK_AMMO = 386
const OFFSET_FLASH_AMMO = 387
const OFFSET_HE_AMMO = 388
const OFFSET_SMOKE_AMMO = 389
const OFFSET_C4_AMMO = 390
const OFFSET_CLIPAMMO = 51
#else
const OFFSET_CSTEAMS = 139
const OFFSET_CSMONEY = 140
const OFFSET_NVGOGGLES = 155
const OFFSET_ZOOMTYPE = 402
const OFFSET_CSDEATHS = 493
const OFFSET_AWM_AMMO  = 426
const OFFSET_SCOUT_AMMO = 427
const OFFSET_PARA_AMMO = 428
const OFFSET_FAMAS_AMMO = 429
const OFFSET_M3_AMMO = 430
const OFFSET_USP_AMMO = 431
const OFFSET_FIVESEVEN_AMMO = 432
const OFFSET_DEAGLE_AMMO = 433
const OFFSET_P228_AMMO = 434
const OFFSET_GLOCK_AMMO = 435
const OFFSET_FLASH_AMMO = 46
const OFFSET_HE_AMMO = 437
const OFFSET_SMOKE_AMMO = 438
const OFFSET_C4_AMMO = 439
const OFFSET_CLIPAMMO = 65
#endif
const OFFSET_LINUX = 5 // offsets 5 higher in Linux builds
const OFFSET_LINUX_WEAPONS = 4 // weapon offsets are only 4 steps higher on Linux
const PRIMARY_WEAPONS_BIT_SUM = (1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90)
const SECONDARY_WEAPONS_BIT_SUM = (1<<CSW_P228)|(1<<CSW_ELITE)|(1<<CSW_FIVESEVEN)|(1<<CSW_USP)|(1<<CSW_GLOCK18)|(1<<CSW_DEAGLE)
const PEV_ADDITIONAL_AMMO = pev_iuser1

stock drop_weapons(id, dropwhat)
{
	// Get user weapons
	static weapons[32], num, i, weaponid
	num = 0 // reset passed weapons count (bugfix)
	get_user_weapons(id, weapons, num)
	
	// Loop through them and drop primaries or secondaries
	for (i = 0; i < num; i++)
	{
		// Prevent re-indexing the array
		weaponid = weapons[i]
		
		if ((dropwhat == 1 && ((1<<weaponid) & PRIMARY_WEAPONS_BIT_SUM)) || (dropwhat == 2 && ((1<<weaponid) & SECONDARY_WEAPONS_BIT_SUM)))
		{
			// Get the weapon entity
			static wname[32], weapon_ent
			get_weaponname(weaponid, wname, sizeof wname - 1)
			weapon_ent = fm_find_ent_by_owner(-1, wname, id);
			
			// Hack: store weapon bpammo on PEV_ADDITIONAL_AMMO
			set_pev(weapon_ent, PEV_ADDITIONAL_AMMO, fm_get_user_bpammo(id, weaponid))
			
			// Player drops the weapon and looses his bpammo
			engclient_cmd(id, "drop", wname)
			fm_set_user_bpammo(id, weaponid, 0)
		}
	}
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
}
stock fm_get_user_bpammo(id, weapon)
{
	static offset
	
	switch(weapon)
	{
		case CSW_AWP: offset = OFFSET_AWM_AMMO;
		case CSW_SCOUT,CSW_AK47,CSW_G3SG1: offset = OFFSET_SCOUT_AMMO;
		case CSW_M249: offset = OFFSET_PARA_AMMO;
		case CSW_M4A1,CSW_FAMAS,CSW_AUG,CSW_SG550,CSW_GALI,CSW_SG552: offset = OFFSET_FAMAS_AMMO;
		case CSW_M3,CSW_XM1014: offset = OFFSET_M3_AMMO;
		case CSW_USP,CSW_UMP45,CSW_MAC10: offset = OFFSET_USP_AMMO;
		case CSW_FIVESEVEN,CSW_P90: offset = OFFSET_FIVESEVEN_AMMO;
		case CSW_DEAGLE: offset = OFFSET_DEAGLE_AMMO;
		case CSW_P228: offset = OFFSET_P228_AMMO;
		case CSW_GLOCK18,CSW_MP5NAVY,CSW_TMP,CSW_ELITE: offset = OFFSET_GLOCK_AMMO;
		case CSW_FLASHBANG: offset = OFFSET_FLASH_AMMO;
		case CSW_HEGRENADE: offset = OFFSET_HE_AMMO;
		case CSW_SMOKEGRENADE: offset = OFFSET_SMOKE_AMMO;
		case CSW_C4: offset = OFFSET_C4_AMMO;
		default: return -1;
	}
	
	return get_pdata_int(id, offset, OFFSET_LINUX);
}
stock fm_set_user_bpammo(id, weapon, amount)
{
	static offset
	
	switch(weapon)
	{
		case CSW_AWP: offset = OFFSET_AWM_AMMO;
		case CSW_SCOUT,CSW_AK47,CSW_G3SG1: offset = OFFSET_SCOUT_AMMO;
		case CSW_M249: offset = OFFSET_PARA_AMMO;
		case CSW_M4A1,CSW_FAMAS,CSW_AUG,CSW_SG550,CSW_GALI,CSW_SG552: offset = OFFSET_FAMAS_AMMO;
		case CSW_M3,CSW_XM1014: offset = OFFSET_M3_AMMO;
		case CSW_USP,CSW_UMP45,CSW_MAC10: offset = OFFSET_USP_AMMO;
		case CSW_FIVESEVEN,CSW_P90: offset = OFFSET_FIVESEVEN_AMMO;
		case CSW_DEAGLE: offset = OFFSET_DEAGLE_AMMO;
		case CSW_P228: offset = OFFSET_P228_AMMO;
		case CSW_GLOCK18,CSW_MP5NAVY,CSW_TMP,CSW_ELITE: offset = OFFSET_GLOCK_AMMO;
		case CSW_FLASHBANG: offset = OFFSET_FLASH_AMMO;
		case CSW_HEGRENADE: offset = OFFSET_HE_AMMO;
		case CSW_SMOKEGRENADE: offset = OFFSET_SMOKE_AMMO;
		case CSW_C4: offset = OFFSET_C4_AMMO;
		default: return;
	}
	
	set_pdata_int(id, offset, amount, OFFSET_LINUX)
}