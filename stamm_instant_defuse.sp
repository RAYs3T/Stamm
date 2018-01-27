/**
 * -----------------------------------------------------
 * File        stamm_instant_defuse.sp
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
#include <sdktools>

#undef REQUIRE_PLUGIN
#include <stamm>

#pragma semicolon 1



public Plugin:myinfo =
{
	name = "Stamm Feature Instant Defuse",
	author = "Popoklopsi",
	version = "${-version-}", // Version is replaced by GitLab runner due the build phase
	description = "VIP's can defuse the bomb instantly",
	url = "https://forums.alliedmods.net/showthread.php?t=142073"
};




public STAMM_OnFeatureLoaded(const String:basename[])
{
}




// Add Feature
public OnAllPluginsLoaded()
{
	if (!STAMM_IsAvailable()) 
	{
		SetFailState("Can't Load Feature, Stamm is not installed!");
	}
	
	if (STAMM_GetGame() == GameTF2 || STAMM_GetGame() == GameDOD) 
	{
		SetFailState("Can't Load Feature, not Supported for your game!");
	}
		

	STAMM_LoadTranslation();
	STAMM_RegisterFeature("VIP Instant Defuse");
}




// Add descriptions
public STAMM_OnClientRequestFeatureInfo(client, block, &Handle:array)
{
	decl String:fmt[256];
	
	Format(fmt, sizeof(fmt), "%T", "GetInstantDefuse", client);
	
	PushArrayString(array, fmt);
}




// Hook defuse begin
public OnPluginStart()
{
	HookEvent("bomb_begindefuse", Event_Defuse);
}




// Handle defusing
public Event_Defuse(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (STAMM_IsClientValid(client))
	{
		// Set to defuse
		if (STAMM_HaveClientFeature(client)) 
		{
			CreateTimer(0.5, setCountdown, client);
		}
	}
}



// No set countdown to zero
public Action:setCountdown(Handle:timer, any:client)
{
	new bombent = FindEntityByClassname(-1, "planted_c4");
	
	if (bombent) 
	{
		SetEntPropFloat(bombent, Prop_Send, "m_flDefuseCountDown", 0.1);
	}
}