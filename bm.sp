/**
	CS:GO BlockMaker taken from AlliedMods.
	Enchanced and purified by Jakub "Sejnt" Kisielewski.
	Work still in progress.
	Enjoy!
*/

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <smlib>

#define CHAT_TAG "[BlockBuilder]"
#define PREFIX "\x03[BlockBuilder]\x04 "
#define MESS "[BlockBuilder] %s"

new currentEnt[MAXPLAYERS + 1];
new Unit_Rotation[MAXPLAYERS + 1];

enum BlockTypes {
	PLATFORM,
	BUNNYHOP,
	DAMAGE,
	HEALTH,
	ICE,
	TRAMPOLINE,
	SPEEDBOOST,
	INVINCIBLITY,
	STEALTH,
	DEATH,
	GRAVITY,
	BARRIER_CT,
	BARRIER_T,
	BOOTS_OF_SPEED,
	GLASS,
	BUNNYHOP_NSD, //no slow down
	NO_FALL_DAMAGE,
	HONEY,
	CAMOUFLAGE,
	DEAGLE,
	AWP,
	RANDOM,
	HE,
	FLASH,
	FROST,
	BUNNYHOP_DELAYED
}

new const String:BlockNames[_:BlockTypes][] = {
	"PLATFORM",
	"BUNNYHOP",
	"DAMAGE",
	"HEALTH",
	"ICE",
	"TRAMPOLINE",
	"SPEEDBOOST",
	"INVINCIBLITY",
	"STEALTH",
	"DEATH",
	"GRAVITY",
	"BARRIER_CT",
	"BARRIER_T",
	"BOOTS_OF_SPEED",
	"GLASS",
	"BUNNYHOP_NSD",
	"NO_FALL_DAMAGE",
	"HONEY",
	"CAMOUFLAGE",
	"DEAGLE",
	"AWP",
	"RANDOM",
	"HE",
	"FLASH",
	"FROST",
	"BUNNYHOP_DELAYED"
}

#define MAXPROPERTIES 3

/* Doesn't work if string length (third dim) isn't set */
new const String:g_sPropertyName[_:BlockTypes][MAXPROPERTIES][64] =
{
	{"", "", ""},
	{"Trigger delay", "Cooldown", ""},
	{"Damage dealt", "Interval", ""},
	{"Health restored", "Interval", ""},
	{"", "", ""},
	{"Force", "", ""},
	{"Force", "Speed", ""},
	{"Time", "Cooldown", ""},
	{"Time", "Cooldown", ""},
	{"", "", ""},
	{"", "", ""},
	{"", "", ""},
	{"", "", ""},
	{"Time", "Cooldown", "Speed"},
	{"", "", ""},
	{"Trigger delay", "Cooldown", ""},
	{"", "", ""},
	{"", "", ""},
	{"", "", ""},
	{"", "", ""},
	{"", "", ""},
	{"", "", ""},
	{"", "", ""},
	{"", "", ""},
	{"", "", ""},
	{"Trigger delay", "Cooldown", ""},
};

new const Float:g_fPropertyDefault[_:BlockTypes][MAXPROPERTIES] = {
	{0.0, 0.0, 0.0},
	{0.1, 1.0, 0.0},
	{5.0, 2.0, 0.0},
	{5.0, 2.0, 0.0},
	{0.0, 0.0, 0.0},
	{300.0, 0.0, 0.0},
	{300.0, 300.0, 0.0},
	{0.0, 0.0, 0.0},
	{0.0, 0.0, 0.0},
	{0.0, 0.0, 0.0},
	{0.0, 0.0, 0.0},
	{0.0, 0.0, 0.0},
	{0.0, 0.0, 0.0},
	{0.0, 0.0, 0.0},
	{0.0, 0.0, 0.0},
	{0.0, 0.0, 0.0},
	{0.0, 0.0, 0.0},
	{0.0, 0.0, 0.0},
	{0.0, 0.0, 0.0},
	{0.0, 0.0, 0.0},
	{0.0, 0.0, 0.0},
	{0.0, 0.0, 0.0},
	{0.0, 0.0, 0.0},
	{0.0, 0.0, 0.0},
	{0.0, 0.0, 0.0},
	{3.0, 1.0, 0.0}
}

new const g_bTopOnlyDefault[_:BlockTypes] =
{
	1,
	0,
	1,
	1,
	1,
	1,
	0,
	1,
	1,
	1,
	0,
	1,
	1,
	1,
	1,
	1,
	1,
	1,
	1,
	1,
	0,
	1,
	1,
	1,
	1,
	0
};

new g_bTopOnly[2048],  Float:g_fPropertyValue[2048][MAXPROPERTIES];

enum BlockConfig
{
	String:BlockName[64],
	String:ModelPathPrefix[256],
	String:ModelName[256],
	String:SoundPath[256],
	Float:EffectTime,
	Float:CooldownTime
}

enum BlockSizes {
	BLOCK_NORMAL = 0,
	BLOCK_POLE,
	BLOCK_SMALL,
	BLOCK_LARGE
}

new const String:BlockDirName[_:BlockSizes][] =  {
	"normal",
	"pole",
	"small",
	"large"
}

#define	 HEGrenadeOffset		14	// (14 * 4)
#define	 FlashbangOffset		15	// (15 * 4)
#define	 SmokegrenadeOffset		16	// (16 * 4)
#define	 IncenderyGrenadesOffset	17	// (17 * 4) Also Molotovs
#define	 DecoyGrenadeOffset		18	// (18 * 4)

new const String:INVI_SOUND_PATH[] = "*blockbuilder/invincibility.mp3"
new const String:STEALTH_SOUND_PATH[] = "*blockbuilder/stealth.mp3"
new const String:NUKE_SOUND_PATH[] = "*blockbuilder/nuke.mp3"
new const String:BOS_SOUND_PATH[] = "*blockbuilder/bootsofspeed.mp3"
new const String:CAM_SOUND_PATH[] = "*blockbuilder/camouflage.mp3"
new const String:TELE_SOUND_PATH[] = "*blockbuilder/teleport.mp3"

new bool:g_bTouchStartTriggered[MAXPLAYERS + 1];

new g_iClCurrentBlock[MAXPLAYERS + 1]; // current block client is inputting property for
new g_iClInputting[MAXPLAYERS + 1] = {-1, ...}; //client is inputting a property (number)

new g_iClBlockSize[MAXPLAYERS + 1]; // client's selected block size

new g_iDragEnt[MAXPLAYERS + 1];
new g_iLastDragEnt[MAXPLAYERS + 1];

new g_iBlockSelection[MAXPLAYERS + 1] =  { 0, ... };
new g_iBlocks[2048] =  { -1, ... };
new g_iBlocksSize[2048] =  { -1, ... };
new g_iTeleporters[2048] =  { -1, ... };
// new g_iClientBlocks[MAXPLAYERS+1] = {-1, ...};
new g_iGravity[MAXPLAYERS + 1] =  { 0, ... };
new g_iAmmo;
new g_iPrimaryAmmoType;
new g_iCurrentTele[MAXPLAYERS + 1] =  { -1, ... };
new g_iBeamSprite = 0;
new CurrentModifier[MAXPLAYERS + 1] = 0
new Float:TrampolineForce[2048] = 0.0
new Float:SpeedBoostForce_1[2048] = 0.0
new Float:SpeedBoostForce_2[2048] = 0.0
//new Float:velocity_duck = 0.0
new Block_Transparency[2048] = 0
new Float:g_fGrabOffset[MAXPLAYERS + 1];

new bool:g_bNoFallDmg[MAXPLAYERS + 1] =  { false, ... };
new bool:g_bInvCanUse[MAXPLAYERS + 1] =  { true, ... };
new bool:g_bInv[MAXPLAYERS + 1] =  { false, ... };
new bool:g_bStealthCanUse[MAXPLAYERS + 1] =  { true, ... };
new bool:g_bBootsCanUse[MAXPLAYERS + 1] =  { true, ... };
new bool:g_bLocked[MAXPLAYERS + 1] =  { false, ... };
new bool:g_bTriggered[2048] =  { false, ... };
new bool:g_bCamCanUse[MAXPLAYERS + 1] =  { true, ... };
new bool:g_bDeagleCanUse[MAXPLAYERS + 1] =  { true, ... };
new bool:g_bAwpCanUse[MAXPLAYERS + 1] =  { true, ... };
new bool:g_bHEgrenadeCanUse[MAXPLAYERS + 1] =  { true, ... };
new bool:g_bFlashbangCanUse[MAXPLAYERS + 1] =  { true, ... };
new bool:g_bSmokegrenadeCanUse[MAXPLAYERS + 1] =  { true, ... };
new bool:g_bSnapping[MAXPLAYERS + 1] =  { false, ... };
new bool:g_bGroups[MAXPLAYERS + 1][2048];
new bool:g_bRandomCantUse[MAXPLAYERS + 1];

new Handle:Block_Timers[64] = {INVALID_HANDLE, ...};
new Block_Touching[MAXPLAYERS + 1] = 0;


new Float:g_fSnappingGap[MAXPLAYERS + 1] =  { 0.0, ... };
new Float:g_fClientAngles[MAXPLAYERS + 1][3];
new Float:g_fAngles[2048][3];

// Skriv antal blocks!
new g_eBlocks[35][BlockConfig];

new Handle:g_hClientMenu[MAXPLAYERS + 1];
new Handle:g_hBlocksKV = INVALID_HANDLE;
new Handle:g_hTeleSound = INVALID_HANDLE;

new Handle:Cvar_Prefix;
new Handle:Cvar_Height;
new Handle:Cvar_RandomTime;
new Float:TrueForce
new Float:randomblock_time = 0.0;

new RoundIndex = 0; // Quite lazy way yet effective one

#include "bm/bm_propmenu"

public Plugin:myinfo =
{
	name = "Blockmaker",
	author = "x3ro + k0nan + sejtn",
	description = "Spawn Blocks",
	version = "1.046",
	url = "https://forums.alliedmods.net/showthread.php?t=270733"
}

public OnPluginStart()
{

	randomblock_time = 60.0;
	g_hTeleSound = CreateConVar("sm_blockbuilder_telesound", "blockbuilder/teleport.mp3");
	Cvar_Height = CreateConVar("sm_blockbuilder_block_height", "0.0", "Height of block (Can be -10.0 aswell as 15.0")
	HookConVarChange(Cvar_Height, OnHeightConVarChange)

	Cvar_RandomTime = CreateConVar("sm_blockbuilder_random_cooldown", "60", "A cooldown for using random block for player. Example: After you use once random block you need to wait 60 sec.")
	HookConVarChange(Cvar_RandomTime, OnRandomChanged)

	//
	//	ADMIN FLAG "O" FOR USING BLOCKMAKER
	//	ADMIN FLAG "P" FOR SAVING AND LOADING
	//

	//	RegConsoleCmd("sm_bb", Command_BlockBuilder);
	RegAdminCmd("sm_bb", Command_BlockBuilder, ADMFLAG_CUSTOM1);
	RegAdminCmd("sm_prop", Command_BlockProperty, ADMFLAG_CUSTOM1);
	//	RegConsoleCmd("sm_bsave", Command_SaveBlocks);
	RegAdminCmd("sm_bsave", Command_SaveBlocks, ADMFLAG_CUSTOM2);
	RegAdminCmd("sm_blocksnap", Command_BlockSnap, ADMFLAG_CUSTOM1);
	RegAdminCmd("sm_snapgrid", Command_SnapGrid, ADMFLAG_CUSTOM1);
	RegAdminCmd("sm_del", Command_DeleteLastGrabbed, ADMFLAG_CUSTOM1);
	RegAdminCmd("+grab", Command_GrabBlock, ADMFLAG_CUSTOM1);
	RegAdminCmd("-grab", Command_ReleaseBlock, ADMFLAG_CUSTOM1);
	RegAdminCmd("tgrab", Command_ToggleGrab, ADMFLAG_CUSTOM1);

	AddCommandListener(OnSayCmd, "say");
	AddCommandListener(OnSayCmd, "say_team");

	HookEvent("round_start", RoundStart);
	HookEvent("round_end", RoundEnd);

	AutoExecConfig();

	g_iAmmo = FindSendPropOffs("CCSPlayer", "m_iAmmo");
	g_iPrimaryAmmoType = FindSendPropOffs("CBaseCombatWeapon", "m_iPrimaryAmmoType");

	new String:file[256];
	BuildPath(Path_SM, file, sizeof(file), "configs/blockbuilder.blocks.txt");

	new Handle:kv = CreateKeyValues("Blocks");
	FileToKeyValues(kv, file);

	if (!KvGotoFirstSubKey(kv))
	{
		PrintToServer("No first subkey");
		return;
	}

	new i = 0;

	do
	{
		KvGetSectionName(kv, g_eBlocks[i][BlockName], 64);
		KvGetString(kv, "model_pathprefix", g_eBlocks[i][ModelPathPrefix], 256);
		KvGetString(kv, "model_name", g_eBlocks[i][ModelName], 256);
		KvGetString(kv, "sound", g_eBlocks[i][SoundPath], 256);
		g_eBlocks[i][EffectTime] = KvGetFloat(kv, "effect");
		g_eBlocks[i][CooldownTime] = KvGetFloat(kv, "cooldown");
		++i;
	} while (KvGotoNextKey(kv));

	CloseHandle(kv);

	g_hBlocksKV = CreateKeyValues("Blocks");
}

public Action:Command_BlockProperty(client, args)
{
	new ent = GetClientAimTarget2(client, false);

	if(!IsValidBlock(ent))
		return;

	g_iClCurrentBlock[client] = ent;
	ShowPropertyMenu(client);
}

public Action:OnSayCmd(client, const String:command[], argc)
{
	if(g_iClInputting[client] == -1)
		return Plugin_Continue;

	if(!IsValidBlock(g_iClCurrentBlock[client]))
		PrintToChat(client, "%s Couldn't input property. Block is NOT valid.", PREFIX);

	decl String:arg[8];
	GetCmdArg(1, arg, sizeof(arg));

	new block = g_iClCurrentBlock[client];
	new blocktype = g_iBlocks[block];
	new propnum = g_iClInputting[client];

	new Float:newval = StringToFloat(arg);

	g_fPropertyValue[block][propnum] = newval;

	PrintToChat(client, "%s\x03 %s\x04 of\x03 %s\x04 changed to\x03 %.2f",
	PREFIX, g_sPropertyName[blocktype][propnum], BlockNames[blocktype], newval);

	g_iClInputting[client] = -1;

	return Plugin_Handled;
}

public Action:Command_DeleteLastGrabbed(client, args)
{
	if (IsValidBlock(g_iLastDragEnt[client]))
	{
		AcceptEntityInput(g_iLastDragEnt[client], "Kill");
	}
	else {
		PrintToChat(client, "\x03%s\x04 Could NOT delete the block. It's not valid :(", CHAT_TAG);
	}
	// Fixes "Unknown Command"
	return Plugin_Handled;
}

public Action:Command_GrabBlock(client, args)
{
	if (g_iDragEnt[client] == 0)
	{
		new ent = GetClientAimTarget2(client, false);
		StartGrabbing(client, ent);
	}

	return Plugin_Handled;
}

public Action:Command_ReleaseBlock(client, args)
{
	if (g_iDragEnt[client] != 0)
	{
		new Float:fVelocity[3] =  { 0.0, 0.0, 0.0 };
		StopGrabbing(client, g_iDragEnt[client]);
		TeleportEntity(g_iDragEnt[client], NULL_VECTOR, g_fAngles[g_iDragEnt[client]], fVelocity);
	}

	return Plugin_Handled;
}

public Action:Command_ToggleGrab(client, args)
{
	new ent = GetClientAimTarget2(client, false);

	if (g_iDragEnt[client] == 0) {
		StartGrabbing(client, ent);
	}
	else {
		StopGrabbing(client, g_iDragEnt[client]);
	}
}

public OnRandomChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	randomblock_time = StringToFloat(newVal)
}

public Action:Command_BlockSnap(client, args)
{
	g_bSnapping[client] = !g_bSnapping[client];
	PrintToChat(client, "\x03%s\x04 Block Snapping %s.", CHAT_TAG, g_bSnapping[client] ? "On" : "Off");
}

public Action:Command_SnapGrid(client, args)
{
	decl String:argc[18]
	GetCmdArg(1, argc, sizeof(argc))

	g_fSnappingGap[client] = StringToFloat(argc)
}

public OnHeightConVarChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	TrueForce = StringToFloat(newVal)
}

// REMOVE BREAKABLES
public OnEntityCreated(entity, const String:classname[]) {
	if (StrEqual(classname, "func_breakable") || StrEqual(classname, "func_breakable_surf")) {
		SDKHook(entity, SDKHook_Spawn, Hook_OnEntitySpawn);
	}
}
public Action:Hook_OnEntitySpawn(entity) {
	AcceptEntityInput(entity, "Kill");
	return Plugin_Handled;
}
// END OF REMOVE BREAKABLES

public OnConfigsExecuted()
{
	new String:sound[512];
	GetConVarString(g_hTeleSound, sound, sizeof(sound));
	if (!StrEqual(sound, ""))
	{
		PrecacheSound(sound);
	}
}

public Action:RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	// STEALTH FIX ??
	for (new client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		SetEntityRenderMode(client, RENDER_NORMAL);
		SDKUnhook(client, SDKHook_SetTransmit, Stealth_SetTransmit)
	}

	for (new i = 0; i < 2048; ++i)
	{
		g_iBlocks[i] = -1;
		g_bTriggered[i] = false;
		g_iTeleporters[i] = -1;
	}
	for (new i = 1; i <= MaxClients; ++i)
	{
		g_bHEgrenadeCanUse[i] = true;
		g_bFlashbangCanUse[i] = true;
		g_bSmokegrenadeCanUse[i] = true;
		g_iCurrentTele[i] = -1;
		g_bInv[i] = false;
		g_bInvCanUse[i] = true;
		g_bStealthCanUse[i] = true;
		g_bBootsCanUse[i] = true;
		g_bLocked[i] = false;
		g_bNoFallDmg[i] = false;
		g_bCamCanUse[i] = true;
		g_bAwpCanUse[i] = true;
		g_bDeagleCanUse[i] = true;
		g_bRandomCantUse[i] = false;
	}
	RoundIndex++
	LoadBlocks();
	return Plugin_Continue;
}

public Action:RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	return Plugin_Continue;
}

public OnClientPutInServer(client)
{
	g_bInv[client] = false;
	g_bInvCanUse[client] = true;
	g_bStealthCanUse[client] = true;
	g_bBootsCanUse[client] = true;
	g_bLocked[client] = false;
	g_bNoFallDmg[client] = false;
	g_bCamCanUse[client] = true;
	g_bAwpCanUse[client] = true;
	g_bDeagleCanUse[client] = true;
	g_bHEgrenadeCanUse[client] = true;
	g_bFlashbangCanUse[client] = true;
	//	g_iClientBlocks[client]=-1;
	g_iCurrentTele[client] = -1;
	g_bSnapping[client] = true;
	g_bRandomCantUse[client] = false;
	g_fSnappingGap[client] = 0.0
	for (new i = 0; i < 2048; ++i)
	g_bGroups[client][i] = false;
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public OnMapStart()
{
	RoundIndex = 0;
	SetConVarBool(FindConVar("sv_turbophysics"), true);

	for (new i = 0; i < sizeof(g_eBlocks); ++i)
	{
		if (strcmp(g_eBlocks[i][SoundPath], "") != 0)
			PrecacheSound(g_eBlocks[i][SoundPath], true);
	}

	PrecacheModel("models/player/ctm_gign.mdl");
	PrecacheModel("models/player/tm_phoenix.mdl");

	FakePrecacheSound(INVI_SOUND_PATH);
	FakePrecacheSound(STEALTH_SOUND_PATH);
	FakePrecacheSound(NUKE_SOUND_PATH);
	FakePrecacheSound(BOS_SOUND_PATH);
	FakePrecacheSound(CAM_SOUND_PATH);
	FakePrecacheSound(TELE_SOUND_PATH);

	DownloadsTable()

	g_iBeamSprite = PrecacheModel("materials/sprites/orangelight1.vmt");

	for (new i = 0; i < 2048; ++i)
	{
		for (new a = 1; a <= MaxClients; ++a)
		{
			g_bGroups[a][i] = false;
		}
		g_iBlocks[i] = -1;
		g_iTeleporters[i] = -1;
		g_bTriggered[i] = false;
	}

	if (g_hBlocksKV != INVALID_HANDLE)
	{
		CloseHandle(g_hBlocksKV);
		g_hBlocksKV = INVALID_HANDLE;
	}

	new String:file[256];
	new String:map[64];
	//new String:id[64];
	//GetCurrentWorkshopMap(map, 65, id, 65)
	GetCurrentMap(map, sizeof(map));
	BuildPath(Path_SM, file, sizeof(file), "data/block.%s.txt", map);
	if (FileExists(file))
	{
		g_hBlocksKV = CreateKeyValues("Blocks");
		FileToKeyValues(g_hBlocksKV, file);
	}
}

Download(String:frm[128])
{
	new String:tmp[128];

	Format(tmp, sizeof(tmp), "%s.mdl", frm);
	AddFileToDownloadsTable(tmp);
	PrecacheModel(tmp);

	/*Format(tmp, sizeof(tmp), "%s.dx80.vtx", frm);
	AddFileToDownloadsTable(tmp);*/

	Format(tmp, sizeof(tmp), "%s.dx90.vtx", frm);
	AddFileToDownloadsTable(tmp);

	Format(tmp, sizeof(tmp), "%s.phy", frm);
	AddFileToDownloadsTable(tmp);

	/*Format(tmp, sizeof(tmp), "%s.sw.vtx", frm);
	AddFileToDownloadsTable(tmp);

	*/

	Format(tmp, sizeof(tmp), "%s.vvd", frm);
	AddFileToDownloadsTable(tmp);
}

TextureDownload(String:frm[128])
{
	new String:tmp[128];

	Format(tmp, sizeof(tmp), "%s.vtf", frm);
	AddFileToDownloadsTable(tmp);

	Format(tmp, sizeof(tmp), "%s.vmt", frm);
	AddFileToDownloadsTable(tmp);
}

TextureDownloadPlusSide(String:frm[128])
{
	new String:tmp[128];

	Format(tmp, sizeof(tmp), "%s.vtf", frm);
	AddFileToDownloadsTable(tmp);

	Format(tmp, sizeof(tmp), "%s_side.vtf", frm);
	AddFileToDownloadsTable(tmp);

	Format(tmp, sizeof(tmp), "%s.vmt", frm);
	AddFileToDownloadsTable(tmp);

	Format(tmp, sizeof(tmp), "%s_side.vmt", frm);
	AddFileToDownloadsTable(tmp);

}

DownloadsTable()
{
	Download("models/platforms/r-tele");
	Download("models/platforms/b-tele");
	Download("models/test11_normal/platform")
	Download("models/test11_large/platform")
	Download("models/test11_small/platform")
	Download("models/test11_pole/platform")


	Download("models/test11_normal/bunnyhop")
	Download("models/test11_large/bunnyhop")
	Download("models/test11_small/bunnyhop")
	Download("models/test11_pole/bunnyhop")

	Download("models/test11_normal/damage")
	Download("models/test11_large/damage")
	Download("models/test11_small/damage")
	Download("models/test11_pole/damage")

	Download("models/test11_normal/ice")
	Download("models/test11_large/ice")
	Download("models/test11_small/ice")
	Download("models/test11_pole/ice")

	Download("models/test11_normal/honey")
	Download("models/test11_large/honey")
	Download("models/test11_small/honey")
	Download("models/test11_pole/honey")


	Download("models/test11_normal/trampoline")
	Download("models/test11_large/trampoline")
	Download("models/test11_small/trampoline")
	Download("models/test11_pole/trampoline")


	Download("models/test11_normal/heal")
	Download("models/test11_large/heal")
	Download("models/test11_small/heal")
	Download("models/test11_pole/heal")

	Download("models/test11_normal/speedboost")
	Download("models/test11_large/speedboost")
	Download("models/test11_small/speedboost")
	Download("models/test11_pole/speedboost")

	Download("models/test11_normal/death")
	Download("models/test11_large/death")
	Download("models/test11_small/death")
	Download("models/test11_pole/death")

	TextureDownloadPlusSide("materials/omnihns_normal/platform")
	TextureDownload("materials/omnihns_large/platform")
	TextureDownload("materials/omnihns_small/platform")
	TextureDownload("materials/omnihns_pole/platform")


	TextureDownloadPlusSide("materials/omnihns_normal/bunnyhop")
	TextureDownload("materials/omnihns_large/bunnyhop")
	TextureDownload("materials/omnihns_small/bunnyhop")
	TextureDownload("materials/omnihns_pole/bunnyhop")

	TextureDownloadPlusSide("materials/omnihns_normal/damage")
	TextureDownload("materials/omnihns_large/damage")
	TextureDownload("materials/omnihns_small/damage")
	TextureDownload("materials/omnihns_pole/damage")

	TextureDownloadPlusSide("materials/omnihns_normal/ice")
	TextureDownload("materials/omnihns_large/ice")
	TextureDownload("materials/omnihns_small/ice")
	TextureDownload("materials/omnihns_pole/ice")

	TextureDownloadPlusSide("materials/omnihns_normal/honey")
	TextureDownload("materials/omnihns_large/honey")
	TextureDownload("materials/omnihns_small/honey")
	TextureDownload("materials/omnihns_pole/honey")


	TextureDownloadPlusSide("materials/omnihns_normal/trampoline")
	TextureDownload("materials/omnihns_large/trampoline")
	TextureDownload("materials/omnihns_small/trampoline")
	TextureDownload("materials/omnihns_pole/trampoline")


	TextureDownloadPlusSide("materials/omnihns_normal/heal")
	TextureDownload("materials/omnihns_large/heal")
	TextureDownload("materials/omnihns_small/heal")
	TextureDownload("materials/omnihns_pole/heal")

	TextureDownloadPlusSide("materials/omnihns_normal/speedboost")
	TextureDownload("materials/omnihns_large/speedboost")
	TextureDownload("materials/omnihns_small/speedboost")
	TextureDownload("materials/omnihns_pole/speedboost")

	TextureDownloadPlusSide("materials/omnihns_normal/death")
	TextureDownload("materials/omnihns_large/death")
	TextureDownload("materials/omnihns_small/death")
	TextureDownload("materials/omnihns_pole/death")

	TextureDownloadPlusSide("materials/omnihns_normal/delayedbunnyhop")
	TextureDownload("materials/omnihns_large/delayedbunnyhop")
	TextureDownload("materials/omnihns_small/delayedbunnyhop")
	TextureDownload("materials/omnihns_pole/delayedbunnyhop")

	/*Download("models/blockbuilder/awp")
	Download("models/blockbuilder/bhop")
	Download("models/blockbuilder/camouflage")
	Download("models/blockbuilder/ctbarrier")
	Download("models/blockbuilder/damage")
	Download("models/blockbuilder/deagle")
	Download("models/blockbuilder/death")
	Download("models/blockbuilder/delay")
	Download("models/blockbuilder/fire")
	Download("models/blockbuilder/flash")
	Download("models/blockbuilder/frost")
	Download("models/blockbuilder/glass")
	Download("models/blockbuilder/gravity")
	Download("models/blockbuilder/he")
	Download("models/blockbuilder/health")
	Download("models/blockbuilder/honey")
	Download("models/blockbuilder/ice")
	Download("models/blockbuilder/invincibility")
	Download("models/blockbuilder/nofalldmg")
	Download("models/blockbuilder/noslowdown")
	Download("models/blockbuilder/nuke")

	Download("models/blockbuilder/random")
	Download("models/blockbuilder/slap")
	Download("models/blockbuilder/speed")
	Download("models/blockbuilder/speedboost")
	Download("models/blockbuilder/stealth")
	Download("models/blockbuilder/tbarrier")
	Download("models/blockbuilder/tramp")

	// LARGE BLOCKS

	Download("models/blockbuilder/large_awp")
	Download("models/blockbuilder/large_bhop")
	Download("models/blockbuilder/large_camouflage")
	Download("models/blockbuilder/large_ctbarrier")
	Download("models/blockbuilder/large_damage")
	Download("models/blockbuilder/large_deagle")
	Download("models/blockbuilder/large_death")
	Download("models/blockbuilder/large_delay")
	Download("models/blockbuilder/large_fire")
	Download("models/blockbuilder/large_flash")
	Download("models/blockbuilder/large_frost")
	Download("models/blockbuilder/large_glass")
	Download("models/blockbuilder/large_gravity")
	Download("models/blockbuilder/large_he")
	Download("models/blockbuilder/large_health")
	Download("models/blockbuilder/large_honey")
	Download("models/blockbuilder/large_ice")
	Download("models/blockbuilder/large_invincibility")
	Download("models/blockbuilder/large_nofalldmg")
	Download("models/blockbuilder/large_noslowdown")
	Download("models/blockbuilder/large_nuke")

	Download("models/blockbuilder/large_random")
	Download("models/blockbuilder/large_slap")
	Download("models/blockbuilder/large_speed")
	Download("models/blockbuilder/large_speedboost")
	Download("models/blockbuilder/large_stealth")
	Download("models/blockbuilder/large_tbarrier")
	Download("models/blockbuilder/large_tramp")

	// small BLOCKS

	Download("models/blockbuilder/small_awp")
	Download("models/blockbuilder/small_bhop")
	Download("models/blockbuilder/small_camouflage")
	Download("models/blockbuilder/small_ctbarrier")
	Download("models/blockbuilder/small_damage")
	Download("models/blockbuilder/small_deagle")
	Download("models/blockbuilder/small_death")
	Download("models/blockbuilder/small_delay")
	Download("models/blockbuilder/small_fire")
	Download("models/blockbuilder/small_flash")
	Download("models/blockbuilder/small_frost")
	Download("models/blockbuilder/small_glass")
	Download("models/blockbuilder/small_gravity")
	Download("models/blockbuilder/small_he")
	Download("models/blockbuilder/small_health")
	Download("models/blockbuilder/small_honey")
	Download("models/blockbuilder/small_ice")
	Download("models/blockbuilder/small_invincibility")
	Download("models/blockbuilder/small_nofalldmg")
	Download("models/blockbuilder/small_noslowdown")
	Download("models/blockbuilder/small_nuke")

	Download("models/blockbuilder/small_random")
	Download("models/blockbuilder/small_slap")
	Download("models/blockbuilder/small_speed")
	Download("models/blockbuilder/small_speedboost")
	Download("models/blockbuilder/small_stealth")
	Download("models/blockbuilder/small_tbarrier")
	Download("models/blockbuilder/small_tramp")

	// pole BLOCKS

	Download("models/blockbuilder/pole_awp")
	Download("models/blockbuilder/pole_bhop")
	Download("models/blockbuilder/pole_camouflage")
	Download("models/blockbuilder/pole_ctbarrier")
	Download("models/blockbuilder/pole_damage")
	Download("models/blockbuilder/pole_deagle")
	Download("models/blockbuilder/pole_death")
	Download("models/blockbuilder/pole_delay")
	Download("models/blockbuilder/pole_fire")
	Download("models/blockbuilder/pole_flash")
	Download("models/blockbuilder/pole_frost")
	Download("models/blockbuilder/pole_glass")
	Download("models/blockbuilder/pole_gravity")
	Download("models/blockbuilder/pole_he")
	Download("models/blockbuilder/pole_health")
	Download("models/blockbuilder/pole_honey")
	Download("models/blockbuilder/pole_ice")
	Download("models/blockbuilder/pole_invincibility")
	Download("models/blockbuilder/pole_nofalldmg")
	Download("models/blockbuilder/pole_noslowdown")
	Download("models/blockbuilder/pole_nuke")

	Download("models/blockbuilder/pole_random")
	Download("models/blockbuilder/pole_slap")
	Download("models/blockbuilder/pole_speed")
	Download("models/blockbuilder/pole_speedboost")
	Download("models/blockbuilder/pole_stealth")
	Download("models/blockbuilder/pole_tbarrier")
	Download("models/blockbuilder/pole_tramp")*/


	// materials for normal ones

	/*TextureDownload("materials/models/blockbuilder/awp.vtf")
	TextureDownload("materials/models/blockbuilder/awp_side.vmt")

	TextureDownload("materials/models/blockbuilder/bhop.vmt")
	TextureDownload("materials/models/blockbuilder/bhop_side.vmt")

	TextureDownload("materials/models/platforms/glow2")
	TextureDownload("materials/models/platforms/blue_glow1.vmt")

	TextureDownload("materials/models/blockbuilder/camouflage.vtf")
	TextureDownload("materials/models/blockbuilder/camouflage_side.vmt")

	TextureDownload("materials/models/blockbuilder/ctbarrier.vmt")
	TextureDownload("materials/models/blockbuilder/ctbarrier_side.vmt")

	TextureDownload("materials/models/blockbuilder/damage.vtf")
	TextureDownload("materials/models/blockbuilder/damage_side.vtf")

	TextureDownload("materials/models/blockbuilder/deagle.vtf")
	TextureDownload("materials/models/blockbuilder/deagle_side.vmt")

	TextureDownload("materials/models/blockbuilder/death.vmt")
	AddFileToDownloadsTable("materials/models/blockbuilder/death_n.vtf")

	TextureDownload("materials/models/blockbuilder/delay.vmt")
	TextureDownload("materials/models/blockbuilder/delay_side.vmt")

	TextureDownload("materials/models/blockbuilder/fire.vmt")
	TextureDownload("materials/models/blockbuilder/fire_side.vmt")

	TextureDownload("materials/models/blockbuilder/flash.vtf")

	TextureDownload("materials/models/blockbuilder/frost.vmt")
	TextureDownload("materials/models/blockbuilder/frost_side.vtf")

	TextureDownload("materials/models/blockbuilder/glass.vmt")

	TextureDownload("materials/models/blockbuilder/gravity.vmt")
	TextureDownload("materials/models/blockbuilder/gravity_side.vmt")

	TextureDownload("materials/models/blockbuilder/he.vmt")
	TextureDownload("materials/models/blockbuilder/he_side.vtf")

	TextureDownload("materials/models/blockbuilder/health.vmt")

	AddFileToDownloadsTable("materials/models/blockbuilder/health.vtf")
	AddFileToDownloadsTable("materials/models/blockbuilder/health_n.vtf")

	TextureDownload("materials/models/blockbuilder/honey.vmt")
	TextureDownload("materials/models/blockbuilder/honey_side.vtf")
	AddFileToDownloadsTable("materials/models/blockbuilder/ice_n.vtf")

	TextureDownload("materials/models/blockbuilder/invincibility.vmt")
	TextureDownload("materials/models/blockbuilder/invincibility_side.vmt")

	TextureDownload("materials/models/blockbuilder/nofalldmg.vmt")
	TextureDownload("materials/models/blockbuilder/nofalldmg_side.vtf")

	TextureDownload("materials/models/blockbuilder/noslowdown.vmt")
	TextureDownload("materials/models/blockbuilder/noslowdown_side.vmt")
	TextureDownload("materials/models/blockbuilder/nuke.vtf")*/


	/*TextureDownload("materials/models/blockbuilder/random.vtf")
	TextureDownload("materials/models/blockbuilder/random_side.vtf")

	TextureDownload("materials/models/platforms/red_glow1.vtf")

	TextureDownload("materials/models/blockbuilder/slap.vtf")

	TextureDownload("materials/models/blockbuilder/speed.vmt")

	AddFileToDownloadsTable("materials/models/blockbuilder/speed_n.vtf")

	TextureDownload("materials/models/blockbuilder/speedboost.vmt")
	TextureDownload("materials/models/platforms/sphere.vmt")

	TextureDownload("materials/models/blockbuilder/stealth.vmt")
	TextureDownload("materials/models/blockbuilder/stealth_side.vmt")

	TextureDownload("materials/models/platforms/tape.vmt")

	TextureDownload("materials/models/blockbuilder/tbarrier.vmt")
	TextureDownload("materials/models/blockbuilder/tbarrier_side.vmt")

	TextureDownload("materials/models/blockbuilder/tramp.vmt")
	AddFileToDownloadsTable("materials/models/blockbuilder/tramp_n.vtf")

	TextureDownload("materials/models/blockbuilder/ice_top.vmt")*/
}

public Action:Command_SaveBlocks(client, args)
{

	if (client)
	{
		//		if(!(GetUserFlagBits(client) & ADMFLAG_CUSTOM1 || GetUserFlagBits(client) & ADMFLAG_ROOT))
		//		{
		//			PrintToChat(client, "\x03%s\x04 You don't have permission to access this.", CHAT_TAG);
		//			return Plugin_Handled;
		//		}
	}
	else {
		new iPlayers = 0;
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsValidClient(i))
			{
				iPlayers++;
			}
		}
		if (!iPlayers)
		{
			PrintToServer("You can only save when at least one client is in-game");
			return Plugin_Handled;
		}
	}


	SaveBlocks();
	return Plugin_Handled;
}

SaveBlocks(bool:msg = false)
{
	if (g_hBlocksKV != INVALID_HANDLE)
		CloseHandle(g_hBlocksKV);

	g_hBlocksKV = CreateKeyValues("Blocks");
	KvGotoFirstSubKey(g_hBlocksKV);

	new index = 1, blocks = 0, teleporters = 0;
	new String:tmp[11];
	new Float:fPos[3], Float:fAng[3];

	for (new i = MaxClients + 1; i <= 2048; ++i)
	{
		if (!IsValidBlock(i) || g_iTeleporters[i] == 1) // TPs without exit
			continue;

		GetEntPropVector(i, Prop_Data, "m_vecOrigin", fPos);


		IntToString(index, tmp, sizeof(tmp));
		KvJumpToKey(g_hBlocksKV, tmp, true);
		if (g_iTeleporters[i] > 1 && IsValidBlock(g_iTeleporters[i]))
		{
			GetEntPropVector(g_iTeleporters[i], Prop_Data, "m_vecOrigin", fAng);
			KvSetNum(g_hBlocksKV, "teleporter", 1);
			KvSetVector(g_hBlocksKV, "entrance", fPos);
			KvSetVector(g_hBlocksKV, "exit", fAng);
			teleporters++;
		}
		else
		{
			GetEntPropVector(i, Prop_Data, "m_angRotation", fAng);
			KvSetNum(g_hBlocksKV, "blocktype", g_iBlocks[i]);
			KvSetNum(g_hBlocksKV, "blocksize", g_iBlocksSize[i]);
			KvSetVector(g_hBlocksKV, "position", fPos);
			KvSetVector(g_hBlocksKV, "angles", fAng);
			KvSetNum(g_hBlocksKV, "toponly", g_bTopOnly[i])

			if (Block_Transparency[i] > 0)
				KvSetNum(g_hBlocksKV, "transparency", Block_Transparency[i])

			decl String:propnum[12];
			for(new j = 0; j < MAXPROPERTIES; i++) {
				Format(propnum, sizeof(propnum), "property%i", j);
				KvSetFloat(g_hBlocksKV, propnum, g_fPropertyValue[i][j]);
			}

			blocks++;
		}
		KvGoBack(g_hBlocksKV);
		index++;
	}
	KvRewind(g_hBlocksKV);
	new String:file[256];
	new String:map[64];
	//new String:id[64];

	//GetCurrentWorkshopMap(map, 65, id, 65)
	GetCurrentMap(map, sizeof(map));
	BuildPath(Path_SM, file, sizeof(file), "data/block.%s.txt", map);
	KeyValuesToFile(g_hBlocksKV, file);

	if (msg)
		PrintToChatAll("\x03%s\x04 %d blocks and %d pair of teleporters were saved.", CHAT_TAG, blocks, teleporters);
	PrintToServer("%d blocks and %d teleports saved", blocks, teleporters);
}

LoadBlocks(bool:msg = false)
{
	if (g_hBlocksKV == INVALID_HANDLE)
		return;

	new teleporters = 0, blocks = 0;
	new Float:fPos[3], Float:fAng[3];

	KvRewind(g_hBlocksKV);
	KvGotoFirstSubKey(g_hBlocksKV);

	do
	{
		if (KvGetNum(g_hBlocksKV, "teleporter") == 1)
		{
			KvGetVector(g_hBlocksKV, "entrance", fPos);
			KvGetVector(g_hBlocksKV, "exit", fAng);
			g_iTeleporters[CreateTeleportEntrance(0, fPos)] = CreateTeleportExit(0, fAng);
			teleporters++;
		}
		else
		{
			KvGetVector(g_hBlocksKV, "position", fPos);
			KvGetVector(g_hBlocksKV, "angles", fAng);
			new transparency = KvGetNum(g_hBlocksKV, "transparency", 0);
			new blocktype = KvGetNum(g_hBlocksKV, "blocktype");
			new blocksize = KvGetNum(g_hBlocksKV, "blocksize");

			new b = CreateBlock(0, blocktype, blocksize, fPos, fAng, 0.0, 0.0, transparency);
			blocks++;
			/* The toponly property key doesn't exist.
			 	CreateBlock loads default properties and
				we don't want to overwrite them with 0 */
			if(KvGetDataType(g_hBlocksKV, "toponly") == KvData_None) {
				continue;
			}

			g_bTopOnly[b] = KvGetNum(g_hBlocksKV, "toponly");

			decl String:propnum[12];
			for(new i = 0; i < MAXPROPERTIES; i++) {
				Format(propnum, sizeof(propnum), "property%i", i);
				g_fPropertyValue[b][i] = KvGetFloat(g_hBlocksKV, propnum);
			}
		}
	} while (KvGotoNextKey(g_hBlocksKV));

	if (msg)
		PrintToChatAll("\x03%s\x04 %d blocks and %d pair of teleporters were loaded.", CHAT_TAG, blocks, teleporters);
}

//public Action:ResetPerform(Handle:timer, any:client)
//{
//	if(!DuckHop[client])
//		DuckHop_Perform[client] = false
//}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	new Float:fPos[3];
	new Float:fPos2[3];
	GetClientAbsOrigin(client, fPos);
	fPos[2] += 50.0;

	//new block_ent = GetClientAimTarget(client, false);

	for (new a = MaxClients + 1; a < 2048; ++a)
	{
		if (GetClientTeam(client) < 2)
			continue;

		if (g_iBlocks[a] == 10)
		{
			GetEntPropVector(a, Prop_Data, "m_vecOrigin", fPos2);
			if (fPos[0] - 20.0 < fPos2[0] < fPos[0] + 20.0 && fPos[1] - 20.0 < fPos2[1] < fPos[1] + 20.0 && fPos[2] - 60.0 < fPos2[2] < fPos[2] + 60.0)
			{
				new iTeam = GetClientTeam(client);
				if (iTeam == 2)
					PrintToChatAll("\x03%s\x04 %N has nuked the Counter-Terrorist team.", CHAT_TAG, client);
				else if (iTeam == 3)
					PrintToChatAll("\x03%s\x04 %N has nuked the Terrorist team.", CHAT_TAG, client);

				g_iBlocks[a] = 0;

				EmitSoundToAll(NUKE_SOUND_PATH)

				for (new i = 1; i <= MaxClients; ++i)
				{
					if (IsClientInGame(i))
					{
						if (IsPlayerAlive(i))
						{
							if ((iTeam == 2 && GetClientTeam(i) == 3) || (iTeam == 3 && GetClientTeam(i) == 2))
							{
								if (!g_bInv[i])
									ForcePlayerSuicide(i);
							}
						}
					}
				}
				break;
			}
		}
		else if (g_iBlocks[a] == 14 || g_iBlocks[a] == 43 || g_iBlocks[a] == 72 || g_iBlocks[a] == 101) // CT Barrier
		{
			if (GetClientTeam(client) == 3)
			{
				if (!g_bLocked[client])
				{
					GetEntPropVector(a, Prop_Data, "m_vecOrigin", fPos2);
					if (fPos[0] - 60.0 < fPos2[0] < fPos[0] + 60.0 && fPos[1] - 60.0 < fPos2[1] < fPos[1] + 60.0 && fPos[2] - 120.0 < fPos2[2] < fPos[2] + 120.0)
					{
						new Float:fVelocity[3];
						GetEntPropVector(client, Prop_Data, "m_vecVelocity", fVelocity);
						ScaleVector(fVelocity, -2.0);
						fVelocity[2] = 0.0;
						g_bLocked[client] = true;
						CreateTimer(0.1, ResetLock, client);

						TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, fVelocity);
					}
				}
			}
		}
		else if (g_iBlocks[a] == 15 || g_iBlocks[a] == 44 || g_iBlocks[a] == 73 || g_iBlocks[a] == 102) // T Barrier
		{

			if (GetClientTeam(client) == 2)
			{
				if (!g_bLocked[client])
				{
					GetEntPropVector(a, Prop_Data, "m_vecOrigin", fPos2);
					if (fPos[0] - 60.0 < fPos2[0] < fPos[0] + 60.0 && fPos[1] - 60.0 < fPos2[1] < fPos[1] + 60.0 && fPos[2] - 120.0 < fPos2[2] < fPos[2] + 120.0)
					{
						new Float:fVelocity[3];
						GetEntPropVector(client, Prop_Data, "m_vecVelocity", fVelocity);
						ScaleVector(fVelocity, -2.0);
						fVelocity[2] = 0.0;
						g_bLocked[client] = true;
						CreateTimer(0.1, ResetLock, client);

						TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, fVelocity);
					}
				}
			}
		}
		else if (g_iBlocks[a] == 19 || g_iBlocks[a] == 5 || g_iBlocks[a] == 6 || g_iBlocks[a] == 35 || g_iBlocks[a] == 64 || g_iBlocks[a] == 93 || g_iBlocks[a] == 36 || g_iBlocks[a] == 65 || g_iBlocks[a] == 94 || g_iBlocks[a] == 48 || g_iBlocks[a] == 77 || g_iBlocks[a] == 105) // NOFALLDAMAGE for the NOFALLDMG Block TRAMPOLINE AND SPEEDBOOST
		{
			GetEntPropVector(a, Prop_Data, "m_vecOrigin", fPos2);
			if (GetVectorDistance(fPos, fPos2) <= 100.0)
			{
				if (!g_bNoFallDmg[client])
					CreateTimer(0.2, ResetNoFall, client);
				g_bNoFallDmg[client] = true;
			}
		} else if (g_iTeleporters[a] > 1 && 2 <= GetClientTeam(client) <= 3)
		{
			GetEntPropVector(a, Prop_Data, "m_vecOrigin", fPos2);
			if (IsValidBlock(g_iTeleporters[a]))
			{
				if (fPos[0] - 32.0 < fPos2[0] < fPos[0] + 32.0 && fPos[1] - 32.0 < fPos2[1] < fPos[1] + 32.0 && fPos[2] - 64.0 < fPos2[2] < fPos[2] + 64.0)
				{
					new String:sound[512], Float:Vec[3];
					GetConVarString(g_hTeleSound, sound, sizeof(sound));
					GetEntPropVector(g_iTeleporters[a], Prop_Data, "m_vecOrigin", fPos2);

					GetEntPropVector(client, Prop_Data, "m_vecVelocity", Vec);
					Vec[2] = FloatAbs(Vec[2])*1.0;
					TeleportEntity(client, fPos2, NULL_VECTOR, NULL_VECTOR);
					TeleportEntity(client, fPos2, NULL_VECTOR, Vec);

					PrintToChat(client, "%f %f %f", Vec[0], Vec[1], Vec[2]);

					EmitSoundToClient(client, TELE_SOUND_PATH);
				}
			}
		}
	}
	if (g_iDragEnt[client] != 0)
	{
		if (IsValidEdict(g_iDragEnt[client]))
		{
			//	new ent = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			//	if(ent != -1)
			//	{
			//		SetEntPropFloat(ent, Prop_Send, "m_flNextPrimaryAttack", 10000.0);
			//		SetEntPropFloat(ent, Prop_Send, "m_flNextSecondaryAttack", 10000.0);
			//	}

			new Float:vecDir[3], Float:vecPos[3], Float:vecVel[3];
			new Float:viewang[3];

			GetClientEyeAngles(client, viewang);
			GetAngleVectors(viewang, vecDir, NULL_VECTOR, NULL_VECTOR);
			GetClientEyePosition(client, vecPos);

			/*vecPos[0] += vecDir[0] * 100;
			vecPos[1] += vecDir[1] * 100;
			vecPos[2] += vecDir[2] * 100;*/


			vecPos[0] += vecDir[0] * g_fGrabOffset[client];
			vecPos[1] += vecDir[1] * g_fGrabOffset[client];
			vecPos[2] += (vecDir[2]) * g_fGrabOffset[client];

			//PrintToChat(client, "position vector: %f %f %f", vecPos[0], vecPos[1], vecPos[2]);
			//PrintToChat(client, "direction vector: %f %f %f", vecDir[0], vecDir[1], vecDir[2]);

			GetEntPropVector(g_iDragEnt[client], Prop_Send, "m_vecOrigin", vecDir);

			new Float:fPos3[3];

			new bool:bSnap = false;
			new bool:bGroup = g_bGroups[client][g_iDragEnt[client]];

			if (g_bSnapping[client] && (FloatAbs(g_fClientAngles[client][1]) - FloatAbs(angles[1])) < 2.0 && !bGroup)
			{
				for (new i = MaxClients + 1; i < 2048; ++i)
				{
					if (IsValidBlock(i) && i != g_iDragEnt[client])
					{
						GetEntPropVector(i, Prop_Send, "m_vecOrigin", fPos3);
						if (GetVectorDistance(vecDir, fPos3) <= 60.0 + g_fSnappingGap[client])
						{
							bSnap = true;
							new Float:d1, Float:d2, Float:d3, Float:d4, Float:d5, Float:d6;
							if (g_fAngles[i][1] == 0.0 && g_fAngles[i][2] == 0.0)
							{
								fPos3[0] += 64.0;
								d1 = GetVectorDistance(vecDir, fPos3);
								fPos3[0] -= 128.0;
								d2 = GetVectorDistance(vecDir, fPos3);
								fPos3[0] += 64.0;
								fPos3[1] += 64.0;
								d3 = GetVectorDistance(vecDir, fPos3);
								fPos3[1] -= 128.0;
								d4 = GetVectorDistance(vecDir, fPos3);
								fPos3[1] += 64.0;
								fPos3[2] += 8.0;
								d5 = GetVectorDistance(vecDir, fPos3);
								fPos3[2] -= 16.0;
								d6 = GetVectorDistance(vecDir, fPos3);
								fPos3[2] += 8.0;

								vecDir = fPos3;
								if (d1 < d2 && d1 < d3 && d1 < d4 && d1 < d5 && d1 < d6)
									vecDir[0] += 63.95 + g_fSnappingGap[client];
								else if (d2 < d1 && d2 < d3 && d2 < d4 && d2 < d5 && d2 < d6)
									vecDir[0] -= 63.95 + g_fSnappingGap[client];
								else if (d3 < d1 && d3 < d2 && d3 < d4 && d3 < d5 && d3 < d6)
									vecDir[1] += 63.95 + g_fSnappingGap[client];
								else if (d4 < d1 && d4 < d2 && d4 < d3 && d4 < d5 && d4 < d6)
									vecDir[1] -= 63.95 + g_fSnappingGap[client];
								else if (d5 < d1 && d5 < d2 && d5 < d3 && d5 < d4 && d5 < d6)
									vecDir[2] += 8.0 + g_fSnappingGap[client];
								else if (d6 < d1 && d6 < d2 && d6 < d3 && d6 < d4 && d6 < d5)
									vecDir[2] -= 8.0 + g_fSnappingGap[client];
							} else if (g_fAngles[i][1] == 0.0 && g_fAngles[i][2] == 90.0)
							{
								fPos3[0] += 64.0;
								d1 = GetVectorDistance(vecDir, fPos3);
								fPos3[0] -= 128.0;
								d2 = GetVectorDistance(vecDir, fPos3);
								fPos3[0] += 64.0;
								fPos3[1] += 8.0;
								d3 = GetVectorDistance(vecDir, fPos3);
								fPos3[1] -= 16.0;
								d4 = GetVectorDistance(vecDir, fPos3);
								fPos3[1] += 8.0;
								fPos3[2] += 64.0;
								d5 = GetVectorDistance(vecDir, fPos3);
								fPos3[2] -= 128.0;
								d6 = GetVectorDistance(vecDir, fPos3);
								fPos3[2] += 64.0;

								vecDir = fPos3;
								if (d1 < d2 && d1 < d3 && d1 < d4 && d1 < d5 && d1 < d6)
									vecDir[0] += 63.9 + g_fSnappingGap[client];
								else if (d2 < d1 && d2 < d3 && d2 < d4 && d2 < d5 && d2 < d6)
									vecDir[0] -= 63.9 + g_fSnappingGap[client];
								else if (d3 < d1 && d3 < d2 && d3 < d4 && d3 < d5 && d3 < d6)
									vecDir[1] += 8.0 + g_fSnappingGap[client];
								else if (d4 < d1 && d4 < d2 && d4 < d3 && d4 < d5 && d4 < d6)
									vecDir[1] -= 8.0 + g_fSnappingGap[client];
								else if (d5 < d1 && d5 < d2 && d5 < d3 && d5 < d4 && d5 < d6)
									vecDir[2] += 63.9 + g_fSnappingGap[client];
								else if (d6 < d1 && d6 < d2 && d6 < d3 && d6 < d4 && d6 < d5)
									vecDir[2] -= 63.9 + g_fSnappingGap[client];
							}
							else
							{
								fPos3[0] += 8.0;
								d1 = GetVectorDistance(vecDir, fPos3);
								fPos3[0] -= 16.0;
								d2 = GetVectorDistance(vecDir, fPos3);
								fPos3[0] += 8.0;
								fPos3[1] += 64.0;
								d3 = GetVectorDistance(vecDir, fPos3);
								fPos3[1] -= 128.0;
								d4 = GetVectorDistance(vecDir, fPos3);
								fPos3[1] += 64.0;
								fPos3[2] += 64.0;
								d5 = GetVectorDistance(vecDir, fPos3);
								fPos3[2] -= 128.0;
								d6 = GetVectorDistance(vecDir, fPos3);
								fPos3[2] += 64.0;

								vecDir = fPos3;
								if (d1 < d2 && d1 < d3 && d1 < d4 && d1 < d5 && d1 < d6)
									vecDir[0] += 8.0 + g_fSnappingGap[client];
								else if (d2 < d1 && d2 < d3 && d2 < d4 && d2 < d5 && d2 < d6)
									vecDir[0] -= 8.0 + g_fSnappingGap[client];
								else if (d3 < d1 && d3 < d2 && d3 < d4 && d3 < d5 && d3 < d6)
									vecDir[1] += 64.0 + g_fSnappingGap[client];
								else if (d4 < d1 && d4 < d2 && d4 < d3 && d4 < d5 && d4 < d6)
									vecDir[1] -= 64.0 + g_fSnappingGap[client];
								else if (d5 < d1 && d5 < d2 && d5 < d3 && d5 < d4 && d5 < d6)
									vecDir[2] += 64.0 + g_fSnappingGap[client];
								else if (d6 < d1 && d6 < d2 && d6 < d3 && d6 < d4 && d6 < d5)
									vecDir[2] -= 64.0 + g_fSnappingGap[client];
							}

							g_fAngles[g_iDragEnt[client]] = g_fAngles[i];
							break;
						}
					}
				}
			}

			if (!bSnap)
			{
				SubtractVectors(vecPos, vecDir, vecVel);
				ScaleVector(vecVel, 10.0);

				//TeleportEntity(g_iDragEnt[client], NULL_VECTOR, g_fAngles[g_iDragEnt[client]], vecVel);
				TeleportEntity(g_iDragEnt[client], vecPos, NULL_VECTOR, NULL_VECTOR);
				if (bGroup)
				{
					new Float:playerPos[3];
					GetClientEyePosition(client, playerPos);
					new Float:vecOrig[3];
					vecOrig = vecPos;

					for (new i = MaxClients + 1; i < 2048; ++i)
					{
						if (IsValidBlock(i) && i != g_iDragEnt[client] && g_bGroups[client][i])
						{
							vecPos = vecOrig;
							SubtractVectors(vecPos, vecDir, vecVel);
							ScaleVector(vecVel, 10.0);

							TeleportEntity(i, NULL_VECTOR, g_fAngles[i], vecVel);
						}
					}
				}
			}
			else
			{
				SetEntityMoveType(g_iDragEnt[client], MOVETYPE_NONE);
				AcceptEntityInput(g_iDragEnt[client], "disablemotion");
				new Float:nvel[3] =  { 0.0, 0.0, 0.0 };
				TeleportEntity(g_iDragEnt[client], vecDir, g_fAngles[g_iDragEnt[client]], nvel);

				g_iDragEnt[client] = 0

				DisplayMenu(CreateMainMenu(client), client, 0);
			}
		}
		else
		{
			g_iDragEnt[client] = 0;
		}
	}

	g_fClientAngles[client] = angles;

	return Plugin_Continue;
}

public Action:ResetLock(Handle:timer, any:client)
{
	if (!IsClientInGame(client))
		return Plugin_Stop;
	g_bLocked[client] = false;
	new Float:fVelocity[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", fVelocity);
	ScaleVector(fVelocity, -0.5);
	return Plugin_Stop;
}

public bool:TraceRayDontHitSelf(entity, mask, any:data)
{
	if (entity == data)
		return false;
	return true;
}

public Action:Command_BlockBuilder(client, args)
{
	//	if(!(GetUserFlagBits(client) & ADMFLAG_CUSTOM1 || GetUserFlagBits(client) & ADMFLAG_ROOT))
	//	{
	//		PrintToChat(client, "\x03%s\x04 You don't have permission to access this.", CHAT_TAG);
	//		return Plugin_Handled;
	//	}

	new Handle:menu = CreateMainMenu(client);

	DisplayMenu(menu, client, 30);
	return Plugin_Handled;
}

public Handler_BlockBuilder(Handle:menu, MenuAction:action, client, param2)
{
	if (action != MenuAction_Select)
	{
		return;
	}

	new bool:bDisplayMenu = true;

	switch (param2) {
		case 0: {
			bDisplayMenu = false;
			DisplayMenu(CreateBlocksMenu(), client, 0);
		}
		case 1: {
			new ent = GetClientAimTarget2(client, false);

			if (g_iDragEnt[client] == 0) {

				if (!IsValidBlock(ent)) {
					CreateBlockAiming(client);
				}
				else {
					StartGrabbing(client, ent);
				}
			}
			else {
				StopGrabbing(client, g_iDragEnt[client]);
			}
		}
		case 2: {
			g_iClBlockSize[client]++;

			if (g_iClBlockSize[client] >= _:BlockSizes) {
				g_iClBlockSize[client] = 0;
			}
		}
		case 3: {
			new ent = GetClientAimTarget2(client, false);

			if (IsValidBlock(ent))
			{
				decl Float:vAng[3];
				GetEntPropVector(ent, Prop_Data, "m_angRotation", vAng);

				if(g_iBlocksSize[ent] == _:BLOCK_POLE) {
					if (vAng[1])
					{
						vAng[1] = 0.0;
						vAng[2] = 0.0;
					}
					else if (vAng[0])
						vAng[1] = 90.0;
					else
						vAng[0] = 90.0;
				}
				else {

					if (vAng[1])
					{
						vAng[1] = 0.0;
						vAng[2] = 0.0;
					}
					else if (vAng[2])
						vAng[1] = 90.0;
					else
						vAng[2] = 90.0;
				}


				g_fAngles[ent] = vAng;

				TeleportEntity(ent, NULL_VECTOR, vAng, NULL_VECTOR);
			}
			else
			{
				PrintToChat(client, "\x03%s\x04 You must aim at a block.", CHAT_TAG);
			}
		}
		case 4: {
			new ent = GetClientAimTarget2(client, false);
			if (IsValidBlock(ent))
			{
				AcceptEntityInput(ent, "Kill");
				g_iBlocks[ent] = -1;
				if (g_iTeleporters[ent] >= 1)
				{
					if (g_iTeleporters[ent] > 1 && IsValidBlock(g_iTeleporters[ent]))
					{
						AcceptEntityInput(g_iTeleporters[ent], "Kill");
						g_iTeleporters[g_iTeleporters[ent]] = -1;
					} else if (g_iTeleporters[ent] == 1)
					{
						for (new i = MaxClients + 1; i < 2048; ++i)
						{
							if (g_iTeleporters[i] == ent)
							{
								if (IsValidBlock(i))
									AcceptEntityInput(i, "Kill");
								g_iTeleporters[i] = -1;
								break;
							}
						}
					}

					g_iTeleporters[ent] = -1;
				}
				//PrintToChat(client, MESS, "Block has been deleted.");
			}
			else
			{
				PrintToChat(client, "\x03%s\x04 You must aim at a block.", CHAT_TAG);
			}
		}
		case 5: {
			if (GetEntityMoveType(client) != MOVETYPE_NOCLIP)
			{
				SetEntityMoveType(client, MOVETYPE_NOCLIP);
			}
			else
			{
				SetEntityMoveType(client, MOVETYPE_ISOMETRIC);
			}
		}
		case 6: {

			new ent = GetClientAimTarget2(client, false);
			if (IsValidBlock(ent) && g_iTeleporters[ent] == -1)
			{
				if (g_iBlockSelection[client] == g_iBlocks[ent])
				{
					PrintToChat(client, "%s The block type is the same, there's no need to change.", CHAT_TAG);
				}
				else
				{
					g_iBlocks[ent] = g_iBlockSelection[client];
					//SetEntityModel(ent, g_eBlocks[g_iBlockSelection[client]][ModelPath]);
					PrintToChat(client, "This function is not implemented. Yet.");
				}
			}
			else
			{
				PrintToChat(client, "\x03%s\x04 You must aim at a block.", CHAT_TAG);
			}
		}
		case 7: {
			if (GetEntProp(client, Prop_Data, "m_takedamage", 1) == 2)
			{
				SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
			}
			else
			{
				SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
			}
		}
		case 8: {
			bDisplayMenu = false;
			DisplayMenu(CreateTeleportMenu(client), client, 0);
		}
		case 9: {
			new ent = GetClientAimTarget(client, false);
			if (IsValidBlock(ent))
			{
				bDisplayMenu = false;
				CurrentModifier[client] = ent
				Command_BlockAlpha(client)
			}
		}
		case 10: {
			new ent = GetClientAimTarget(client, false);
			if (IsValidBlock(ent))
			{
				bDisplayMenu = false;
				//show property menu
			}
			else
			{
				PrintToChat(client, "\x03%s\x04 You have to aim at the block to change it's properties.", CHAT_TAG);
			}
		}
		case 11: {
			bDisplayMenu = false;
			DisplayMenu(CreateOptionsMenu(client), client, 0);
		}
	}

	if (bDisplayMenu)
		DisplayMenu(CreateMainMenu(client), client, 0);

}

public Command_BlockAlpha(client)
{
	new Handle:menu = CreateMenu(BB_ALPHA, MenuAction_Select | MenuAction_End);
	SetMenuTitle(menu, "Block Transparency");
	AddMenuItem(menu, "20", "20");
	AddMenuItem(menu, "40", "40");
	AddMenuItem(menu, "60", "60");
	AddMenuItem(menu, "80", "80");
	AddMenuItem(menu, "100", "100");
	AddMenuItem(menu, "120", "120");
	AddMenuItem(menu, "140", "140");
	AddMenuItem(menu, "160", "160");
	AddMenuItem(menu, "180", "180");
	AddMenuItem(menu, "200", "200");
	AddMenuItem(menu, "220", "240");
	AddMenuItem(menu, "250", "250");
	AddMenuItem(menu, "255", "255 (DEFAULT)");

	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}


public BB_ALPHA(Handle:menu, MenuAction:action, client, param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			decl String:item[16];
			GetMenuItem(menu, param2, item, sizeof(item));
			SetEntityRenderMode(CurrentModifier[client], RENDER_TRANSCOLOR)
			SetEntityRenderColor(CurrentModifier[client], 255, 255, 255, StringToInt(item))
			DisplayMenu(CreateMainMenu(client), client, 0);
			PrintToChat(client, "\x03%s\x04 Block's Transparency has been adjusted.", CHAT_TAG);
			Block_Transparency[CurrentModifier[client]] = StringToInt(item);
		}
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
	}
}

public Handle:CreateTeleportMenu(client)
{
	new Handle:menu = CreateMenu(Handler_Teleport);
	SetMenuTitle(menu, "Teleport Menu");
	if (g_iCurrentTele[client] == -1)
		AddMenuItem(menu, "0", "Teleport Start");
	else
		AddMenuItem(menu, "0", "Cancel teleport");
	AddMenuItem(menu, "1", "Teleport End");
	AddMenuItem(menu, "2", "Swap Teleport Start/End");
	AddMenuItem(menu, "3", "Delete Teleport");
	AddMenuItem(menu, "4", "Show Teleport Path");
	SetMenuExitBackButton(menu, true);
	return menu;
}

public Handle:CreateBlocksMenu()
{
	new Handle:menu = CreateMenu(Handler_Blocks);
	decl String:szItem[4];
	SetMenuTitle(menu, "Block Menu");
	for (new i; i < sizeof(g_eBlocks); i++)
	{
		IntToString(i, szItem, sizeof(szItem));
		AddMenuItem(menu, szItem, g_eBlocks[i][BlockName]);
	}
	SetMenuExitBackButton(menu, true);
	return menu;
}

public Handle:CreateMainMenu(client)
{
	new Handle:menu = CreateMenu(Handler_BlockBuilder);

	SetMenuTitle(menu, "blockbuilder Blockmaker");

	new String:sInfo[256], String:sSize[32];
	Format(sInfo, sizeof(sInfo), "Block: %s", g_eBlocks[g_iBlockSelection[client]][BlockName]);
	AddMenuItem(menu, "0", sInfo);
	if (g_iDragEnt[client] == 0)
		AddMenuItem(menu, "1", "Place Block");
	else
		AddMenuItem(menu, "1", "Release Block");

	Format(sSize, sizeof(sSize), "Size: %s", BlockDirName[g_iClBlockSize[client]]);
	AddMenuItem(menu, "2", sSize);


	AddMenuItem(menu, "3", "Rotate Block");
	AddMenuItem(menu, "4", "Delete Block");

	if (GetEntityMoveType(client) != MOVETYPE_NOCLIP)
		AddMenuItem(menu, "5", "No Clip: Off");
	else
		AddMenuItem(menu, "5", "No Clip: On");

	AddMenuItem(menu, "6", "Replace Block");

	if (GetEntProp(client, Prop_Data, "m_takedamage", 1) == 2)
		AddMenuItem(menu, "7", "Godmode: Off");
	else
		AddMenuItem(menu, "7", "Godmode: On");

	AddMenuItem(menu, "8", "Teleport Builder");
	AddMenuItem(menu, "9", "Block Transparency");
	AddMenuItem(menu, "10", "Block Properties");
	AddMenuItem(menu, "11", "More Options");
	SetMenuExitButton(menu, true);
	g_hClientMenu[client] = menu;
	return menu;
}

public Handle:CreateOptionsMenu(client)
{
	new Handle:menu = CreateMenu(Handler_Options);
	SetMenuTitle(menu, "Options Menu");

	if (g_bSnapping[client])
		AddMenuItem(menu, "0", "Snapping: On");
	else
		AddMenuItem(menu, "0", "Snapping: Off");


	new String:sText[256];
	Format(sText, sizeof(sText), "Snapping gap: %.1f\n \n", g_fSnappingGap[client]);
	AddMenuItem(menu, "1", sText);

	AddMenuItem(menu, "2", "Add to group");
	AddMenuItem(menu, "3", "Clear group\n \n");

	new bRoot = (GetUserFlagBits(client) & ADMFLAG_ROOT || GetUserFlagBits(client) & ReadFlagString("p") ? true:false);

	//	AddMenuItem(menu, "4", "Load from file");
	AddMenuItem(menu, "4", "Load from file", (bRoot ? ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED));
	//	AddMenuItem(menu, "5", "Save to file\n \n");
	AddMenuItem(menu, "5", "Save to file\n \n", (bRoot ? ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED));

	//	AddMenuItem(menu, "6", "Delete all blocks");
	AddMenuItem(menu, "6", "Delete all blocks", (bRoot ? ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED));
	//	AddMenuItem(menu, "7", "Delete all teleporters");
	AddMenuItem(menu, "7", "Delete all teleporters", (bRoot ? ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED));

	SetMenuExitBackButton(menu, true);
	return menu;
}

CreateTeleportEntrance(client, Float:fPos[3] =  { 0.0, 0.0, 0.0 } )
{
	new Float:vecDir[3], Float:vecPos[3], Float:viewang[3];
	if (client > 0)
	{
		GetClientEyeAngles(client, viewang);
		GetAngleVectors(viewang, vecDir, NULL_VECTOR, NULL_VECTOR);
		GetClientEyePosition(client, vecPos);
		vecPos[0] += vecDir[0] * 100;
		vecPos[1] += vecDir[1] * 100;
		vecPos[2] += vecDir[2] * 100;
	}
	else
	{
		vecPos = fPos;
	}

	new ent = CreateEntityByName("prop_physics_override");
	DispatchKeyValue(ent, "model", "models/platforms/b-tele.mdl");
	TeleportEntity(ent, vecPos, NULL_VECTOR, NULL_VECTOR);
	DispatchSpawn(ent);

	SetEntityMoveType(ent, MOVETYPE_NONE);
	AcceptEntityInput(ent, "disablemotion");
	SetEntProp(ent, Prop_Data, "m_CollisionGroup", 2);

	g_iTeleporters[ent] = 1;
	g_iCurrentTele[client] = ent;

	SDKHook(ent, SDKHook_StartTouch, OnStartTouch);

	return ent;
}

CreateTeleportExit(client, Float:fPos[3] =  { 0.0, 0.0, 0.0 } )
{
	new Float:vecDir[3], Float:vecPos[3], Float:viewang[3];
	if (client > 0)
	{
		GetClientEyeAngles(client, viewang);
		GetAngleVectors(viewang, vecDir, NULL_VECTOR, NULL_VECTOR);
		GetClientEyePosition(client, vecPos);
		vecPos[0] += vecDir[0] * 100;
		vecPos[1] += vecDir[1] * 100;
		vecPos[2] += vecDir[2] * 100;
	}
	else
	{
		vecPos = fPos;
	}

	new ent = CreateEntityByName("prop_physics_override");
	DispatchKeyValue(ent, "model", "models/platforms/r-tele.mdl");
	TeleportEntity(ent, vecPos, NULL_VECTOR, NULL_VECTOR);
	DispatchSpawn(ent);

	SetEntityMoveType(ent, MOVETYPE_NONE);
	AcceptEntityInput(ent, "disablemotion");
	SetEntProp(ent, Prop_Data, "m_CollisionGroup", 2);

	g_iTeleporters[ent] = 1;

	return ent;
}

CreateBlockAiming(client) {
	new Float:vecPos[3], Float:vecDir[3], Float:viewang[3];

	GetClientEyeAngles(client, viewang);
	GetAngleVectors(viewang, vecDir, NULL_VECTOR, NULL_VECTOR);
	GetClientEyePosition(client, vecPos);
	vecPos[0] += vecDir[0] * 100;
	vecPos[1] += vecDir[1] * 100;
	vecPos[2] += vecDir[2] * 100;

	return CreateBlock(client, g_iBlockSelection[client], g_iClBlockSize[client], vecPos, _, _, _, _);
}

CreateBlock(client, blocktype = 0, blocksize = _:BLOCK_NORMAL, Float:fPos[3] =  { 0.0, 0.0, 0.0 }, Float:fAng[3] =  { 0.0, 0.0, 0.0 }, Float:attrib1 = 0.0, Float:attrib2 = 0.0, transparency = 0)
{
	new Float:vecPos[3];
	vecPos = fPos;

	new block_entity = CreateEntityByName("prop_physics_override");

	new String:sModel[256];
	Format(sModel, sizeof(sModel), "%s_%s/%s", g_eBlocks[blocktype][ModelPathPrefix], BlockDirName[blocksize], g_eBlocks[blocktype][ModelName]);
	DispatchKeyValue(block_entity, "model", sModel);

	TeleportEntity(block_entity, vecPos, fAng, NULL_VECTOR);
	DispatchSpawn(block_entity);

	SetEntityMoveType(block_entity, MOVETYPE_NONE);
	AcceptEntityInput(block_entity, "disablemotion");

	g_iBlocksSize[block_entity] = blocksize;

	Block_Transparency[block_entity] = -1;
	if (transparency > 0) {
		SetEntityRenderMode(block_entity, RENDER_TRANSCOLOR)
		SetEntityRenderColor(block_entity, 255, 255, 255, transparency)
		Block_Transparency[block_entity] = transparency;
	}

	if (blocktype == _:BARRIER_T || blocktype == _:BARRIER_CT)
		SetEntProp(block_entity, Prop_Data, "m_CollisionGroup", 2);

	g_iBlocks[block_entity] = blocktype;

	SDKHook(block_entity, SDKHook_StartTouch, OnStartTouch);
	SDKHook(block_entity, SDKHook_Touch, OnTouch);
	SDKHook(block_entity, SDKHook_EndTouch, OnEndTouch);

	g_fAngles[block_entity] = fAng;

	SetDefaultProperty(block_entity);

	//PrintToChat(client, "%sSuccessfully spawned block \x03%s\x04.", CHAT_TAG, g_eBlocks[g_iBlockSelection[client]][BlockName]);
	return block_entity;
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if (g_bInv[victim] || (g_bNoFallDmg[victim] && damagetype & DMG_FALL))
		return Plugin_Handled;
	return Plugin_Continue;
}

public Action:OnStartTouch(block, client)
{
	if (g_iTeleporters[block] != -1) {
		return Plugin_Continue;
	}

	if (!IsClientInGame(client)) {
		return Plugin_Continue;
	}

	/* The block can be activated from top only
		but the player isn't on ground */
	if(g_bTopOnly[block] == 1
		&& (!(GetEntityFlags(client) & FL_ONGROUND)
		|| GetEntPropEnt(client, Prop_Send, "m_hGroundEntity") != block)) {

		g_bTouchStartTriggered[client] = false;

		return Plugin_Continue;
	}

	g_bTouchStartTriggered[client] = true;

	DataPack pack = CreateDataPack();
	pack.WriteCell(client);
	pack.WriteCell(block);

	switch(g_iBlocks[block]) {
		case TRAMPOLINE: {
			CreateTimer(0.0, JumpPlayer, pack)
			g_bNoFallDmg[client] = true;
		}
		case SPEEDBOOST: {
			CreateTimer(0.0, BoostPlayer, pack);
		}
		case DEATH: {
			if (IsClientInGame(client) && IsPlayerAlive(client))
			{
				if (!g_bInv[client] && GetEntProp(client, Prop_Data, "m_takedamage", 1) != 0) {
					SDKHooks_TakeDamage(client, 0, 0, 10000.0);
				}
			}
		}
		case DAMAGE: {
			ClearTimer(Block_Timers[client]);

			Block_Timers[client] = CreateTimer(0.0, DamagePlayer, pack);
		}
		case HEALTH: {
			ClearTimer(Block_Timers[client]);

			Block_Timers[client] = CreateTimer(g_fPropertyValue[block][0], HealPlayer, pack);
		}
		case NO_FALL_DAMAGE: {
			g_bNoFallDmg[client] = true;
		}
		case BUNNYHOP: {
			g_bTriggered[block] = true;
			CreateTimer(g_fPropertyValue[block][0], StartNoBlock, block);
		}
		case BUNNYHOP_DELAYED: {
			g_bTriggered[block] = true;
			CreateTimer(g_eBlocks[1][EffectTime], StartNoBlock, block);
		}
		case BUNNYHOP_NSD: {
			g_bTriggered[block] = true;
			CreateTimer(g_eBlocks[18][EffectTime], StartNoBlock, block);
			SetEntPropFloat(client, Prop_Send, "m_flStamina", 0.0);
		}
		default: {
			CloseHandle(pack);
		}
	}

	decl Float:block_loc[3]
	GetEntPropVector(block, Prop_Send, "m_vecOrigin", block_loc);
	decl Float:player_loc[3]
	GetClientAbsOrigin(client, player_loc)
	player_loc[2] += TrueForce;

	if (false && FL_ONGROUND && GetEntPropEnt(client, Prop_Send, "m_hGroundEntity") == block)
	{
		//	new bool:bRandom = false;
		if (g_iBlocks[block] == 24 || g_iBlocks[block] == 53 || g_iBlocks[block] == 82 || g_iBlocks[block] == 111)
		{
			if (!g_bRandomCantUse[client])
			{
				g_bRandomCantUse[client] = true;
				new Handle:datapack = CreateDataPack()
				WritePackCell(datapack, client)
				WritePackCell(datapack, RoundIndex)
				if (randomblock_time >= 1.0)
				{
					CreateTimer(randomblock_time, ResetCooldownRandom, datapack)
				}
				else
				{
					CreateTimer(1.0, ResetCooldownRandom, datapack)
				}
				new random = RoundFloat(GetRandomFloat(1.00, 8.00))
				if (random == 1) // Invincibility, Stealth, Camouflage, Boots Of Speed, a slap, or death!
				{
					new Handle:packet_f = CreateDataPack()
					WritePackCell(packet_f, RoundIndex)
					WritePackCell(packet_f, client)
					CreateTimer(g_eBlocks[7][EffectTime], ResetInv, packet_f);
					CreateTimer(g_eBlocks[7][CooldownTime], ResetInvCooldown, packet_f);
					g_bInv[client] = true;
					g_bInvCanUse[client] = false;

					//	CreateLight(client)

					new Handle:packet = CreateDataPack()
					WritePackCell(packet, RoundIndex)
					WritePackCell(packet, client)
					WritePackCell(packet, RoundFloat(g_eBlocks[7][EffectTime]))
					WritePackString(packet, "Invincibility")

					EmitSoundToClient(client, INVI_SOUND_PATH, block)
					CreateTimer(1.0, TimeLeft, packet)
					PrintToChat(client, "\x03%s\x04 You've rolled an Invincibility from Random Block!", CHAT_TAG);
				}
				else if (random == 2)
				{
					new Handle:packet_f = CreateDataPack()
					WritePackCell(packet_f, RoundIndex)
					WritePackCell(packet_f, client)

					CreateTimer(g_eBlocks[8][EffectTime], ResetStealth, packet_f);
					CreateTimer(g_eBlocks[8][CooldownTime], ResetStealthCooldown, packet_f);
					SetEntityRenderMode(client, RENDER_NONE);
					SDKHook(client, SDKHook_SetTransmit, Stealth_SetTransmit)
					g_bStealthCanUse[client] = false;

					new Handle:packet = CreateDataPack()
					WritePackCell(packet, RoundIndex)
					WritePackCell(packet, client)
					WritePackCell(packet, RoundFloat(g_eBlocks[8][EffectTime]))
					WritePackString(packet, "Stealth")
					EmitSoundToClient(client, STEALTH_SOUND_PATH, block)
					CreateTimer(1.0, TimeLeft, packet)
					PrintToChat(client, "\x03%s\x04 You've rolled a Stealth from Random Block!", CHAT_TAG);
				}
				else if (random == 3)
				{
					if (GetClientTeam(client) == 2)
						SetEntityModel(client, "models/player/ctm_gign.mdl");
					else if (GetClientTeam(client) == 3)
						SetEntityModel(client, "models/player/tm_phoenix.mdl");
					g_bCamCanUse[client] = false;
					new Handle:packet_f = CreateDataPack()
					WritePackCell(packet_f, RoundIndex)
					WritePackCell(packet_f, client)
					CreateTimer(g_eBlocks[21][EffectTime], ResetCamouflage, packet_f);
					CreateTimer(g_eBlocks[21][CooldownTime], ResetCamCanUse, packet_f);

					new Handle:packet = CreateDataPack()
					WritePackCell(packet, RoundIndex)
					WritePackCell(packet, client)
					WritePackCell(packet, RoundFloat(g_eBlocks[21][EffectTime]))
					WritePackString(packet, "Camouflage")
					EmitSoundToClient(client, CAM_SOUND_PATH, block)
					CreateTimer(1.0, TimeLeft, packet)
					PrintToChat(client, "\x03%s\x04 You've rolled a Camouflage from Random Block!", CHAT_TAG);
				}
				else if (random == 4)
				{
					new Handle:packet_f = CreateDataPack()
					WritePackCell(packet_f, RoundIndex)
					WritePackCell(packet_f, client)
					CreateTimer(g_eBlocks[16][EffectTime], ResetBoots, packet_f);
					CreateTimer(g_eBlocks[16][CooldownTime], ResetBootsCooldown, packet_f);
					SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.45);
					g_bBootsCanUse[client] = false;

					new Handle:packet = CreateDataPack()
					WritePackCell(packet, RoundIndex)
					WritePackCell(packet, client)
					WritePackCell(packet, RoundFloat(g_eBlocks[16][EffectTime]))
					WritePackString(packet, "Speed Boost")

					EmitSoundToClient(client, BOS_SOUND_PATH, block)

					CreateTimer(1.0, TimeLeft, packet)
					PrintToChat(client, "\x03%s\x04 You've rolled a Speed Boost from Random Block!", CHAT_TAG);
				}
				else if (random == 5)
				{
					if (!g_bInv[client])
					{
						SDKHooks_TakeDamage(client, 0, 0, 10000.0);
						PrintToChat(client, "\x03%s\x04 You've rolled a Death from Random Block!", CHAT_TAG);
					}
					else
					{
						PrintToChat(client, "\x03%s\x04 Huh? It looks like you've avoided death from Random Block!", CHAT_TAG);
					}
				}
				else if (random == 6)
				{
					new ent = -1;
					ent = Client_GiveWeaponAndAmmo(client, "weapon_deagle", true, 0, 1, 1, 1);
					SetEntProp(ent, Prop_Data, "m_iClip1", 1);
					SetEntProp(ent, Prop_Data, "m_iClip2", 1);
					SetEntData(client, g_iAmmo + (GetEntData(ent, g_iPrimaryAmmoType) << 2), 0, 4, true);
					PrintToChatAll("\x03%s\x04 %N just got a Deagle", CHAT_TAG, client);
				}
				else if (random == 7)
				{
					new ent = -1;
					ent = Client_GiveWeaponAndAmmo(client, "weapon_awp", true, 0, 1, 1, 1);
					SetEntProp(ent, Prop_Data, "m_iClip1", 1);
					SetEntProp(ent, Prop_Data, "m_iClip2", 1);
					SetEntData(client, g_iAmmo + (GetEntData(ent, g_iPrimaryAmmoType) << 2), 0, 4, true);
					PrintToChatAll("\x03%s\x04 %N just got a AWP", CHAT_TAG, client);
				}
				else if (random == 8)
				{
					new grenade_random = RoundFloat(GetRandomFloat(1.00, 3.00))
					if (grenade_random == 1)
					{
						GivePlayerItem(client, "weapon_hegrenade");
					}
					else if (grenade_random == 2)
					{
						GivePlayerItem(client, "weapon_flashbang");
					}
					else if (grenade_random == 3)
					{
						// GivePlayerItem(client, "weapon_smokegrenade");
						GivePlayerItem(client, "weapon_decoy");
					}
					PrintToChat(client, "\x03%s\x04 You've rolled a Grenade from Random Block!", CHAT_TAG);
				}
			}
		}

		else if (g_iBlocks[block] == 4 || g_iBlocks[block] == 34 || g_iBlocks[block] == 63 || g_iBlocks[block] == 92)
		{
		}
		else if (g_iBlocks[block] == 7 || g_iBlocks[block] == 37 || g_iBlocks[block] == 66 || g_iBlocks[block] == 95)
		{
			if (g_bInvCanUse[client])
			{
				new Handle:packet_f = CreateDataPack()
				WritePackCell(packet_f, RoundIndex)
				WritePackCell(packet_f, client)
				CreateTimer(g_eBlocks[7][EffectTime], ResetInv, packet_f);
				CreateTimer(g_eBlocks[7][CooldownTime], ResetInvCooldown, packet_f);
				g_bInv[client] = true;
				g_bInvCanUse[client] = false;

				//	CreateLight(client)

				new Handle:packet = CreateDataPack()
				WritePackCell(packet, RoundIndex)
				WritePackCell(packet, client)
				WritePackCell(packet, RoundFloat(g_eBlocks[7][EffectTime]))
				WritePackString(packet, "Invincibility")

				EmitSoundToClient(client, INVI_SOUND_PATH, block)
				CreateTimer(1.0, TimeLeft, packet)
			}
		}
		else if (g_iBlocks[block] == 8 || g_iBlocks[block] == 38 || g_iBlocks[block] == 67 || g_iBlocks[block] == 96)
		{
			if (g_bStealthCanUse[client])
			{
				new Handle:packet_f = CreateDataPack()
				WritePackCell(packet_f, RoundIndex)
				WritePackCell(packet_f, client)

				CreateTimer(g_eBlocks[8][EffectTime], ResetStealth, packet_f);
				CreateTimer(g_eBlocks[8][CooldownTime], ResetStealthCooldown, packet_f);
				SetEntityRenderMode(client, RENDER_NONE);
				SDKHook(client, SDKHook_SetTransmit, Stealth_SetTransmit)
				g_bStealthCanUse[client] = false;

				new Handle:packet = CreateDataPack()
				WritePackCell(packet, RoundIndex)
				WritePackCell(packet, client)
				WritePackCell(packet, RoundFloat(g_eBlocks[8][EffectTime]))
				WritePackString(packet, "Stealth")
				EmitSoundToClient(client, STEALTH_SOUND_PATH, block)
				CreateTimer(1.0, TimeLeft, packet)
			}
		}
		else if (g_iBlocks[block] == 11 || g_iBlocks[block] == 40 || g_iBlocks[block] == 69 || g_iBlocks[block] == 98)
		{
			SetEntityGravity(client, 0.4);
			CreateTimer(3.0, ResetGrav, client)
			g_iGravity[client] = 1;
		}
		//	else if(g_iBlocks[block]==14 || g_iBlocks[block]==43 || g_iBlocks[block]==72 || g_iBlocks[block]==101)
		//	{
		//		if(GetClientTeam(client) == 2)
		//		{
		//			SetEntProp(block_entity, Prop_Data, "m_CollisionGroup", 2);
		//		}
		//	}
		//	else if(g_iBlocks[block]==15 || g_iBlocks[block]==44 || g_iBlocks[block]==73 || g_iBlocks[block]==102)
		//	{
		//		if(GetClientTeam(client) == 3)
		//		{
		//			SetEntProp(block_entity, Prop_Data, "m_CollisionGroup", 2);
		//		}
		//	}
		else if (g_iBlocks[block] == 16 || g_iBlocks[block] == 45 || g_iBlocks[block] == 74 || g_iBlocks[block] == 103)
		{
			if (g_bBootsCanUse[client])
			{
				new Handle:packet_f = CreateDataPack()
				WritePackCell(packet_f, RoundIndex)
				WritePackCell(packet_f, client)
				CreateTimer(g_eBlocks[16][EffectTime], ResetBoots, packet_f);
				CreateTimer(g_eBlocks[16][CooldownTime], ResetBootsCooldown, packet_f);

				SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.45);
				g_bBootsCanUse[client] = false;

				new Handle:packet = CreateDataPack()
				WritePackCell(packet, RoundIndex)
				WritePackCell(packet, client)
				WritePackCell(packet, RoundFloat(g_eBlocks[16][EffectTime]))
				WritePackString(packet, "Speed Boost")

				EmitSoundToClient(client, BOS_SOUND_PATH, block)

				CreateTimer(1.0, TimeLeft, packet)
			}
		}
		else if (g_iBlocks[block] == 21 || g_iBlocks[block] == 50 || g_iBlocks[block] == 79 || g_iBlocks[block] == 108)
		{
			if (g_bCamCanUse[client])
			{
				if (GetClientTeam(client) == 2)
					SetEntityModel(client, "models/player/ctm_gign.mdl");
				else if (GetClientTeam(client) == 3)
					SetEntityModel(client, "models/player/tm_phoenix.mdl");
				g_bCamCanUse[client] = false;
				new Handle:packet_f = CreateDataPack()
				WritePackCell(packet_f, RoundIndex)
				WritePackCell(packet_f, client)
				CreateTimer(g_eBlocks[21][EffectTime], ResetCamouflage, packet_f);
				CreateTimer(g_eBlocks[21][CooldownTime], ResetCamCanUse, packet_f);

				new Handle:packet = CreateDataPack()
				WritePackCell(packet, RoundIndex)
				WritePackCell(packet, client)
				WritePackCell(packet, RoundFloat(g_eBlocks[21][EffectTime]))
				WritePackString(packet, "Camouflage")
				EmitSoundToClient(client, CAM_SOUND_PATH, block)
				CreateTimer(1.0, TimeLeft, packet)
			}
		}
		else if (g_iBlocks[block] == 22 || g_iBlocks[block] == 51 || g_iBlocks[block] == 80 || g_iBlocks[block] == 109)
		{
			if (g_bDeagleCanUse[client])
			{
				if (GetClientTeam(client) == 2)
				{
					new ent = -1;
					ent = Client_GiveWeaponAndAmmo(client, "weapon_deagle", true, 0, 1, 1, 1);
					SetEntProp(ent, Prop_Data, "m_iClip1", 1);
					SetEntProp(ent, Prop_Data, "m_iClip2", 1);
					SetEntData(client, g_iAmmo + (GetEntData(ent, g_iPrimaryAmmoType) << 2), 0, 4, true);
					PrintToChatAll("\x03%s\x04 %N has got a DEAGLE", CHAT_TAG, client);
					g_bDeagleCanUse[client] = false;
				}
			}
		}
		else if (g_iBlocks[block] == 23 || g_iBlocks[block] == 52 || g_iBlocks[block] == 81 || g_iBlocks[block] == 110)
		{
			if (g_bAwpCanUse[client])
			{
				if (GetClientTeam(client) == 2)
				{
					new ent = -1;
					ent = Client_GiveWeaponAndAmmo(client, "weapon_awp", true, 0, 1, 1, 1);
					SetEntProp(ent, Prop_Data, "m_iClip1", 1);
					SetEntProp(ent, Prop_Data, "m_iClip2", 1);
					SetEntData(client, g_iAmmo + (GetEntData(ent, g_iPrimaryAmmoType) << 2), 0, 4, true);
					PrintToChatAll("\x03%s\x04 %N has got an AWP", CHAT_TAG, client);
					g_bAwpCanUse[client] = false;
				}
			}
		}
	}

	else if (g_iBlocks[block] == 28 || g_iBlocks[block] == 57 || g_iBlocks[block] == 86 || g_iBlocks[block] == 115) // Delayed
	{
		g_bTriggered[block] = true;
		CreateTimer(SpeedBoostForce_1[block], StartNoBlock, block);
	}

	return Plugin_Continue;
}

public Action:ResetCooldownRandom(Handle:timer, any:packet)
{
	ResetPack(packet)
	new client = ReadPackCell(packet)
	new round = ReadPackCell(packet)
	if (round == RoundIndex)
	{
		g_bRandomCantUse[client] = false;
		PrintToChat(client, "\x03%s\x04 Random block cooldown has worn off.", CHAT_TAG);
	}
}

public Action:Stealth_SetTransmit(entity, clients)
{
	if (entity == clients)
		return Plugin_Continue;
	return Plugin_Handled;
}

public Action:TimeLeft(Handle:timer, any:pack)
{
	ResetPack(pack)
	new round_index = ReadPackCell(pack)
	if (round_index != RoundIndex)
	{
		KillTimer(timer, true)
		return Plugin_Handled;
	}
	new client = ReadPackCell(pack)
	if (!IsFakeClient(client))
	{
		if (IsClientInGame(client))
		{
			new time = ReadPackCell(pack)
			time -= 1

			if (time > 0)
			{
				decl String:effectname[32];
				ReadPackString(pack, effectname, sizeof(effectname))
				PrintHintText(client, "%s will worn off in: %i", effectname, time)

				new Handle:packet = CreateDataPack()
				WritePackCell(packet, RoundIndex)
				WritePackCell(packet, client)
				WritePackCell(packet, time)
				WritePackString(packet, effectname)


				CreateTimer(1.0, TimeLeft, packet)
			}
		}
	}
	return Plugin_Continue;
}

public Action:ResetGrav(Handle:timer, any:client)
{
	if (IsValidClient(client))
	{
		SetEntityGravity(client, 1.0)
	}
}

stock bool:IsValidClient(client)
{
	if (!(1 <= client <= MaxClients) || !IsClientInGame(client))
		return false;

	return true;
}

public Action:OnTouch(block, client)
{
	if (g_iTeleporters[block] != -1) {
		return Plugin_Continue;
	}

	if (!IsClientInGame(client)) {
		return Plugin_Continue;
	}

	if(!g_bTouchStartTriggered[client]) {
		OnStartTouch(block, client);

		return Plugin_Continue;
	}

	Block_Touching[client] = g_iBlocks[block]

		if (g_iBlocks[block] == 1 || g_iBlocks[block] == 31 || g_iBlocks[block] == 89 || g_iBlocks[block] == 60)
		{
			if (!g_bTriggered[block])
				CreateTimer(g_eBlocks[1][EffectTime], StartNoBlock, block);
		} else if (g_iBlocks[block] == 2 || g_iBlocks[block] == 32 || g_iBlocks[block] == 61 || g_iBlocks[block] == 90)
		{
		} else if (g_iBlocks[block] == 3 || g_iBlocks[block] == 33 || g_iBlocks[block] == 62 || g_iBlocks[block] == 91)
		{
		} else if (g_iBlocks[block] == 4 || g_iBlocks[block] == 34 || g_iBlocks[block] == 63 || g_iBlocks[block] == 92)
		{
		} else if (g_iBlocks[block] == 5 || g_iBlocks[block] == 35 || g_iBlocks[block] == 64 || g_iBlocks[block] == 93)
		{
		} else if (g_iBlocks[block] == 6 || g_iBlocks[block] == 36 || g_iBlocks[block] == 65 || g_iBlocks[block] == 94)
		{
		} else if (g_iBlocks[block] == 7 || g_iBlocks[block] == 37 || g_iBlocks[block] == 66 || g_iBlocks[block] == 95)
		{
		} else if (g_iBlocks[block] == 8 || g_iBlocks[block] == 38 || g_iBlocks[block] == 67 || g_iBlocks[block] == 96)
		{
		}
		else if (g_iBlocks[block] == 9 || g_iBlocks[block] == 29 || g_iBlocks[block] == 58 || g_iBlocks[block] == 87) // DEATHBLOCK
		{
			if (IsClientInGame(client) && IsPlayerAlive(client))
			{
				if (!g_bInv[client]) {
					if (GetEntityFlags(client) & FL_ONGROUND) {
						SDKHooks_TakeDamage(client, 0, 0, 10000.0);
					}
				}
			}
		}
		else if (g_iBlocks[block] == 10 || g_iBlocks[block] == 39 || g_iBlocks[block] == 68 || g_iBlocks[block] == 97)
		{
		} else if (g_iBlocks[block] == 11 || g_iBlocks[block] == 40 || g_iBlocks[block] == 69 || g_iBlocks[block] == 98)
		{
		} else if (g_iBlocks[block] == 12 || g_iBlocks[block] == 41 || g_iBlocks[block] == 70 || g_iBlocks[block] == 99)
		{
		} else if (g_iBlocks[block] == 13 || g_iBlocks[block] == 42 || g_iBlocks[block] == 71 || g_iBlocks[block] == 100)
		{
		} else if (g_iBlocks[block] == 14 || g_iBlocks[block] == 43 || g_iBlocks[block] == 72 || g_iBlocks[block] == 101)
		{
		} else if (g_iBlocks[block] == 15 || g_iBlocks[block] == 44 || g_iBlocks[block] == 73 || g_iBlocks[block] == 102)
		{
		} else if (g_iBlocks[block] == 16 || g_iBlocks[block] == 45 || g_iBlocks[block] == 74 || g_iBlocks[block] == 103)
		{
		} else if (g_iBlocks[block] == 18 || g_iBlocks[block] == 47 || g_iBlocks[block] == 76 || g_iBlocks[block] == 105)
		{
			if (!g_bTriggered[block])
				CreateTimer(g_eBlocks[18][EffectTime], StartNoBlock, block);
			SetEntPropFloat(client, Prop_Send, "m_flStamina", 0.0);
		}
		else if (g_iBlocks[block] == 19 || g_iBlocks[block] == 48 || g_iBlocks[block] == 77 || g_iBlocks[block] == 106)
		{
			g_bNoFallDmg[client] = true;
		}
		else if (g_iBlocks[block] == 20 || g_iBlocks[block] == 49 || g_iBlocks[block] == 78 || g_iBlocks[block] == 107)
		{
			SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 0.4);
		}
		else if (g_iBlocks[block] == 25 || g_iBlocks[block] == 54 || g_iBlocks[block] == 83 || g_iBlocks[block] == 112)
		{
			if (g_bHEgrenadeCanUse[client])
			{
				if (GetClientTeam(client) == 2)
				{
					if (GetClientHEGrenades(client) < 1)
					{
						GivePlayerItem(client, "weapon_hegrenade");
						g_bHEgrenadeCanUse[client] = false;
					}
				}
			}
		}
		else if (g_iBlocks[block] == 26 || g_iBlocks[block] == 55 || g_iBlocks[block] == 84 || g_iBlocks[block] == 113)
		{
			if (g_bFlashbangCanUse[client])
			{
				if (GetClientTeam(client) == 2)
				{
					if (GetClientFlashbangs(client) < 1)
					{
						GivePlayerItem(client, "weapon_flashbang");
						g_bFlashbangCanUse[client] = false;
					}
				}
			}
		}
		else if (g_iBlocks[block] == 27 || g_iBlocks[block] == 56 || g_iBlocks[block] == 85 || g_iBlocks[block] == 114)
		{
			if (g_bSmokegrenadeCanUse[client])
			{
				if (GetClientTeam(client) == 2)
				{
					if (GetClientSmokeGrenades(client) < 1)
					{
						// GivePlayerItem(client, "weapon_smokegrenade");
						GivePlayerItem(client, "weapon_decoy");
						g_bSmokegrenadeCanUse[client] = false;
					}
				}
			}
		}

		return Plugin_Continue;
}

// Thanks for those three stocks to TnTSCS (https://forums.alliedmods.net/showpost.php?p=2242491&postcount=12)

stock GetClientHEGrenades(client)
{
	return GetEntProp(client, Prop_Data, "m_iAmmo", _, HEGrenadeOffset);
}

stock GetClientSmokeGrenades(client)
{
	return GetEntProp(client, Prop_Data, "m_iAmmo", _, SmokegrenadeOffset);
}

stock GetClientFlashbangs(client)
{
	return GetEntProp(client, Prop_Data, "m_iAmmo", _, FlashbangOffset);
}

public Action:OnEndTouch(block, client)
{
	if (g_iTeleporters[block] != -1) {
		return Plugin_Continue;
	}

	if (!IsClientInGame(client)) {
		return Plugin_Continue;
	}

	g_bTouchStartTriggered[client] = false;

	decl Float:block_loc[3]
	GetEntPropVector(block, Prop_Send, "m_vecOrigin", block_loc);

	decl Float:player_loc[3]
	GetClientAbsOrigin(client, player_loc)

	player_loc[2] += TrueForce;
	if (!(player_loc[2] <= block_loc[2]))
	{

		if (g_iBlocks[block] == 1 || g_iBlocks[block] == 31 || g_iBlocks[block] == 89 || g_iBlocks[block] == 60)
		{
		} else if (g_iBlocks[block] == 2 || g_iBlocks[block] == 32 || g_iBlocks[block] == 61 || g_iBlocks[block] == 90)
		{
		} else if (g_iBlocks[block] == 3 || g_iBlocks[block] == 33 || g_iBlocks[block] == 62 || g_iBlocks[block] == 91)
		{
		} else if (g_iBlocks[block] == 4 || g_iBlocks[block] == 34 || g_iBlocks[block] == 63 || g_iBlocks[block] == 92)
		{
		} else if (g_iBlocks[block] == 5 || g_iBlocks[block] == 35 || g_iBlocks[block] == 64 || g_iBlocks[block] == 93)
		{
			g_bNoFallDmg[client] = false;
		} else if (g_iBlocks[block] == 6 || g_iBlocks[block] == 36 || g_iBlocks[block] == 65 || g_iBlocks[block] == 94)
		{
		} else if (g_iBlocks[block] == 7 || g_iBlocks[block] == 37 || g_iBlocks[block] == 66 || g_iBlocks[block] == 95)
		{
		} else if (g_iBlocks[block] == 8 || g_iBlocks[block] == 38 || g_iBlocks[block] == 67 || g_iBlocks[block] == 96)
		{
		} else if (g_iBlocks[block] == 9 || g_iBlocks[block] == 29 || g_iBlocks[block] == 58 || g_iBlocks[block] == 87)
		{
		} else if (g_iBlocks[block] == 10 || g_iBlocks[block] == 39 || g_iBlocks[block] == 68 || g_iBlocks[block] == 97)
		{
		} else if (g_iBlocks[block] == 11 || g_iBlocks[block] == 40 || g_iBlocks[block] == 69 || g_iBlocks[block] == 98)
		{
			g_iGravity[client] = 2;
		} else if (g_iBlocks[block] == 12 || g_iBlocks[block] == 41 || g_iBlocks[block] == 70 || g_iBlocks[block] == 99)
		{
			CreateTimer(0.2, ResetFire, client)

		} else if (g_iBlocks[block] == 13 || g_iBlocks[block] == 42 || g_iBlocks[block] == 71 || g_iBlocks[block] == 100)
		{
		} else if (g_iBlocks[block] == 14 || g_iBlocks[block] == 43 || g_iBlocks[block] == 72 || g_iBlocks[block] == 101)
		{
		} else if (g_iBlocks[block] == 15 || g_iBlocks[block] == 44 || g_iBlocks[block] == 73 || g_iBlocks[block] == 102)
		{
		} else if (g_iBlocks[block] == 16 || g_iBlocks[block] == 45 || g_iBlocks[block] == 74 || g_iBlocks[block] == 103)
		{
		} else if (g_iBlocks[block] == 18 || g_iBlocks[block] == 47 || g_iBlocks[block] == 76 || g_iBlocks[block] == 105)
		{
		} else if (g_iBlocks[block] == 19 || g_iBlocks[block] == 48 || g_iBlocks[block] == 77 || g_iBlocks[block] == 106)
		{
			g_bNoFallDmg[client] = false;
		}
		else if (g_iBlocks[block] == 20 || g_iBlocks[block] == 49 || g_iBlocks[block] == 78 || g_iBlocks[block] == 107)
		{
			CreateTimer(0.2, ResetHoney, client)
		}

		//		if(bRandom)
		//		{
		//			g_iBlocks[block]=24;
		//		}
	}
	CreateTimer(0.01, BlockTouch_End, client);

	return Plugin_Continue;
}

public Action:ResetFire(Handle:timer, any:client)
{
	if (Block_Touching[client] != 12 && Block_Touching[client] != 41 && Block_Touching[client] != 70 && Block_Touching[client] != 99)
	{
		new ent = GetEntPropEnt(client, Prop_Data, "m_hEffectEntity");
		if (IsValidEdict(ent))
			SetEntPropFloat(ent, Prop_Data, "m_flLifetime", 0.0);
	}
}

public Action:BlockTouch_End(Handle:timer, any:client)
{
	Block_Touching[client] = 0;
}

public Action:ResetHoney(Handle:timer, any:client)
{
	if (Block_Touching[client] != 20 && Block_Touching[client] != 49 && Block_Touching[client] != 78 && Block_Touching[client] != 107)
	{
		SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0);
	}
}

public Action:DamagePlayer(Handle:timer, any:pack)
{
	ResetPack(pack);
	new client = ReadPackCell(pack);
	new block = ReadPackCell(pack);

	if(!IsClientInGame(client)
	|| !IsPlayerAlive(client)
	|| Block_Touching[client] != _:DAMAGE) {
		ClearTimer(Block_Timers[client]);
		CloseHandle(pack);
		return Plugin_Handled;
	}

	Block_Timers[client] =
		CreateTimer(g_fPropertyValue[block][1], DamagePlayer, pack);

	if (g_bInv[client])
		return Plugin_Handled;

	/*if (GetClientHealth(client) - 5 > 0)
		SetEntityHealth(client, GetClientHealth(client) - 5);
	else*/
	SDKHooks_TakeDamage(client, 0, 0, g_fPropertyValue[block][0]);

	return Plugin_Handled;
}

public Action:ResetCamouflage(Handle:timer, any:packet)
{
	ResetPack(packet)
	new index = ReadPackCell(packet)
	if (index != RoundIndex)
	{
		KillTimer(timer, true)
		return Plugin_Handled;
	}
	new client = ReadPackCell(packet)

	if (!IsClientInGame(client))
		return Plugin_Stop;
	if (GetClientTeam(client) == 3)
		SetEntityModel(client, "models/player/ctm_gign.mdl");
	else if (GetClientTeam(client) == 2)
		SetEntityModel(client, "models/player/tm_phoenix.mdl");

	PrintToChat(client, "\x03%s\x04 Camouflage has worn off.", CHAT_TAG);
	return Plugin_Stop;
}

public Action:ResetCamCanUse(Handle:timer, any:packet)
{
	ResetPack(packet)
	new index = ReadPackCell(packet)
	if (index != RoundIndex)
	{
		KillTimer(timer, true)
		return Plugin_Handled;
	}
	new client = ReadPackCell(packet)

	if (!IsClientInGame(client))
		return Plugin_Stop;
	g_bCamCanUse[client] = true;
	PrintToChat(client, "\x03%s\x04 Camouflage block cooldown has worn off.", CHAT_TAG);
	return Plugin_Stop;
}

public Action:StartNoBlock(Handle:timer, any:block)
{
	SetEntProp(block, Prop_Data, "m_CollisionGroup", 2);
	SetEntityRenderMode(block, RENDER_TRANSADD);
	if (Block_Transparency[block] > 0)
	{
		SetEntityRenderColor(block, 177, 177, 177, RoundFloat(float(Block_Transparency[block]) * 0.4588));
	}
	else
	{
		SetEntityRenderColor(block, 177, 177, 177, 177);
	}
	CreateTimer(g_fPropertyValue[block][1], CancelNoBlock, block);
	return Plugin_Stop;
}

public Action:CancelNoBlock(Handle:timer, any:block)
{
	SetEntProp(block, Prop_Data, "m_CollisionGroup", 0);
	SetEntityRenderMode(block, RENDER_TRANSCOLOR);
	if (Block_Transparency[block] > 0)
	{
		SetEntityRenderColor(block, 255, 255, 255, Block_Transparency[block]);
	}
	else
	{
		SetEntityRenderColor(block, 255, 255, 255, 255);
	}
	g_bTriggered[block] = false;
	return Plugin_Stop;
}

public Action:HealPlayer(Handle:timer, any:pack)
{
	ResetPack(pack);
	new client = ReadPackCell(pack);
	new block = ReadPackCell(pack);

	if(!IsClientInGame(client)
	|| !IsPlayerAlive(client)
	|| Block_Touching[client] != _:HEALTH) {
		ClearTimer(Block_Timers[client]);
		CloseHandle(pack);
		return Plugin_Handled;
	}

	Block_Timers[client] =
		CreateTimer(g_fPropertyValue[block][1], HealPlayer, pack);

	new health = RoundFloat(g_fPropertyValue[block][0]);

	if (GetClientHealth(client) + health <= 100) {
		SetEntityHealth(client, GetClientHealth(client) + health);
	}
	else {
		SetEntityHealth(client, 100);
	}

	return Plugin_Handled;
}

public Action:ResetNoFall(Handle:timer, any:client)
{
	if (!IsClientInGame(client))
		return Plugin_Stop;
	g_bNoFallDmg[client] = false;
	return Plugin_Stop;
}

public Action:ResetInv(Handle:timer, any:packet)
{
	ResetPack(packet)
	new index = ReadPackCell(packet)
	if (index != RoundIndex)
	{
		KillTimer(timer, true)
		return Plugin_Handled;
	}
	new client = ReadPackCell(packet)
	if (!IsClientInGame(client))
		return Plugin_Stop;
	g_bInv[client] = false;
	PrintToChat(client, "\x03%s\x04 Invincibility has worn off.", CHAT_TAG);
	return Plugin_Stop;
}

public Action:ResetInvCooldown(Handle:timer, any:packet)
{
	ResetPack(packet)
	new index = ReadPackCell(packet)
	if (index != RoundIndex)
	{
		KillTimer(timer, true)
		return Plugin_Handled;
	}
	new client = ReadPackCell(packet)
	if (!IsClientInGame(client))
		return Plugin_Stop;
	g_bInvCanUse[client] = true;
	PrintToChat(client, "\x03%s\x04 Invincibility block cooldown has worn off.", CHAT_TAG);
	return Plugin_Stop;
}

public Action:ResetStealth(Handle:timer, any:packet)
{
	ResetPack(packet)

	new index = ReadPackCell(packet)

	if (index != RoundIndex)
	{
		KillTimer(timer, true)
		return Plugin_Handled;
	}

	new client = ReadPackCell(packet)

	if (!IsClientInGame(client))
		return Plugin_Stop;
	SetEntityRenderMode(client, RENDER_NORMAL);
	SDKUnhook(client, SDKHook_SetTransmit, Stealth_SetTransmit)
	PrintToChat(client, "\x03%s\x04 Stealth has worn off.", CHAT_TAG);
	return Plugin_Stop;
}

public Action:ResetStealthCooldown(Handle:timer, any:packet)
{
	ResetPack(packet)
	new index = ReadPackCell(packet)
	if (index != RoundIndex)
	{
		KillTimer(timer, true)
		return Plugin_Handled;
	}
	new client = ReadPackCell(packet)
	if (!IsClientInGame(client))
		return Plugin_Stop;
	g_bStealthCanUse[client] = true;
	PrintToChat(client, "\x03%s\x04 Stealth block cooldown has worn off.", CHAT_TAG);
	return Plugin_Stop;
}

//public Action:ResetRandom(Handle:timer, any:packet)
//{
//	ResetPack(packet)
//	new index = ReadPackCell(packet)
//	if(index != RoundIndex)
//	{
//		KillTimer(timer, true)
//		return Plugin_Handled;
//	}
//	new client = ReadPackCell(packet)
//
//	if(!IsClientInGame(client))
//		return Plugin_Stop;
//	g_iClientBlocks[client]=-1;
//	return Plugin_Stop;
//}

public Action:ResetBoots(Handle:timer, any:packet)
{
	ResetPack(packet)
	new index = ReadPackCell(packet)
	if (index != RoundIndex)
	{
		KillTimer(timer, true)
		return Plugin_Handled;
	}
	new client = ReadPackCell(packet)

	if (!IsClientInGame(client))
		return Plugin_Stop;
	SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0);
	//	PrintToChat(client, "\x03%s\x04 Boots of Speed has worn off.", CHAT_TAG);
	return Plugin_Stop;
}

public Action:ResetBootsCooldown(Handle:timer, any:packet)
{
	ResetPack(packet)
	new index = ReadPackCell(packet)
	if (index != RoundIndex)
	{
		KillTimer(timer, true)
		return Plugin_Handled;
	}
	new client = ReadPackCell(packet)

	if (!IsClientInGame(client))
		return Plugin_Stop;

	g_bBootsCanUse[client] = true;
	PrintToChat(client, "\x03%s\x04 Boots of Speed block cooldown has worn off.", CHAT_TAG);
	return Plugin_Stop;
}

public Action:BoostPlayer(Handle:timer, any:pack)
{
	ResetPack(pack)
	new client = ReadPackCell(pack)
	new block = ReadPackCell(pack)

	new Float:fAngles[3];
	GetClientEyeAngles(client, fAngles);

	new Float:fVelocity[3];
	GetAngleVectors(fAngles, fVelocity, NULL_VECTOR, NULL_VECTOR);

	NormalizeVector(fVelocity, fVelocity);

	ScaleVector(fVelocity, g_fPropertyValue[block][1]);
	fVelocity[2] = g_fPropertyValue[block][0];
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, fVelocity);
	return Plugin_Stop;
}

public Action:JumpPlayer(Handle:timer, any:pack)
{
	ResetPack(pack)
	new client = ReadPackCell(pack)
	new block = ReadPackCell(pack)

	new Float:fAngles[3];
	GetClientEyeAngles(client, fAngles);

	new Float:fVelocity[3];
	GetAngleVectors(fAngles, fVelocity, NULL_VECTOR, NULL_VECTOR);

	GetEntPropVector(client, Prop_Data, "m_vecVelocity", fVelocity);

	fVelocity[0] *= 1.15;
	fVelocity[1] *= 1.15;
	fVelocity[2] = g_fPropertyValue[block][0];

	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, fVelocity);

	return Plugin_Stop;
}

public Action:SlapPlayerBlock(Handle:timer, any:client)
{
	SlapPlayer(client, 5);
	new Float:fVelocity[3];
	fVelocity[0] = float(GetRandomInt(-100, 100));
	fVelocity[1] = float(GetRandomInt(-100, 100));
	fVelocity[2] = float(GetRandomInt(260, 360));
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, fVelocity);
	return Plugin_Stop;
}

public Handler_Teleport(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		if (param2 == 0)
		{
			if (g_iCurrentTele[client] == -1)
				CreateTeleportEntrance(client);
			else
			{
				if (IsValidEdict(g_iCurrentTele[client]))
					AcceptEntityInput(g_iCurrentTele[client], "Kill");
				g_iCurrentTele[client] = -1;
			}
		} else if (param2 == 1)
		{
			if (g_iCurrentTele[client] == -1)
				PrintToChat(client, "\x03%s\x04 You must create an entrance first", CHAT_TAG);
			else
			{
				g_iTeleporters[g_iCurrentTele[client]] = CreateTeleportExit(client);
				g_iCurrentTele[client] = -1;
			}
		} else if (param2 == 2)
		{
			new ent = GetClientAimTarget(client, false);
			new entrance = -1;
			new hexit = -1;
			if (g_iTeleporters[ent] >= 1)
			{
				if (g_iTeleporters[ent] > 1)
				{
					entrance = ent;
					hexit = g_iTeleporters[ent];
				}
				else
				{
					for (new i = MaxClients + 1; i < 2048; ++i)
					{
						if (g_iTeleporters[i] == ent)
						{
							hexit = ent;
							entrance = i;
							break;
						}
					}
				}

				if (entrance > 0 && hexit > 0)
				{
					if (IsValidBlock(entrance) && IsValidBlock(hexit))
					{
						SetEntityModel(entrance, "models/platforms/r-tele.mdl");
						SetEntityModel(hexit, "models/platforms/b-tele.mdl");
						g_iTeleporters[entrance] = 1;
						g_iTeleporters[hexit] = entrance;
					}
				}
			}
		} else if (param2 == 3)
		{
			new ent = GetClientAimTarget(client, false);
			if (IsValidBlock(ent))
			{
				AcceptEntityInput(ent, "Kill");
				g_iBlocks[ent] = -1;
				if (g_iTeleporters[ent] >= 1)
				{
					if (g_iTeleporters[ent] > 1 && IsValidBlock(g_iTeleporters[ent]))
					{
						AcceptEntityInput(g_iTeleporters[ent], "Kill");
						g_iTeleporters[g_iTeleporters[ent]] = -1;
					} else if (g_iTeleporters[ent] == 1)
					{
						for (new i = MaxClients + 1; i < 2048; ++i)
						{
							if (g_iTeleporters[i] == ent)
							{
								if (IsValidBlock(i))
									AcceptEntityInput(i, "Kill");
								g_iTeleporters[i] = -1;
								break;
							}
						}
					}

					g_iTeleporters[ent] = -1;
				}
			}
		} else if (param2 == 4)
		{
			new ent = GetClientAimTarget(client, false);
			if (ent != -1)
			{
				new entrance = -1;
				new hexit = -1;
				if (g_iTeleporters[ent] >= 1)
				{
					if (g_iTeleporters[ent] > 1)
					{
						entrance = ent;
						hexit = g_iTeleporters[ent];
					}
					else
					{
						for (new i = MaxClients + 1; i < 2048; ++i)
						{
							if (g_iTeleporters[i] == ent)
							{
								hexit = ent;
								entrance = i;
								break;
							}
						}
					}
					if (entrance > 0 && hexit > 0)
					{
						if (IsValidBlock(entrance) && IsValidBlock(hexit))
						{
							new color[4] =  { 255, 0, 0, 255 };
							new Float:pos1[3], Float:pos2[3];
							GetEntPropVector(entrance, Prop_Data, "m_vecOrigin", pos1);
							GetEntPropVector(hexit, Prop_Data, "m_vecOrigin", pos2);
							TE_SetupBeamPoints(pos2, pos1, g_iBeamSprite, 0, 0, 40, 15.0, 20.0, 20.0, 25, 0.0, color, 10);
							TE_SendToClient(client);
						}
					}
				}
			}
			else
			{
				PrintToChat(client, "\x03%s\x04 You must aim at a teleporter first", CHAT_TAG);
			}
		}
		DisplayMenu(CreateTeleportMenu(client), client, 0);
	}
	else if ((action == MenuAction_Cancel) && (param2 == MenuCancel_ExitBack))
		DisplayMenu(CreateMainMenu(client), client, 0);
}

public Handler_Blocks(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		g_iBlockSelection[client] = param2;
		//PrintToChat(client, "%sYou have selected block \x03%s\x04.", CHAT_TAG, g_eBlocks[param2][BlockName]);
		DisplayMenu(CreateMainMenu(client), client, 0);
	}
	else if ((action == MenuAction_Cancel) && (param2 == MenuCancel_ExitBack))
		DisplayMenu(CreateMainMenu(client), client, 0);
}

public Handler_Options(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new bool:bDontDisplay = false;
		if (param2 == 0)
		{
			g_bSnapping[client] = !g_bSnapping[client];
		}
		else if (param2 == 1)
		{
			if (g_fSnappingGap[client] < 100.0)
				g_fSnappingGap[client] += 5.0;
			else
				g_fSnappingGap[client] = 0.0;
		}
		else if (param2 == 2)
		{
			new ent = GetClientAimTarget(client, false);
			if (IsValidBlock(ent))
				g_bGroups[client][ent] = true;
		} else if (param2 == 3)
		{
			for (new i = 0; i < 2048; ++i)
			g_bGroups[client][i] = false;
		} else if (param2 == 4)
		{
			LoadBlocks_Menu(client);
			bDontDisplay = true;
		} else if (param2 == 5)
		{
			SaveBlocks_Menu(client);
			bDontDisplay = true;
		} else if (param2 == 6)
		{
			for (new i = MaxClients + 1; i < 2048; ++i)
			{
				if (g_iBlocks[i] != -1)
				{
					if (IsValidBlock(i))
					{
						AcceptEntityInput(i, "Kill");
					}
					g_iBlocks[i] = -1;
				}
			}
		} else if (param2 == 7)
		{
			for (new i = MaxClients + 1; i < 2048; ++i)
			{
				if (g_iTeleporters[i] != -1)
				{
					if (IsValidBlock(i))
					{
						AcceptEntityInput(i, "Kill");
					}
					g_iTeleporters[i] = -1;
				}
			}
		}
		if (!bDontDisplay)
		{
			DisplayMenu(CreateOptionsMenu(client), client, 0);
		}
	}
	else if ((action == MenuAction_Cancel) && (param2 == MenuCancel_ExitBack))
		DisplayMenu(CreateMainMenu(client), client, 0);
}

stock SaveBlocks_Menu(client)
{
	new Handle:menu = CreateMenu(SaveBlocks_Handler, MenuAction_Select | MenuAction_End | MenuAction_DisplayItem);
	SetMenuTitle(menu, "Block Builder - Save Blocks?");
	AddMenuItem(menu, "X", "Are you sure you want to save blocks?", ITEMDRAW_DISABLED)
	AddMenuItem(menu, "1", "Yes!")
	AddMenuItem(menu, "2", "No!")

	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public SaveBlocks_Handler(Handle:menu, MenuAction:action, client, param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			decl String:item[64];
			GetMenuItem(menu, param2, item, sizeof(item));

			new option = StringToInt(item)
			if (option == 1)
			{
				SaveBlocks(true)
			}
			else
			{
				DisplayMenu(CreateOptionsMenu(client), client, 0);
			}
		}
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
	}
}


stock LoadBlocks_Menu(client)
{
	new Handle:menu = CreateMenu(LoadBlocks_Handler, MenuAction_Select | MenuAction_End | MenuAction_DisplayItem);
	SetMenuTitle(menu, "Block Builder - Load Blocks?");
	AddMenuItem(menu, "X", "Are you sure you want to load blocks?", ITEMDRAW_DISABLED)
	AddMenuItem(menu, "1", "Yes!")
	AddMenuItem(menu, "2", "No!")

	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public LoadBlocks_Handler(Handle:menu, MenuAction:action, client, param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			decl String:item[64];
			GetMenuItem(menu, param2, item, sizeof(item));

			new option = StringToInt(item)
			if (option == 1)
			{
				LoadBlocks(true)
			}
			else
			{
				DisplayMenu(CreateOptionsMenu(client), client, 0);
			}
		}
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
	}
}

bool:IsValidBlock(ent)
{
	if (MaxClients < ent < 2048)
		if ((g_iBlocks[ent] != -1 || g_iTeleporters[ent] != -1) && IsValidEdict(ent))
		return true;
	return false;
}

stock FakePrecacheSound(const String:szPath[])
{
	AddToStringTable(FindStringTable("soundprecache"), szPath);
}

stock GetCurrentWorkshopMap(String:szMap[], iMapBuf, String:szWorkShopID[], iWorkShopBuf)
{
	decl String:szCurMap[128];
	decl String:szCurMapSplit[2][64];

	GetCurrentMap(szCurMap, sizeof(szCurMap));

	ReplaceString(szCurMap, sizeof(szCurMap), "workshop/", "", false);

	ExplodeString(szCurMap, "/", szCurMapSplit, 2, 64);

	strcopy(szMap, iMapBuf, szCurMapSplit[1]);
	strcopy(szWorkShopID, iWorkShopBuf, szCurMapSplit[0]);
}


/** Objects can't be targeted through walls with this one.
	Thanks AlliedModders! */
GetClientAimTarget2(client, bool:only_clients = true)
{
	new Float:eyeloc[3], Float:ang[3];
	GetClientEyePosition(client, eyeloc);
	GetClientEyeAngles(client, ang);
	TR_TraceRayFilter(eyeloc, ang, MASK_SOLID, RayType_Infinite, TRFilter_AimTarget, client);
	new entity = TR_GetEntityIndex();

	if (only_clients)
	{
		if (entity >= 1 && entity <= 64)
			return entity;
	}
	else
	{
		if (entity > 0)
			return entity;
	}

	return -1;
}

public bool:TRFilter_AimTarget(entity, mask, any:client)
{
	if (entity == client)
		return false;
	return true;
}

public StartGrabbing(client, ent) {
	if(!IsValidBlock(ent))
		return;

	g_iDragEnt[client] = ent;
	g_iLastDragEnt[client] = ent;

	if (g_bGroups[client][g_iDragEnt[client]])
	{
		for (new i = 0; i < 2048; ++i)
		{
			if (IsValidBlock(i) && g_bGroups[client][i])
			{
				//SetEntityMoveType(i, MOVETYPE_VPHYSICS);
				AcceptEntityInput(i, "enablemotion");
			}
		}
	}
	else
	{
		decl Float:VecPos_grabbed[3], Float:VecPos_client[3];

		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", VecPos_grabbed);
		GetClientEyePosition(client, VecPos_client);

		g_fGrabOffset[client] = GetVectorDistance(VecPos_grabbed, VecPos_client);

		AcceptEntityInput(g_iDragEnt[client], "enablemotion");
	}
}

public StopGrabbing(client, ent) {
	new Float:fVelocity[3] =  { 0.0, 0.0, 0.0 };

	TeleportEntity(g_iDragEnt[client], NULL_VECTOR, g_fAngles[g_iDragEnt[client]], fVelocity);

	if (g_bGroups[client][g_iDragEnt[client]])
	{
		for (new i = 0; i < 2048; ++i)
		{
			if (IsValidBlock(i) && g_bGroups[client][i])
			{
				SetEntityMoveType(i, MOVETYPE_NONE);
				AcceptEntityInput(i, "disablemotion");
			}
		}
	}
	else
	{
		SetEntityMoveType(g_iDragEnt[client], MOVETYPE_NONE);
		AcceptEntityInput(g_iDragEnt[client], "disablemotion");
	}
	g_iDragEnt[client] = 0;
}

public SetDefaultProperty(block) {
	new blocktype = g_iBlocks[block];

	g_bTopOnly[block] = g_bTopOnlyDefault[blocktype];

	for(new i = 0; i < MAXPROPERTIES; i++) {
		g_fPropertyValue[block][i] = g_fPropertyDefault[blocktype][i];
	}
}

stock ClearTimer(&Handle:timer)
{
    if (timer != INVALID_HANDLE)
    {
        KillTimer(timer);
    }
    timer = INVALID_HANDLE;
}
