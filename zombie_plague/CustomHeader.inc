// Vsade kde je /*ZP*/ je nas uprava alebo /***/

// Vlastne zadefinovane
new const svab_meno[] = "Svab" 

new Array:model_witch, Array:model_mom, Array:model_deratizer, 
	model_vknife_witch[64], model_vknife_mom[64], 
	model_vm249_deratizer[64], Array:witch_pain, Array:mom_pain,
	Array:sound_witch, Array:sound_deratizer, Array:sound_mob

new msgtext, gCvarShowNames, g_cached_gCvarShowNames;
new g_witch[33], g_mom[33], g_deratizer[33], g_stara_trieda[33]
new g_witchround, g_momround, g_deratizervround, g_mobround, g_marryround

new Array:g_modelindex_deratizer, Array:g_modelindex_witch, Array:g_modelindex_mom

new cvar_witch, cvar_witchchance, cvar_witchminplayer, cvar_witchhp, cvar_witchglow, cvar_witchgravity,
cvar_witchpainfree, cvar_witchspd,cvar_witchignoreammo, cvar_witchignorefrags, cvar_witchaura, 
cvar_witchdamage, cvar_witchnvgcolor[3]

new cvar_marry, cvar_marrychance, cvar_marryminplayers;
new cvar_mom, cvar_momchance, cvar_momminplayers, cvar_momhp, cvar_momglow, cvar_momgravity,
	cvar_mompainfree, cvar_momspd,cvar_momignoreammo, cvar_momignorefrags, cvar_momaura, 
	cvar_momdamage, cvar_momminplayer, cvar_momnvgcolor[3]

new cvar_deratizerv, cvar_deratizervpainfree, cvar_deratizervchance, cvar_deratizervhp, cvar_deratizervspd,
	cvar_deratizervgravity, cvar_deratizervignorefrags, cvar_deratizervminplayers,
	cvar_deratizervignoreammo, cvar_deratizervaura, cvar_deratizervglow
	
new	cvar_mob, cvar_mobchance, cvar_mobminplayers, cvar_mobratio
new Float:g_cached_witchspd, Float:g_cached_momspd, 
	Float:g_cached_deratizervspd, g_cached_cvar_hudicons
