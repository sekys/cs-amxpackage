#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fun>
#include <cstrike>
#include <fakemeta>

#define SPAWNOV 64
#define DATABASE_HOST ""
#define DATABASE_USERNAME ""
#define DATABASE_PASSWORD ""
#define DATABASE_DATABASE "phpbanlist"

#if defined USING_DATABASE
	#include <sqlx>
#endif

//======================================================================================================================

new const sound_respawn[][] = { "gecom/respawn.wav", "gecom/respawn2.wav" };
new const sound_pick[][] = { "gecom/pick.wav" };
new const modely[][] = { "models/gecom/vajicka1.mdl",
								"models/gecom/vajicka2.mdl",
								"models/gecom/vajicka3.mdl",
								"models/gecom/vajicka4.mdl",
								"models/gecom/vajicka5.mdl"
								//"models/gecom/sliepocka7.mdl"
							};
new const sound_win[] =  "gecom/Bunny.wav";
stock const NADPIS[] = "^x04[VN]^x01 %s";

new gcvar_removePresents, g_explo, gcvar_presentAmount, g_orginFilePath[256],
	pcvar_blast, pcvar_blast_color , Float:g_spawnOrigins[SPAWNOV][3] , g_totalOrigins,
	pcvar_zbrane;

#if defined USING_DATABASE
	new Handle:g_loginData;
	new Handle:g_connection;
#endif

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

	register_plugin("Vianoce salalla", "1.5", "Seky");
	register_dictionary("presentsspawner.txt");

	register_clcmd("darcek_spawn_add", "darcek_spawn_add", ADMIN_RCON, "-");
	register_clcmd("darcek_spawn", "darcek_spawn", ADMIN_RCON, "-");
	register_clcmd("darcek_remove", "darcek_remove", ADMIN_RCON, "-");

	gcvar_removePresents = register_cvar("darcek_remove_cvar", "1");
	gcvar_presentAmount = register_cvar("darcek_pocet", "3");
	pcvar_blast = register_cvar("darcek_efekt", "0");
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
	
#if defined USING_DATABASE
	register_clcmd("say", "cmd_say");
	SQL_SetAffinity("mysql");

	g_loginData = SQL_MakeDbTuple(DATABASE_HOST, DATABASE_USERNAME, DATABASE_PASSWORD, DATABASE_DATABASE);
	
	database_connect();
#endif
}
public plugin_precache()
{
	new i;

	for(i = 0; i < sizeof modely; i++)
		engfunc(EngFunc_PrecacheModel, modely[i]);

	for (i = 0; i < sizeof sound_respawn; i++)
		engfunc(EngFunc_PrecacheSound, sound_respawn[i]);
		
	for (i = 0; i < sizeof sound_pick; i++)
		engfunc(EngFunc_PrecacheSound, sound_pick[i]);
		
	precache_sound("gecom/gecom/woohoo.wav");
	precache_sound("gecom/gecom/homerhehehe.wav");	
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
		
	// http://www.eastereggrun.co.uk/
	//#if defined XMAS
	new vip = random_num(1, 1111);
	if(vip == 100) {
		emit_sound(pToucher, CHAN_STATIC, sound_win, 1.0, ATTN_NORM, 0, PITCH_NORM);
		new meno[33];
		get_user_name(pToucher, meno, 32);
		SayText(0, pToucher, NADPIS ,"%s nasiel Kinder vajicko ,ziskal VIP !",meno);
		
		//pridame do VIP
		log_amx("[Velka Noc] VIP %s",meno)
		
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
				client_cmd(pToucher, "spk gecom/homerhehehe.wav");
				SayText(pToucher, pToucher, NADPIS ,"Vajicko je prazdne :D");
			}
			case 2: { //vesta
				client_cmd(pToucher, "spk gecom/woohoo.wav");
				give_item(pToucher,"item_kevlar");
				give_item(pToucher,"item_assaultsuit");
				SayText(pToucher, pToucher, NADPIS ,"Vo vajicku bola vesta.");
			}

			case 3: { //naboje
				client_cmd(pToucher, "spk gecom/woohoo.wav");
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
				SayText(pToucher, pToucher, NADPIS ,"Vo vajicku boli naboje");
			}
			case 4: {  //zivot
				client_cmd(pToucher, "spk gecom/woohoo.wav");
				new health = 50;
				new totalhealth = get_user_health (pToucher) + health;
				set_user_health(pToucher, totalhealth);
				SayText(pToucher, pToucher, NADPIS ,"Cokoladove vajicko + 50HP");
			}		
			case 5: {  //peniaze
				client_cmd(pToucher, "spk gecom/woohoo.wav");
				new addmoney = random_num(100, 3000);
				SayText(pToucher, pToucher, NADPIS ,"Namiesto vajicka si dostal $%d .", addmoney);
				new totalmoney = cs_get_user_money(pToucher) + addmoney;
				cs_set_user_money(pToucher, totalmoney);
			}
			case 6: {  //granaty
				client_cmd(pToucher, "spk gecom/woohoo.wav");
				give_item(pToucher,"weapon_hegrenade");
				give_item(pToucher,"weapon_hegrenade");
				give_item(pToucher,"weapon_flashbang");
				give_item(pToucher,"weapon_flashbang");
				give_item(pToucher,"weapon_smokegrenade");
				SayText(pToucher, pToucher, NADPIS ,"Sliepka ti zniesla granaty.");
			}
			case 7: { //deagle
				client_cmd(pToucher, "spk gecom/woohoo.wav");
				give_item(pToucher,"weapon_deagle");
				give_item(pToucher,"ammo_50ae");
				give_item(pToucher,"ammo_50ae");
				give_item(pToucher,"ammo_50ae");
				give_item(pToucher,"ammo_50ae");
				give_item(pToucher,"ammo_50ae");
				give_item(pToucher,"ammo_50ae");
				give_item(pToucher,"ammo_50ae");
				SayText(pToucher, pToucher, NADPIS ,"Vo vajicku bol Deagle");
			}
			case 8: {  //m4
				client_cmd(pToucher, "spk gecom/woohoo.wav");
				give_item(pToucher,"weapon_m4a1");
				give_item(pToucher,"ammo_556nato");
				give_item(pToucher,"ammo_556nato");
				give_item(pToucher,"ammo_556nato");
				SayText(pToucher, pToucher, NADPIS ,"Vo vajicku bola M4");
			}		
			case 9: {  //kalach
				client_cmd(pToucher, "spk gecom/woohoo.wav");
				give_item(pToucher,"weapon_ak47");
				give_item(pToucher,"ammo_762nato");
				give_item(pToucher,"ammo_762nato");
				give_item(pToucher,"ammo_762nato");
				SayText(pToucher, pToucher, NADPIS ,"Vo vajicku bol kalach.");
			}
			case 10: {  //nic
				SayText(pToucher, pToucher, NADPIS ,"Vajicko je prazdne :D");
				client_cmd(pToucher, "spk gecom/homerhehehe.wav");

			}	
		}	
	}
		
	#if defined USING_DATABASE	
		database_updateRecord(pToucher, randomMoney);
	#endif

	remove_entity(pTouched);
	
	return PLUGIN_HANDLED;
}
//======================================================================================================================
#if defined USING_DATABASE
public cmd_say(id)
{
	if(id < 1)
		return PLUGIN_CONTINUE;
	
	new chatMessage[191];
	read_args(chatMessage, 190);
	remove_quotes(chatMessage);
	

	if(equali(chatMessage, "/vnrank"))
	{
		database_showRank(id);
	} else if(equali(chatMessage, "/vntop") || equali(chatMessage, "/vntop10") || equali(chatMessage, "/vntop10"))
	{
		show_motd(id, "http://gotjuice.nl/stats/presentStats.php", "Velka Noc Top 10");
	} /*else if(equali(chatMessage, "/easterinfo"))
	{
		show_motd(id, "http://gotjuice.nl/stats/easterInfo.html", "Easter Contest Info");
	}  else if(equali(chatMessage, "/easternextrank"))
	{
		database_showNextRank(id);
	}*/



	return PLUGIN_CONTINUE;
}

public plugin_end()
{
	if(g_connection && g_connection != Empty_Handle)
		SQL_FreeHandle(g_connection);
}

stock database_connect()
{
	new errorCode, strError[128];
	
	//Make the actual connection
	g_connection = SQL_Connect(g_loginData, errorCode, strError, 127);
	
	//Check for errors
	if(g_connection == Empty_Handle)
	{
		//Log the error to file
		log_amx("Error while connecting to MySQL host %s with user %s", DATABASE_HOST, DATABASE_USERNAME);
		log_amx("Errorcode %d: %s", errorCode, strError);
	}
}

//%%% Command showRank %%%
stock database_showRank(id)
{
	static authid[32], strQuery[256];
	
	get_user_authid(id, authid, 31);
	
	formatex(strQuery, 255, "SELECT rank, presentAmount, moneyAmount FROM presentStats WHERE authid = '%s';", authid);
	
	//Send the playerid with the query
	new data[1];
	data[0] = id;
	
	SQL_ThreadQuery(g_loginData, "database_rankCallback", strQuery, data, 1);
}

public database_rankCallback(failstate, Handle:query, error[], errnum, data[], size)
{
	//new queryerror[256];
	//SQL_QueryError (query, queryerror, 255);
	//server_print("Data is -> id: %d [*] queryerror: %s", data[0], queryerror);
	
	//Check if the user is still ingame
	if(!is_user_connected(data[0]))
		return PLUGIN_HANDLED;
		
	new rank, presents, money;
	
	if(failstate)
	{
		client_print(data[0], print_chat, "The presents statistics are currently offline.");		
	} else
	{
		//Check if the query did match a row
		if(SQL_NumResults(query) != 0)
		{
			//We only need to get 3 columns, next row is impossible and undesirable
			rank   = SQL_ReadResult(query, 0);
			presents  = SQL_ReadResult(query, 1);
			money = SQL_ReadResult(query, 2);
			

			if(rank > 0)
				client_print(data[0], print_chat, "Your rank is #%d with %d presents containing %d dollars. Happy Easter!", rank, presents, money);
			else
				client_print(data[0], print_chat, "Your rank hasn't been calculated yet, but you collected %d presents containing %d dollars. Happy Easter!", presents, money);

				
		} else
		{
			client_print(data[0], print_chat, "Your rank hasn't been calculated yet or you didn't pickup any presents.");
		}
	}
	
	return PLUGIN_HANDLED;
}

//%%% Show Next Rank %%%
stock database_showNextRank(id)
{
	static authid[32], strQuery[256];
	
	get_user_authid(id, authid, 31);
	
	formatex(strQuery, 255, "SELECT rank, presentAmount FROM presentStats WHERE authid = '%s';", authid);
	
	//Send the playerid with the query
	new data[1];
	data[0] = id;
	
	SQL_ThreadQuery(g_loginData, "database_nextRankCallbackOne", strQuery, data, 1);
}

public database_nextRankCallbackOne(failstate, Handle:query, error[], errnum, data[], size)
{
	//new queryerror[256];
	//SQL_QueryError (query, queryerror, 255);
	//server_print("Data is -> id: %d [*] queryerror: %s", data[0], queryerror);
	
	//Check if the user is still ingame
	if(!is_user_connected(data[0]))
		return PLUGIN_HANDLED;
		
	new rank, presents;
	static strQuery[256];
	
	if(failstate)
	{
		client_print(data[0], print_chat, "The presents statistics are currently offline.");		
	} else
	{
		//Check if the query did match a row
		if(SQL_NumResults(query) != 0)
		{
			//We only need to get 2 columns, next row is impossible and undesirable
			rank   = SQL_ReadResult(query, 0);
			presents  = SQL_ReadResult(query, 1);
			
			//You can't be better than #1
			if(rank == 1)
			{
				client_print(data[0], print_chat, "You are #1. There isn't anyone above you!");
				return PLUGIN_HANDLED;
			}
			
			//Make a new query that checks for the next ranking person.
			formatex(strQuery, 255, "SELECT rank, presentAmount FROM presentStats WHERE presentAmount > %d ORDER BY presentAmount ASC LIMIT 1", presents);
			
			//Pack the id and amount of presents and do the query
			new newData[2];
			newData[0] = data[0];
			newData[1] = presents;
			
			SQL_ThreadQuery(g_loginData, "database_nextRankCallbackTwo", strQuery, newData, 2);
				
		} else
		{
			client_print(data[0], print_chat, "Your rank hasn't been calculated yet or you didn't pickup any presents.");
		}
	}
	
	return PLUGIN_HANDLED;
}

public database_nextRankCallbackTwo(failstate, Handle:query, error[], errnum, data[], size)
{
	//new queryerror[256];
	//SQL_QueryError (query, queryerror, 255);
	//server_print("Data is -> id: %d [*] queryerror: %s", data[0], queryerror);
	
	//Check if the user is still ingame
	if(!is_user_connected(data[0]))
		return PLUGIN_HANDLED;
		
	if(failstate)
	{
		client_print(data[0], print_chat, "The presents statistics are currently offline.");
	} else
	{
		//Check if the query did match a row
		if(SQL_NumResults(query) != 0)
		{
			//Get two columns, one row
			new aboveRank = SQL_ReadResult(query, 0);
			new abovePresents = SQL_ReadResult(query, 1);
			
			//Output the final message to the client
			client_print(data[0], print_chat, "You need %d more presents to go to #%d.", ((abovePresents - data[1]) + 1), aboveRank );
		} else
		{
			client_print(data[0], print_chat, "Your rank hasn't been calculated yet or you didn't pickup any presents.");
		}
	}
	
	return PLUGIN_HANDLED;
}

//%%% Update player record %%%
stock database_updateRecord(id, money)
{
	//Check for database connection
	if(g_connection == Empty_Handle)
		return;
	
	static authid[32], query[256], errorMessage[2], errorNum;
	
	get_user_authid(id, authid, 31);
	
	formatex(query, 255, "INSERT INTO presentStats VALUES('%s', 0, 1, %d) ON DUPLICATE KEY UPDATE presentAmount=presentAmount+1, moneyAmount=moneyAmount+%d;", authid, money, money);	
	
	//We discard the successfullness
	SQL_SimpleQuery (g_connection, query, errorMessage, 1, errorNum);
}


#endif

//======================================================================================================================

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
	engfunc(EngFunc_EmitSound,entity,CHAN_AUTO,sound_respawn[random_num(0, sizeof sound_respawn - 1)],1.0,ATTN_NORM,0,PITCH_NORM);

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
//======================================================================================================================
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