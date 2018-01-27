/**
 * -----------------------------------------------------
 * File        stamm_resizeplayer.sp
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


// Include 
#include <sourcemod>
#include <autoexecconfig>

#undef REQUIRE_PLUGIN
#include <stamm>

#pragma semicolon 1




new Handle:g_hResize;
new Float:g_hClientSize[MAXPLAYERS + 1];




// Plugin ifno
public Plugin:myinfo =
{
	name = "Stamm Feature ResizePlayer",
	author = "Popoklopsi",
	version = "1.1.1",
	description = "Resizes VIP's",
	url = "https://forums.alliedmods.net/showthread.php?t=142073"
};




// All Plugins loaded
public OnAllPluginsLoaded()
{
	// Stamm not found
	if (!STAMM_IsAvailable()) 
	{
		SetFailState("Can't Load Feature, Stamm is not installed!");
	}

	// Not for game CSGO
	if (STAMM_GetGame() == GameCSGO) 
	{
		SetFailState("Can't Load Feature. not Supported for your game!");
	}


	// Load translation and add feaure
	STAMM_LoadTranslation();
	STAMM_RegisterFeature("VIP Resize Player");
}




// Feature started
public OnPluginStart()
{
	// Hook event player spawn
	HookEvent("player_spawn", PlayerSpawn);


	// Create Config
	AutoExecConfig_SetFile("resizeplayer", "stamm/features");
	AutoExecConfig_SetCreateFile(true);

	g_hResize = AutoExecConfig_CreateConVar("resize_amount", "10", "Resize amount in(+)/de(-)crease in percent each block!");
	
	AutoExecConfig_CleanFile();
	AutoExecConfig_ExecuteFile();
}



public STAMM_OnFeatureLoaded(const String:basename[])
{
}




// Add descriptions
public STAMM_OnClientRequestFeatureInfo(client, block, &Handle:array)
{
	decl String:fmt[256];
	
	Format(fmt, sizeof(fmt), "%T", "GetResize", client, GetConVarInt(g_hResize) * block);
	
	PushArrayString(array, fmt);
}




// Client is ready
public STAMM_OnClientReady(client)
{
	// Default size is 1.0
	g_hClientSize[client] = 1.0;

	// For each block
	for (new i=STAMM_GetBlockCount(); i > 0; i--)
	{
		// Client has feature
		if (STAMM_HaveClientFeature(client, i))
		{
			// set new size
			g_hClientSize[client] = 1.0 + float(GetConVarInt(g_hResize))/100.0 * i;

			if (g_hClientSize[client] < 0.1) 
			{
				g_hClientSize[client] = 0.1;
			}

			// Break here
			break;
		}
	}
}



// Resize player on Spawn
public PlayerSpawn(Handle:event, String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	STAMM_OnClientChangedFeature(client, true, false);
}



public STAMM_OnClientBecomeVip(client, oldlevel, newlevel)
{
	STAMM_OnClientReady(client);
}



// Client changed a feature
public STAMM_OnClientChangedFeature(client, bool:mode, bool:isShop)
{
	if (STAMM_IsClientValid(client))
	{
		// Resize is defined in metod OnClientReady
		STAMM_OnClientReady(client);


		// Setz size
		SetEntPropFloat(client, Prop_Send, "m_flModelScale", g_hClientSize[client]);


		if (STAMM_GetGame() == GameTF2)
		{
			// On TF2 setz head size
			SetEntPropFloat(client, Prop_Send, "m_flHeadScale", g_hClientSize[client]);
		}
	}
}



// For TF2 set head size on game frame
public OnGameFrame()
{
	if (STAMM_GetGame() == GameTF2)
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (STAMM_IsClientValid(i) && g_hClientSize[i] != 1.0)
			{
				// Set head size
				SetEntPropFloat(i, Prop_Send, "m_flHeadScale", g_hClientSize[i]);
			}
		}
	}
}