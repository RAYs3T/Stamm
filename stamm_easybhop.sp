/**
 * -----------------------------------------------------
 * File        stamm_easybhop.sp
 * Authors     Bara
 * License     GPLv3
 * Web         https://bara.in
 * -----------------------------------------------------
 * 
 * Copyright (C) 2012-2014 Bara
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


#include <sourcemod>

#undef REQUIRE_PLUGIN
#include <stamm>

#pragma semicolon 1



public Plugin:myinfo =
{
	name = "Stamm Feature EasyBhop",
	author = "Bara",
	version = "${-version-}", // Version is replaced by GitLab runner due the build phase
	description = "Give VIP's eady bunnyhop",
	url = "www.bara.in"
};


public STAMM_OnFeatureLoaded(const String:basename[])
{
}


// Add the feature
public OnAllPluginsLoaded()
{
	if (!STAMM_IsAvailable()) 
	{
		SetFailState("Can't Load Feature, Stamm is not installed!");
	}

	if (STAMM_GetGame() == GameTF2 || STAMM_GetGame() == GameDOD) 
	{
		SetFailState("Can't Load Feature. Not Supported for your game!");
	}


	STAMM_LoadTranslation();
	STAMM_RegisterFeature("VIP EasyBhop");
}




// Add descriptions
public STAMM_OnClientRequestFeatureInfo(client, block, &Handle:array)
{
	decl String:fmt[256];
	
	Format(fmt, sizeof(fmt), "%T", "GetEasyBhop", client);
	
	PushArrayString(array, fmt);
}



// Hook player jump
public OnPluginStart()
{
	HookEvent("player_jump", eventPlayerJump);
}



public Action:eventPlayerJump(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);
	
	// Set Stamina for VIPs to zero
	if (STAMM_IsClientValid(client) && STAMM_HaveClientFeature(client))
	{
		SetEntPropFloat(client, Prop_Send, "m_flStamina", 0.0);
	}
}
