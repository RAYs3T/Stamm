/**
 * -----------------------------------------------------
 * File        stamm_throwing_knifes.sp
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
#include <cssthrowingknives>

#pragma semicolon 1



new Handle:g_hThrowingKnife;
new Handle:g_hAddThrowingKnifes;



public Plugin:myinfo =
{
	name = "Stamm Feature Throwing Knife",
	author = "Popoklopsi",
	version = "${-version-}", // Version is replaced by GitLab runner due the build phase
	description = "Give VIP's every Round x Throwing Knifes",
	url = "https://gitlab.com/PushTheLimits/Sourcemod/Stamm/wikis"
};





// Add feature
public OnAllPluginsLoaded()
{
	if (!STAMM_IsAvailable()) 
	{
		SetFailState("Can't Load Feature, Stamm is not installed!");
	}

	// We need throwing knifes	
	if (!LibraryExists("cssthrowingknives")) 
	{	
		SetFailState("Can't Load Feature, Throwing Knifes is not installed!");
	}

	// And CSS
	if (STAMM_GetGame() != GameCSS) 
	{
		SetFailState("Can't Load Feature, not Supported for your game!");
	}


	STAMM_LoadTranslation();
	STAMM_RegisterFeature("VIP Throwing Knife");
}




public STAMM_OnFeatureLoaded(const String:basename[])
{
}




// Add descriptions
public STAMM_OnClientRequestFeatureInfo(client, block, &Handle:array)
{
	decl String:fmt[256];
	
	Format(fmt, sizeof(fmt), "%T", "GetThrowingKnife", client, GetConVarInt(g_hThrowingKnife));
	
	PushArrayString(array, fmt);
}




// Create the config
public OnPluginStart()
{
	AutoExecConfig_SetFile("throwing_knifes", "stamm/features");
	AutoExecConfig_SetCreateFile(true);

	g_hThrowingKnife = AutoExecConfig_CreateConVar("throwingknife_amount", "3", "x = Amount of throwing knifes VIP's get");
	g_hAddThrowingKnifes = AutoExecConfig_CreateConVar("throwingknife_onlyadd", "0", "1 = Only append throwing knifes to old ones, 0 = Set them new");

	AutoExecConfig_CleanFile();
	AutoExecConfig_ExecuteFile();
	

	HookEvent("player_spawn", eventPlayerSpawn);
}




// Client changed feature
public STAMM_OnClientChangedFeature(client, bool:mode, bool:isShop)
{
	if (!mode && !GetConVarBool(g_hAddThrowingKnifes)) 
	{
		SetClientThrowingKnives(client, 0);
	}
}




// A Player spawned, check his knifes
public Action:eventPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	CreateTimer(1.0, SetKnifes, client);
}




// Add knifes
public Action:SetKnifes(Handle:timer, any:client)
{
	if (STAMM_IsClientValid(client))
	{
		// First set to zero
		if (!GetConVarBool(g_hAddThrowingKnifes))
		{
			SetClientThrowingKnives(client, 0);
		}
		
		// Check if VIP and want it
		if (STAMM_HaveClientFeature(client))
		{
			// If valid -> Give knifes
			if ((GetClientTeam(client) == 2 || GetClientTeam(client) == 3) && IsPlayerAlive(client)) 
			{
				if (GetConVarBool(g_hAddThrowingKnifes))
				{
					SetClientThrowingKnives(client, GetClientThrowingKnives(client) + GetConVarInt(g_hThrowingKnife));
				}
				else
				{
					SetClientThrowingKnives(client, GetConVarInt(g_hThrowingKnife));
				}
			}
		}
	}
}