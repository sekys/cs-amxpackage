
#define zp_play_random(%1) \
	ArrayGetString(%1, random_num(0, ArraySize(%1) - 1), sound, charsmax(sound)); \
	PlaySound(sound);

#define zp_play_randomS(%1) \
	static sound[64]; \
	ArrayGetString(%1, random_num(0, ArraySize(%1) - 1), sound, charsmax(sound)); \
	PlaySound(sound);

stock zp_make_a_zombie(	const mode, const id, 
						const iPlayersnum, const preventconsecutive, 
						koniec) 
{
	if ((mode == MODE_NONE && (!preventconsecutive || g_lastmode != MODE_DERATIZER) && random_num(1, get_pcvar_num(cvar_deratizervchance)) == get_pcvar_num(cvar_deratizerv) && iPlayersnum >= get_pcvar_num(cvar_deratizervminplayers)) || mode == MODE_DERATIZER)
	{
		zp_make_deratizer(mode, id, iPlayersnum);	
		return true;
	} else if ((mode == MODE_NONE && (!preventconsecutive || g_lastmode != MODE_MARRY) && random_num(1, get_pcvar_num(cvar_marrychance)) == get_pcvar_num(cvar_marry) && iPlayersnum >= get_pcvar_num(cvar_marryminplayers)) || mode == MODE_MARRY)
	{
		new ret = zp_make_svadbu(mode, id, iPlayersnum);
		if(ret == -1) {
			koniec = -1;
		}
		return true;
	} else if ((mode == MODE_NONE && (!preventconsecutive || g_lastmode != MODE_MOB) && random_num(1, get_pcvar_num(cvar_mobchance)) == get_pcvar_num(cvar_mob) && floatround((iPlayersnum-2)*get_pcvar_float(cvar_mobratio), floatround_ceil) >= 1 && iPlayersnum >= get_pcvar_num(cvar_mobminplayers)) || mode == MODE_MOB)
	{
		zp_make_mob(mode, id, iPlayersnum);
		return true;
	} else if ((mode == MODE_NONE && (!preventconsecutive || g_lastmode != MODE_WITCH) && random_num(1, get_pcvar_num(cvar_witchchance)) == get_pcvar_num(cvar_witch) && iPlayersnum >= get_pcvar_num(cvar_witchminplayer)) || mode == MODE_WITCH)
	{	
		zp_make_witch(mode, id, iPlayersnum);
		return true;
	} else if ((mode == MODE_NONE && (!preventconsecutive || g_lastmode != MODE_MOM) && random_num(1, get_pcvar_num(cvar_momchance)) == get_pcvar_num(cvar_mom) && iPlayersnum >= get_pcvar_num(cvar_momminplayers)) || mode == MODE_MOM)
	{	
		zp_make_mom(mode, id, iPlayersnum);
		return true;
	}
	return false;
}
stock zp_make_deratizer(const mode, id, const iPlayersnum) {
	// Deratizer Mode
	g_deratizervround = true
	g_lastmode = MODE_DERATIZER
	
	// Choose player randomly?
	if (mode == MODE_NONE) id = fnGetRandomAlive(random_num(1, iPlayersnum))		
	// Turn player into a survivor
	humanme(id, 2);
	// Hladame svaba podla mena
	new ID_SVABA = HladajClassIdPodlaNazvu(svab_meno);
	
	//client_print(0, print_chat, "id svaba %d",ID_SVABA) // log
	if(ID_SVABA == -1) {
		client_print(0, print_chat, "[G/L ZP] Svab plugin nieje nainstalovany.")
	}	
	
	for (new i = 1; i <= g_maxplayers; i++) {
		if (!g_isalive[i]) continue;
		if (g_deratizer[i] || g_zombie[i]) continue;
		
		// Nastavime
		if(ID_SVABA) {
			//client_print(0, print_chat, "%d %d",id, g_zombieclass[id]) // log
			if( g_zombieclassnext[i] != ID_SVABA) {			
				g_stara_trieda[i] = g_zombieclass[i];
				g_zombieclassnext[i] = ID_SVABA
				//client_print(0, print_chat, "nastaveny zombie") // log
			}	
		}
		// Info sprava
		client_print(i, print_chat, "[G/L ZP] Musis sa skryt aby ta deratizer nenasiel!")
		// Turn into a zombie
		zombieme(i, 0, 0, 1)
	}
	
	// Play survivor sound
	zp_play_randomS(sound_plague)
	
	// Show Survivor HUD notice
	set_hudmessage(20, 20, 255, HUD_EVENT_X, HUD_EVENT_Y, 1, 0.0, 5.0, 1.0, 1.0, -1)
	ShowSyncHudMsg(0, g_MsgSync, "%L", LANG_PLAYER, "NOTICE_DERATIZER", g_playername[id])
	// Round start forward
	g_modestarted = true
	ExecuteForward(g_fwRoundStart, g_fwDummyResult, MODE_DERATIZER, id);
	return id;
}
stock zp_make_svadbu(const mode, const id, const iPlayersnum) 
{
	new svadobcania[2], hrac_a, hrac_b, hrac
	hrac_a = random_num(0, 1);
	g_lastmode = MODE_MARRY;
	
	// Trocha to este zamiesame ....
	svadobcania[hrac_a] = (!id) ? fnGetRandomAlive(random_num(1, iPlayersnum)) : id;
	hrac_b = (hrac_a==1) ? 0 : 1;
	
	// Hladame druheho hraca ......nahodne
	hrac = fnGetRandomAlive(random_num(1, iPlayersnum));
	if(svadobcania[hrac_a] !=  hrac) {	
		svadobcania[hrac_b] = hrac;
	} else { // Ak ziadneho nenaslo daj dalsieho zaradom .....
		for (hrac = 1; hrac <= g_maxplayers; hrac++) {
			if (!g_isalive[hrac]) continue;
			if(svadobcania[hrac_a] ==  hrac) continue;
			svadobcania[hrac_b] = hrac;
			break;
		}
	}
	
	// NASLI sme niekoho ?...vobec sme nenasli
	if(!svadobcania[hrac_b]) {
		// pre static by nebolo rozumne volat rekurzivne ...
		// set_task(1.0, "make_zombie_task", TASK_MAKEZOMBIE)
		return -1;
	}
	// Nemesis 
	g_nemround = true;
	zombieme(svadobcania[0], 0, 4, 0)
	// WItch
	g_witchround = true;
	zombieme(svadobcania[1], 0, 5, 0)
	
	// Spolu
	set_hudmessage(255, 20, 20, HUD_EVENT_X, HUD_EVENT_Y, 1, 0.0, 5.0, 1.0, 1.0, -1)
	ShowSyncHudMsg(0, g_MsgSync, "%L", LANG_PLAYER, "NOTICE_MARRY", g_playername[svadobcania[0]], g_playername[svadobcania[1]])

	static sound[64]
	if(hrac_a) {
		zp_play_random(sound_nemesis)
	} else {
		zp_play_random(sound_witch)
	}	
	// Ostatny
	for (new i = 1; i <= g_maxplayers; i++) {
		if (!g_isalive[i]) continue;
		if(i == svadobcania[0] || i == svadobcania[1]) continue;
	
		// Switch to CT
		if (fm_get_user_team(i) != FM_CS_TEAM_CT) // need to change team?
		{
			remove_task(i+TASK_TEAM)
			fm_set_user_team(i, FM_CS_TEAM_CT)
			fm_user_team_update(i)
		}
	}
	g_modestarted = true
	ExecuteForward(g_fwRoundStart, g_fwDummyResult, MODE_MARRY, 0);
	return 0;
}
stock zp_make_mob(const mode,const id, const iPlayersnum) {
	// mob Mode
	new hrac, iZombies
	g_mobround = true;
	g_lastmode = MODE_MOB;
			
	// iMaxZombies is rounded up, in case there aren't enough players
	new iMaxZombies = floatround(iPlayersnum*get_pcvar_float(cvar_mobratio), floatround_ceil)
	
	// Randomly turn iMaxZombies players into zombies
	while (iZombies < iMaxZombies) {
		// Keep looping through all players
		if (hrac++ == g_maxplayers) hrac = 0;
		// Dead or already a zombie or survivor
		if (!g_isalive[hrac] || g_zombie[hrac] || hrac == id) continue;
		
		// Random chance
		if (random_num(0, 1)) {
			// Turn into a zombie
			zombieme(hrac, 0, 0, 1)
			iZombies++
		}
	}
	
	// Turn the rest of players into humans
	for (hrac = 1; hrac <= g_maxplayers; hrac++) {
		if (!g_isalive[hrac] || g_zombie[hrac]) continue
		
		// Switch to CT
		if (fm_get_user_team(hrac) != FM_CS_TEAM_CT) // need to change team?
		{
			remove_task(hrac+TASK_TEAM)
			fm_set_user_team(hrac, FM_CS_TEAM_CT)
			fm_user_team_update(hrac)
		}
	}
	
	// Play mob sound
	zp_play_randomS(sound_mob)
	// Show mob HUD notice
	set_hudmessage(0, 50, 200, HUD_EVENT_X, HUD_EVENT_Y, 1, 0.0, 5.0, 1.0, 1.0, -1)
	ShowSyncHudMsg(0, g_MsgSync, "%L", LANG_PLAYER, "NOTICE_MOB")
	// Round start forward
	g_modestarted = true
	ExecuteForward(g_fwRoundStart, g_fwDummyResult, MODE_MOB, 0);
	return 0;
}
stock zp_make_witch(const mode, id, const iPlayersnum) {
	// Choose player randomly?
	if (mode == MODE_NONE) id = fnGetRandomAlive(random_num(1, iPlayersnum))
	
	g_witchround = true
	g_lastmode = MODE_WITCH
	zombieme(id, 0, 2, 0)
	
	// Rest of players should be humans (CTs)
	for (new i = 1; i <= g_maxplayers; i++) {
		if (!g_isalive[i]) continue;
		if (g_zombie[i]) continue;
		
		// Switch to CT
		if (fm_get_user_team(i) != FM_CS_TEAM_CT) // need to change team?
		{
			remove_task(i+TASK_TEAM)
			fm_set_user_team(i, FM_CS_TEAM_CT)
			fm_user_team_update(i)
		}
	}

	// Play Nemesis sound
	zp_play_randomS(sound_witch)
	
	// Show Nemesis HUD notice
	set_hudmessage(255, 20, 20, HUD_EVENT_X, HUD_EVENT_Y, 1, 0.0, 5.0, 1.0, 1.0, -1)
	ShowSyncHudMsg(0, g_MsgSync, "%L", LANG_PLAYER, "NOTICE_WITCH", g_playername[id])
	// Round start forward
	g_modestarted = true
	ExecuteForward(g_fwRoundStart, g_fwDummyResult, MODE_WITCH, id);
	return id;
}
stock zp_make_mom(const mode, id, const iPlayersnum) {
	// Choose player randomly?
	if (mode == MODE_NONE)
		id = fnGetRandomAlive(random_num(1, iPlayersnum))
	
	g_momround = true
	g_lastmode = MODE_MOM
	// Turn player into nemesis
	zombieme(id, 0, 3, 0)
	
	
	// Rest of players should be humans (CTs)
	for(new i = 1; i <= g_maxplayers; i++) {
		if (!g_isalive[i]) continue;	
		if (g_zombie[i]) continue;	
		
		// Switch to CT
		if (fm_get_user_team(i) != FM_CS_TEAM_CT) // need to change team?
		{
			remove_task(i+TASK_TEAM)
			fm_set_user_team(i, FM_CS_TEAM_CT)
			fm_user_team_update(i)
		}
	}
	// Show Nemesis HUD notice
	set_hudmessage(255, 20, 20, HUD_EVENT_X, HUD_EVENT_Y, 1, 0.0, 5.0, 1.0, 1.0, -1)
	ShowSyncHudMsg(0, g_MsgSync, "%L", LANG_PLAYER, "NOTICE_MOM", g_playername[id])
	
	// Round start forward
	g_modestarted = true
	ExecuteForward(g_fwRoundStart, g_fwDummyResult, MODE_MOM, id);
	return id;
}
