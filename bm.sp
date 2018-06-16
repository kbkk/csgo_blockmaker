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
#include <cstrike>
//#include <mm>

#define CHAT_TAG "[TeamMates]"
#define PREFIX "\x03[TeamMates]\x04 "
#define MESS "[TeamMates] %s"

#define ALL_WEAPONS 33

new const String:g_sWeapons[ALL_WEAPONS][] = {
	"weapon_ak47", "weapon_revolver", "weapon_aug", "weapon_bizon", "weapon_deagle", "weapon_awp", "weapon_elite", "weapon_famas", "weapon_fiveseven", "weapon_cz75a",
	"weapon_g3sg1", "weapon_galilar", "weapon_glock", "weapon_hkp2000", "weapon_usp_silencer", "weapon_m249", "weapon_m4a1",
	"weapon_mac10", "weapon_mag7", "weapon_mp7", "weapon_mp9", "weapon_negev", "weapon_nova", "weapon_p250", "weapon_p90", "weapon_sawedoff",
	"weapon_scar20", "weapon_sg556", "weapon_ssg08", "weapon_taser", "weapon_tec9", "weapon_ump45", "weapon_xm1014"
};

new g_iWeaponSlot[ALL_WEAPONS] = {
	CS_SLOT_PRIMARY, CS_SLOT_SECONDARY, CS_SLOT_PRIMARY, CS_SLOT_PRIMARY, CS_SLOT_SECONDARY, CS_SLOT_PRIMARY, CS_SLOT_SECONDARY, CS_SLOT_PRIMARY, CS_SLOT_SECONDARY, CS_SLOT_SECONDARY,
	CS_SLOT_PRIMARY, CS_SLOT_PRIMARY, CS_SLOT_SECONDARY, CS_SLOT_SECONDARY, CS_SLOT_SECONDARY, CS_SLOT_PRIMARY, CS_SLOT_PRIMARY,
	CS_SLOT_PRIMARY, CS_SLOT_PRIMARY, CS_SLOT_PRIMARY, CS_SLOT_PRIMARY, CS_SLOT_PRIMARY, CS_SLOT_PRIMARY, CS_SLOT_SECONDARY, CS_SLOT_PRIMARY, CS_SLOT_PRIMARY,
	CS_SLOT_PRIMARY, CS_SLOT_PRIMARY, CS_SLOT_PRIMARY, CS_SLOT_KNIFE, CS_SLOT_SECONDARY, CS_SLOT_PRIMARY, CS_SLOT_PRIMARY
};

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
	MONEY,
	HONEY,
	CAMOUFLAGE,
	WEAPON,
	AWP,
	RANDOM,
	HE,
	FLASH,
	FROST,
	BUNNYHOP_DELAYED,
	KEY,
	LOCK
}

new const String:BlockNames[_:BlockTypes][] = {
	"Platform",
	"Bunnyhop",
	"Damage",
	"Health",
	"ICE",
	"Trampoline",
	"Speedboost",
	"Invincibility",
	"Stealth",
	"Death",
	"GRAVITY",
	"CT Barrier",
	"T Barrier",
	"Boots of Speed",
	"GLASS",
	"Bunnyhop No Slow Down",
	"Money",
	"Honey",
	"CAMOUFLAGE",
	"WEAPON",
	"AWP",
	"RANDOM",
	"HE",
	"FLASH",
	"Frost",
	"Delayed Bunnyhop",
	"Key",
	"Lock"
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
	{"Kills with godmode", "", ""},
	{"Gravity ratio", "", ""},
	{"Trigger delay", "Cooldown", ""},
	{"Trigger delay", "Cooldown", ""},
	{"Time", "Cooldown", "Speed"},
	{"", "", ""},
	{"Trigger delay", "Cooldown", ""},
	{"Money", "", ""},
	{"", "", ""},
	{"", "", ""},
	{"Weapon", "", ""},
	{"", "", ""},
	{"", "", ""},
	{"", "", ""},
	{"", "", ""},
	{"", "", ""},
	{"Trigger delay", "Cooldown", ""},
	{"Gives key", "", ""},
	{"Required key", "", ""},
};

new const Float:g_fPropertyDefault[_:BlockTypes][MAXPROPERTIES] = {
	{0.0, 0.0, 0.0},
	{0.1, 1.0, 0.0},
	{1.0, 0.5, 0.0},
	{1.0, 0.5, 0.0},
	{0.0, 0.0, 0.0},
	{300.0, 0.0, 0.0},
	{300.0, 300.0, 0.0},
	{10.0, 60.0, 0.0},
	{10.0, 60.0, 0.0},
	{0.0, 0.0, 0.0},
	{0.75, 0.0, 0.0},
	{0.0, 1.0, 0.0},
	{0.0, 1.0, 0.0},
	{10.0, 60.0, 320.0},
	{0.0, 0.0, 0.0},
	{0.0, 0.0, 0.0},
	{40.0, 0.0, 0.0},
	{0.0, 0.0, 0.0},
	{0.0, 0.0, 0.0},
	{0.0, 0.0, 0.0},
	{0.0, 0.0, 0.0},
	{0.0, 0.0, 0.0},
	{0.0, 0.0, 0.0},
	{0.0, 0.0, 0.0},
	{0.0, 0.0, 0.0},
	{1.0, 1.0, 0.0},
	{0.0, 0.0, 0.0},
	{0.0, 0.0, 0.0},
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
	0,
	1,
	1
};

bool g_bTopOnly[2048];
float g_fPropertyValue[2048][MAXPROPERTIES];

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

enum e_Effect {
	bool:active,
	bool:canUse,
	Float:endTime,
	Float:cooldownEndTime,
	Handle:timerEnd,
	Handle:timerCdEnd
}

enum e_PlayerEffects {
	Stealth,
	Invincibility,
	BootsOfSpeed
}

new g_PlayerEffects[MAXPLAYERS + 1][e_PlayerEffects][e_Effect];
new const String:g_PlayerEffectsNames[e_PlayerEffects][] = {
	"Stealth",
	"Invincibility",
	"Boots of Speed"
};

new const String:FULL_INVI_SOUND_PATH[] = 	"sound/teammates/invincibility.mp3";
new const String:REL_INVI_SOUND_PATH[] = 	"*teammates/invincibility.mp3";

new const String:FULL_STEALTH_SOUND_PATH[] = "sound/teammates/stealth.mp3";
new const String:REL_STEALTH_SOUND_PATH[] =  "*teammates/stealth.mp3";

new const String:FULL_BOS_SOUND_PATH[] = "sound/teammates/bootsofspeed.mp3";
new const String:REL_BOS_SOUND_PATH[] = "*teammates/bootsofspeed.mp3";

new const String:FULL_TELE_SOUND_PATH[] = "sound/teammates/teleport.mp3";
new const String:REL_TELE_SOUND_PATH[] = "*teammates/teleport.mp3";

new const String:FULL_MONEY_SOUND_PATH[] = "sound/teammates/money.mp3";
new const String:REL_MONEY_SOUND_PATH[] = "*teammates/money.mp3";


bool g_bTouchStartTriggered[MAXPLAYERS + 1];

new g_iClCurrentBlock[MAXPLAYERS + 1]; // current block client is inputting property for
new g_iClInputting[MAXPLAYERS + 1] = {-1, ...}; //client is inputting a property (number)

new g_iClBlockSize[MAXPLAYERS + 1]; // client's selected block size

new g_iDragEnt[MAXPLAYERS + 1];
new g_iLastDragEnt[MAXPLAYERS + 1];

int g_iBlockSelection[MAXPLAYERS + 1] =  { 0, ... };
int g_iBlocks[2048] =  { -1, ... };
int g_iBlocksSize[2048] =  { -1, ... };
int g_iTeleporters[2048] =  { -1, ... };

new g_iCurrentTele[MAXPLAYERS + 1] =  { -1, ... };
new g_iBeamSprite = 0;
new CurrentModifier[MAXPLAYERS + 1] = 0

new Block_Transparency[2048] = 0
new Float:g_fGrabOffset[MAXPLAYERS + 1];

bool g_bNoFallDmg[MAXPLAYERS + 1] =  { false, ... };
bool g_bLocked[MAXPLAYERS + 1] =  { false, ... };
bool g_bTriggered[2048] =  { false, ... };
bool g_bCamCanUse[MAXPLAYERS + 1] =  { true, ... };
bool g_bAwpCanUse[MAXPLAYERS + 1] =  { true, ... };
bool g_bHEgrenadeCanUse[MAXPLAYERS + 1] =  { true, ... };
bool g_bFlashbangCanUse[MAXPLAYERS + 1] =  { true, ... };
bool g_bSmokegrenadeCanUse[MAXPLAYERS + 1] =  { true, ... };
bool g_bWeaponUsed[MAXPLAYERS + 1][ALL_WEAPONS];

bool g_bSnapping[MAXPLAYERS + 1] =  { false, ... };
bool g_bGroups[MAXPLAYERS + 1][2048];
ArrayList g_PlayerKeys[MAXPLAYERS + 1];
StringMap g_Lock[2048];


//GHOST
new g_Collision;
bool g_bGhost[MAXPLAYERS + 1];

bool g_bCanUseMoney[MAXPLAYERS + 1] = {true, ...};

Handle Block_Timers[64] = {INVALID_HANDLE, ...};
bool Block_Touching[MAXPLAYERS + 1][2048];


float g_fSnappingGap[MAXPLAYERS + 1] =  { 0.0, ... };
float g_fClientAngles[MAXPLAYERS + 1][3];
float g_fAngles[2048][3];

// Skriv antal blocks!
new g_eBlocks[35][BlockConfig];

Handle g_hClientMenu[MAXPLAYERS + 1];
Handle g_hBlocksKV = INVALID_HANDLE;
Handle g_hTeleSound = INVALID_HANDLE;

new RoundIndex = 0; // Quite lazy way yet effective one

static const Float:g_fBlockSizes[4][2][3] = {
	{{-32.25, -32.22, -4.21}, {32.25, 32.22, 4.21}},
	{{-4.25, -32.25, -4.25}, {4.25, 32.25, 4.25}},
	{{-15.97, -16.00, -3.97}, {15.97, 16.00, 3.97}},
	{{-64.25, -64.18, -4.21}, {64.25, 64.18, 4.21}}
};

static const Float:g_fBlockSizes2[4][2][3] = {
	{{-32.25, -4.21, -32.22}, {32.25, 4.21, 32.22}},
	{{-32.25, -4.25, -4.25}, {32.25, 4.25, 4.25}},
	{{-15.97, -3.97, -16.00}, {15.97, 3.97, 16.00}},
	{{-64.25, -4.21, -64.18}, {64.25, 4.21, 64.18}}
};

static const Float:g_fBlockSizes3[4][2][3] = {
	{{-4.21, -32.25, -32.22}, {4.21, 32.25, 32.22}},
	{{-4.25, -4.25, -32.25}, {4.25, 4.25, 32.25}},
	{{-3.97, -15.97, -16.00}, {3.97, 15.97, 16.00}},
	{{-4.21, -64.25, -64.18}, {4.21, 64.25, 64.18}}
};

#include "bm/bm_propmenu"
#include "bm/bm_readonlyproppanel"

#include "bm/bm_cpmenu"

#include "bm/effects/invincibility"
#include "bm/effects/bootsofspeed"

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
	g_Collision = FindSendPropInfo("CBaseEntity", "m_CollisionGroup");

	g_hTeleSound = CreateConVar("sm_blockbuilder_telesound", "blockbuilder/teleport.mp3");

	//
	//	ADMIN FLAG "O" FOR USING BLOCKMAKER
	//	ADMIN FLAG "P" FOR SAVING AND LOADING
	//

	//	RegConsoleCmd("sm_bb", Command_BlockBuilder);
	RegAdminCmd("sm_bb", Command_BlockBuilder, ADMFLAG_CUSTOM1);
	RegAdminCmd("sm_prop", Command_BlockProperty, ADMFLAG_CUSTOM1);
	RegAdminCmd("sm_cp", Command_CheckpointMenu, ADMFLAG_CUSTOM1);
	//	RegConsoleCmd("sm_bsave", Command_SaveBlocks);
	RegAdminCmd("sm_bsave", Command_SaveBlocks, ADMFLAG_CUSTOM2);
	RegAdminCmd("sm_blocksnap", Command_BlockSnap, ADMFLAG_CUSTOM1);
	RegAdminCmd("sm_snapgrid", Command_SnapGrid, ADMFLAG_CUSTOM1);
	RegAdminCmd("sm_del", Command_DeleteLastGrabbed, ADMFLAG_CUSTOM1);
	RegAdminCmd("+grab", Command_GrabBlock, ADMFLAG_CUSTOM1);
	RegAdminCmd("-grab", Command_ReleaseBlock, ADMFLAG_CUSTOM1);
	RegAdminCmd("tgrab", Command_ToggleGrab, ADMFLAG_CUSTOM1);

	RegAdminCmd("sm_setdeath1", SetAllDeathsKillWithGod, ADMFLAG_CUSTOM2);

	AddCommandListener(OnSayCmd, "say");
	AddCommandListener(OnSayCmd, "say_team");

	//GHOST
	RegConsoleCmd("sm_ghost", Command_Ghost);
	AddNormalSoundHook(OnNormalSoundPlayed);
	HookEvent("player_spawn", Event_PlayerSpawn);

	HookEvent("round_start", RoundStart);
	HookEvent("round_end", RoundEnd);

	AutoExecConfig();

	new String:file[256];
	BuildPath(Path_SM, file, sizeof(file), "configs/blockbuilder.blocks.txt");

	new Handle:kv = CreateKeyValues("Blocks");
	FileToKeyValues(kv, file);

	if (!KvGotoFirstSubKey(kv))
	{
		PrintToServer("[BlockMaker] The config file seems to be empty :O");
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

	for(int client = 1; client <= MaxClients; client++) {
		g_PlayerKeys[client] = new ArrayList();
	}
}

public void OnClientPostAdminCheck(client) {
    SDKHookEx(client, SDKHook_StartTouch, StartTouch);
}

public Action:StartTouch(client, victim)
{
    if(!g_bGhost[client] && 0 < victim <= MaxClients && GetClientTeam(victim) != GetClientTeam(client))
    {
        new ground = GetEntPropEnt(client, Prop_Send, "m_hGroundEntity");

        if(ground == victim
		&& GetEntityFlags(victim) & FL_ONGROUND){
			SDKHooks_TakeDamage(victim, client, client, 8.0);
		}
	}
}

public Action:Event_PlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	//SDKHook(client, SDKHook_SetTransmit, Hook_SetTransmit);

	if(g_bGhost[client]) {
		g_bGhost[client] = false;
		GhostUnhook(client);
	}
}

public Action:Command_Ghost(client, args)
{
	MakePlayerGhost(client);
}

public Action:OnTraceAttack(victim, &attacker, &inflictor, &Float:damage, &damagetype, &ammotype, hitbox, hitgroup)
{
	if(IsValidEntity(victim) && g_bGhost[victim])
		return Plugin_Handled;

	return Plugin_Continue;
}

public Action:OnWeaponCanUse(client, weapon)
{
	return g_bGhost[client] ? Plugin_Handled : Plugin_Continue;
}

public Action:OnNormalSoundPlayed(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags)
{
	if(entity && entity <= MaxClients && g_bGhost[entity])
		return Plugin_Handled;

	return Plugin_Continue;
}

GhostUnhook(client)
{
	SDKUnhook(client, SDKHook_TraceAttack, OnTraceAttack);
	SDKUnhook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
}

MakePlayerGhost(client)
{
	if(IsPlayerAlive(client) || GetClientTeam(client) <= 1)
	{
		PrintToChat(client, "%s\x06You must be dead to use\x04 !ghost\x06!", PREFIX);
		return;
	}

	g_bGhost[client] = false;
	CS_RespawnPlayer(client);
	g_bGhost[client] = true;

	new weaponIndex;
	for (new i = 0; i <= 3; i++)
	{
		if ((weaponIndex = GetPlayerWeaponSlot(client, i)) != -1)
		{
			RemovePlayerItem(client, weaponIndex);
			RemoveEdict(weaponIndex);
		}
	}

	SetEntProp(client, Prop_Send, "m_lifeState", 1);
	SetEntData(client, g_Collision, 2, 4, true);
	SetEntProp(client, Prop_Data, "m_ArmorValue", 0);
	SetEntProp(client, Prop_Send, "m_bHasDefuser", 0);

	SDKHook(client, SDKHook_TraceAttack, OnTraceAttack);
	SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);

	//unhook on round start for perfomance

	PrintToChat(client, "%s\x06You are a\x04 !ghost\x06 now!", PREFIX);
}

public Action:Command_BlockProperty(client, args)
{
	new ent = GetClientAimTarget2(client, false);

	if(!IsValidBlock(ent))
		return;

	g_iClCurrentBlock[client] = ent;
	ShowPropertyMenu(client);
}

public Action:Command_CheckpointMenu(client, args)
{
	ShowCheckpointMenu(client);
}

public Action:OnSayCmd(client, const String:command[], argc)
{
	if(g_iClInputting[client] == -1)
		return Plugin_Continue;

	decl String:arg[8];
	GetCmdArg(1, arg, sizeof(arg));

	if(!IsCharNumeric(arg[0])) {
		PrintToChat(client, "%s Wrong value detected. Property inputting canceled.", PREFIX);
		g_iClInputting[client] = -1;
		return Plugin_Continue;
	}

	if(!IsValidBlock(g_iClCurrentBlock[client])) {
		PrintToChat(client, "%s Couldn't input property. Block is NOT valid.", PREFIX);
		return Plugin_Handled;
	}

	new block = g_iClCurrentBlock[client];
	new blocktype = g_iBlocks[block];
	new propnum = g_iClInputting[client];

	float newval = StringToFloat(arg);

	if(blocktype == _:LOCK && g_Lock[block] != null && propnum >= 100) {
		if(propnum == 2137) {
			int newType = RoundFloat(newval);
			if(newType < 0 || newType > _:LOCK) {
				PrintToChat(client, "%s\x04 invalid block number", PREFIX);
				return Plugin_Continue;
			}

			g_Lock[block].SetValue("blocktype", newType, true);
			PrintToChat(client, "%s\x04 key\x03 block type set to\x04 %s",
			PREFIX, BlockNames[newType]);
		}
		else {
			propnum -= 100;

			float values[3];
			int type;
			g_Lock[block].GetValue("blocktype", type);
			g_Lock[block].GetArray("properties", values, 3);
			values[propnum] = newval;
			g_Lock[block].SetArray("properties", values, 3, true);

			PrintToChat(client, "%s\x03 %s\x04 of\x03 %s\x04 changed to\x03 %.2f",
			PREFIX, g_sPropertyName[type][propnum], BlockNames[type], newval);
		}
	}
	else {
		g_fPropertyValue[block][propnum] = newval;

		PrintToChat(client, "%s\x03 %s\x04 of\x03 %s\x04 changed to\x03 %.2f",
		PREFIX, g_sPropertyName[blocktype][propnum], BlockNames[blocktype], newval);
	}

	g_iClInputting[client] = -1;
	ShowPropertyMenu(client);

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
		for(int i = 0; i < view_as<int>(e_PlayerEffects); i++)
			ResetPlayerEffect(client, e_PlayerEffects:i);

		SDKUnhook(client, SDKHook_OnTakeDamage, INVINCIBLITY_OnTakeDamage);

		if (!IsClientInGame(client))
			continue;

		SetEntityRenderMode(client, RENDER_NORMAL);
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
		g_bLocked[i] = false;
		g_bNoFallDmg[i] = false;
		g_bCamCanUse[i] = true;
		g_bAwpCanUse[i] = true;
		g_bCanUseMoney[i] = true;
		g_PlayerKeys[i].Clear();

		for(int j = 0; j < ALL_WEAPONS; j++)
			g_bWeaponUsed[i][j] = false;

		for(int j = 0; j < 2048; j++)
			Block_Touching[i][j] = false;
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
	g_bCanUseMoney[client] = true;
	g_bLocked[client] = false;
	g_bNoFallDmg[client] = false;
	g_bCamCanUse[client] = true;
	g_bAwpCanUse[client] = true;
	g_bHEgrenadeCanUse[client] = true;
	g_bFlashbangCanUse[client] = true;
	//	g_iClientBlocks[client]=-1;
	g_iCurrentTele[client] = -1;
	g_bSnapping[client] = true;
	g_fSnappingGap[client] = 0.0;

	g_bGhost[client] = false;

	for(int j = 0; j < ALL_WEAPONS; j++)
		g_bWeaponUsed[client][j] = false;

	for (new i = 0; i < 2048; ++i)
		g_bGroups[client][i] = false;

	for(int i = 0; i < view_as<int>(e_PlayerEffects); i++)
		ResetPlayerEffect(client, e_PlayerEffects:i);

	SDKUnhook(client, SDKHook_OnTakeDamage, INVINCIBLITY_OnTakeDamage);

}

public Action DisplayEffectsHud(Handle timer)
{
	char buffer[384];
	float gametime = GetGameTime();
	bool print;

	for (new client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client) || !IsPlayerAlive(client))
			continue;

		print = false;
		buffer[0] = '\0';
		for(int i = 0; i < view_as<int>(e_PlayerEffects); i++)
		{
			if(g_PlayerEffects[client][e_PlayerEffects:i][active])
			{
				print = true;

				Format(buffer, sizeof(buffer), "%s%s: %.1f <br>",
					buffer, g_PlayerEffectsNames[e_PlayerEffects:i],
					g_PlayerEffects[client][e_PlayerEffects:i][endTime] - gametime);
			}
		}

		if(print)
		{
			Format(buffer, sizeof(buffer), "<font color='#47BEE6'>Team-Mates</font><br>%s", buffer);
			PrintHintText(client, buffer);
		}

	}

}

public OnMapStart()
{
	CreateTimer(0.1, DisplayEffectsHud, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);

	RoundIndex = 0;

	for (new i = 0; i < sizeof(g_eBlocks); ++i)
	{
		if (strcmp(g_eBlocks[i][SoundPath], "") != 0)
			PrecacheSound(g_eBlocks[i][SoundPath], true);
	}

	PrecacheModel("models/player/ctm_gign.mdl");
	PrecacheModel("models/player/tm_phoenix.mdl");

	AddFileToDownloadsTable(FULL_INVI_SOUND_PATH);
	FakePrecacheSound(REL_INVI_SOUND_PATH);

	AddFileToDownloadsTable(FULL_STEALTH_SOUND_PATH);
	FakePrecacheSound(REL_STEALTH_SOUND_PATH);

	AddFileToDownloadsTable(FULL_BOS_SOUND_PATH);
	FakePrecacheSound(REL_BOS_SOUND_PATH);

	AddFileToDownloadsTable(FULL_TELE_SOUND_PATH);
	FakePrecacheSound(REL_TELE_SOUND_PATH);

	AddFileToDownloadsTable(FULL_MONEY_SOUND_PATH);
	FakePrecacheSound(REL_MONEY_SOUND_PATH);

	DownloadsTable();

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
	TextureDownload("materials/models/platforms/sphere");
	TextureDownload("materials/models/platforms/blue_glow1");
	TextureDownload("materials/models/platforms/red_glow1");
	TextureDownload("materials/models/platforms/glow2");
	TextureDownload("materials/models/platforms/tape");



	decl String:tmp[128];

	for(new i = 0; i < _:BlockTypes; i++) {
		for(new j = 0; j < _:BlockSizes; j++) {

			//dont precache the same things multiple times
			for(int b = 1; b < i; b++)
			{
				if(StrEqual(g_eBlocks[i][ModelName], g_eBlocks[b][ModelName]))
					continue;
			}


			Format(tmp, sizeof(tmp), "%s_%s/%s", g_eBlocks[i][ModelPathPrefix], BlockDirName[j], g_eBlocks[i][ModelName]);
			ReplaceString(tmp, sizeof(tmp), ".mdl", "");
			Download(tmp);

			ReplaceString(tmp, sizeof(tmp), "models", "materials");

			if(j == _:BLOCK_NORMAL) {
				TextureDownloadPlusSide(tmp);
			}
			else {
				TextureDownload(tmp)
			}
		}
	}
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

SaveBlocks(bool msg = false)
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

			char propnum[16];
			for(int j = 0; j < MAXPROPERTIES; j++) {
				Format(propnum, sizeof(propnum), "property%i", j);
				KvSetFloat(g_hBlocksKV, propnum, g_fPropertyValue[i][j]);
			}

			if(g_iBlocks[i] == _:LOCK) {
				float values[3];
				int lockBlocktype;
				g_Lock[i].GetValue("blocktype", lockBlocktype);
				KvSetNum(g_hBlocksKV, "lockBlocktype", lockBlocktype)

				g_Lock[i].GetArray("properties", values, 3);

				for(int j = 0; j < MAXPROPERTIES; j++) {
					Format(propnum, sizeof(propnum), "subproperty%i", j);
					KvSetFloat(g_hBlocksKV, propnum, values[j]);
				}
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

void LoadBlocks(bool msg = false)
{
	if (g_hBlocksKV == INVALID_HANDLE)
		return;

	int teleporters = 0, blocks = 0;
	float fPos[3], fAng[3];

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

			if(blocktype >= _:BlockTypes)
				continue;

			new b = CreateBlock(0, blocktype, blocksize, fPos, fAng, transparency);
			blocks++;
			/* The toponly property key doesn't exist.
			 	CreateBlock loads default properties and
				we don't want to overwrite them with 0 */
			if(KvGetDataType(g_hBlocksKV, "toponly") == KvData_None) {
				continue;
			}

			g_bTopOnly[b] = view_as<bool>(KvGetNum(g_hBlocksKV, "toponly"));

			char propnum[16];
			for(int i = 0; i < MAXPROPERTIES; i++) {
				Format(propnum, sizeof(propnum), "property%i", i);
				g_fPropertyValue[b][i] = KvGetFloat(g_hBlocksKV, propnum);
			}

			if(g_iBlocks[b] == _:LOCK) {
				float values[3];
				int lockBlocktype = KvGetNum(g_hBlocksKV, "lockBlocktype");
				g_Lock[b].SetValue("blocktype", lockBlocktype, true);

				for(int i = 0; i < MAXPROPERTIES; i++) {
					Format(propnum, sizeof(propnum), "subproperty%i", i);
					values[i] = KvGetFloat(g_hBlocksKV, propnum);
				}

				g_Lock[b].SetArray("properties", values, 3, true);
			}
		}
	} while (KvGotoNextKey(g_hBlocksKV));

	if (msg)
		PrintToChatAll("\x03%s\x04 %d blocks and %d pair of teleporters were loaded.", CHAT_TAG, blocks, teleporters);
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if(buttons & IN_USE) {
		new ent = GetClientAimTarget2(client, false);

		if(!IsValidBlock(ent))
			return Plugin_Continue;

		ShowReadOnlyPropertyPanelAiming(client);
	}

	if (g_iDragEnt[client] != 0)
	{
		if (IsValidEdict(g_iDragEnt[client]))
		{
			new Float:vecDir[3], Float:vecPos[3], Float:vecVel[3];
			new Float:viewang[3];

			GetClientEyeAngles(client, viewang);
			GetAngleVectors(viewang, vecDir, NULL_VECTOR, NULL_VECTOR);
			GetClientEyePosition(client, vecPos);

			vecPos[0] += vecDir[0] * g_fGrabOffset[client];
			vecPos[1] += vecDir[1] * g_fGrabOffset[client];
			vecPos[2] += (vecDir[2]) * g_fGrabOffset[client];

			GetEntPropVector(g_iDragEnt[client], Prop_Send, "m_vecOrigin", vecDir);

			new bool:bSnap = false;
			new bool:bGroup = g_bGroups[client][g_iDragEnt[client]];

			if (g_bSnapping[client]/* && (FloatAbs(g_fClientAngles[client][1]) - FloatAbs(angles[1])) < 2.0 && !bGroup*/)
			{
				doSnapping(client, g_iDragEnt[client]);
			}

			if (!bSnap)
			{
				SubtractVectors(vecPos, vecDir, vecVel);
				ScaleVector(vecVel, 10.0);

				//TeleportEntity(g_iDragEnt[client], NULL_VECTOR, g_fAngles[g_iDragEnt[client]], vecVel);
				TeleportEntity(g_iDragEnt[client], vecPos, NULL_VECTOR, NULL_VECTOR);
				doSnapping(client, g_iDragEnt[client]);
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
	if(action == MenuAction_End)
		CloseHandle(menu);

	if (action != MenuAction_Select)
		return;

	new bool:bDisplayMenu = true;

	switch (param2) {
		case 0: {
			bDisplayMenu = false;
			DisplayMenu(CreateBlocksMenu(), client, 0);
		}
		case 1: {
			CreateBlockAiming(client);
			/*new ent = GetClientAimTarget2(client, false);

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
			}*/
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
					if(!vAng[0] && !vAng[1] && !vAng[2])
					{
						vAng[1] = 90.0;
					}
					else if(!vAng[0] && vAng[1] == 90.0 && !vAng[2])
					{
						vAng[2] = 90.0;
					}
					else
					{
						vAng[0] = 0.0;
						vAng[1] = 0.0;
						vAng[2] = 0.0;
					}
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
			ShowCheckpointMenu(client);
			bDisplayMenu = false;
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
	Handle menu = CreateMenu(BB_ALPHA, MenuAction_Select | MenuAction_End);
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


public int BB_ALPHA(Menu menu, MenuAction action, int client, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char item[16];
			GetMenuItem(menu, param2, item, sizeof(item));
			SetEntityRenderMode(CurrentModifier[client], RENDER_TRANSCOLOR)
			SetEntityRenderColor(CurrentModifier[client], 255, 255, 255, StringToInt(item))
			DisplayMenu(CreateMainMenu(client), client, 0);
			PrintToChat(client, "\x03%s\x04 Block's Transparency has been adjusted.", CHAT_TAG);
			Block_Transparency[CurrentModifier[client]] = StringToInt(item);
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
}

public Handle CreateTeleportMenu(client)
{
	Handle menu = CreateMenu(Handler_Teleport);
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

public Handle CreateBlocksMenu()
{
	Handle menu = CreateMenu(Handler_Blocks);
	char szItem[4];
	SetMenuTitle(menu, "Block Menu");
	for (int i; i < sizeof g_eBlocks; i++)
	{
		IntToString(i, szItem, sizeof(szItem));
		AddMenuItem(menu, szItem, g_eBlocks[i][BlockName]);
	}
	SetMenuExitBackButton(menu, true);
	return menu;
}

public Handle CreateMainMenu(client)
{
	Handle menu = CreateMenu(Handler_BlockBuilder);

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
	AddMenuItem(menu, "10", "Checkpoint Menu");
	AddMenuItem(menu, "11", "More Options");
	SetMenuExitButton(menu, true);
	g_hClientMenu[client] = menu;
	return menu;
}

public Handle CreateOptionsMenu(client)
{
	Handle menu = CreateMenu(Handler_Options);
	SetMenuTitle(menu, "Options Menu");

	if (g_bSnapping[client])
		AddMenuItem(menu, "0", "Snapping: On");
	else
		AddMenuItem(menu, "0", "Snapping: Off");


	char sText[256];
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

int CreateTeleportEntrance(int client, float fPos[3] =  { 0.0, 0.0, 0.0 } )
{
	float vecDir[3], vecPos[3], viewang[3];
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

	int ent = CreateEntityByName("prop_physics_override");
	DispatchKeyValue(ent, "model", "models/platforms/b-tele.mdl");
	TeleportEntity(ent, vecPos, NULL_VECTOR, NULL_VECTOR);
	DispatchSpawn(ent);

	SetEntityMoveType(ent, MOVETYPE_NONE);
	AcceptEntityInput(ent, "disablemotion");
	//SetEntProp(ent, Prop_Data, "m_CollisionGroup", 2);
	SetEntProp(ent, Prop_Send, "m_usSolidFlags", FSOLID_TRIGGER);
	SetEntProp(ent, Prop_Data, "m_nSolidType", 6); // SOLID_VPHYSICS
	SetEntProp(ent, Prop_Send, "m_CollisionGroup", 1); //COLLISION_GROUP_DEBRIS

	// basically it's not solid but the touch event is triggered
	// if it was solid the player would lose speed because teleport works on next tick

	g_iTeleporters[ent] = 1;
	g_iCurrentTele[client] = ent;

	SDKHook(ent, SDKHook_StartTouch, OnStartTouch);

	return ent;
}

int CreateTeleportExit(int client, float fPos[3] =  { 0.0, 0.0, 0.0 } )
{
	float vecDir[3], vecPos[3], viewang[3];
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

	int ent = CreateEntityByName("prop_physics_override");
	DispatchKeyValue(ent, "model", "models/platforms/r-tele.mdl");
	TeleportEntity(ent, vecPos, NULL_VECTOR, NULL_VECTOR);
	DispatchSpawn(ent);

	SetEntityMoveType(ent, MOVETYPE_NONE);
	AcceptEntityInput(ent, "disablemotion");
	//SetEntProp(ent, Prop_Data, "m_CollisionGroup", 2);
	SetEntProp(ent, Prop_Send, "m_usSolidFlags", FSOLID_TRIGGER);
	SetEntProp(ent, Prop_Data, "m_nSolidType", 6); // SOLID_VPHYSICS
	SetEntProp(ent, Prop_Send, "m_CollisionGroup", 1); //COLLISION_GROUP_DEBRIS

	g_iTeleporters[ent] = 1;

	return ent;
}

int CreateBlockAiming(int client) {
	float vecPos[3], vecDir[3], viewang[3];

	GetClientEyeAngles(client, viewang);
	GetAngleVectors(viewang, vecDir, NULL_VECTOR, NULL_VECTOR);
	GetClientEyePosition(client, vecPos);
	vecPos[0] += vecDir[0] * 100;
	vecPos[1] += vecDir[1] * 100;
	vecPos[2] += vecDir[2] * 100;

	return CreateBlock(client, g_iBlockSelection[client], g_iClBlockSize[client], vecPos, _, _);
}

int CreateBlock(int client, int blocktype = 0, int blocksize = _:BLOCK_NORMAL, float fPos[3] =  { 0.0, 0.0, 0.0 }, float fAng[3] =  { 0.0, 0.0, 0.0 }, int transparency = 0)
{
	#pragma unused client

	float vecPos[3];
	vecPos = fPos;
	int block_entity = CreateEntityByName("prop_physics_override");
	char sModel[256];

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

	g_iBlocks[block_entity] = blocktype;
	g_fAngles[block_entity] = fAng;
	SetDefaultProperty(block_entity);

	SDKHook(block_entity, SDKHook_StartTouch, OnStartTouch);
	SDKHook(block_entity, SDKHook_Touch, OnTouch);
	SDKHook(block_entity, SDKHook_EndTouch, OnEndTouch);

	if(blocktype == _:LOCK) {
		delete g_Lock[block_entity];
		g_Lock[block_entity] = new StringMap();
		float v[3];
		g_Lock[block_entity].SetValue("blocktype", _:HONEY);
		g_Lock[block_entity].SetArray("properties", v, sizeof v);
	}

	//PrintToChat(client, "%sSuccessfully spawned block \x03%s\x04.", CHAT_TAG, g_eBlocks[g_iBlockSelection[client]][BlockName]);
	return block_entity;
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if ((g_bNoFallDmg[victim] && damagetype & DMG_FALL))
		return Plugin_Handled;
	return Plugin_Continue;
}

public Teleport_Action(any:pack) {
	ResetPack(pack);
	new client = ReadPackCell(pack);
	new block = ReadPackCell(pack);
	CloseHandle(pack);

	new String:sound[512], Float:Vec[3], Float:exitPos[3];
	GetConVarString(g_hTeleSound, sound, sizeof(sound));

	GetEntPropVector(g_iTeleporters[block], Prop_Data, "m_vecOrigin", exitPos);
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", Vec);

	Vec[2] = FloatAbs(Vec[2])*1.0;

	TeleportEntity(client, exitPos, NULL_VECTOR, Vec);

	EmitSoundToClient(client, REL_TELE_SOUND_PATH);
	EmitSoundToAll(REL_TELE_SOUND_PATH, block, SNDCHAN_AUTO);
}

public Action OnStartTouch(int block, int client)
{
	/*if (g_iTeleporters[block] != -1) {
		return Plugin_Continue;
	}*/

	if (1 > client > MAXPLAYERS || !IsClientInGame(client)) {
		return Plugin_Continue;
	}

	if (g_iTeleporters[block] > 1 && 2 <= GetClientTeam(client) <= 3)
	{
		DataPack pack = CreateDataPack();
		pack.WriteCell(client);
		pack.WriteCell(block);

		RequestFrame(Teleport_Action, pack);

		return Plugin_Handled;
	}

	Block_Touching[client][block] = true;

	/* The block can be activated from top only
		but the player isn't on ground */
	if(g_bTopOnly[block] == true
		&& (!(GetEntityFlags(client) & FL_ONGROUND)
		|| GetEntPropEnt(client, Prop_Send, "m_hGroundEntity") != block)) {

		g_bTouchStartTriggered[client] = false;

		return Plugin_Continue;
	}

	g_bTouchStartTriggered[client] = true;

	if(g_bTriggered[block]) //kinda experimental
		return Plugin_Continue;

	if(g_iBlocks[block] == _:LOCK)
	{
		int key = RoundFloat(g_fPropertyValue[block][0]);
		if(g_PlayerKeys[client].FindValue(key) != -1)
		{
			float values[3];
			int type;
			g_Lock[block].GetValue("blocktype", type);
			g_Lock[block].GetArray("properties", values, 3);

			Block_HandleStartTouch(client, block, type, values);
		}
		return Plugin_Continue;
	}

	Block_HandleStartTouch(client, block, g_iBlocks[block], g_fPropertyValue[block]);

	return Plugin_Continue;
}

public void Block_HandleStartTouch(int client, int block, int blocktype, float properties[3])
{
	bool packUsed = false;
	DataPack pack = CreateDataPack();
	pack.WriteCell(client);
	pack.WriteCell(block);

	//now this shit is experimental
	if(!g_bGhost[client])
	{
		switch(blocktype) {
			case DAMAGE: {
				packUsed = true;

				ClearTimer(Block_Timers[client]);
				Block_Timers[client] = CreateTimer(0.0, DamagePlayer, pack);
			}
			case HEALTH: {
				packUsed = true;

				ClearTimer(Block_Timers[client]);
				Block_Timers[client] = CreateTimer(properties[1], HealPlayer, pack);
			}
			case BUNNYHOP: {
				g_bTriggered[block] = true;
				CreateTimer(properties[0], Timer_StartNoBlock, block);
			}
			case BUNNYHOP_DELAYED: {
				g_bTriggered[block] = true;
				CreateTimer(properties[0], Timer_StartNoBlock, block);
			}
			case BUNNYHOP_NSD: {
				g_bTriggered[block] = true;
				CreateTimer(properties[0], Timer_StartNoBlock, block);
				SetEntPropFloat(client, Prop_Send, "m_flStamina", 0.0);
			}
			case BARRIER_CT: {
				if(GetClientTeam(client) == 2) {
					g_bTriggered[block] = true;
					if(properties[0] < 0.05)
						StartNoBlock(block);
					else
						CreateTimer(properties[0], Timer_StartNoBlock, block);
				}
			}
			case BARRIER_T: {
				if(GetClientTeam(client) == 3) {
					g_bTriggered[block] = true;
					if(properties[0] < 0.05)
						StartNoBlock(block);
					else
						CreateTimer(properties[0], Timer_StartNoBlock, block);
				}
			}
			case GRAVITY: {
				SetEntityGravity(client, properties[0]);
				//SDKHook(client, SDKHook_GroundEntChangedPost, Gravity_GroundEntChanged);
			}
			case HONEY: {
				SDKHook(client, SDKHook_PostThink, Honey_OnPostThink);
			}
			case STEALTH: {
				if(g_PlayerEffects[client][Stealth][canUse])
				{
					SetEntityRenderMode(client, RENDER_NONE);
					SetPlayerEffect(client, Stealth, properties[0]/* + float(mm_GetStealthTime(client))*/,
						properties[1], STEALTH_end, STEALTH_cdEnd);

					EmitSoundToAll(REL_STEALTH_SOUND_PATH, block, SNDCHAN_AUTO);
				}
			}
			case INVINCIBLITY: {

				if(g_PlayerEffects[client][Invincibility][canUse])
				{
					SDKHook(client, SDKHook_OnTakeDamage, INVINCIBLITY_OnTakeDamage);
					SetEntityRenderMode(client, RENDER_GLOW);
					SetEntityRenderFx(client, RENDERFX_PULSE_SLOW);
					SetEntityRenderColor(client, 230, 230, 40, 255);

					SetPlayerEffect(client, Invincibility, properties[0]/* + float(mm_GetInvincibilityTime(client))*/,
						properties[1], INVINCIBLITY_end, INVINCIBLITY_cdEnd);

					EmitSoundToAll(REL_INVI_SOUND_PATH, block, SNDCHAN_AUTO);
				}
			}
			case BOOTS_OF_SPEED: {

				if(g_PlayerEffects[client][BootsOfSpeed][canUse])
				{
					float newSpeedMultiplier = properties[2] / 250.0;
					SetEntPropFloat(client, Prop_Send, "m_flVelocityModifier",  newSpeedMultiplier);

					SetPlayerEffect(client, BootsOfSpeed, properties[0]/* + float(mm_GetBootsTime(client))*/,
						properties[1], BOOTS_OF_SPEED_end, BOOTS_OF_SPEED_cdEnd);

					EmitSoundToAll(REL_BOS_SOUND_PATH, block, SNDCHAN_AUTO);
				}
			}
			case MONEY: {

				if(g_bCanUseMoney[client] && GetClientTeam(client) == CS_TEAM_T)
				{
					int money = /*mm_AddMoney(client, RoundFloat(properties[0]), 1.5)*/50;
					PrintToChat(client, "%s\x03 You have received\x04 $%i\03 from the moneyblock!",
						CHAT_TAG, money);

					EmitSoundToAll(REL_MONEY_SOUND_PATH, block, SNDCHAN_AUTO);

					g_bCanUseMoney[client] = false;
				}
			}
			case HE: {

				if(GetClientTeam(client) == CS_TEAM_T && g_bHEgrenadeCanUse[client])
				{
					GivePlayerItem(client, "weapon_hegrenade");

					g_bHEgrenadeCanUse[client] = false;
				}
			}
			case FROST: {

				if(GetClientTeam(client) == CS_TEAM_T && g_bSmokegrenadeCanUse[client])
				{
					GivePlayerItem(client, "weapon_smokegrenade");

					g_bSmokegrenadeCanUse[client] = false;
				}
			}
			case FLASH: {

				if(GetClientTeam(client) == CS_TEAM_T && g_bFlashbangCanUse[client])
				{
					GivePlayerItem(client, "weapon_flashbang");

					g_bFlashbangCanUse[client] = false;
				}
			}
			case WEAPON: {
				int weaponIndex = RoundFloat(properties[0]);

				if(GetClientTeam(client) == CS_TEAM_T && !g_bWeaponUsed[client][weaponIndex])
				{
					int slot = g_iWeaponSlot[weaponIndex];
					if(GetPlayerWeaponSlot(client, slot) == -1) 
					{
						int ent = GivePlayerItem(client, g_sWeapons[weaponIndex]);
						
						if(IsValidEntity(ent))
						{
							SetEntProp(ent, Prop_Data, "m_iClip1", 1);
							SetEntProp(ent, Prop_Send, "m_iPrimaryReserveAmmoCount", 0);

							g_bWeaponUsed[client][weaponIndex] = true;
						}
					}
				}
			}
		}
	}

	switch(blocktype)
	{
		case TRAMPOLINE: {
			packUsed = true;

			RequestFrame(Trampoline_Action, pack);
			g_bNoFallDmg[client] = true;
		}
		case SPEEDBOOST: {
			packUsed = true;
			CreateTimer(0.0, BoostPlayer, pack);
		}
		case DEATH: {

			if (IsPlayerAlive(client))
			{
				//has no godmode
				if (!g_PlayerEffects[client][Invincibility][active]
					|| properties[0] > 0.5) {
					SDKHooks_TakeDamage(client, 0, 0, 10000.0);
				}
			}
		}
		case KEY: {
			int key = RoundFloat(properties[0]);
			if(g_PlayerKeys[client].FindValue(key) == -1)
			{
				g_PlayerKeys[client].Push(key);
				PrintToChat(client, "%s\x03 You have received a\x04 key\03: \x10%i\x03!", CHAT_TAG, key);
			}
		}
	}

	if(!packUsed)
		CloseHandle(pack);
}

public Action Gravity_GroundEntChanged(client)
{
	int ground = GetEntPropEnt(client, Prop_Send, "m_hGroundEntity");

	// -1 ground
	// 0 air
	if(ground != 0)
		SDKUnhook(client, SDKHook_GroundEntChangedPost, Gravity_GroundEntChanged);

	SetEntityGravity(client, 1.0);
}

public Action Honey_GroundEntChanged(client)
{
	int ground = GetEntPropEnt(client, Prop_Send, "m_hGroundEntity");

	// -1 ground
	// 0 air
	if(ground != 0) {
		SDKUnhook(client, SDKHook_GroundEntChangedPost, Honey_GroundEntChanged);
		SDKUnhook(client, SDKHook_PostThink, Honey_OnPostThink);
	}
}

float GetAbsVec(const float[] a)
{
    return SquareRoot(a[0] * a[0] + a[1] * a[1]);
}

public Honey_OnPostThink(client)
{
	static float speedcap = 40.0;
	float vel[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", vel);
	float speed = GetAbsVec(vel);

	if(speed > speedcap)
	{
		vel[0] *= speedcap / speed;
		vel[1] *= speedcap / speed;
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vel);
	}

	int ground = GetEntPropEnt(client, Prop_Send, "m_hGroundEntity");
	
	if(ground == 0) {
		SDKUnhook(client, SDKHook_PostThink, Honey_OnPostThink);
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

	if (client > MAXPLAYERS || !IsClientInGame(client)) {
		return Plugin_Continue;
	}

	if(!g_bTouchStartTriggered[client]) {
		OnStartTouch(block, client);

		return Plugin_Continue;
	}

	switch(g_iBlocks[block]) {
		case ICE: {
			SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.15);
		}
		case TRAMPOLINE: {
			DataPack pack = CreateDataPack();
			pack.WriteCell(client);
			pack.WriteCell(block);

			RequestFrame(Trampoline_Action, pack);

			g_bNoFallDmg[client] = true;
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

	if (client > MAXPLAYERS || !IsClientInGame(client)) {
		return Plugin_Continue;
	}

	g_bTouchStartTriggered[client] = false;

	decl Float:block_loc[3]
	GetEntPropVector(block, Prop_Send, "m_vecOrigin", block_loc);

	decl Float:player_loc[3]
	GetClientAbsOrigin(client, player_loc)

	switch(g_iBlocks[block]) {
		case HONEY: {
			SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0);
			Honey_GroundEntChanged(client);
			SDKHook(client, SDKHook_GroundEntChangedPost, Honey_GroundEntChanged);
		}
		case ICE: {
			SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0);
		}
		case GRAVITY: {
			SetEntityGravity(client, g_fPropertyValue[block][0]);
			SDKHook(client, SDKHook_GroundEntChangedPost, Gravity_GroundEntChanged);
		}
	}

	Block_Touching[client][block] = false;

	return Plugin_Continue;
}

public Action:BlockTouch_End(Handle:timer, any:client)
{
	//Block_Touching[client] = 0;
}

public Action:DamagePlayer(Handle:timer, any:pack)
{
	ResetPack(pack);
	new client = ReadPackCell(pack);
	new block = ReadPackCell(pack);

	if(!IsClientInGame(client)
	|| !IsPlayerAlive(client)) {
		ClearTimer(Block_Timers[client]);
		CloseHandle(pack);
		return Plugin_Handled;
	}

	Block_Timers[client] =
		CreateTimer(GetBlockProperty(block, 1), DamagePlayer, pack);

	if (g_PlayerEffects[client][Invincibility][active])
		return Plugin_Handled;

	/*if (GetClientHealth(client) - 5 > 0)
		SetEntityHealth(client, GetClientHealth(client) - 5);
	else*/
	SDKHooks_TakeDamage(client, 0, 0, GetBlockProperty(block, 0));

	if(Block_Touching[client][block] == false) {
		ClearTimer(Block_Timers[client]);
		CloseHandle(pack);
	}

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

public Action:Timer_StartNoBlock(Handle:timer, any:block)
{
	StartNoBlock(block);

	return Plugin_Stop;
}

public StartNoBlock(block) {
	SetEntProp(block, Prop_Data, "m_CollisionGroup", 2);
	SetEntityRenderMode(block, RENDER_TRANSADD);

	if (Block_Transparency[block] > 0)
		SetEntityRenderColor(block, 177, 177, 177, RoundFloat(float(Block_Transparency[block]) * 0.4588));
	else
		SetEntityRenderColor(block, 177, 177, 177, 177);

	CreateTimer(GetBlockProperty(block, 1), CancelNoBlock, block);
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
	|| Block_Touching[client][block] == false) {
		ClearTimer(Block_Timers[client]);
		CloseHandle(pack);
		return Plugin_Handled;
	}

	Block_Timers[client] =
		CreateTimer(GetBlockProperty(block, 1), HealPlayer, pack);

	new health = RoundFloat(GetBlockProperty(block, 0));

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

public Action STEALTH_end(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);

	if(!client)
		return Plugin_Stop;

	g_PlayerEffects[client][Stealth][active] = false;
	SetEntityRenderMode(client, RENDER_NORMAL);
	PrintToChat(client, "\x03%s\x04 Stealth\x01 has worn off.", CHAT_TAG);

	return Plugin_Stop;
}

public Action STEALTH_cdEnd(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);

	if(!client)
		return Plugin_Stop;

	g_PlayerEffects[client][Stealth][canUse] = true;
	PrintToChat(client, "\x03%s\x04 Stealth\x01 cooldown has ended.", CHAT_TAG);

	return Plugin_Stop;
}

public Action BoostPlayer(Handle timer, any pack)
{
	ResetPack(pack);
	new client = ReadPackCell(pack);
	new block = ReadPackCell(pack);

	CloseHandle(pack);

	new Float:fAngles[3];
	GetClientEyeAngles(client, fAngles);

	new Float:fVelocity[3];
	GetAngleVectors(fAngles, fVelocity, NULL_VECTOR, NULL_VECTOR);

	NormalizeVector(fVelocity, fVelocity);

	ScaleVector(fVelocity, GetBlockProperty(block, 1));
	fVelocity[2] = GetBlockProperty(block, 0);
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, fVelocity);

	return Plugin_Stop;
}

public Trampoline_Action(any pack)
{
	ResetPack(pack);
	new client = ReadPackCell(pack);
	new block = ReadPackCell(pack);
	CloseHandle(pack);

	new Float:fVelocity[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", fVelocity);

	fVelocity[2] = GetBlockProperty(block, 0);
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, fVelocity);
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
	if(action == MenuAction_End)
		CloseHandle(menu);


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

public Action SetAllDeathsKillWithGod(client, args)
{
	for (new i = MaxClients + 1; i < 2048; ++i)
	{
		if(IsValidBlock(i) && g_iBlocks[i] == _:DEATH)
		{
			g_fPropertyValue[i][0] = 1.0;
		}
	}

	PrintToChatAll("%s\x03 first property \x04 of\x03 all death blocks\x04 changed to\x03 1", CHAT_TAG);
}

public SetDefaultProperty(block) {
	new blocktype = g_iBlocks[block];

	g_bTopOnly[block] = view_as<bool>(g_bTopOnlyDefault[blocktype]);

	for(new i = 0; i < MAXPROPERTIES; i++) {
		g_fPropertyValue[block][i] = g_fPropertyDefault[blocktype][i];
	}
}

public SetPlayerEffect(int client, e_PlayerEffects effect, float lasts,
	float cooldown, Timer end, Timer cdEnd)
{
	float gametime = GetGameTime();
	int userid = GetClientUserId(client);

	g_PlayerEffects[client][effect][canUse] = false;
	g_PlayerEffects[client][effect][active] = true;

	g_PlayerEffects[client][effect][endTime] = gametime + lasts;
	g_PlayerEffects[client][effect][cooldownEndTime] = gametime + lasts + cooldown;

	g_PlayerEffects[client][effect][timerEnd] =
		CreateTimer(lasts, end, userid, TIMER_FLAG_NO_MAPCHANGE);

	g_PlayerEffects[client][effect][timerCdEnd] =
		CreateTimer(lasts + cooldown, cdEnd, userid, TIMER_FLAG_NO_MAPCHANGE);
}

public ResetPlayerEffect(int client, e_PlayerEffects effect)
{
	g_PlayerEffects[client][effect][canUse] = true;
	g_PlayerEffects[client][effect][active] = false;
}

stock ClearTimer(&Handle:timer)
{
	if (timer != INVALID_HANDLE)
	{
		KillTimer(timer);
	}
	timer = INVALID_HANDLE;
}

// thanks Mitchell
stock IsPlayerStuck(client) {
	decl Float:vecMin[3], Float:vecMax[3], Float:vecOrigin[3];

	GetClientMins(client, vecMin);
	GetClientMaxs(client, vecMax);

	GetClientAbsOrigin(client, vecOrigin);

	TR_TraceHullFilter(vecOrigin, vecOrigin, vecMin, vecMax, MASK_PLAYERSOLID, TraceRayDontHitPlayerAndWorld);
	return TR_GetEntityIndex();
}
stock bool:IsStuckInEnt(client, ent) {
	decl Float:vecMin[3], Float:vecMax[3], Float:vecOrigin[3];

	GetClientMins(client, vecMin);
	GetClientMaxs(client, vecMax);

	GetClientAbsOrigin(client, vecOrigin);

	TR_TraceHullFilter(vecOrigin, vecOrigin, vecMin, vecMax, MASK_ALL, TraceRayHitOnlyEnt, ent);
	return TR_DidHit();
}

public bool:TraceRayDontHitPlayerAndWorld(entityhit, mask) {
	return entityhit>MaxClients
}
public bool:TraceRayHitOnlyEnt(entityhit, mask, any:data) {
	return entityhit==data;
}

doSnapping(id, ent){
	float fMoveTo[3];

	float fSizeMin[3], fSizeMax[3];
	/*GetEntPropVector(ent, Prop_Data, "m_vecMins", fSizeMin);
	GetEntPropVector(ent, Prop_Data, "m_vecMaxs", fSizeMax);*/

	GetEntPropVector(ent, Prop_Data, "m_vecOrigin", fMoveTo);
	#pragma unused id

	new Float:vReturn[3];
	new Float:dist;
	new Float:distOld = 9999.9;
	new Float:vTraceStart[3];
	new Float:vTraceEnd[3];

	new trClosest = 0;
	new blockFace;

	float ang[3];
	GetEntPropVector(ent, Prop_Data, "m_angRotation", ang);

	int size = g_iBlocksSize[ent];
	int rotation = getRotation(size, ang);


	for(new x = 0 ; x < 3 ; x++){
		fSizeMin[x] = rotation == 2 ? g_fBlockSizes3[size][0][x] : rotation == 1 ? g_fBlockSizes2[size][0][x] : g_fBlockSizes[size][0][x];
		fSizeMax[x] = rotation == 2 ? g_fBlockSizes3[size][1][x] : rotation == 1 ? g_fBlockSizes2[size][1][x] : g_fBlockSizes[size][1][x];
	}
	new Float:fVec[3];
	for (new i = 0; i < 6; ++i){
		vTraceStart = fMoveTo;

		switch (i)
		{
			case 0: vTraceStart[0] += fSizeMin[0];		//edge of block on -X
			case 1: vTraceStart[0] += fSizeMax[0];		//edge of block on +X
			case 2: vTraceStart[1] += fSizeMin[1];		//edge of block on -Y
			case 3: vTraceStart[1] += fSizeMax[1];		//edge of block on +Y
			case 4: vTraceStart[2] += fSizeMin[2];		//edge of block on -Z
			case 5: vTraceStart[2] += fSizeMax[2];		//edge of block on +Z
		}

		vTraceEnd = vTraceStart;

		new Handle:tr = TR_TraceRayFilterEx(vTraceStart, vTraceEnd, MASK_SHOT, RayType_EndPoint, TraceRayNoPlayers, ent);

		if(TR_DidHit(tr)){
			new tr2 = TR_GetEntityIndex(tr);

			TR_GetEndPosition(vReturn, tr);
			if(IsValidBlock(tr2)){
				dist = GetVectorDistance(vTraceStart, vReturn); //this!!

				if (dist < distOld){
					trClosest = tr2;
					distOld = dist;

					GetEntPropVector(trClosest, Prop_Data, "m_vecOrigin", fVec);
					fVec[i/2] += (i == 0 || i%2 == 0) ? fSizeMax[i/2] : fSizeMin[i/2];
					blockFace = i;
				}
			}
		}

		CloseHandle(tr);
	}

	if(IsValidBlock(trClosest)){

		new Float:vOrigin[3];
		GetEntPropVector(trClosest, Prop_Data, "m_vecOrigin", vOrigin);

		new Float:fTrSizeMin[3];
		new Float:fTrSizeMax[3];

		GetEntPropVector(trClosest, Prop_Data, "m_angRotation", ang);

		size = g_iBlocksSize[trClosest];
		rotation = getRotation(size, ang);

		/*GetEntPropVector(ent, Prop_Data, "m_vecMins", fTrSizeMin);
		GetEntPropVector(ent, Prop_Data, "m_vecMaxs", fTrSizeMax);*/

		for(new x = 0 ; x < 3 ; x++){
			fTrSizeMin[x] = rotation == 2 ? g_fBlockSizes3[size][0][x] : rotation == 1 ? g_fBlockSizes2[size][0][x] : g_fBlockSizes[size][0][x];
			fTrSizeMax[x] = rotation == 2 ? g_fBlockSizes3[size][1][x] : rotation == 1 ? g_fBlockSizes2[size][1][x] : g_fBlockSizes[size][1][x];
		}

		fMoveTo = vOrigin;

		if (blockFace == 0) fMoveTo[0] += (fTrSizeMax[0] + fSizeMax[0]) - 0.5;
		if (blockFace == 1) fMoveTo[0] += (fTrSizeMin[0] + fSizeMin[0]) + 0.5
		if (blockFace == 2) fMoveTo[1] += (fTrSizeMax[1] + fSizeMax[1]) - 0.5;
		if (blockFace == 3) fMoveTo[1] += (fTrSizeMin[1] + fSizeMin[1]) + 0.5;
		if (blockFace == 4) fMoveTo[2] += (fTrSizeMax[2] + fSizeMax[2]) - 0.5;
		if (blockFace == 5) fMoveTo[2] += (fTrSizeMin[2] + fSizeMin[2]) + 0.5;
	}

	TeleportEntity(ent, fMoveTo, NULL_VECTOR, NULL_VECTOR);
}

public bool:TraceRayNoPlayers(entity, mask, any:data)
{
    if(entity == data || (entity >= 1 && entity <= MaxClients))
    {
        return false;
    }
    return true;
}

// it will convert the angles to a number that can be used with the mins/maxs array
// to avoid storing rotation in the save file (backwards comp)
int getRotation(blockType, float vAng[3])
{
	if(blockType == _:BLOCK_POLE)
	{
		if(!vAng[0] && !vAng[1] && !vAng[2])
		{
			return 0;
		}
		else if(!vAng[0] && vAng[1] == 90.0 && !vAng[2])
		{
			return 1;
		}
		else
		{
			return 2;
		}
	}
	else
	{
		if (vAng[1])
		{
			return 2;
		}
		else if (vAng[2])
			return 1;
		else
			return 0;
	}
}

float GetBlockProperty(int block, int num)
{
	static float values[3];
	
	if(g_iBlocks[block] == _:LOCK) {
		g_Lock[block].GetArray("properties", values, 3);
		return values[num];
	}

	return g_fPropertyValue[block][num];
}

stock any:MathMin(any:a, any:b) { return a < b ? a : b; }

stock any:MathMax(any:a, any:b) { return a > b ? a : b; }