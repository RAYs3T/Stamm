/**
 * -----------------------------------------------------
 * File        stamm_spawnhp.sp
 * Authors     David <popoklopsi> Ordnung
 * License     GPLv3
 * Web         http://popoklopsi.de
 * -----------------------------------------------------
 * 
 * Copyright (C) 2012-2014 David <popoklopsi> Ordnung
 * 
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>
 */




// Includes
#include <sourcemod>
#include <autoexecconfig>

#undef REQUIRE_PLUGIN
#include <stamm>

#pragma semicolon 1




new Handle:g_hHP;




// Plugin Info
public Plugin:myinfo =
{
	name = "Stamm Feature SpawnHP",
	author = "Popoklopsi",
	version = "${-version-}", // Version is replaced by GitLab runner due the build phase
	description = "Give VIP's more HP on spawn",
	url = "https://forums.alliedmods.net/showthread.php?t=142073"
};




// Add Feature
public OnAllPluginsLoaded()
{
	if (!STAMM_IsAvailable()) 
	{
		SetFailState("Can't Load Feature, Stamm is not installed!");
	}

	STAMM_LoadTranslation();
	STAMM_RegisterFeature("VIP SpawnHP");
}



public STAMM_OnFeatureLoaded(const String:basename[])
{
}



// Add descriptions
public STAMM_OnClientRequestFeatureInfo(client, block, &Handle:array)
{
	decl String:fmt[256];
	
	Format(fmt, sizeof(fmt), "%T", "GetSpawnHP", client, GetConVarInt(g_hHP) * block);
	
	PushArrayString(array, fmt);
}



// Create the config
public OnPluginStart()
{
	HookEvent("player_spawn", PlayerSpawn);


	AutoExecConfig_SetFile("spawnhp", "stamm/features");
	AutoExecConfig_SetCreateFile(true);

	g_hHP = AutoExecConfig_CreateConVar("spawnhp_hp", "50", "HP a VIP gets every spawn more per block");
	
	AutoExecConfig_CleanFile();
	AutoExecConfig_ExecuteFile();
}





// Change player health
public PlayerSpawn(Handle:event, String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (STAMM_IsClientValid(client))
	{
		// Timer to add points
		if (IsPlayerAlive(client) && (GetClientTeam(client) == 2 || GetClientTeam(client) == 3)) 
		{
			CreateTimer(0.5, changeHealth, GetClientUserId(client));
		}
	}
}




// Change here the health
public Action:changeHealth(Handle:timer, any:userid)
{
	// Get highest client block
	new client = GetClientOfUserId(userid);

	if (!STAMM_IsClientValid(client))
	{
		return Plugin_Stop;
	}

	new clientBlock = STAMM_GetClientBlock(client);


	// Have client block
	if (clientBlock > 0)
	{
		// Set new HP
		new newHP = GetClientHealth(client) + GetConVarInt(g_hHP) * clientBlock;
		
		// also increate max HP
		SetEntProp(client, Prop_Data, "m_iMaxHealth", newHP);
		SetEntityHealth(client, newHP);
	}

	return Plugin_Stop;
}