#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fun>
#include <cstrike>
#include <fakemeta>

#define SPAWNOV 64

//======================================================================================================================

new const modely[][] = { "models/tekvica.mdl", "models/tekvica2.mdl" };
stock const NADPIS[] = "^x04[Halloween]^x01 %s";

new gcvar_removePresents, g_explo, gcvar_presentAmount, g_orginFilePath[256],
	pcvar_blast, pcvar_blast_color , Float:g_spawnOrigins[SPAWNOV][3] , g_totalOrigins,
	pcvar_zbrane, darcek_pravd, g_ExplosionMdl, g_SmokeMdl;

new Float:colors[][3] = 
{
	{95.0, 200.0, 255.0},
	{0.0, 150.0, 255.0},
	{180.0, 255.0, 175.0},
	{0.0, 155.0, 0.0},
	{255.0, 255.0, 255.0},
	{255.0, 190.0, 90.0},
	{222.0, 110.0, 0.0},
	{192.0, 192.0, 192.0},
	{190.0, 100.0, 10.0},
	{0.0, 0.0, 0.0}
};

//======================================================================================================================
public plugin_init()
{

	register_plugin("Vianoce salalla", "1.5", "");
	register_dictionary("presentsspawner.txt");

	register_clcmd("darcek_spawn_add", "darcek_spawn_add", ADMIN_RCON, "-");
	register_clcmd("darcek_spawn", "darcek_spawn", ADMIN_LEVEL_E, "-");
	register_clcmd("darcek_remove", "darcek_remove", ADMIN_LEVEL_E, "-");

	darcek_pravd = register_cvar("darcek_pravd2", "1000");
	gcvar_removePresents = register_cvar("darcek_remove_cvar", "0");
	gcvar_presentAmount = register_cvar("darcek_pocet", "3");
	pcvar_blast = register_cvar("darcek_efekt","0");
	pcvar_blast_color = register_cvar("darcek_efekt_farba","255 255 255");
	pcvar_zbrane = register_cvar("darcek_zbrane","1");
	
	register_logevent("event_roundStart", 2, "1=Round_Start");
	register_touch("maximusbroodPresent", "player", "event_dotknutie");
			
	new filepath[256];
	get_datadir(filepath, 255);
	
	new mapname[32];
	get_mapname(mapname, 31);
	
	format(g_orginFilePath, 255, "%s/presents/%s.ini", filepath, mapname);
	
	loadData();
}
public plugin_precache()
{
	new i;

	for(i = 0; i < sizeof modely; i++)
		engfunc(EngFunc_PrecacheModel, modely[i]);
		
	engfunc(EngFunc_PrecacheSound, "survivor2.wav");
	engfunc(EngFunc_PrecacheSound, "mkbell.wav");
	engfunc(EngFunc_PrecacheSound, "female_cry_1.wav");
	engfunc(EngFunc_PrecacheSound, "ghoullaugh.mp3");
				
	g_ExplosionMdl = precache_model("sprites/zerogxplode.spr")
	g_SmokeMdl = precache_model("sprites/steam1.spr")
	g_explo = engfunc(EngFunc_PrecacheModel,"sprites/shockwave.spr");
	
	return PLUGIN_CONTINUE;
}
//======================================================================================================================

loadData()
{
	g_totalOrigins = 0;
	
	//Note that we won't throw any errormessages when no presents are found
	new buffer[128];
	new strX[12], strY[12], strZ[12];
	if( file_exists(g_orginFilePath) )  
	{
		new readPointer = fopen(g_orginFilePath, "rt");
		
		if(!readPointer)
			return;
			
		while( !feof(readPointer) )
		{
			fgets(readPointer, buffer, 127);
			
			if(buffer[0] == ';' || !buffer[0])
				continue;
				
			parse(buffer, strX, 11, strY, 11, strZ, 11);
			
			g_spawnOrigins[g_totalOrigins][0] = float(str_to_num(strX));
			g_spawnOrigins[g_totalOrigins][1] = float(str_to_num(strY));
			g_spawnOrigins[g_totalOrigins][2] = float(str_to_num(strZ));
			
			++g_totalOrigins;
		}
		
		fclose(readPointer);
	}
}

//======================================================================================================================

public darcek_spawn_add(id, level, cid)
{
	if (!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED;
		
	if(g_totalOrigins >= SPAWNOV)
	{
		client_print(id, print_console, "[presentsSpawner] %L", id, "MAXSPAWNS_REACHED", SPAWNOV);
		return PLUGIN_CONTINUE;
	}
	
	new Float:currentOrigin[3];
	entity_get_vector(id, EV_VEC_origin, currentOrigin);
	
	//Open the file for writing, write the origin and close up
	new writePointer = fopen(g_orginFilePath, "at");
	
	if(writePointer)
	{
		server_print("Writing, coords are {%f, %f, %f} or {%d, %d, %d}", currentOrigin[0], currentOrigin[1], currentOrigin[2], floatround(currentOrigin[0]), floatround(currentOrigin[1]), floatround(currentOrigin[2]));	
		fprintf(writePointer, "%d %d %d^n", floatround(currentOrigin[0]), floatround(currentOrigin[1]), floatround(currentOrigin[2]) );	
		fclose(writePointer);
		
		client_print(id, print_console, "[presentsSpawner] %L", id, "ADD_SUCCESS");
	
		//Reload spawnpoints
		loadData();
	} else
		client_print(id, print_console, "Failed to add!");

	
	return PLUGIN_CONTINUE;
}

public darcek_spawn(id, level, cid)
{
	if (!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED;
		
	//Get the player's origin
	new Float:playerOrigin[3];
	entity_get_vector(id, EV_VEC_origin, playerOrigin);
	
	//Pack the origin
	new packedOrigin[3];
	FVecIVec(playerOrigin, packedOrigin);
	
	set_task(2.5, "spawnPresent", _, packedOrigin, 3);
	
	//Don't display a message to the user, gets irritating	
	return PLUGIN_HANDLED;
}

public darcek_remove(id, level, cid)
{
	if (!cmd_access(id, level, cid, 1))
		return PLUGIN_CONTINUE;
		
	removePresents();	
	client_print(id, print_console, "[presentsSpawner] %L", id, "REMOVED_ALL");
	return PLUGIN_CONTINUE;
}
public event_dotknutie(pTouched, pToucher)
{
	if(!is_valid_ent(pToucher) || !is_valid_ent(pTouched) || !is_user_connected(pToucher))
		return PLUGIN_HANDLED;
		
	if(random_num(1, get_pcvar_num(darcek_pravd)) == 2) {
		emit_sound(pToucher, CHAN_STATIC, "ghoullaugh.mp3", 1.0, ATTN_NORM, 0, PITCH_NORM);
		new meno[33];
		get_user_name(pToucher, meno, 32);
		SayText(0, pToucher, NADPIS ,"%s ma z pekla stastie, ziskal VIP !",meno);	
		//Pridame do VIP
		log_to_file("vip.log","VIP %s",meno)
		
	} else {
		new darcek;
		if(get_pcvar_num(pcvar_zbrane) == 1)
		{
			darcek = random_num(1, 5);
		} else {
			darcek = random_num(1, 10);
		}
		switch (darcek) {
			case 1: {  //nic
				client_cmd(pToucher, "spk sound/female_cry_1.wav");
				SayText(pToucher, pToucher, NADPIS ,"Tekvica je prazdna :D");
			}
			case 2: { //vesta
				client_cmd(pToucher, "spk sound/mkbell.wav");
				give_item(pToucher,"item_kevlar");
				give_item(pToucher,"item_assaultsuit");
				SayText(pToucher, pToucher, NADPIS ,"V tekvici bola vesta.");
			}

			case 3: { //naboje
				client_cmd(pToucher, "spk sound/mkbell.wav");
				give_item(pToucher,"ammo_556nato");
				give_item(pToucher,"ammo_556nato");
				give_item(pToucher,"ammo_556nato");
				give_item(pToucher,"ammo_50ae");
				give_item(pToucher,"ammo_50ae");
				give_item(pToucher,"ammo_50ae");
				give_item(pToucher,"ammo_50ae");
				give_item(pToucher,"ammo_50ae");
				give_item(pToucher,"ammo_50ae");
				give_item(pToucher,"ammo_50ae");
				give_item(pToucher,"ammo_762nato");
				give_item(pToucher,"ammo_762nato");
				give_item(pToucher,"ammo_762nato");
				give_item(pToucher,"ammo_9mm");
				give_item(pToucher,"ammo_9mm"); 
				give_item(pToucher,"ammo_9mm");
				give_item(pToucher,"ammo_9mm");
				give_item(pToucher,"ammo_45acp"); 
				give_item(pToucher,"ammo_45acp"); 
				give_item(pToucher,"ammo_45acp"); 
				give_item(pToucher,"ammo_45acp");
				SayText(pToucher, pToucher, NADPIS ,"V tekvici boli naboje");
			}
			case 4: {  //zivot
				client_cmd(pToucher, "spk sound/mkbell.wav");
				new health = 50;
				new totalhealth = get_user_health (pToucher) + health;
				set_user_health(pToucher, totalhealth);
				SayText(pToucher, pToucher, NADPIS ,"Tucna tekvica + 50HP");
			}		
			case 5: {  //peniaze
				client_cmd(pToucher, "spk sound/mkbell.wav");
				new addmoney = random_num(100, 3000);
				SayText(pToucher, pToucher, NADPIS ,"Dostal si sladkosti a %i", addmoney);
				new totalmoney = cs_get_user_money(pToucher) + addmoney;
				cs_set_user_money(pToucher, totalmoney);
			}
			case 6: {  //zabija
				SayText(pToucher, pToucher, NADPIS ,"Skazena tekvica !");
				dllfunc(DLLFunc_ClientKill, pToucher);
				make_explosion(pTouched,  g_ExplosionMdl, g_SmokeMdl)
			}
			case 7: { //deagle
				client_cmd(pToucher, "spk sound/mkbell.wav");
				give_item(pToucher,"weapon_deagle");
				give_item(pToucher,"ammo_50ae");
				give_item(pToucher,"ammo_50ae");
				give_item(pToucher,"ammo_50ae");
				give_item(pToucher,"ammo_50ae");
				give_item(pToucher,"ammo_50ae");
				give_item(pToucher,"ammo_50ae");
				give_item(pToucher,"ammo_50ae");
				SayText(pToucher, pToucher, NADPIS ,"V tekvici bol Deagle");
			}
			case 8: {  //m4
				client_cmd(pToucher, "spk sound/mkbell.wav");
				give_item(pToucher,"weapon_m4a1");
				give_item(pToucher,"ammo_556nato");
				give_item(pToucher,"ammo_556nato");
				give_item(pToucher,"ammo_556nato");
				SayText(pToucher, pToucher, NADPIS ,"V tekvici bola M4");
			}		
			case 9: {  //kalach
				client_cmd(pToucher, "spk sound/mkbell.wav");
				give_item(pToucher,"weapon_ak47");
				give_item(pToucher,"ammo_762nato");
				give_item(pToucher,"ammo_762nato");
				give_item(pToucher,"ammo_762nato");
				SayText(pToucher, pToucher, NADPIS ,"V tekvici bol kalach.");
			}
			case 10: {  //nic
				client_cmd(pToucher, "spk sound/female_cry_1.wav");
				SayText(pToucher, pToucher, NADPIS ,"Tekvica je prazdna :D");
			}	
		}	
	}
	remove_entity(pTouched);
	
	return PLUGIN_HANDLED;
}
public event_roundStart()
{
	//Check if there are spawnlocations to drop to
	if(g_totalOrigins < 0)
		return PLUGIN_CONTINUE;
		
	//Get the number of players minus HLTV or bots
	//Only spawn presents with 2 or more real players
	new currPlayers, temp[32];
	get_players(temp, currPlayers, "ch");
	
	if(currPlayers < 2)
		return PLUGIN_CONTINUE;
		
	//Remove all eggs if requested
	if(get_pcvar_num(gcvar_removePresents) == 1)
		removePresents();
		
	//Get the amount of eggs to drop
	new eggAmount = get_pcvar_num(gcvar_presentAmount);
	
	//Plant the presents ^_-
	new currentOrigin[3];
	for(new a = 0; a < g_totalOrigins; ++a)
	{
		//Pack the origin
		FVecIVec(g_spawnOrigins[a], currentOrigin);
		
		for(new b = 0; b < eggAmount; ++b)
		{
			spawnPresent(currentOrigin);
		}
	}
	
	return PLUGIN_CONTINUE;
}

public spawnPresent(packedOrigin[3])
{
	//Unpack the origin
	new Float:origin[3];
	IVecFVec(packedOrigin, origin);
	
	//Create entity and set origin and velocity
	new entity;
	entity = create_entity("info_target");
	
	entity_set_origin(entity, origin);
	
	/*new Float:velocity[3];
	velocity[0] = (random_float(0.0, 256.0) - 128.0);
	velocity[1] = (random_float(0.0, 256.0) - 128.0);
	velocity[2] = (random_float(0.0, 300.0) + 75.0);
		
	entity_set_vector(entity, EV_VEC_velocity, velocity );*/
	func_make_blast(origin);
	if(random_num(1, 4) == 2) {
		engfunc(EngFunc_EmitSound, entity, CHAN_AUTO, "survivor2.wav",1.0,ATTN_NORM,0,PITCH_NORM);
	}
	//Set a random model
	static modelName[64];
	

	formatex(modelName, 63, modely[random_num(0, sizeof modely - 1)]);


	entity_set_model(entity, modelName);
	
	//Color (75% chance)
	if(random_num(1, 4) > 2)
	{
		//Special effect (25% chance)
		if(random_num(1, 4) == 1)
			entity_set_int(entity, EV_INT_renderfx, kRenderFxHologram);
		//Farby	
	//	entity_set_vector(entity, EV_VEC_rendercolor, colors[random( sizeof colors)] );
			
		entity_set_int(entity, EV_INT_renderfx, kRenderFxGlowShell);
		entity_set_float(entity, EV_FL_renderamt, 1000.0);
		entity_set_int(entity, EV_INT_rendermode, kRenderTransAlpha);
	}
	
	//The rest of the properties
	entity_set_string(entity, EV_SZ_classname, "maximusbroodPresent");
	entity_set_int(entity, EV_INT_effects, 32);
	entity_set_int(entity, EV_INT_solid, SOLID_TRIGGER);
	entity_set_int(entity, EV_INT_movetype, MOVETYPE_TOSS);
	
	return PLUGIN_CONTINUE;
}
removePresents()
{
	new currentEntity;

	while ( (currentEntity = find_ent_by_class(currentEntity, "maximusbroodPresent")) != 0)
	{
		remove_entity(currentEntity);
	}
}

stock formatPrecache_model(name[], ...)
{
	static buffer[256];
	
	vformat(buffer, 255, name, 2);
	
	precache_model(buffer);
}
public func_get_rgb(Float:rgb[3])
{
	static color[12], parts[3][4];
	get_pcvar_string(pcvar_blast_color,color,11);
	
	parse(color,parts[0],3,parts[1],3,parts[2],3);
	rgb[0] = floatstr(parts[0]);
	rgb[1] = floatstr(parts[1]);
	rgb[2] = floatstr(parts[2]);
}
public func_make_blast(Float:fOrigin[3])
{
	if(!get_pcvar_num(pcvar_blast))
		return;
	
	//Create origin variable
	new origin[3];
	
	//Make float origins from integer origins
	FVecIVec(fOrigin,origin);
	
	//Get blast color
	new Float:rgbF[3], rgb[3];
	func_get_rgb(rgbF);
	FVecIVec(rgbF,rgb);
	
	//Finally create blast
	
	//smallest ring
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY);
	write_byte(TE_BEAMCYLINDER);
	write_coord(origin[0]);
	write_coord(origin[1]);
	write_coord(origin[2]);
	write_coord(origin[0]);
	write_coord(origin[1]);
	write_coord(origin[2] + 385);
	write_short(g_explo);
	write_byte(0);
	write_byte(0);
	write_byte(4);
	write_byte(60);
	write_byte(0);
	write_byte(rgb[0]);
	write_byte(rgb[1]);
	write_byte(rgb[2]);
	write_byte(100);
	write_byte(0);
	message_end();
	
	// medium ring
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY);
	write_byte(TE_BEAMCYLINDER);
	write_coord(origin[0]);
	write_coord(origin[1]);
	write_coord(origin[2]);
	write_coord(origin[0]);
	write_coord(origin[1]);
	write_coord(origin[2] + 470);
	write_short(g_explo);
	write_byte(0);
	write_byte(0);
	write_byte(4);
	write_byte(60);
	write_byte(0);
	write_byte(rgb[0]);
	write_byte(rgb[1]);
	write_byte(rgb[2]);
	write_byte(100);
	write_byte(0);
	message_end();

	// largest ring
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY);
	write_byte(TE_BEAMCYLINDER);
	write_coord(origin[0]);
	write_coord(origin[1]);
	write_coord(origin[2]);
	write_coord(origin[0]);
	write_coord(origin[1]);
	write_coord(origin[2] + 555);
	write_short(g_explo);
	write_byte(0);
	write_byte(0);
	write_byte(4);
	write_byte(60);
	write_byte(0);
	write_byte(rgb[0]);
	write_byte(rgb[1]);
	write_byte(rgb[2]);
	write_byte(100);
	write_byte(0);
	message_end();
	
	//Create nice light effect
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY);
	write_byte(TE_DLIGHT);
	write_coord(origin[0]);
	write_coord(origin[1]);
	write_coord(origin[2]);
	write_byte(floatround(240.0/5.0));
	write_byte(rgb[0]);
	write_byte(rgb[1]);
	write_byte(rgb[2]);
	write_byte(8);
	write_byte(60);
	message_end();
}

new msgSayText = -1;
stock bool:SayText(const receiver, sender, const msg[], any:...)
{
	if(msgSayText == -1)
		msgSayText = get_user_msgid("SayText");
		
	if(msgSayText)
	{	
		if(!sender)
			sender = receiver;
		
		static buffer[512];
		vformat(buffer,charsmax(buffer),msg,4);
		
		if(receiver)
			message_begin(MSG_ONE_UNRELIABLE,msgSayText,_,receiver);
		else
			message_begin(MSG_BROADCAST,msgSayText);
		
		write_byte(sender);
		write_string(buffer);
		message_end();
		
		return true;
	}
	
	return false;
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