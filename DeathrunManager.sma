#include <amxmodx>
#include <amxmisc>
#include <fakemeta>	
#include <hamsandwich>
#include <engine>
#include <dr>

// Menu spravit, Vymeni sa z
// Pidat druhy plugin a cez native odosielat vysledky do databazy
// ako najrychlejsi cas na mape, najvacsie skore na mape,
// top aj celkovo a pod.

#if cellbits == 32
	#define OFFSET_BZ 235
#else
	#define OFFSET_BZ 268
#endif

#define spawn(%1)					ExecuteHamB(Ham_CS_RoundRespawn, %1)
#define fm_reset_user_model(%1) 	dllfunc(DLLFunc_ClientUserInfoChanged, %1, engfunc(EngFunc_GetInfoKeyBuffer, %1))
#define is_solid(%1)				( pev(%1, pev_solid) == SOLID_SLIDEBOX )
#define fm_remove_entity(%1) 		engfunc(EngFunc_RemoveEntity, %1)

#define BOT_NAME 		"GeCom::Lekos"
#define MAX_ENTIT 		300	// maximalne rozbitnych entit .....
#define TASK_HUD		102

const KEYSMENU = (1<<0)|(1<<1)|(1<<2)|(1<<3)|(1<<4)|(1<<5)|(1<<6)|(1<<7)|(1<<8)|(1<<9)
new const TeamInfo[][] = { "UNASSIGNED", "TERRORIST", "CT", "SPECTATOR" };
new const DR_MENO[] = "^x04[G/L DR]^x01 %L";

new bool:mapa_haunted, bool:mapa_gamer,
	g_SprayB, g_RemoveBZ, g_nasobic, bool:zivoty_supovolene, gMaxPlayers, bot_id,
	g_HideHud, gMsgWeapon, gMsgCrosshair, gMsgStatus, gMsgMoney, gMsgSayText, g_Semiclip, gMsgTeamInfo, 
	entita[MAX_ENTIT], Float:entita_fl[MAX_ENTIT], g_nasobic2,
	cas_min[33], cas_sec[33], bool:pObnovit[33],
	ForwardGameMenu, ForwardResult

public plugin_init() {
	register_plugin("Death-Run-Match", "1.0", "Seky" );
	
	g_SprayB     = register_cvar( "deathrun_spray",      "0" );
	g_RemoveBZ   = register_cvar( "deathrun_removebz",   "1" );
	g_HideHud    = register_cvar( "deathrun_hidehud",    "1" );
	g_nasobic	 = register_cvar( "deathrun_t_add",  	 "12" );
	g_nasobic2	 = register_cvar( "deathrun_t_del",  	 "8" );
	g_Semiclip	 = register_cvar( "deathrun_semiclip",	 "1" );
		
	gMaxPlayers     = get_maxplayers();
	gMsgMoney       = get_user_msgid("Money");
	gMsgSayText     = get_user_msgid("SayText");
	gMsgTeamInfo	= get_user_msgid("TeamInfo");
	gMsgStatus 		= get_user_msgid("StatusText");
	
	InitMapUtilities();
	RegisterHam( Ham_Spawn, "player", "FwdHamPlayerSpawnPost", 1);
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled");
	
	register_menucmd(register_menuid("Team_Select",1),(1<<0)|(1<<1)|(1<<4),"event_vyber_teamov_2");
	register_forward( FM_PlayerPostThink,	"postThink");
	register_logevent("nove_kolo", 2, "1=Round_Start");
	register_menu("Game Menu", KEYSMENU, "GameMenu");
	register_event("Money",	"eMoney", "b" );
	register_dictionary("deathrun.txt");
	
	register_clcmd("deathrun_obnov", "cmd_obnov", ADMIN_BAN, "Obnovy mapu " );
	register_clcmd("fullupdate", "clcmd_fullupdate"); 
	register_clcmd("say menu", "clcmd_GameMenu");
	register_clcmd("say /menu", "clcmd_GameMenu");
	register_clcmd("say /dr", "clcmd_GameMenu");
	register_clcmd("jointeam",	 "event_vyber_teamov_1");
	register_clcmd("chooseteam", "clcmd_changeteam")	
	register_clcmd("say /lifes",	"cmdShowlifes");
	register_clcmd("say /lives", 	"cmdShowlifes");
	register_clcmd("say /zivotov",  "cmdShowlifes");
	register_clcmd("say /zivot", 	"respawn");
	register_clcmd("say /respawn", 	"respawn");
	register_clcmd("say /spawn", 	"respawn");
	register_clcmd("say /kill", 	"respawn");
	
	// Vlastne dalsie nastavenia ...
	if( get_pcvar_num(g_SprayB) ) register_impulse( 201, "FwdImpulse_201" );	
	if( get_pcvar_num(g_HideHud) ) { 
		gMsgWeapon = get_user_msgid( "HideWeapon" );
		gMsgCrosshair  = get_user_msgid( "Crosshair" );
		register_event("ResetHUD",	"eResetHUD", "be" );
	}	
	if( get_pcvar_num(g_Semiclip) ) {
		register_forward(FM_PlayerPreThink, "preThink");
		register_forward(FM_AddToFullPack, "addToFullPack", 1);
	}	
	
	obnov_prestrelne_save();
	InitTasks();
	
	ForwardGameMenu = CreateMultiForward("dr_GameMenu", ET_IGNORE, FP_CELL, FP_CELL);
	ForwardGameMenu = CreateMultiForward("dr_kill", ET_IGNORE, FP_CELL, FP_CELL);
}
stock InitMapUtilities() {
	// Mapa
	new szMapName[ 64 ];
	get_mapname( szMapName, 63 );
	
	if( contain( szMapName, "deathrun_" ) != -1 ) {
		if( contain( szMapName, "hauntedhouse" ) != -1 )
			mapa_haunted = true;
		else {
			mapa_gamer = ( equal( szMapName, "deathrun_gamerfun" ) ) ? true : false
		}
	}
	if( get_pcvar_num(g_RemoveBZ) ) {
		register_message( get_user_msgid("StatusIcon"), "MsgStatusIcon" ); // BuyZone Icon

		// Remove buyzone on map
		remove_entity_name( "info_map_parameters" );
		remove_entity_name( "func_buyzone" );
		
		// Create own entity to block buying
		new ent = create_entity( "info_map_parameters" );
		set_kvd( 0, KV_ClassName, "info_map_parameters" );
		set_kvd( 0, KV_KeyName, "buying" );
		set_kvd( 0, KV_Value, "3" );
		set_kvd( 0, KV_fHandled, 0 );
		
		dllfunc( DLLFunc_KeyValue, ent, 0);
		dllfunc( DLLFunc_Spawn, ent);
	}
}
stock InitTasks() {
	if(!mapa_haunted ) set_task(180.0, "precisti_mapu", _,_,_, "b");
	set_task(30.0, "TerroristQuotaSystem", _,_,_, "b");
	set_task(5.0, "UpdateBot" );
	set_task(90.0, "obnov_mapu", _,_,_, "b");
	set_task(1.0, "HudCyklus", TASK_HUD, _, _, "b");
}
public HudCyklus() {
	static sprava[128], meno2[32], id
	for(id = 1; id <= gMaxPlayers; id++) {
		if (!is_user_alive(id)) continue;
		if(is_user_bot(id)) continue;
		// Mieritko
		/*get_user_aiming(id, ciel, docasne, 500)
		if( ciel > 0 && is_user_alive(ciel)) {
			get_user_name(ciel, meno, 31);
		} else {
			format(meno, 31, "");
		}*/
		get_user_name(id, meno2, 31);
		CasovacUpdate(id);
		// Odosleme informacie
		formatex(sprava, 127, "%s [Body %d|VIP %s| %2d:%2d] ", // %s 
			meno2, dr_get_user_ammo_packs(id), (get_user_flags(id) & ADMIN_LEVEL_F ) ? "on" : "off", 
			cas_min[id], cas_sec[id]) // , meno)
		message_begin(MSG_ONE, gMsgStatus, {0,0,0}, id);
		write_byte(0)
		write_string(sprava)
		message_end()
	}
	return PLUGIN_CONTINUE;
}
stock CasovacUpdate(const id) {
	// Casovac					get_systime() nam netreba ....
	if(cas_sec[id] == 59)	{
		cas_min[id]++;	
		cas_sec[id]=-1;
	}
	cas_sec[id]++;
}
public UpdateBot() {
	new id = find_player("i");
	if(!id) {
		id = engfunc( EngFunc_CreateFakeClient, BOT_NAME );
		if( pev_valid( id ) ) {
			engfunc( EngFunc_FreeEntPrivateData, id );
			dllfunc( MetaFunc_CallGameEntity, "player", id );
			set_user_info( id, "rate", "3500" );
			set_user_info( id, "cl_updaterate", "25" );
			set_user_info( id, "cl_lw", "1" );
			set_user_info( id, "cl_lc", "1" );
			set_user_info( id, "cl_dlmax", "128" );
			set_user_info( id, "cl_righthand", "1" );
			set_user_info( id, "_vgui_menus", "0" );
			set_user_info( id, "_ah", "0" );
			set_user_info( id, "dm", "0" );
			set_user_info( id, "tracker", "0" );
			set_user_info( id, "friends", "0" );
			set_user_info( id, "*bot", "1" );
			set_pev( id, pev_flags, pev( id, pev_flags ) | FL_FAKECLIENT );
			set_pev( id, pev_colormap, id );
			
			new szMsg[ 128 ];
			dllfunc( DLLFunc_ClientConnect, id, BOT_NAME, "127.0.0.1", szMsg );
			dllfunc( DLLFunc_ClientPutInServer, id );	
			fm_set_user_team( id, CS_TEAM_T );
			spawn(id)
		
			set_pev( id, pev_effects, pev( id, pev_effects ) | EF_NODRAW );
			set_pev( id, pev_solid, SOLID_NOT );
			dllfunc( DLLFunc_Think, id );		
			bot_id = id;			
		}
	}
}
public TerroristQuotaSystem() {
	// Cvars
	set_cvar_num ("mp_autoteambalance",	0)
	set_cvar_num ("mp_limitteams",		50)
	set_cvar_num ("mp_fraglimit",		0)
	static i, terroristov , hracov, uspech, team;
	terroristov = hracov = uspech = 0;
	
	// Pocitame hracov
	for( i = 1; i <= gMaxPlayers; i++ ) {			
		if(!is_user_connected(i)) continue;
		if(is_user_bot(i)) continue;			
		team = fm_get_user_team(i);
		// Bug s SPE
		if(team == CS_TEAM_SPECTATOR) {
			if (is_user_alive(i)) user_silentkill(i);
			continue; // Rovno pokracujeme dalej ....
		}
		if(team == CS_TEAM_CT) {
			hracov++;
			continue;
		}
		if( team == CS_TEAM_T ) {
			hracov++;
			// Bugfix ak na novej mape niekto ostane v T ako DEAD
			if(!is_user_alive(i)) {
				fm_set_user_team(i, CS_TEAM_CT);
				fm_reset_user_model(i);	
				spawn(i);
			} else {
				terroristov++;
			}
		}
	}
	//Ak niesu hraci ...
	if(!hracov) return PLUGIN_CONTINUE;
	//  CTcko odober
	if( (hracov < get_pcvar_num(g_nasobic2) &&  terroristov > 1) || terroristov >= 3) {
		uspech = RandomPlayer(CS_TEAM_T);
		if(uspech != 1) {
			fm_set_user_team(uspech, CS_TEAM_CT);
			fm_reset_user_model(uspech);	
			spawn(uspech)	
		}
		return PLUGIN_CONTINUE;
	}
	//  CTcko pridaj							Bug ak je sam .T ...
	if( hracov > get_pcvar_num(g_nasobic)*terroristov && hracov > 1) {
		uspech = RandomPlayer(CS_TEAM_CT);
		if(uspech != -1) Player2CT(uspech);
		return PLUGIN_CONTINUE;
	}
	return PLUGIN_CONTINUE;
}
stock RandomPlayer(const team) {
	// Nahodne najdeme hraca ...
	new hracov, buffer[32], i;
	for(i=1; i <= gMaxPlayers; i++ ) {			
		if(!is_user_connected(i)) continue;
		if(is_user_bot(i)) continue;
		if( fm_get_user_team(i) == team) {
			buffer[hracov] = i;
			hracov++;
		}
	}
	// Nic sme nenasli
	if(!hracov) return -1;
	return buffer[random_num(0, hracov)];
}
stock Player2CT(const uspech) {
	fm_set_user_team(uspech, CS_TEAM_T);
	fm_reset_user_model(uspech);
	spawn(uspech);
	
	static szName[32], i;
	get_user_name(uspech, szName, 31);
	for(i = 1; i <= gMaxPlayers; i++ ) {
		if(!is_user_connected(i)) continue;
		dr_colored_print(i, DR_MENO, i, "DR_NOW_TERR", "^x03", szName, "^x01");
	}
}
public fw_PlayerKilled(victim, attacker, shouldgib) {
	// Je respawn povoleny ?
	if(!zivoty_supovolene) return PLUGIN_CONTINUE;
	// Zistime este jeho team ..
	new team = fm_get_user_team(victim);
	client_print(0, print_console, "#DR#->Killed(%d, %d, %d);", victim, attacker, team);		// log
	// Bug
	if( team == CS_TEAM_SPECTATOR || team == CS_TEAM_UNASSIGNED) {
		return;
	}	
	// CT zabil T
	if( attacker != victim && fm_get_user_team(attacker) == CS_TEAM_CT && team == CS_TEAM_T) {	
		client_print(0, print_console, "#DR#->CT zabil T");		// log
		KillCTZabilT(victim, attacker);
		return 
	}
	// Ak nahodou T spadol .....
	if( team == CS_TEAM_T) {
		client_print(0, print_console, "#DR#->T Spadol");		// log
		KillTSpadol(victim);
		return;
	}
	// Ani jedna moznost ,teda CT spadol
	if( team == CS_TEAM_CT)	{
		client_print(0, print_console, "#DR#->CT Spadol");		// log
		set_task(1.0, "SpawnDelay", victim);
		return;
	}
	// Este existuju male moznosti pri SPECTATOR spawne ale horna podmienka to blokuje .....
}
public SpawnDelay(const id) {
	if(is_user_alive(id)) PLUGIN_CONTINUE;
	spawn(id);
	return PLUGIN_CONTINUE;
}
stock KillTSpadol(const victim) {
	// Najdeme nahradu ....	
	static uspech;
	uspech = RandomPlayer_Okrem(CS_TEAM_CT, victim);
	if(uspech != -1) {
		Player2CT(uspech);
		set_hudmessage(255, 0, 0, 0.7, 0.1, 0, 0.1, 5.0, 0.0, 0.0,4)
		show_hudmessage(victim, "Vydrzal si:^n %2d:%2d", cas_min[victim], cas_sec[victim] - 1)
		fm_set_user_team(victim, CS_TEAM_CT);
		spawn(victim);
	} else {
		// Nieje ziadna nahrada
		spawn(victim);
	}
}
stock RandomPlayer_Okrem(const team, const okrem) {
	// Nahodne najdeme hraca ...
	new hracov, buffer[32], i;
	for(i=1; i <= gMaxPlayers; i++ ) {			
		if(!is_user_connected(i)) continue;
		if(is_user_bot(i)) continue;
		if( fm_get_user_team(i) == team && i != okrem) {
			buffer[hracov] = i;
			hracov++;
		}
	}
	// Nic sme nenasli
	if(!hracov) return -1;
	return buffer[random_num(0, hracov)];
}
stock KillCTZabilT(const victim, const attacker) {
	//cas_sec[attacker]--; // prefix DEATH_CASOVACu		
	zivoty_supovolene = false;
	fm_set_user_team(attacker, CS_TEAM_T);
	fm_reset_user_model(attacker);
	static szName[32], i;
	get_user_name(attacker, szName, 31);
	fm_set_user_team(victim, CS_TEAM_CT);
	
	// Ak mal checkpointy
	if( vymaz_checkpointy(attacker) != -1)
		dr_colored_print(attacker, "^x04[G/L DR]^x01 Stal si sa T, zmazali sa ti checkpointy.")
		
	for( i=1; i <= gMaxPlayers; i++ ) {
		if(!is_user_connected(i) ) continue;			
		if(is_user_bot(i) ) continue;		
		// Respawnujeme vsetky CTcka ALEBO vsetkych zabijeme pre nove kolo ...
		if(is_user_alive(i)) user_silentkill(i);
				
		set_hudmessage(0, 255, 0, 0.7, 0.1, 0, 0.1, 5.0, 0.0, 0.0,4) 
		show_hudmessage(i, "Doskakal za:^n %2d:%2d", cas_min[attacker], cas_sec[attacker])			
		dr_colored_print(i, DR_MENO, i, "DR_NOW_TERR", "^x03", szName, "^x01");	
	}	
	// Este dalsie informacie ..
	set_hudmessage(255, 0, 0, 0.7, 0.1, 0, 0.1, 5.0, 0.0, 0.0,4);
	show_hudmessage(victim, "Vydrzal si:^n %2d:%2d", cas_min[victim], cas_sec[victim] - 1);		
	return PLUGIN_CONTINUE;
}
public nove_kolo() {
	zivoty_supovolene = true;
}
public cmd_obnov(const id, const level, const cid ) {
	if(!cmd_access( id, level, cid, 1 )) return PLUGIN_HANDLED; 
	obnov_mapu();
	return PLUGIN_CONTINUE;
}
public obnov_mapu() {
	// Moja nova funkcia na obnovenie znicenych entit ,.....
	static ent;
	ent = -1
	// Hladame rozbitne veci ....
	while( (ent = find_ent_by_class(ent, "func_breakable") )) {	
		entity_set_int(ent, EV_INT_solid, 	4)	// bude dat prechadzat
		entity_set_int(ent, EV_INT_effects, 0)	// obnovy sa
	}
	obnov_prestrelne_load()
	return PLUGIN_CONTINUE;
}
stock obnov_prestrelne_save() {
	// Hladame entity ....
	new ent = -1
	new posledny_array = -1
	new float:temp 
	
	while( (ent = find_ent_by_class(ent, "func_breakable"))) {
		// Ak je prestrelna
		temp = entity_get_float(ent, EV_FL_takedamage)
		if( temp > 0.0) {
			posledny_array++;
			if( posledny_array == MAX_ENTIT) {
				log_amx("Presiahnuty maximalny pocet rozbitnych %d ENTITI ",MAX_ENTIT);
				return PLUGIN_CONTINUE;
			}
			entita[posledny_array] = ent;
			entita_fl[posledny_array] = temp			
		}
	}	
	return PLUGIN_CONTINUE;
}
stock obnov_prestrelne_load() {
	// Entity mame len nastavy vlastnosti ....
	static i;
	for(i=0; i < MAX_ENTIT; i++) {
		if(pev_valid(entita[i])) entity_set_float( entita[i] , EV_FL_takedamage, entita_fl[i]);	
	}
	return PLUGIN_CONTINUE;
}
public precisti_mapu() {
	// Niekdy ostane v mape vela entit co moze sposobovat lagy
	static ent, string[32]
	ent = -1;	
	while((ent = find_ent_by_class(ent, "weaponbox"))) {
		// Porovnavame model
		if(pev_valid(ent)) {
			entity_get_string(ent, EV_SZ_model, string, 31);
			if( equal(string, "models/w_usp.mdl"))  fm_remove_entity(ent);
		}
	}
	return PLUGIN_CONTINUE;
}
public eResetHUD(const id) {
	message_begin( MSG_ONE_UNRELIABLE, gMsgWeapon, _, id );
	write_byte( ( 1<<4 | 1<<5 ) );
	message_end();
	
	message_begin( MSG_ONE_UNRELIABLE, gMsgCrosshair, _, id );
	write_byte( 0 );
	message_end();
}
public eMoney(const id) {
	set_pdata_int( id, 115, 0 );
	message_begin( MSG_ONE_UNRELIABLE, gMsgMoney, _, id );
	write_long ( 0 );
	write_byte ( 1 );
	message_end( );
}
public client_disconnect(id)  {
	if( bot_id == id ) {
		set_task( 1.5, "UpdateBot" );	
		bot_id = 0;
	}
	TerroristQuotaSystem();
	cas_min[id]=0;	
	cas_sec[id]=0;
}
public addToFullPack( const es,const e,const ent,const host,const flags,const player,const pSet ) {
	if(player) {
        if(is_solid(host) && is_solid(ent)) {
            set_es(es, ES_Solid, SOLID_BSP)//SOLID_NOT)
            set_es(es, ES_RenderMode, kRenderTransAlpha);
            set_es(es, ES_RenderAmt, 85);
        }
    }
}
public FwdHamPlayerSpawnPost(const id) {
	//set_pdata_int( id, 192, 0 ); // to je na deathrun radio
	if( !is_user_alive( id ) ) return HAM_IGNORED;
	// Naozaj spawnut sa moze ako camera, nezije ..
	
	// Je to bot ?
	if( bot_id == id ) {		
		set_pev( id, pev_effects, pev(id, pev_effects) | EF_NODRAW );
		set_pev( id, pev_solid, SOLID_BSP ) //SOLID_NOT );
		entity_set_origin(id, Float:{ 999999.0, 999999.0, 999999.0 } );
		dllfunc( DLLFunc_Think, id );
		return HAM_IGNORED;
	} 
	
	// Normalne clovek
	cas_min[id]=0;	
	cas_sec[id]=0;
	fm_strip_user_weapons(id);
	fm_give_item( id, "weapon_knife" );
	
	if(fm_get_user_team( id ) == CS_TEAM_CT) {
		if( mapa_gamer) fm_give_item( id, "weapon_smokegrenade" );	
		if(!mapa_haunted ) {
			fm_give_item( id, "weapon_usp" );
			fm_set_user_bpammo( id, CSW_USP, 100 );
		}	
	}		
	return HAM_IGNORED;
}
public FwdImpulse_201(const id,const uc_handle,const seed ) {	
	if( is_user_alive(id) ) {
		client_print(id, print_center, "%L", id, "DR_BLOCK_SPRAY");
		return PLUGIN_HANDLED_MAIN;
	}
	return PLUGIN_CONTINUE;
}
public preThink(const id) {
    if(!is_solid(id)) return;
    
	static i;
    for( i=1; i <= gMaxPlayers; i++) {
        if(!is_solid(i) || id == i) continue;
        set_pev(i, pev_solid, SOLID_BSP) //SOLID_NOT);
        pObnovit[i] = true;
    }
}
public postThink(const id) {
	if( is_user_alive(id)) set_pdata_int(id, OFFSET_BZ, get_pdata_int(id, OFFSET_BZ, 5) & ~(1<<0), 5);
	
	static i;
    for(i=1; i <= gMaxPlayers; i++) {
        if(pObnovit[i]) {
            set_pev(i, pev_solid, SOLID_SLIDEBOX);
            pObnovit[i] = false;
        }
    }
	return FMRES_IGNORED;
}
public MsgStatusIcon(const msg_id,const msg_dest,const id ) {
	new szIcon[8];
	get_msg_arg_string(2, szIcon, 7);
	
	if( equal(szIcon, "buyzone") ) {
		set_pdata_int( id, OFFSET_BZ, get_pdata_int( id, OFFSET_BZ, 5 ) & ~( 1 << 0 ), 5 );	
		return PLUGIN_HANDLED;
	}
	return PLUGIN_CONTINUE;
}
public cmdShowlifes(const id ) { dr_colored_print(id, DR_MENO, id, "DR_LIFE_CC" ); }
public respawn(const id) {
	new team = fm_get_user_team(id)	
	if( team == CS_TEAM_CT || team == CS_TEAM_T) {
		spawn(id);
		return PLUGIN_CONTINUE;
	}
	dr_colored_print(id, DR_MENO, id, "DR_NOT_CT");
	return PLUGIN_CONTINUE;
}
public client_putinserver(id) {
	if( bot_id != id ) set_task(20.0, "welcome_msg", id);
}
public welcome_msg(const id) {
	if(is_user_connected(id)) {
		dr_colored_print(id, "^x01 +++ Death-Run-Match^x03 1.0^x01 by ^x04Seky^x01 +++");
	}	
}
stock dr_colored_print(const target, const message[], any:...) {
	static buffer[512];
	vformat(buffer, sizeof buffer - 1, message, 3);
	message_begin(MSG_ONE, gMsgSayText, _, target);
	write_byte(target);
	write_string(buffer);
	message_end();
}
public clcmd_changeteam(const id) {		
	new temp = fm_get_user_team(id)
	if (temp == CS_TEAM_CT || temp == CS_TEAM_T)	{
		show_GameMenu(id);
		return PLUGIN_HANDLED;
	}
}
public vyber_teamov(const id,const team) {	
	switch(team) {
		case 6: { // Spectators off ...
			return PLUGIN_CONTINUE;
		}
		case 5: { // Blokujeme 5 nahodne - bug zneuzivali....
			client_print( id, print_chat, "[G/L DR] %L", id, "TEAM_5");
			engclient_cmd(id, " chooseteam"); 
			return PLUGIN_HANDLED;
		}
		case 2: { // Ak vybral CT
			set_task(5.0, "kontrola_vstupu_do_hry", id);
			return PLUGIN_CONTINUE
		}
		case 1: { // Ak vybral T
			set_task(1.0, "PresunT2CT", id)
		}
	}
	return PLUGIN_CONTINUE;
}
public PresunT2CT(const id) {
	fm_set_user_team(id, CS_TEAM_CT);
	fm_reset_user_model(id);	
	spawn(id);
	set_task(5.0, "kontrola_vstupu_do_hry", id);
}
public kontrola_vstupu_do_hry(const id) {
	// Nikedy vyberie si TEAM ale nehodi ho do hry do konca kola
	dr_colored_print(id, "^x04[G/L DR]^x01 Ak ta nehodi do hry, stlac^x04 M^x01 a vyber^x04 RESPAWN")
	new temp = fm_get_user_team(id)
	if (temp == CS_TEAM_CT || temp == CS_TEAM_T ) {
		if(!is_user_alive(id)) spawn(id);
	}
}
public event_vyber_teamov_1(const id) {
	new arg[1]; 
	read_argv(1,arg,1);
	return vyber_teamov(id, str_to_num(arg))
}
public event_vyber_teamov_2(const id,const key) { return vyber_teamov(id, key+1); }
stock show_GameMenu(const id) {
	new menu[250], len = 0;
	// Nazov
	len += formatex(menu[len], sizeof menu - 1 - len, "\y%s^n^n", "Game Menu")	
	// 2. Bonusy
	len += formatex(menu[len], sizeof menu - 1 - len, "\r1.\w %L^n", id, "MENU_EXTRABUY")
	// 3. checkpointy
	len += formatex(menu[len], sizeof menu - 1 - len, 
			(is_user_alive(id) && fm_get_user_team(id) == CS_TEAM_CT) ? "\r2.\w %L^n" : "\d2. %L^n"
		, id, "MENU_CHECK")	
	// 4. Zivot
	len += formatex(menu[len], sizeof menu - 1 - len, "\r3.\w %L^n", id, "MENU_RESPAWN")
	len += formatex(menu[len], sizeof menu - 1 - len, "\r4.\w Kamera^n")	
	//Help
	len += formatex(menu[len], sizeof menu - 1 - len, "\r5.\w %L^n^n\r6.\w %L^n", id, "MENU_INFO", id, "MENU_SPECTATOR")
	// Zvucky
	/*new temp = dr_get_sound_status(id)
	if(temp == - 1) {
		len += formatex(menu[len], sizeof menu - 1 - len, "\d7.\w Zvucky off^n")	
	} else
		len += formatex(menu[len], sizeof menu - 1 - len, (temp == 1) ? "\r7.\w Zvucky\r on^n" : "\r7.\w Zvucky\r off^n")
	*/
	// 0. Exit
	len += formatex(menu[len], sizeof menu - 1 - len, "^n^n\r0.\w %L", id, "MENU_EXIT")
	
	show_menu(id, KEYSMENU, menu, -1, "Game Menu");
}
public clcmd_GameMenu(const id) {
	new temp = fm_get_user_team(id)	
	if (temp == CS_TEAM_CT || temp == CS_TEAM_T)	{
		show_GameMenu(id);
		return PLUGIN_CONTINUE;
	}
}
public GameMenu(const id,const key) {
	switch (key) {
		case 0: { // bonusy
			client_cmd(id, "menu_shop");
		}
		case 1: { // checkpointy
			client_cmd(id, "menu_checkpoint");
		}
		case 2: { // Respawn funckia
			respawn(id);
			//dr_colored_print(id, "^x04[G/L DR]^x01 %L", id ,"CMD_NOT")
		}	
		case 3: { // Kamera
			client_cmd(id, "dr_camera")
		}
		case 4: { // Help 
			show_motd(id, "<style type='text/css'><!-- body{ background-color: #000000; } --></style><iframe src='http://www.cs.gecom.sk/cstrike/dr_help.php' width='1024px' height='768px' scrolling='yes' frameborder='0' ></iframe>", "Death-Run-Match");
		}
		case 5: { // Spectator
			fm_set_user_team(id, CS_TEAM_SPECTATOR)
			if (is_user_alive(id)) user_silentkill(id);	
		}
		case 8: { // Exit ..
			return PLUGIN_HANDLED;
		}
		/*default : { // Podpluginy ..
			ExecuteForward(ForwardGameMenu, ForwardResult, id, key);
		}*/
	}
	return PLUGIN_HANDLED;
}
public clcmd_fullupdate() { return PLUGIN_HANDLED_MAIN; }  


// CS Offsets
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
const OFFSET_LINUX = 5;

stock fm_set_user_bpammo(const id,const weapon,const amount) {
	static offset;
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
stock fm_give_item(const index, const item[]) {
	if (!equal(item, "weapon_", 7) && !equal(item, "ammo_", 5) && !equal(item, "item_", 5))
		return 0;
	
	static ent, save;
	ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, item));
	if (!pev_valid(ent))
		return 0;
	
	static Float:origin[3];
	pev(index, pev_origin, origin);
	set_pev(ent, pev_origin, origin);
	set_pev(ent, pev_spawnflags, pev(ent, pev_spawnflags) | SF_NORESPAWN);
	dllfunc(DLLFunc_Spawn, ent);
	
	save = pev(ent, pev_solid);
	dllfunc(DLLFunc_Touch, ent, index);
	if (pev(ent, pev_solid) != save) return ent;
	
	engfunc(EngFunc_RemoveEntity, ent);
	return -1;
}
stock fm_strip_user_weapons(const index) {
	new ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "player_weaponstrip"));
	if (!pev_valid(ent)) return 0;
	dllfunc(DLLFunc_Spawn, ent);
	dllfunc(DLLFunc_Use, ent, index);
	engfunc(EngFunc_RemoveEntity, ent);
}
stock fm_get_user_team(id) {
	return get_pdata_int(id, OFFSET_CSTEAMS, OFFSET_LINUX);
}
stock fm_set_user_team(const id,const team) {
	set_pdata_int(id, OFFSET_CSTEAMS, team, OFFSET_LINUX)
	
	emessage_begin(MSG_ALL, gMsgTeamInfo);
	ewrite_byte(id);
	ewrite_string(TeamInfo[team]);
	emessage_end();
}