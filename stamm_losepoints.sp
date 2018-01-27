/**
 * -----------------------------------------------------
 * File        stamm_losepoints.sp
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




new g_iDeathCounter[MAXPLAYERS + 1];

new Handle:g_hDeathCount;
new Handle:g_hPointScount;




public Plugin:myinfo =
{
	name = "Stamm Feature LosePoints",
	author = "Popoklopsi",
	version = "${-version-}", // Version is replaced by GitLab runner due the build phase
	description = "Non VIP's lose until a specific level points on death",
	url = "https://forums.alliedmods.net/showthread.php?t=142073"
};




// Add feature
public OnAllPluginsLoaded()
{
	if (!STAMM_IsAvailable()) 
	{
		SetFailState("Can't Load Feature, Stamm is not installed!");
	}


	STAMM_LoadTranslation();
	STAMM_RegisterFeature("VIP LosePoints");
}




// Add descriptions
public STAMM_OnClientRequestFeatureInfo(client, block, &Handle:array)
{
	decl String:fmt[256];
	
	Format(fmt, sizeof(fmt), "%T", "NoLosePoints", client);
	
	PushArrayString(array, fmt);
}




public STAMM_OnFeatureLoaded(const String:basename[])
{
}



// Create Config
public OnPluginStart()
{
	HookEvent("player_death", PlayerDeath);


	AutoExecConfig_SetFile("losepoints", "stamm/features");
	AutoExecConfig_SetCreateFile(true);

	g_hDeathCount = AutoExecConfig_CreateConVar("death_count", "2", "How much deaths a player needs to lose points");
	g_hPointScount = AutoExecConfig_CreateConVar("points_count", "2", "How much points a player loses after <death_count> deaths");

	AutoExecConfig_CleanFile();
	AutoExecConfig_ExecuteFile();
}




// Death counter -> zero
public OnClientAuthorized(client, const String:auth[])
{
	g_iDeathCounter[client] = 0;
}




// A Player died
public PlayerDeath(Handle:event, String:name[], bool:dontBroadcast)
{
	decl String:tag[64];

	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new deathcount = GetConVarInt(g_hDeathCount);
	new pointscount = GetConVarInt(g_hPointScount);


	if (STAMM_IsClientValid(client) && attacker > 0 && client != attacker)
	{
		// Client doesn't have the feature
		if (!STAMM_HaveClientFeature(client) && IsClientInGame(attacker) && (GetClientTeam(client) != GetClientTeam(attacker)))
		{
			// check death count
			if (++g_iDeathCounter[client] == deathcount)
			{				
				// Delete points ):
				STAMM_DelClientPoints(client, pointscount);
				STAMM_GetTag(tag, sizeof(tag));
				
				STAMM_PrintToChat(client, "%s %t", tag, "LosePoints", pointscount, deathcount);


				g_iDeathCounter[client] = 0;
			}
		}
	}
}