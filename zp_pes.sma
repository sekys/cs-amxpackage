#include <amxmodx>
#include <amxmisc>
#include <zombieplague>
#include <fakemeta>
#include <hamsandwich>
#include <cstrike>
#include <Vexd_Utilities>

#define fm_precache_model(%1) 		engfunc(EngFunc_PrecacheModel,%1)
#define fm_precache_sound(%1) 		engfunc(EngFunc_PrecacheSound,%1)
#define fm_remove_entity(%1) 		engfunc(EngFunc_RemoveEntity, %1)
#define fm_drop_to_floor(%1) 		engfunc(EngFunc_DropToFloor,%1)
#define fm_find_ent_by_class(%1,%2) 	engfunc(EngFunc_FindEntityByString, %1, "classname", %2)

// Nastavovacky
#define NAZOV_ENT 			"zp_pes"
#define CASOVAC				2
#define RADIUS_WARNING		700.0
#define RADIUS_ATTACK		400.0
/*#define PES_HP 			200.0
#define HP_OFFSET 			10000.0*/
#define PES_UTOK 			10.0
//#define pes_KILLED 			1
#define OWNER				pev_iuser2
#define WARNING_STUPEN		pev_iuser3
#define pes_FLAG 			pev_iuser4

new const VELKOST_MIN[] = { -15.0, -10.0, -16.0 }
new const VELKOST_MAX[] = { 15.0, 10.0, 16.0 }

new const pes_model[] = "models/zombie_plague/hellhound.mdl"
new const pes_sounds[][] = { 
	"zombie_plague/pes/RUR_Random_DogBig01.wav", 
	"zombie_plague/pes/RUR_Random_DogBig02.wav", 
	"zombie_plague/pes/RUR_Random_DogBig03.wav", 
	"zombie_plague/pes/RUR_Random_DogBig04.wav" 
}									 
new const pes_idle = 1
new const pes_bezi = 4
new const pes_smrt = 99
new const pes_cena = 7
new const Float:pes_idle_speed = 1.0
new const Float:pes_bezi_speed = 0.8

// G.Premenne
new item_id, ma_psa[33], maxplayers, bool:pes_stekot[33];
new Float:item_leaptime[33], g_msgDeathMsg, g_msgScoreInfo, g_msgDamage

public plugin_init() {
	register_plugin("Ochranny pes", "1.0", "Seky");
	register_event("DeathMsg","DeathMsg","a");
	
	register_forward(FM_Think, "pes_Think" );	
	RegisterHam(Ham_Touch, "info_target", "player_touch")	
	RegisterHam(Ham_Spawn, "player", "player_spawn", 1)	
	
	item_id = zp_register_extra_item("Pes ochranca 200HP", pes_cena, ZP_TEAM_HUMAN)
	maxplayers = get_maxplayers();
	g_msgDeathMsg 	= get_user_msgid("DeathMsg");
	g_msgScoreInfo	= get_user_msgid("ScoreInfo");
	g_msgDamage 	= get_user_msgid("Damage");
}
public plugin_precache() {
	for(new i = 0; i < sizeof pes_sounds; i++)
		fm_precache_sound(pes_sounds[i])
	
	fm_precache_model(pes_model)	
}
public zp_extra_item_selected(id, itemid) {	
	if(itemid == item_id)	{
		if(ma_psa[id]) {
			client_print(id, print_chat, "[G/L ZP] Uz mas jedneho psa ...")
			//vrat_body(id, pes_cena);
			return ZP_PLUGIN_HANDLED;
		}
		create_pes(id);		
	}
	return PLUGIN_CONTINUE;
}
stock vrat_body(id, kolko) {
	if(get_user_flags(id) & ADMIN_LEVEL_F ) {
		kolko = floatround( float(kolko) * 0.5 , floatround_floor );	
	}
	zp_set_user_ammo_packs(id,zp_get_user_ammo_packs(id) +  kolko)
}

public create_pes(id) {
	if(!is_user_alive(id)) return PLUGIN_CONTINUE;

	//client_print(0, print_chat, "__create") //log
	new ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString,"info_target"))
	set_pev(ent, pev_classname, NAZOV_ENT);	
	engfunc(EngFunc_SetModel, ent, pes_model);
	
	static Float:origin[3];
	//pev(id,pev_origin,origin)	dole je lepsie posunie ho ...		
	get_offset_origin(id, Float:{40.0, 0.0, 0.0}, origin);
	
	// Vlastnosti nastavujeme
	set_pev(ent, pev_origin, origin)
	set_pev(ent, pev_solid, SOLID_TRIGGER)//SOLID_BBOX) //SOLID_TRIGGER)
	set_pev(ent, pev_movetype, MOVETYPE_FLY)
	set_pev(ent, pev_nextthink, 1.0)
	set_pev(ent, OWNER, id)
	set_pev(ent, pev_sequence, pes_idle)
	set_pev(ent, pev_gaitsequence, pes_idle)
	set_pev(ent, pev_framerate, pes_idle_speed)
	/*set_pev(ent, pev_health, PES_HP+HP_OFFSET);
	set_pev(ent, pev_takedamage, DAMAGE_YES);*/

	// Velkost
	//set_pev(ent, pev_mins, VELKOST_MIN);
	//set_pev(ent, pev_maxs, VELKOST_MAX);
	//engfunc(EngFunc_SetSize, ent, VELKOST_MIN, VELKOST_MAX);
		
	// Zaciname task 
	ma_psa[id] = ent;
	engfunc(EngFunc_EmitSound, ent, CHAN_AUTO, pes_sounds[random_num(0,sizeof pes_sounds - 1)], 1.0, 1.2, 0, PITCH_NORM);
	client_print(id, print_chat, "[G/L ZP] Pes ochranca ta obranuje pred zombikmy a steka na nich.(Ma 200HP)")
	return PLUGIN_CONTINUE;
}
public zp_round_ended(winteam) {
	new entid = -1;
	while((entid = fm_find_ent_by_class(entid, NAZOV_ENT))) {
		fm_remove_entity(entid)		
	}
	//client_print(0, print_chat, "__end") //log		
}	
public player_spawn(id)	{			
	pes_stekot[id] = false;
	if(ma_psa[id]) {
		set_task(3.0+get_cvar_float("zp_delay"), "create_pes", id);
		//client_print(0, print_chat, "__spawn") //log
	}
}
public client_disconnect(id) {
	if(ma_psa[id]) {
		pes_stekot[id] = false;
		ma_psa[id] = 0;
		if(pev_valid(ma_psa[id])) {
			fm_remove_entity(ma_psa[id]);
		}
	}
	return PLUGIN_CONTINUE;
}
public pes_Think(ent) {
	//Je to vobec pes ?
	if (!pev_valid(ent) ) {
		return FMRES_IGNORED;
	}	
	static EntityName[32];
	pev(ent, pev_classname, EntityName, 31);
	if(!equal(EntityName, NAZOV_ENT) ) {
		return FMRES_IGNORED;
	}	
	
	// Ak uz je mrtvy
	/*if(pev(ent, pes_FLAG) == pes_KILLED) {
		return FMRES_IGNORED;
	}*/
	new majitel = pev(ent, OWNER);

	// Zabijame psa
	/*if(pev(ent, pev_health) < HP_OFFSET) {
		if(majitel) {
			ma_psa[majitel] = 0;
			pes_stekot[majitel] = false;
			set_pev(ent, OWNER, 0)
		}
		
		set_pev(ent, pev_sequence, pes_smrt);
		set_pev(ent, pev_gaitsequence, pes_smrt);
		set_pev(ent, pev_framerate, 1.0);		
		set_pev(ent, pes_FLAG, pes_KILLED);	
		
		// nova Velkost
		set_pev(ent, pev_mins, { 0.0, 0.0, 0.0 } );
		set_pev(ent, pev_maxs, { 0.0, 0.0, 0.0 });
		engfunc(EngFunc_SetSize, ent, { 0.0, 0.0, 0.0 }, { 0.0, 0.0, 0.0 });
		fm_drop_to_floor(ent);	
		
		// Oprava modelu
		new Float:bod[3]
		pev(ent, pev_origin, bod)
		bod[2] -= 13.0;
		set_pev(ent, pev_origin, bod)
		return FMRES_IGNORED;	
	}*/
	
	// Stratil majitela ?
	if(!majitel) {
		//set_pev(ent, pev_nextthink, 3.0) // vsetko preskakujeme ......ale stale potrebujeme aby sa dal zabit
		return FMRES_IGNORED;
	}
		
	// Pohyb.......
	static Float:origin[3]
	static Float:origin2[3]
	static Float:velocity[3]
	static Float:vzdialenost
	pev(ent, pev_origin, origin2)
	get_offset_origin_body(majitel, Float:{40.0, 0.0, 0.0}, origin);
	vzdialenost = get_distance_f(origin, origin2);
	new bool:StojiNaMieste = false; // bol vykonany pohyb ?
	
	// Je velmi daleko , nastala nejaka cudna situacia a zmenila sa priliz velkost
	if(vzdialenost > 300.0) {
		set_pev(ent, pev_origin, origin);
	}
	// Ide za panom
	else if(vzdialenost > 100.0)
	{		
		// pred aj po dame zeby bol stale na zemy cize nikdy nebude ist hore za rebrikom ....
		//pev(ent, pev_origin, origin2)
		//new float:Y_suradnica = origin2[2];
		get_speed_vector(origin2, origin, 250.0, velocity)
		// aby vsak nenastavalo trhanie a raz bol hore a raz dole ......?
		//origin2[2] = Y_suradnica;
		set_pev(ent, pev_velocity, velocity)
		//fm_drop_to_floor(ent);
		
		if(pev(ent,pev_sequence) != pes_bezi || pev(ent,pev_framerate) != pes_bezi_speed)
		{
			set_pev(ent, pev_sequence, pes_bezi)
			set_pev(ent, pev_gaitsequence, pes_bezi)
			set_pev(ent, pev_framerate, pes_bezi_speed)
		}
	}
	// Je tesne pri nom
	else if(vzdialenost < 75.0)
	{
		if(pev(ent, pev_sequence) != pes_idle || pev(ent, pev_framerate) != pes_idle_speed)
		{
			set_pev(ent, pev_sequence, pes_idle)
			set_pev(ent, pev_gaitsequence, pes_idle)
			set_pev(ent, pev_framerate, pes_idle_speed)
		}
		StojiNaMieste = true;
		set_pev(ent, pev_velocity, Float:{0.0,0.0,0.0})
	}
	
	// Stekanie.....
	new id, Float:vektor2[3], float:najm_vzdialenost=RADIUS_WARNING, najm_id=0;
	
	for(id = 1; id <= maxplayers; id++) {		
		// Filtrujeme ...
		if(!is_user_alive(id)) continue;
		if(!zp_get_user_zombie(id)) continue;
			
		// Hladame najblizsieho ....
		pev(id, pev_origin, vektor2);
		vzdialenost = get_distance_f(origin, vektor2);		
		if ( vzdialenost < RADIUS_WARNING) {
			if( vzdialenost < najm_vzdialenost) {
				najm_id = id;
				najm_vzdialenost = vzdialenost;
			}
		}
	}
	
	// Ma stekat na niekoho .....
	if(najm_id) {
		//client_print(0, print_chat, "__haf") //log
		if(!pes_stekot[majitel]) {
			// este na nikoho nesteka
			pes_stekot[majitel] = true;
			set_pev(ent, WARNING_STUPEN, floatround(najm_vzdialenost / 100.0)) // cim blizsie tym intenzivnejsie
			zvucka_atmosfera(majitel+CASOVAC);
		}	
		
		// Co ak je priliz blizko ? -> branit pana ....
		/*if( vzdialenost < RADIUS_ATTACK) {
			 get_offset_origin(najm_id, Float:{0.0, 0.0, 0.0}, vektor2)
			// S = A+B / 2 stred usecky
			pev(najm_id, pev_origin, vektor2);
			vektor2[0] = (origin[0] + vektor2[0]) / 2;	
			vektor2[1] = (origin[1] + vektor2[1]) / 2;		
			vektor2[2] = (origin[2] + vektor2[2]) / 2;	
			set_pev(ent, pev_velocity, vektor2)
		}*/
		
	} else {
		// Nikto tam nieje ....
		if(task_exists(majitel+CASOVAC)) {
			remove_task(majitel+CASOVAC);
		}
		pes_stekot[majitel] = false;	
	}
	
	// Nastavyme pohlad
	if(!StojiNaMieste || !najm_id) {
		// musi sa nanho pozerat inak ked by ho nasledoval a cuval by a to necheme ...
		pev(majitel, pev_origin, origin)
	} else {
		// Ak stoji a steka tak ukaz na zombika ....
		pev(najm_id, pev_origin, origin)
	}
	origin[2] = origin2[2]
	entity_set_aim(ent, origin)
	
	// Cyklus ....	
	set_pev(ent, pev_nextthink, 1.0)
}
public zvucka_atmosfera(id) {
	id -= CASOVAC;
	if(!pes_stekot[id]) return PLUGIN_CONTINUE;// uz nema stekat ......
	if(!ma_psa[id] || !pev_valid(ma_psa[id]))  return PLUGIN_CONTINUE;

	engfunc(EngFunc_EmitSound, ma_psa[id], CHAN_AUTO, pes_sounds[random_num(0,sizeof pes_sounds - 1)], 1.0, 1.2, 0, PITCH_NORM);	
	set_task(float( pev(ma_psa[id], WARNING_STUPEN) + 3 ), "zvucka_atmosfera", id+CASOVAC);	
}
public DeathMsg() {
	return ponechaj_psa(read_data(2));
}
public zp_user_infected_post(id,infector){
	return ponechaj_psa(id);
}
stock ponechaj_psa(id) {
	// Pes ostava na mieste ....zabyt sa ho bude dat stale.... atd.
	if(ma_psa[id])	{
		set_pev(ma_psa[id], OWNER, 0)
		pes_stekot[id] = false;		
		// Model
		set_pev(ma_psa[id], pev_sequence, pes_idle)
		set_pev(ma_psa[id], pev_gaitsequence, pes_idle)
		set_pev(ma_psa[id], pev_framerate, 1.0)
		fm_drop_to_floor(ma_psa[id]);
		ma_psa[id] = 0;
		//client_print(0, print_chat, "__ponechaj") //log
	}
	return PLUGIN_CONTINUE;
}
stock get_offset_origin_body(ent, const Float:offset[3], Float:origin[3])
{	
	static Float:angle[3]
	pev(ent,pev_angles,angle)
	pev(ent,pev_origin,origin)
	
	origin[0] += floatcos(angle[1],degrees) * offset[0]
	origin[1] += floatsin(angle[1],degrees) * offset[0]
	
	origin[1] += floatcos(angle[1],degrees) * offset[1]
	origin[0] += floatsin(angle[1],degrees) * offset[1]
	return 1;
}

stock get_speed_vector(const Float:origin1[3],const Float:origin2[3],Float:speed, Float:new_velocity[3])
{
	new_velocity[0] = origin2[0] - origin1[0]
	new_velocity[1] = origin2[1] - origin1[1]
	new_velocity[2] = origin2[2] - origin1[2]
	new Float:num = floatsqroot(speed*speed / (new_velocity[0]*new_velocity[0] + new_velocity[1]*new_velocity[1] + new_velocity[2]*new_velocity[2]))
	new_velocity[0] *= num
	new_velocity[1] *= num
	new_velocity[2] *= num
}
public player_touch(pes, clovek)
{	
	// Su to entity ?
	if(!pes || !clovek) {
		return HAM_IGNORED;
	}
	new classname[32]
	pev(pes, pev_classname, classname, 31)
	
	// Je to clovek a pes ? 
	if(clovek < 1 || clovek > 32) {
		return HAM_IGNORED;
	}
	if(!equal(classname, NAZOV_ENT)) {
		return HAM_IGNORED;
	}		
	if(!pev_valid(pes)) {
		return HAM_IGNORED;
	}
	// Zije pes ?	
	/*if(pev(pes, pes_FLAG) == pes_KILLED) {
		return HAM_IGNORED;
	}*/	

	// nema majitela .....	
	new majitel = pev(pes, OWNER);
	if(!majitel)
	{
		// Nema psa,  neje zombik,
		if(!ma_psa[clovek] && !zp_get_user_zombie(clovek))
		{			
			set_pev(pes, OWNER, clovek)
			ma_psa[clovek] = pes;
			pes_stekot[clovek] = false;	
			// + Efekt
			engfunc(EngFunc_EmitSound, pes, CHAN_AUTO, pes_sounds[random_num(0,sizeof pes_sounds - 1)], 1.0, 1.2, 0, PITCH_NORM);
			client_print(clovek, print_chat, "[G/L ZP] Ziskal si noveho psa.")			
		}
	} /*else {
		// Ma majitela ....
		if(zp_get_user_zombie(clovek)) {
			// stretol sa zo zombikom ....	
			if(pev_user_health(clovek) < PES_UTOK) {
				set_score(majitel, clovek, 1)
			} else {			
				fakedamage(clovek, "pes", PES_UTOK, DMG_SLASH);													
			}
			//engfunc(EngFunc_EmitSound, pes, CHAN_AUTO, pes_sounds[random_num(0,sizeof pes_sounds - 1)], 1.0, 1.2, 0, PITCH_NORM);							
			//client_print(0, print_chat, "__attack") //log
		}
	}*/
	return HAM_IGNORED;
}
stock pev_user_health(id)
{
	new Float:health
	pev(id, pev_health, health)
	return health
}
stock set_score(id, target, hitscore)
{
	new idfrags = pev_user_frags(id) + hitscore;	
	set_pev(id, pev_frags, float(idfrags))
	
	message_begin(MSG_ALL, g_msgDeathMsg, {0, 0, 0} ,0)
	write_byte(id)
	write_byte(target)
	write_byte(0)
	write_string("Pes")
	message_end()

	message_begin(MSG_ALL, g_msgScoreInfo)
	write_byte(id)
	write_short(idfrags)
	write_short(cs_get_user_deaths(id))
	write_short(0)
	write_short( int:cs_get_user_team(id) )
	message_end()

	set_msg_block(g_msgDeathMsg, BLOCK_ONCE)
	dllfunc(DLLFunc_ClientKill, target)
}
stock pev_user_frags(index)
{
	new Float:frags;
	pev(index,pev_frags,frags);
	return floatround(frags);
}
stock entity_set_aim(ent,const Float:origin2[3],bone=0) {
	static Float:origin[3]
	origin[0] = origin2[0]
	origin[1] = origin2[1]
	origin[2] = origin2[2]
	
	static Float:ent_origin[3], Float:angles[3]
	
	if(bone)
		engfunc(EngFunc_GetBonePosition, ent, bone, ent_origin,angles)
	else
		pev(ent, pev_origin, ent_origin)
	
	origin[0] -= ent_origin[0]
	origin[1] -= ent_origin[1]
	origin[2] -= ent_origin[2]
	
	static Float:v_length
	v_length = vector_length(origin)
	
	static Float:aim_vector[3]
	aim_vector[0] = origin[0] / v_length
	aim_vector[1] = origin[1] / v_length
	aim_vector[2] = origin[2] / v_length
	
	static Float:new_angles[3]
	vector_to_angle(aim_vector,new_angles)
	
	new_angles[0] *= -1
	
	if(new_angles[1]>180.0) new_angles[1] -= 360
	if(new_angles[1]<-180.0) new_angles[1] += 360
	if(new_angles[1]==180.0 || new_angles[1]==-180.0) new_angles[1]=-179.999999
	
	set_pev(ent,pev_angles,new_angles)
	set_pev(ent,pev_fixangle,1)
	return 1;
}
stock get_offset_origin(ent, Float:offset[3], Float:origin[3])
{    
    static Float:angle[3];
    pev(ent, pev_origin, origin);
    pev(ent, pev_angles, angle);
    
    origin[0] += floatcos(angle[1],degrees) * offset[0];
    origin[1] += floatsin(angle[1],degrees) * offset[0];
    
    origin[2] += floatsin(angle[0],degrees) * offset[0];
    origin[0] += floatcos(angle[0],degrees) * offset[0];
    
    origin[1] += floatcos(angle[1],degrees) * offset[1];
    origin[0] -= floatsin(angle[1],degrees) * offset[1];
    
    origin[2] += floatsin(angle[2],degrees) * offset[1];
    origin[1] += floatcos(angle[2],degrees) * offset[1];
    
    origin[2] += floatcos(angle[2],degrees) * offset[2];
    origin[1] -= floatsin(angle[2],degrees) * offset[2];
    
    origin[2] += floatcos(angle[0],degrees) * offset[2];
    origin[0] -= floatsin(angle[0],degrees) * offset[2];
    
    origin[0] -= offset[0];
    origin[1] -= offset[1];
    origin[2] -= offset[2];
}  