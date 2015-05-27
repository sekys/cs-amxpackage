#include <amxmodx>
#include <fakemeta>
#include <zombieplague>
#include <hamsandwich>
#include <Vexd_Utilities>
#include <cstrike>
#include <gauss>
#include <crab>
#include <fun>
#include <xs>

#define fm_precache_model(%1) 		engfunc(EngFunc_PrecacheModel,%1)
#define fm_precache_sound(%1) 		engfunc(EngFunc_PrecacheSound,%1)
#define fm_remove_entity(%1) 		engfunc(EngFunc_RemoveEntity, %1)
#define fm_find_ent_by_class(%1,%2) engfunc(EngFunc_FindEntityByString, %1, "classname", %2)
#define is_valid_player(%1) 		(1 <= %1 <= g_maxplayers)
#define fm_drop_to_floor(%1) 		engfunc(EngFunc_DropToFloor,%1)

#define PLUGIN 	"[ZP] Velka mama"
#define VERSION "1.1"
#define AUTHOR 	"Seky"

#define FFADE_IN 			0x0000
#define UNIT_SECOND 		(1<<12)
#define BLOOD_COLOR			204
#define TASK_SOUND 			203
#define OWNER				pev_iuser2
#define PAVUCINA_TIMER		pev_iuser3

#define MATKA_UTOK 			1.0
#define NAZOV_OCHRANY		"matka_ochrana"
#define NAZOV_PAVUCINA		"matka_pavucina"
#define NAZOV_VAJEC			"matka_vajco"	
#define DECAL_PAVUCINA		"{mommablob"	
#define EFEKT_TIME_1		5.0	
#define EFEKT_TIME_2		3.0	
#define HP_PER_BOD			1000.0

// Konstanty ....
new const Float:HP_OFFSET = 100000.0; // pouzite na matku aj vacia .....
new const Float:VAJCO_MIN[] = { -4.0, -4.0, -8.0 };
new const Float:VAJCO_MAX[] = { 4.0, 6.0, 16.0 };
// Animacie .... typ a cas			 DEAD	PAVUCI 	VAJCO	Kopanec			Spawn
new const Matka_model_t[] = { 4, 	9,	 	11, 	5, 6, 7,		8 }
new const Float:Matka_model_s[] = { 1.0, 	1.0, 	1.0,	1.0, 1.0, 1.0, 	1.0}

// R E S O U R C E
new const sound_mom[] = { "zombie_plague/mom/mom.wav" }
new const Matka_model_A[] = { "models/player/mom/mom.mdl" } // tento uz cachuje hlavny plugin
new const Matka_model_B[] = { "models/player/mom/momt.mdl" }
new const VajcoModel[][] = { 
	"models/tekvica.mdl"  
};
new const VajcoCreateSound[][] = { 
	"zombie_plague/fart.wav"
	//"sound/zombie_plague/necrofago.wav"
};
new const VajcoVyliahnutieSound[][] = { 
	"zombie_plague/boomer.wav",
	"zombie_plague/boomer2.wav"
};
new const VajcoSoundDie[][] = { 
	"gonarch/gon_childdie1.wav",
	"gonarch/gon_childdie2.wav",
	"gonarch/gon_childdie3.wav"
};
new const MatkaSoundPreAttack[][] = { // matka pred utokom vydava zvuky
	"gonarch/gon_sack3.wav",
	"gonarch/gon_sack2.wav",
	"gonarch/gon_sack1.wav"
};
new const MatkaSoundAttack[][] = { 
	"bullchicken/bc_acid1.wav",
	"bullchicken/bc_spithit1.wav",
	"bullchicken/bc_spithit2.wav"
};
new const PavucinaModel[] = "sprites/mommaspit.spr";

// GLOBALN premenne


new // pomocne
	matka, OchrannaEntita[6], Float:matka_time[2], cooldown[3], Float:damagedone[33],
	vajec = 0, g_maxplayers, bool:zamrznuty[33], decal, sprite_line,
	// cvar 
	pocet_crabov, nahodne_crabov, hp_craba,
	cvar_polomer, cpavucina_radius, cvar_freeze,
	// message
	g_msgDeathMsg, g_msgScoreInfo, g_msgDamage, g_MsgSync,
	// resource
	gSpitSprite, gBlood_drop,  gBlood_spray, gMessageFade, g_explo
	
public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	cooldown[0] = register_cvar("zp_mom_vcooldown", "10.0")
	cooldown[1] = register_cvar("zp_mom_acooldown", "1.0")
	hp_craba = register_cvar("zp_mom_crab_hp", "100.0") //hp jedneho craba
	cooldown[2] = register_cvar("zp_mom_vyliahnutie", "10.0")
	cvar_polomer = register_cvar("zp_mom_polomer", "100.0") // polomer od vyliahnutia ..
	pocet_crabov = register_cvar("zp_mom_vajco", "10") // pocet vo vajci
	nahodne_crabov = register_cvar("zp_mom_nahoda", "5") //nahodny pocet ? +-5
	cvar_freeze = register_cvar("zp_mom_zamrzne", "10.0")
	cpavucina_radius = register_cvar("zp_mom_radius", "250.0")
	
	RegisterHam(Ham_Touch, "info_target", "plugin_touch")
	RegisterHam(Ham_Player_PreThink, "player", "plugin_PlayerPreThink", 1)
	RegisterHam(Ham_TakeDamage, "info_target", "fw_TakeDamage")
	// RegisterHam(Ham_Killed, "player", "fw_PlayerKilled")
	register_forward(FM_Think, "plugin_think" );	
	register_event("HLTV", 	"newround", 	"a",  "1=0", "2=0")
	g_maxplayers = get_maxplayers()
	
	g_msgDeathMsg 	= get_user_msgid("DeathMsg");
	g_msgScoreInfo	= get_user_msgid("ScoreInfo");
	gMessageFade = get_user_msgid("ScreenFade");
	g_msgDamage = get_user_msgid("Damage")
	g_MsgSync = CreateHudSyncObj()
}
public plugin_precache()
{
	// neprecachovany 2. model z matky
	precache_model(Matka_model_B);
	gBlood_drop = precache_model("sprites/blood.spr");
	gBlood_spray = precache_model("sprites/bloodspray.spr");
	g_explo = precache_model("sprites/shockwave.spr");
	gSpitSprite = precache_model(PavucinaModel); // projektil
	//sprite_line = precache_model("sprites/dot.spr")
	
	// a...dalsie
	new i;
	for (i = 0; i < sizeof VajcoModel; i++)
		fm_precache_model(VajcoModel[i]);	
	for (i = 0; i < sizeof VajcoCreateSound; i++) 
		fm_precache_sound(VajcoCreateSound[i]); 	
	for (i = 0; i < sizeof VajcoVyliahnutieSound; i++) 
		fm_precache_sound(VajcoVyliahnutieSound[i]); 	
	for (i = 0; i < sizeof VajcoSoundDie; i++) 
		fm_precache_sound(VajcoSoundDie[i]); 	
	for (i = 0; i < sizeof MatkaSoundPreAttack; i++) 
		fm_precache_sound(MatkaSoundPreAttack[i]); 	
	for (i = 0; i < sizeof MatkaSoundAttack; i++) 
		fm_precache_sound(MatkaSoundAttack[i]); 
	fm_precache_sound(sound_mom);
}
public plugin_touch(const ent, const clovek)
{	
	// Pre istotu ....
	if(!matka) return HAM_IGNORED;
	if(!pev_valid(ent) ) return HAM_IGNORED
	
	static EntityName[32];
	pev(ent, pev_classname, EntityName, 31);
	// Je to matkina ochranna Ochranna Entita ?
	if(equal(EntityName, NAZOV_OCHRANY) ) return Matka_Kope(ent, clovek);
	
	// Alebo projektil ?
	if(equal(EntityName, NAZOV_PAVUCINA) ) {
		// Moze este trafit nasu ochrannu entitu
		pev(clovek, pev_classname, EntityName, 31);
		if(!equal(EntityName, NAZOV_OCHRANY)) {
			return Pavucina_touch(ent, clovek);
		} else {	
			return HAM_SUPERCEDE;
		}

	}
	return HAM_IGNORED;
}
public plugin_PlayerPreThink(const id)
{
	// Mrtvych nechceme
	if(!matka) return HAM_IGNORED;
	if (!is_user_alive(id)) return HAM_IGNORED;
	// Zamrznuty
	if (zamrznuty[id]){
		set_pev(id, pev_velocity, Float:{0.0,0.0,0.0}) // stop motion
		set_pev(id, pev_maxspeed, 1.0) // prevent from moving
	}
	return Matka_think(id);
}	
public plugin_think(const ent)
{
	if(!matka) return FMRES_IGNORED;
	if (!pev_valid(ent) ) return FMRES_IGNORED;	
	//Je to vobec vajco ?
	static EntityName[32];
	pev(ent, pev_classname, EntityName, 31);
	if(equal(EntityName, NAZOV_VAJEC) ) return Vajco_think(ent);
	if(equal(EntityName, NAZOV_PAVUCINA) ) return Pavucina_think(ent);
	return FMRES_IGNORED;
}
public zp_round_started(gamemode, id) 
{	
	if(gamemode != MODE_MOM){ 
		matka = 0;
		return PLUGIN_CONTINUE;
	}
	if(matka == 0) { // Iba prvykrat.....		
		// dame prec zbrane
		for(new i=1; i <= g_maxplayers; i++) if (is_user_alive(i)) molekulator(i, false);				
		// Nove hodnoty
		vajec = 0;
		matka = id;				
		Matka_spawn(id)
		// Efekty
		PlaySound_loop();
		set_task(5.64, "PlaySound_loop", TASK_SOUND, _, _, "b")	
	} else {	// Ak sa odpoji pocas kola znova je round start ....
		matka = id;			
		// Presunieme crabov k novemu majitelovy
		presun_crabov(matka, id);			
		// Matka dostala nove hp ......dame stare.......
		new Float:hp
		pev(OchrannaEntita[0], pev_health, hp);
		hp -= HP_OFFSET;
		set_pev(matka, pev_health, hp)
	}	
	// set_cvar_string("zp_lighting", "a") 
	client_print(matka, print_chat, "[G/L ZP] Snaz sa prezit a zachovat potomstvo!")
	client_print(matka, print_chat, "[G/L ZP] Deti splodis s R , za kazdeho -1000HP.")
	return PLUGIN_CONTINUE;
}
public zp_round_ended(winteam)
{
	// Bolo vobec kolo matky ?
	if(!matka) return PLUGIN_CONTINUE;
	// mix
	new i;
	// set_cvar_string("zp_lighting", "z") 
	remove_task(TASK_SOUND)
	Matka_animacia(matka, 0);
	// Cistime mapu od veci
	i= -1;
	while((i = fm_find_ent_by_class(i, NAZOV_VAJEC))) fm_remove_entity(i);	
	i= -1;
	while((i = fm_find_ent_by_class(i, NAZOV_PAVUCINA))) fm_remove_entity(i);	
	i= -1;
	while((i = fm_find_ent_by_class(i, NAZOV_OCHRANY))) fm_remove_entity(i);
	// Este ochranne entity ...
	for(i=0; i < 6; i++) OchrannaEntita[i] = 0;
	// Odmraz vsetkych
	for(i=1; i <= g_maxplayers; i++) {
		Pavucina_odmraz(i); 
		damagedone[i] = 0.0;
	}	
	matka = 0; vajec = 0;	
	return PLUGIN_CONTINUE;
}
public newround(){
	for(new i=1; i <= g_maxplayers; i++) {
		zamrznuty[i] = false;
	}
	return PLUGIN_CONTINUE
}
public plugin_natives() { register_native("get_vajec", "native_get_vajec", 1); }
public native_get_vajec() { return vajec >= 0 ? vajec : 0; }
stock Matka_spawn(const id) {
	// Potrebujeme zistit par udajov ...+ efekt maly :)
	static Float:origin[3], Float:endorigin[3]
	pev(id, pev_origin, origin);
	decal = UTIL_GetDecalIndex(DECAL_PAVUCINA);
	UTIL_DolnyKoncovyBod(id, origin, endorigin)
	Pavucina_decal_kruh(endorigin, 3, 200.0);
	// Matka sa narodila takze zmen zasahy na tele		
	set_user_hitzones(0, matka, 2);
	Matka_animacia(matka, 6);
	// Zistime si vlastnosti
	new Float:hp;
	pev(matka, pev_health, hp)
	Matka_spawn_entity(hp+HP_OFFSET);
	return PLUGIN_CONTINUE;
}
stock Matka_spawn_entity(const Float:hp)
{
	static i, ent;
	// .......potrebujeme 5 entit ....
	for(i=0; i < 5; i++ ) 
	{
		// Vytvarame
		OchrannaEntita[i] = ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
		set_pev(ent, pev_classname, NAZOV_OCHRANY);	
			
		// Vlastnosti nastavujeme
		engfunc(EngFunc_SetModel, ent, Matka_model_A); // bbox nejde bez modelu	
		set_pev(ent, pev_solid, SOLID_BBOX) // vdaka tomu budeme moct do toho strielat
		set_pev(ent, pev_movetype, MOVETYPE_FLY)
		UTIL_ZneviditelnyEntitu(ent); // toto nam zneviditelny model
		set_pev(ent, pev_health, hp);
		set_pev(ent, pev_takedamage, DAMAGE_YES);
		//UTIL_debug(matka, ent, 60.0)
	}
	// Predna a zadna stena ...	
	Ochrana_size(0,  { -12.0, -80.0, -20.0 },  { 12.0, 80.0, 100.0 })	
	//Bocne steny
	Ochrana_size(2, { -80.0, -12.0, -20.0 },  { 80.0, 12.0, 100.0 })
	// Nad hlavou ....
	UTIL_entity_size(OchrannaEntita[4], { -80.0, -80.0, 0.0 },  { 80.0, 80.0, 24.0 })
	return PLUGIN_CONTINUE;
}
stock Matka_think(const id)
{
	//Je to matka ?
	if(matka!=id) return HAM_IGNORED;
	// Schopnost na vajca
	if((pev(id, pev_button ) & IN_RELOAD) && !(pev(id, pev_oldbuttons ) & IN_RELOAD )) {				
		Matka_think_vajco(id);
	}
	// Attack schopnost
	if((pev(id, pev_button ) & IN_ATTACK) && !(pev(id, pev_oldbuttons ) & IN_ATTACK )) {				
		Matka_think_attack(id);
	}		
	// Existuje este ochranna OchrannaEntita[ ?
	if(!Matka_think_valid() ) return HAM_IGNORED; 
	Matka_think_pozicie(id);
	Matka_think_hp(id);
	return HAM_IGNORED;	
}
stock Matka_think_vajco(const id)
{
	// Casomiera ?
	if(get_gametime() - matka_time[0] < get_pcvar_float(cooldown[0])) {
		client_print(id, print_chat, "[G/L ZP] Musis pockat este %.f sekund !", get_pcvar_float(cooldown[0]) - (get_gametime() - matka_time[0]))			
		return PLUGIN_CONTINUE;
	}
	static Float:hp, Float:hp_ma;
	hp = Vajco_gethp();
	pev(id, pev_health, hp_ma);
	// Ma este dostatok zivota ?
	if( hp_ma <= hp) {
		client_print(id, print_chat, "[G/L ZP] Nemozes vyliahnut vajco, lebo by ta to zabylo.")
		return PLUGIN_CONTINUE;
	}		
	// Next
	static Float:origin[3]
	matka_time[0] = get_gametime();
	Matka_animacia(id, 2);
	fakedamage(id, "vajco", hp, DMG_SLASH);
	pev(id, pev_origin, origin);
	set_task(2.0, "Vajco_vyser", _, origin, 3);	
	return PLUGIN_CONTINUE;
}	
stock Matka_think_attack(const id)
{
	// Casomiera ?
	if(get_gametime() - matka_time[1] < get_pcvar_float(cooldown[1])) {
		//client_print(id, print_chat, "[G/L ZP] Musis pockat este %.f sekund !", get_pcvar_float(cooldown[1]) - (get_gametime() - matka_time[1]))			
		return PLUGIN_CONTINUE;
	}
	// Efekt ...
	Matka_animacia(id, 1);
	Pavucina_attack(id)
	matka_time[1] = get_gametime();
	// Mini oneskorenie...
	//set_task(0.1, "Pavucina_attack");	
	return PLUGIN_CONTINUE;
}
stock Matka_think_valid() {
	for(new i=0; i < 5; i++) if(!pev_valid(OchrannaEntita[i])) return false; 
	return true;
}
stock Matka_think_pozicie(const id) {
	// Zistujeme udaje
	static Float:origin[3];
	pev(id, pev_origin, origin)
	// Predok
	Ochrana_pozicia(0, origin, 0, 128.0);
	// Zadok
	Ochrana_pozicia(1, origin, 0, -128.0)
	// Prvy bok ....
	Ochrana_pozicia(2, origin, 1, 128.0)
	// Druhy bok
	Ochrana_pozicia(3, origin, 1, -128.0)
	// Strop
	Ochrana_pozicia(4, origin, 2, 92.0)
}
stock Matka_think_hp(const id) {
	static Float:hp[3] //, Float:celkovydmg;
	//celkovydmg = 0.0; // kurva aj so static metodou som to 2 tyzdne debugoval 
	
	pev(id, pev_health, hp[0])
	// Hromadne pocitame HP kazdej entity
	for(new i=0; i < 5; i++) {
		pev(OchrannaEntita[i], pev_health, hp[1]);
		hp[1] -= HP_OFFSET;
		// Ake mame dat damage ?
		hp[2] = hp[0] - hp[1];
		if(hp[2] < 0.0 ) { 	// Priamo zasiahly matku alebo matka spadla atd.
			set_pev(OchrannaEntita[i], pev_health, hp[0] + HP_OFFSET)
			continue;
		}	
		// Entita ma menej ako matka
		//if(hp[2] > 0.0) celkovydmg += hp[2];
	}
}/*
public fw_PlayerKilled(victim, attacker, shouldgib)
{
	if(!matka) return HAM_IGNORED;
	if(matka == victim) {
		Matka_animacia(id, 0);
	}
	return HAM_IGNORED;
}*/
public client_disconnect(id){
	zamrznuty[id] = false;
}
public client_putinserver(id){
	zamrznuty[id] = false;
}
public fw_TakeDamage(ent, weapon, attacker, Float:damage, damage_type)
{
	if(!matka) return HAM_IGNORED;
	if(!pev_valid(ent)) return HAM_IGNORED; 
	if(!is_user_connected(attacker)) return HAM_IGNORED;

	// Pre istotu
	static EntityName[32];
	pev(ent, pev_classname, EntityName, 31);
	if(!equal(EntityName, NAZOV_OCHRANY) ) return HAM_IGNORED;
	
	// Zoberieme HP matke ....
	static Float:efekt_time[2];
	static Float:time; // pouzite aj ako HP
	pev(matka, pev_health, time)
	
	if(damage > 0.0) {		
		// Pocitame body ...
		damagedone[attacker] += damage;
		while (damagedone[attacker] >= HP_PER_BOD) {
			zp_add_user_ammo_packs(attacker, 1);
			damagedone[attacker] -= HP_PER_BOD;
		}
			
		// Dalej ukazeme dmg
		// set_hudmessage(255, 0, 0, 0.45, 0.50, 2, 0.1, 4.0, 0.1, 0.1, -1)
		// ShowSyncHudMsg(id, g_MsgSync2, "%i^n", damage)			
		set_hudmessage(0, 100, 200, -1.0, 0.55, 2, 0.1, 4.0, 0.02, 0.02, -1)
		ShowSyncHudMsg(attacker, g_MsgSync, "%i^n", floatround(damage))
	
		// Zvladne to matka ?
		if(damage >= time) {
			// Je zabita matka ...
			// Matka_animacia(matka, 0);
			UTIL_set_score(attacker, matka, 1)
			return HAM_SUPERCEDE;			
		} else {
			// Efekty
			time = get_gametime();
			if(time - efekt_time[0] < EFEKT_TIME_1) {
				static Float:origin[3];
				pev(matka, pev_origin, origin)
				efekt_matky(origin);
				efekt_time[0] = time;
			}
			if(time - efekt_time[1] < EFEKT_TIME_2) {
				efekt_time[1] = time;
				screen_effects(matka);
			}
			fakedamage(matka, "knive", damage, DMG_SLASH);
		}
		// Emulacia dmg na matku..
		// ExecuteHamB(Ham_TakeDamage, matka, weapon, attacker, damage, damage_type) netreba uz
	}
	return HAM_IGNORED;
}
stock Matka_Kope(const nasakrabica, const clovek) {	
	// Ucinok na matku...
	if(clovek==matka) return HAM_IGNORED;				
	// Je to clovek
	if(!is_valid_player(clovek)) return HAM_IGNORED;
	// zahajime utok .....
	Matka_animacia(matka, random_num(3, 5));
	//log_to_file("mom.log", "kopanec %d %d", matka, clovek);
	Matka_utok(matka, clovek, MATKA_UTOK);
	return HAM_IGNORED;
}	
stock Matka_utok(const kto, const obet, const Float:dmg) {
	new Float:hp;
	pev(obet, pev_health, hp);
	if(dmg >= hp) {
		UTIL_set_score(kto, obet, 1)
	} else {			
		screen_effects(obet)
		user_slap(obet, floatround(dmg))
		//fakedamage(obet, "pes", dmg, DMG_SLASH);													
	}
	return PLUGIN_CONTINUE;	
}		
public Vajco_vyser(const Float:vektor[3]) {
	if(!matka) return FMRES_IGNORED;	
	// Opet ziskame udaje .....
	new vajco, hp = Vajco_gethp();
	vajec++;
	// Vytvorime vajco ....
	vajco = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	set_pev(vajco, pev_classname, NAZOV_VAJEC);	
	engfunc(EngFunc_SetModel, vajco, VajcoModel[random_num(0, sizeof VajcoModel - 1)]);		
	set_pev(vajco, pev_origin, vektor)
	set_pev(vajco, pev_solid, SOLID_BBOX) //SOLID_BBOX)
	set_pev(vajco, pev_movetype, MOVETYPE_FLY)
	set_pev(vajco, pev_health, hp+HP_OFFSET);
	set_pev(vajco, pev_max_health, hp+HP_OFFSET);
	set_pev(vajco, pev_takedamage, DAMAGE_YES);
	set_pev(vajco, pev_nextthink, 1.0) // zacina "mysliet"
	// Velkost
	UTIL_entity_size(vajco, VAJCO_MIN, VAJCO_MAX)
	fm_drop_to_floor(vajco)
	// + Efekt
	static Float:Endorigin[3]
	UTIL_DolnyKoncovyBod(vajco, vektor, Endorigin);
	Pavucina_decal_kruh(Endorigin, 3, 200.0);
	engfunc(EngFunc_EmitSound, vajco, CHAN_AUTO, VajcoCreateSound[random_num(0, sizeof VajcoCreateSound - 1)], 1.0, ATTN_NORM, 0, PITCH_NORM);
	//set_task(get_pcvar_float(cooldown[2]), "Vajco_vyliahni", vajco)
	
	//UTIL_debug(matka, vajco, 60.0)	
	return PLUGIN_CONTINUE;
}
stock Vajco_think(const ent) {	
	// Efekt rozbitia vajca
	static Float:hp, Float:old_hp, Float:rozdiel;	
	pev(ent, pev_health, hp);
	pev(ent, pev_max_health, old_hp);
	hp -= HP_OFFSET;
	old_hp -= HP_OFFSET;
	rozdiel = old_hp - hp;	
	// Poskodilo vajco ....
	if(rozdiel != 0) {
		rozdiel = hp - rozdiel + HP_OFFSET;
		Vajco_dmg(ent, rozdiel);
	}
	// Vajco znicime, zabijeme ...
	if(hp < 1.0) return Vajco_die(ent);
	set_pev(ent, pev_nextthink, 1.0)
	return FMRES_IGNORED;
}
stock Vajco_die(const vajco) {
	engfunc(EngFunc_EmitSound, vajco, CHAN_AUTO, VajcoSoundDie[random_num(0, sizeof VajcoSoundDie - 1)], 1.0, ATTN_NORM, 0, PITCH_NORM);
	fm_remove_entity(vajco);
	vajec--;
	return FMRES_IGNORED;
}
stock Vajco_dmg(const vajco, const Float:hp) {
	static Float:origin[3];
	pev(vajco, pev_origin, origin);
	efekt_vajca(origin);
	set_pev(vajco, pev_health, hp);
	set_pev(vajco, pev_max_health, hp);
}
public Vajco_vyliahni(vajco) {	
	// Ak je stlae entita validna
	if(!pev_valid(vajco)) return PLUGIN_CONTINUE;
	// Ak este matka zije. ...
	if(!matka) { // is_user_alive(matka)
		fm_remove_entity(vajco);
		return PLUGIN_CONTINUE;
	}
	// Pocitame polomer a pocet crabov ...
	static celkovypocet, nahoda;	
	celkovypocet = get_pcvar_num(pocet_crabov);
	nahoda = get_pcvar_num(nahodne_crabov);
	celkovypocet = random_num(celkovypocet - nahoda, celkovypocet + nahoda); 
	engfunc(EngFunc_EmitSound, vajco, CHAN_AUTO, VajcoVyliahnutieSound[random_num(0, sizeof VajcoVyliahnutieSound - 1)], 1.0, ATTN_NORM, 0, PITCH_NORM);	
	
	// Vytvarame dookola crabov	celkovypocet
	Vajco_kruh(vajco, celkovypocet, get_pcvar_float(cvar_polomer) );
	fm_remove_entity(vajco);
	return PLUGIN_CONTINUE;	
}
stock Vajco_kruh(const vajco, const celkovypocet, const Float:polomer)
{
	// Ziskame udaje ....
	static  Float:origin[3], Float:velocity[3], Float:temp[3],
			Float:a, Float:b, ent, Float:uhol, Float:stupen;
	uhol = 0.0;
	stupen = 360.0 / float(celkovypocet);
	pev(vajco, pev_origin, origin)
	pev(vajco, pev_velocity, velocity)
	
	for(new i=0; i < celkovypocet; i++) {
		a = floatsin(uhol, degrees ) * polomer;
		b = floatcos(uhol, degrees ) * polomer;
		//client_print(0, print_chat, "%f %f %f", a, b, uhol) //log
		uhol += stupen;
		
		// Call function + vlastnosti
		ent = vytvor_craba(matka);
		/*temp[0] = velocity[0] - a;
		temp[1] = velocity[1] + b;
		temp[2] = velocity[2];	
		set_pev(ent, pev_velocity, temp)*/

		temp[0] = origin[0] - a;
		temp[1] = origin[1] + b;
		temp[2] = origin[2];
		set_pev(ent, pev_origin, temp)	
	}
}
stock Vajco_gethp() { return get_pcvar_float(hp_craba) * float(get_pcvar_num(pocet_crabov)); }
stock efekt_matky(const Float:bod[3] ) {
	static origin[3]
	origin[0] = floatround(bod[0]);
	origin[1] = floatround(bod[1]);
	origin[2] = floatround(bod[2]);
		
	message_begin( MSG_PVS, SVC_TEMPENTITY, origin );
	write_byte( TE_BLOODSPRITE );
	write_coord( origin[ 0 ] );
	write_coord( origin[ 1 ] );
	write_coord( origin[ 2 ] + 200 ); // origin[ 2 ] + 20
	write_short( gBlood_spray );
	write_short( gBlood_drop );
	write_byte( 110 ); //farba 248
	write_byte( 30 );
	message_end();

	message_begin( MSG_PVS, SVC_TEMPENTITY, origin );
	write_byte( TE_BLOODSTREAM );
	write_coord( origin[ 0 ] );
	write_coord( origin[ 1 ] );
	write_coord( origin[ 2 ] + 30 );
	write_coord( random_num( -64, 64 ) ); //random_num( -20, 20 
	write_coord( random_num( -64, 64 ) ); //random_num( -20, 20 
	write_coord( random_num( 50, 400 ) ); //random_num( 50, 300 )
	write_byte( 70 );
	write_byte( random_num( 100, 200 ) );
	message_end();

	message_begin( MSG_PVS, SVC_TEMPENTITY, origin );
	write_byte( TE_PARTICLEBURST );
	write_coord( origin[ 0 ] );
	write_coord( origin[ 1 ] );
	write_coord( origin[ 2 ] );
	write_short( 50 );
	write_byte( 188 ); // 70
	write_byte( 3 );
	message_end();

	message_begin( MSG_PVS, SVC_TEMPENTITY, origin );
	write_byte( TE_BLOODSTREAM );
	write_coord( origin[ 0 ] );
	write_coord( origin[ 1 ] );
	write_coord( origin[ 2 ] + 10 );
	write_coord( random_num( -360, 360 ) );
	write_coord( random_num( -360, 360 ) );
	write_coord( -10 );
	write_byte( 192 ); // 70
	write_byte( random_num( 50, 100 ) );
	message_end();
	return PLUGIN_CONTINUE;	
}
stock efekt_vajca(const Float:bod[3])
{
	static origin[3]
	origin[0] = floatround(bod[0]);
	origin[1] = floatround(bod[1]);
	origin[2] = floatround(bod[2]);
	
	/*message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(TE_BLOODSPRITE)
	write_coord(origin[0])
	write_coord(origin[1])
	write_coord(origin[2])
	write_short(gBlood_spray)
	write_short(gBlood_drop)
	write_byte(BLOOD_COLOR)
	write_byte(10)
	message_end()*/
				
	for (new i = 0; i < 5; i++) {
		message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
		write_byte(101)
		write_coord(origin[0])
		write_coord(origin[1])
		write_coord(origin[2]+30)
		write_coord(random_num(-20,20)) // x
		write_coord(random_num(-20,20)) // y
		write_coord(random_num(50, 200)) // z
		write_byte(188) // color
		write_byte(random_num(25,50)) // speed
		message_end()
	}
	return PLUGIN_CONTINUE;	
}
stock efekt_pavucina(const Float:position[3], const direction[3], const spriteModel,const count )
{
	static integer[3];	
	FVecIVec(position, integer)	
	message_begin( MSG_PVS, SVC_TEMPENTITY, integer);
	write_byte( TE_SPRITE_SPRAY );
	write_coord( integer[0]);	// pos
	write_coord( integer[1]);	
	write_coord( integer[2]);	
	FVecIVec(direction, integer)	
	write_coord( integer[0]);	// dir
	write_coord( integer[1]);	
	write_coord( integer[2]);	
	write_short( spriteModel );	// model
	write_byte ( count );			// count
	write_byte ( 130 );			// speed
	write_byte ( 80 );			// noise 
	message_end();
	return PLUGIN_CONTINUE;	
}
stock efekt_freezescreen(const victim, const Float:dlzka)
{
	message_begin(MSG_ONE_UNRELIABLE, gMessageFade, _, victim)
	write_short(UNIT_SECOND*1) // duration
	write_short(floatround(UNIT_SECOND*dlzka)) // casovanie
	write_short(FFADE_IN) // fade typ
	write_byte(0) // red
	write_byte(50) // green
	write_byte(200) // blue
	write_byte(100) // alpha
	message_end()
}	
stock efekt_freezeicon(const victim)
{
	message_begin(MSG_ONE_UNRELIABLE, g_msgDamage, _, victim)
	write_byte(0) // damage save
	write_byte(0) // damage take
	write_long(DMG_DROWN) // damage type - DMG_FREEZE
	write_coord(0) // x
	write_coord(0) // y
	write_coord(0) // z
	message_end()
}
public PlaySound_loop() {
	client_cmd(0, "spk ^"%s^"", sound_mom)
	return PLUGIN_CONTINUE;	
}
stock Pavucina_attack(const id) {
	// Nejaka zmena ?
	if(!matka) return PLUGIN_CONTINUE;	
	// Efekt
	engfunc(EngFunc_EmitSound, id, CHAN_AUTO, MatkaSoundPreAttack[random_num(0, sizeof MatkaSoundPreAttack - 1)], 1.0, ATTN_NORM, 0, PITCH_NORM);
	//client_print(0, print_chat, "attack")
	// Dalej vytvarame entity
	static Float:origin[3]
	pev(id, pev_origin, origin);
	//Pavucina_shoot(id, origin)
	origin[2] += 150.0 //44.0; // trocha vyssie potrebujeme ....
	Pavucina_create(id, origin)
	efekt_pavucina(origin, {0.0, 0.0, 1.0}, gSpitSprite, 240 )
	return PLUGIN_CONTINUE;	
}
/*
Pavucina_shoot(const id,  const Float:origin[3])				Stare .....
{
	static obet, body
	get_user_aiming(id, obet, body)
	if(is_user_alive(obet)) {
		static Float:temp[3]
		pev(obet, pev_origin, temp);
		if ( get_distance_f(temp, temp) < get_pcvar_float(cvar_freeze) ) {
			Pavucina_zamrzni(obet, get_pcvar_float(cvar_radiusattack) );
			return PLUGIN_CONTINUE;	
		}
	}
	Pavucina_shoot_miss(id, origin);	
	return PLUGIN_CONTINUE;	
}
Pavucina_shoot_miss(const id, const Float:fPlayerOrigin[3])
{
	static 	Float:fAimVector[3], Float:fAimOrigin[3], iTr
	client_print(0, print_chat, "Pavucina_shoot_miss")
	pev( id, pev_v_angle, fAimVector )
	angle_vector( fAimVector, ANGLEVECTOR_FORWARD, fAimVector )
	// lengthen vector and move it to user's origin
	fAimVector[0] = fAimVector[0] * 9999.0 + fPlayerOrigin[0]
	fAimVector[1] = fAimVector[1] * 9999.0 + fPlayerOrigin[1]
	fAimVector[2] = fAimVector[2] * 9999.0 + fPlayerOrigin[2]
	// execute traceline, grab normal vector and end position
	iTr = create_tr2()
	engfunc( EngFunc_TraceLine, fPlayerOrigin, fAimVector, IGNORE_MONSTERS, id, iTr )
	get_tr2( iTr, TR_vecEndPos, fAimOrigin )
	free_tr2( iTr )
	Pavucina_decal(decal, fAimOrigin);
	Create_Line(fPlayerOrigin, fAimOrigin)
}*/
stock Pavucina_create(const id,  const Float:origin[3])
{
	static Float:Endorigin[3], Float:velocity[3], ent
	ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	set_pev(ent, pev_movetype, MOVETYPE_TOSS);	
	set_pev(ent, pev_solid, SOLID_BBOX);	
	set_pev(ent, pev_rendermode, kRenderTransAlpha);	
	set_pev(ent, pev_renderamt, 255.0);	
	engfunc(EngFunc_SetModel, ent, PavucinaModel);
	set_pev(ent, pev_frame, 0.0);	
	UTIL_entity_size(ent, {0.0, 0.0, 0.0}, {0.0, 0.0, 0.0})
	// Normalny vektor od B - A bof
	UTIL_UserSkutocnyKoncovyBod(id, origin, Endorigin)
	velocity[0] = Endorigin[0] - origin[0];
	velocity[1] = Endorigin[1] - origin[1];
	velocity[2] = Endorigin[2] - origin[2];
	set_pev(ent, pev_velocity, velocity);
	// + Dalsie vlastnosti	
	set_pev(ent, pev_classname, NAZOV_PAVUCINA);	
	set_pev(ent, pev_origin, origin);	
	set_pev(ent, pev_owner, id);	
	set_pev(ent, pev_scale, 2.5);	
	set_pev(ent, pev_gravity, 0.6) // trocha rychlejsie
	set_pev(ent, pev_nextthink, get_gametime() + 0.1)
	return PLUGIN_CONTINUE;	
}
stock Pavucina_think(const ent) {
	new Float:origin[3], Float:vec[3];
	pev(ent, pev_velocity, vec);
	pev(ent, pev_origin, origin);
	
	// Niekedy sa zastavy a zabolkuje ...
	if( vec[0] == 0.0 || vec[1] == 0.0 || vec[2] == 0.0) {
		static pocet;
		if( pocet > 10 ) { // 0.1*10 = 1sec
			Pavucina_PlaneNormalDefault(ent, vec);
			Pavucina_koniec(ent, origin, vec); // mozno ostalo na zemy
			return FMRES_IGNORED;	
		}
		pocet = pev(ent, PAVUCINA_TIMER);
		set_pev(ent, PAVUCINA_TIMER, pocet+1);	
	}
	
	// Pohyb
	Pavucina_PlaneNormalDefault(ent, vec);
	efekt_pavucina(origin, vec, gSpitSprite, 3);
	
	// Collision detection
	pev(ent, pev_velocity, vec);
	if(Pavucina_think_touch(ent, origin, vec)) {
		Pavucina_koniec(ent, origin, vec);
		return FMRES_IGNORED;	
	}
			
	// Nastavujeme dalsie frame ....
	set_pev(ent, pev_nextthink, get_gametime() + 0.1)
	set_pev(ent, pev_frame, float(pev(ent, pev_frame) + 1.0));
	if ( pev(ent, pev_frame) > 2.0 ) {
		set_pev(ent, pev_frame, 0.0);
	}
	return FMRES_IGNORED;
}
stock Pavucina_think_touch(const ent, Float:origin[3], Float:velocity[3]) 
{
	static Float:koncovybod[3], iTr, hit	// hladame koncovy bod...
	koncovybod[0] = origin[0] + velocity[0]
	koncovybod[1] = origin[1] + velocity[1]
	koncovybod[2] = origin[2] + velocity[2]
	
	// Skutocny koncovy bod
	iTr = create_tr2()
	engfunc( EngFunc_TraceLine, origin, koncovybod, IGNORE_MONSTERS, ent, iTr )
	get_tr2( iTr, TR_vecEndPos, koncovybod)	
	get_tr2( iTr, TR_vecPlaneNormal, velocity)
	hit = get_tr2( iTr, TR_pHit);
	free_tr2( iTr )
	
	// Narazilo na nasu entitu
	if(pev_valid(hit)) {
		static EntityName[32];
		pev(hit, pev_classname, EntityName, 31);
		if(equal(EntityName, NAZOV_OCHRANY) ) {
			return false;
		}
	
	}
	// Vzdialenos od steny....
	if( get_distance_f(origin, koncovybod) > 80.0) {
		return false;
	}
	
	origin[0] = koncovybod[0];
	origin[1] = koncovybod[1];
	origin[2] = koncovybod[2];
	return true;
}
stock Pavucina_touch(const ent, const vec)
{
	// client_print(0, print_chat, "Pavucina_touch")
	static 	Float:origin[3], Float:vecPlaneNormal[3], Float:temp[3];
	pev(ent, pev_origin, origin);
	pev(ent, pev_velocity, vecPlaneNormal);

	// Vypocet
	if (UTIL_IsBSPModel(vec)) {
		// client_print(0, print_chat, "touch 0 %i %i", ent, vec)		
		new trace = 0
		// Hlada sa bod B = A + u(vektor)
		temp[0] = origin[0] + vecPlaneNormal[0] * 9999.0;
		temp[1] = origin[1] + vecPlaneNormal[1] * 9999.0;
		temp[2] = origin[2] + vecPlaneNormal[2] * 9999.0;
		
		// Vysledok od trace line
		engfunc(EngFunc_TraceLine, origin, temp, DONT_IGNORE_MONSTERS, ent, trace)
		get_tr2(trace, TR_vecEndPos, origin)
		get_tr2(trace, TR_vecPlaneNormal, vecPlaneNormal)			
	} else {
		// client_print(0, print_chat, "touch 1 %i %i", ent, vec)
		Pavucina_PlaneNormalDefault(ent, vecPlaneNormal)
	}
	
	Pavucina_koniec(ent, origin, vecPlaneNormal);
	return HAM_IGNORED;
}

stock Pavucina_PlaneNormalDefault(const ent, Float:vecPlaneNormal[3]) {
	pev(ent, pev_velocity, vecPlaneNormal);
	UTIL_normalize(vecPlaneNormal);
	vecPlaneNormal[0] = vecPlaneNormal[0] * -1.0;
	vecPlaneNormal[1] = vecPlaneNormal[1] * -1.0;
	vecPlaneNormal[2] = vecPlaneNormal[2] * -1.0;
}
stock Pavucina_koniec(	const ent, 
						const Float:origin[3], // bod zaberu
						const Float:vecPlaneNormal[3]
						) {
	// client_print(0, print_chat, "Pavucina_koniec")
	
	// Test
	/*static Float:matkaorigin[3], Float:entorigin[3]
	pev(matka, pev_origin, matkaorigin);
	pev(ent, pev_origin, entorigin);
	Create_Line2(matkaorigin, origin)	
	Create_Line2(entorigin, origin)*/	

	// Efekty
	static 	ipitch;
	ipitch = random_num(90, 110);
	Pavucina_decal(origin);
	efekt_pavucina(origin, vecPlaneNormal, gSpitSprite, 24)	
	engfunc(EngFunc_EmitSound, ent, CHAN_VOICE, MatkaSoundAttack[0], 1.0, ATTN_NORM, 0, ipitch)
	engfunc(EngFunc_EmitSound, ent, CHAN_WEAPON, MatkaSoundAttack[random_num(1, 2)], 1.0, ATTN_NORM, 0, ipitch)

	// Utok
	static Float:dlzka
	dlzka = get_pcvar_float(cvar_freeze)
	if(dlzka > 0.0) {
		// Je zapnuty radius ?
		static Float:pavucina_radius, id
		pavucina_radius = get_pcvar_float(cpavucina_radius);
		if(pavucina_radius > 0.0) {
			id = -1
			while ((id = engfunc(EngFunc_FindEntityInSphere, id, origin, pavucina_radius)) != 0)
			{	// Filtrujeme
				if (!is_user_alive(id)) continue;
				Pavucina_zamrzni(id, dlzka);
			}
		}	
	}
	fm_remove_entity(ent);
	return 0;
}
stock Pavucina_decal(const Float:origin[3]) {
	return UTIL_decal(decal, origin);
}
stock Pavucina_decal_kruh(const Float:vektor[3], const pocet, const Float:radius) {
	if(!decal) return PLUGIN_CONTINUE;	
	new Float:dalsibod[3]
	dalsibod[2] = vektor[2];
	for(new i=0; i < pocet; i++) {
		dalsibod[0] = vektor[0] + random_float(-1*radius, radius); 
		dalsibod[1] = vektor[1] + random_float(-1*radius, radius); 
		Pavucina_decal(dalsibod);
	}
	return PLUGIN_CONTINUE;	
}
stock Pavucina_zamrzni(const id, const Float:dlzka)
{
	//Filtrujeme ...
	if(zamrznuty[id]) return;
	if(id==matka) return;
	if(zp_get_user_zombie(id)) return;
	// + Efekt
	new Float:origin[3], Float:Endorigin[3]
	pev(id, pev_origin, origin);
	UTIL_DolnyKoncovyBod(id, origin, Endorigin);
	Pavucina_decal(Endorigin);
	// Zamrzame ......
	efekt_freezeicon(id)
	fm_set_rendering(id, kRenderFxGlowShell, 220, 220, 0, kRenderNormal, 25)
	efekt_freezescreen(id, dlzka)	
	//Aby neskakali ....
	if (pev(id, pev_flags) & FL_ONGROUND)
		set_pev(id, pev_gravity, 999999.9) // nepohne sa nikdyyyy
	else
		set_pev(id, pev_gravity, 0.000001) // naopak...
	// TASK
	zamrznuty[id] = true;
	set_task(dlzka, "Pavucina_odmraz", id);
}
public Pavucina_odmraz(const id) {
	//Odmraz.....
	if(zamrznuty[id]) {
		// Zije este ?
		if (is_user_alive(id)) {
			//Odmraz.....
			set_pev(id, pev_gravity, 1.0)
			fm_set_rendering(id);
		}
	}
	zamrznuty[id] = false;
	return 1;
}
stock Matka_animacia(const id, const typ) { return Animacia(id, Matka_model_t[typ], Matka_model_s[typ]); }
stock Animacia(const id, const typ, const Float:speed) {
	if(pev(id, pev_sequence) != typ || pev(id, pev_framerate) != speed) {
		set_pev(id, pev_sequence, typ)
		set_pev(id, pev_gaitsequence, typ)
		set_pev(id, pev_framerate, speed)
	}	
	return PLUGIN_CONTINUE;	
}
stock Ochrana_size(const index, const Float:min[3], const Float:max[3]) {
	UTIL_entity_size(OchrannaEntita[index], min, max);
	UTIL_entity_size(OchrannaEntita[index+1], min, max);
	return PLUGIN_CONTINUE;	
}
stock Ochrana_pozicia(const ent, Float:origin[3], const index, const Float:value) {
	static Float:temp[3]
	temp[0] = origin[0];
	temp[1] = origin[1];
	temp[2] = origin[2];
	temp[index] += value;
	set_pev(OchrannaEntita[ent], pev_origin, temp)
}
stock UTIL_entity_size(const ent, const Float:p_mins[3], const Float:p_maxs[3]) {
	engfunc(EngFunc_SetSize, ent, p_mins, p_maxs);
	set_pev(ent, pev_mins, p_mins);
	set_pev(ent, pev_maxs, p_maxs );
	set_pev(ent, pev_absmin, p_mins);
	set_pev(ent, pev_absmax, p_maxs );
	return PLUGIN_CONTINUE;	
}
stock UTIL_decal(const decalid, const Float:origin[3]) {
	engfunc(EngFunc_MessageBegin, MSG_PAS, SVC_TEMPENTITY, origin, 0)
	write_byte(TE_WORLDDECAL) // TE id
	engfunc(EngFunc_WriteCoord, origin[0]) // x
	engfunc(EngFunc_WriteCoord, origin[1]) // y
	engfunc(EngFunc_WriteCoord, origin[2]) // z
	write_byte(decalid)
	message_end()
	return PLUGIN_CONTINUE;	
}
stock screen_effects( target )
{
	message_begin( MSG_ONE_UNRELIABLE, gMessageFade , {0,0,0}, target );
	write_short( 1<<10 );
	write_short( 1<<10 );
	write_short( FFADE_IN );
	write_byte( 255 );
	write_byte( 0 );  
	write_byte( 0 );  
	write_byte( 99 );
	message_end(); 	
	return PLUGIN_CONTINUE;	
}
stock UTIL_set_score(const id, const target, const hitscore)
{
	if(!is_user_alive(id)) return PLUGIN_CONTINUE;

	new Float:frags;
	pev(id, pev_frags, frags);
	frags += float(hitscore);	
	zp_add_user_ammo_packs(id, hitscore);
	set_pev(id, pev_frags, frags)
	
	message_begin(MSG_ALL, g_msgDeathMsg, {0, 0, 0} ,0)
	write_byte(id)
	write_byte(target)
	write_byte(0)
	write_string("matka")
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
stock fm_set_rendering(entity, fx = kRenderFxNone, r = 255, g = 255, b = 255, render = kRenderNormal, amount = 16)
{
	new Float:color[3]
	color[0] = float(r)
	color[1] = float(g)
	color[2] = float(b)
	
	set_pev(entity, pev_renderfx, fx)
	set_pev(entity, pev_rendercolor, color)
	set_pev(entity, pev_rendermode, render)
	set_pev(entity, pev_renderamt, float(amount))
	return PLUGIN_CONTINUE;	
}
stock UTIL_normalize(Float:Vec[3]) {
	new Float:v_length;
	v_length = vector_length(Vec)
	Vec[1] = Vec[0] / v_length
	Vec[1] = Vec[1] / v_length
	Vec[2] = Vec[2] / v_length
}
stock UTIL_IsBSPModel(const ent) {
	return (pev(ent, pev_solid) == SOLID_BSP || pev(ent, pev_movetype) == MOVETYPE_PUSHSTEP);
}
stock UTIL_GetDecalIndex( nazov[]) {
	return engfunc(EngFunc_DecalIndex, nazov);
}
stock UTIL_UserSkutocnyKoncovyBod(const id, const Float:origin[3], Float:Endorigin[3])
{
	new Float:fAimVector[3], iTr
	pev( id, pev_v_angle, fAimVector )
	angle_vector( fAimVector, ANGLEVECTOR_FORWARD, fAimVector )
	// nasobyme vektor, ...je to po aku dlzku az pojde
	fAimVector[0] = fAimVector[0] * 9999.0 + origin[0]
	fAimVector[1] = fAimVector[1] * 9999.0 + origin[1]
	fAimVector[2] = fAimVector[2] * 9999.0 + origin[2]
	// vysledok ulozime
	iTr = create_tr2()
	engfunc( EngFunc_TraceLine, origin, fAimVector, IGNORE_MONSTERS, id, iTr )
	get_tr2( iTr, TR_vecEndPos, Endorigin)
	free_tr2( iTr )
}	
stock UTIL_DolnyKoncovyBod(	const id, 
							const Float:origin[3],
							Float:Endorigin[3], 
							const Float:koeficient = 300.0 )
{	
	new iTr
	Endorigin[0] = origin[0];
	Endorigin[1] = origin[1];
	Endorigin[2] = origin[2] - koeficient; // zatial postaci ...
	iTr = create_tr2()
	engfunc( EngFunc_TraceLine, origin, Endorigin, IGNORE_MONSTERS, id, iTr )
	get_tr2( iTr, TR_vecEndPos, Endorigin)
	free_tr2( iTr )
}	
stock UTIL_ZneviditelnyEntitu(const ent) {
	set_pev(ent, pev_rendermode, 2.0)
	set_pev(ent, pev_renderamt, 1.0)
}










/*

stock UTIL_debug(const id, const ent, const Float:cas = 0.01)
{
	static 	Float: ent_min[3],Float: ent_max[3],Float: id_ori[3],
			e_min[3],e_max[3],ori[3],ents[3];	
	
	entity_get_vector(ent,EV_VEC_absmin,ent_min)
	entity_get_vector(ent,EV_VEC_absmax,ent_max)	
	entity_get_vector(id,EV_VEC_origin,id_ori);
	
	for(new i=0;i<3;i++) {
		e_min[i]=floatround(ent_min[i])
		e_max[i]=floatround(ent_max[i])
		ori[i]=floatround(id_ori[i])
		ents[i]=(e_min[i]+e_max[i])/2
	}
	Create_Line(id, ori, ents, cas)
	Create_Box(id, e_min, e_max, cas)
}
stock Create_Box(const id,const mins[3], const maxs[3], const Float:cas)
{
	DrawLine(id,maxs[0], maxs[1], maxs[2], mins[0], maxs[1], maxs[2], cas)
	DrawLine(id,maxs[0], maxs[1], maxs[2], maxs[0], mins[1], maxs[2], cas)
	DrawLine(id,maxs[0], maxs[1], maxs[2], maxs[0], maxs[1], mins[2], cas)

	DrawLine(id,mins[0], mins[1], mins[2], maxs[0], mins[1], mins[2], cas)
	DrawLine(id,mins[0], mins[1], mins[2], mins[0], maxs[1], mins[2], cas)
	DrawLine(id,mins[0], mins[1], mins[2], mins[0], mins[1], maxs[2], cas)

	DrawLine(id,mins[0], maxs[1], maxs[2], mins[0], maxs[1], mins[2], cas)
	DrawLine(id,mins[0], maxs[1], mins[2], maxs[0], maxs[1], mins[2], cas)
	DrawLine(id,maxs[0], maxs[1], mins[2], maxs[0], mins[1], mins[2], cas)
	DrawLine(id,maxs[0], mins[1], mins[2], maxs[0], mins[1], maxs[2], cas)
	DrawLine(id,maxs[0], mins[1], maxs[2], mins[0], mins[1], maxs[2], cas)
	DrawLine(id,mins[0], mins[1], maxs[2], mins[0], maxs[1], maxs[2], cas)
}
stock DrawLine(const id, const x1, const y1, const z1, const x2, const y2, const z2, const Float:cas) 
{
	static start[3], stop[3]
	start[0]=(x1)
	start[1]=(y1)
	start[2]=(z1)
	stop[0]=(x2)
	stop[1]=(y2)
	stop[2]=(z2)
	Create_Line(id,start, stop, cas)
}
stock Create_Line2(const start[3], const stop[3]) {
	Create_Line(matka, start, stop, 10.0)
}
stock Create_Line(const id,const start[3], const stop[3], const Float:cas)
{
	message_begin(MSG_ONE,SVC_TEMPENTITY,{0,0,0},id)
	write_byte(0)
	write_coord(start[0])
	write_coord(start[1])
	write_coord(start[2])
	write_coord(stop[0])
	write_coord(stop[1])
	write_coord(stop[2])
	write_short(sprite_line)
	write_byte(1)
	write_byte(5)
	write_byte(floatround(cas*10))
	write_byte(3)
	write_byte(0)
	write_byte(255)	// RED
	write_byte(0)	// GREEN
	write_byte(0)	// BLUE					
	write_byte(250)	// brightness
	write_byte(5)
	message_end()
}*/
/*	pouzite s SOLID_BBOX - len BBOX zachytava palbu overene na 4
	spustie aspon		zaznamenava strelbu ?  da sa prechadzat ?
	0 IDE				nie				ano
	1 hl error
	2 hl error
	3 eror
	4					ANO
	5					ano
	6 asi					ano
	7
	8 vyplo hru
	9					ano				ano
	10 pekne								ano

	SOLID_TRIGGER - malo by byt rovnako ...
	10    					NIE				ANO			-	pekne odskakuje ....
	
	Ci sa da prechadzat to mozme spravit podla svojej funkcie, dolezite je len GULKY
*/
/*
GetEntityAbsMins(ent, Float:absMins[3])
{
    new Float:tMins[3];
    GetEntPropVector(ent,Prop_Data,"m_vecMins",tMins);

    absMins[0] = FloatAbs(tMins[0]);
    absMins[1] = FloatAbs(tMins[1]);
    absMins[2] = FloatAbs(tMins[2]);
}

GetEntityAbsMaxs(ent, Float:absMaxs[3])
{
    new Float:tMaxs[3];
    GetEntPropVector(ent,Prop_Data,"m_vecMaxs",tMaxs);

    absMaxs[0] = FloatAbs(tMaxs[0]);
    absMaxs[1] = FloatAbs(tMaxs[1]);
    absMaxs[2] = FloatAbs(tMaxs[2]);
}
*/
/*	
	// Strielame projektil, skrytu entitu ...
	static Float:origin[3], Float: velocity[3], Float: vAngle[3], ent
	ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	// Udaje ..
	pev(matka, pev_velocity, velocity)
	pev(matka, pev_origin, origin)
	pev(matka, pev_v_angle, vAngle)
	// nastav ...
	set_pev(ent, pev_classname, NAZOV_PAVUCINA);
	UTIL_entity_size(ent, {-1.0, -7.0, -1.0}, {1.0, 7.0, 1.0})
	// vektory ... a ine
	vAngle[0] -= 90
	set_pev(ent, pev_origin, origin)
	set_pev(ent, pev_angles, vAngle)
	set_pev(ent, pev_effects, 2)
	set_pev(ent, pev_solid, SOLID_TRIGGER)
	set_pev(ent, pev_movetype, MOVETYPE_TOSS)
	VelocityByAim(matka, get_pcvar_num(cvar_dostrel) , velocity)
	set_pev(ent, pev_velocity, velocity)
	//debug ...
	entity_set_model(ent, "models/w_throwingknife.mdl")
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_BEAMFOLLOW) // TE id
	write_short(ent) // entity
	write_short(gSpitSprite) // sprite
	write_byte(10) // life
	write_byte(10) // width
	write_byte(120) // r
	write_byte(120) // g
	write_byte(120) // b
	write_byte(200) // brightness
	message_end()
*/