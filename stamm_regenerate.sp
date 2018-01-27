/**
 * -----------------------------------------------------
 * File        stamm_regenerate.sp
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
new Handle:g_hTime;
new bool:g_bStarted;


// Plugin Info
public Plugin:myinfo =
{
	name = "Stamm Feature RegenerateHP",
	author = "Popoklopsi",
	version = "${-version-}", // Version is replaced by GitLab runner due the build phase
	description = "Regenerate HP of VIP's",
	url = "https://gitlab.com/PushTheLimits/Sourcemod/Stamm/wikis"
};




// Add feature to stamm
public OnAllPluginsLoaded()
{
	if (!STAMM_IsAvailable()) 
	{
		SetFailState("Can't Load Feature, Stamm is not installed!");
	}

	STAMM_LoadTranslation();
	STAMM_RegisterFeature("VIP HP Regenerate");
}



public STAMM_OnFeatureLoaded(const String:basename[])
{
}




// Add descriptions
public STAMM_OnClientRequestFeatureInfo(client, block, &Handle:array)
{
	decl String:fmt[256];
	
	Format(fmt, sizeof(fmt), "%T", "GetRegenerate", client, GetConVarInt(g_hHP) * block, GetConVarInt(g_hTime));
	
	PushArrayString(array, fmt);
}




// Create Config
public OnPluginStart()
{
	g_bStarted = false;

	AutoExecConfig_SetFile("regenerate", "stamm/features");
	AutoExecConfig_SetCreateFile(true);

	g_hHP = AutoExecConfig_CreateConVar("regenerate_hp", "2", "HP regeneration of a VIP, every x seconds per block");
	g_hTime = AutoExecConfig_CreateConVar("regenerate_time", "1", "Time interval to regenerate (in Seconds)");
	
	AutoExecConfig_CleanFile();
	AutoExecConfig_ExecuteFile();
}




public OnConfigsExecuted()
{
	if (!g_bStarted)
	{
		g_bStarted = true;
		CreateTimer(float(GetConVarInt(g_hTime)), GiveHealth, _, TIMER_REPEAT);
	}
}



// Regenerate Timer
public Action:GiveHealth(Handle:timer, any:data)
{
	for (new client=1; client <= MaxClients; client++)
	{
		// Is client valid?
		if (STAMM_IsClientValid(client) && STAMM_HaveClientFeature(client))
		{
			// Get highest client block
			new clientBlock = STAMM_GetClientBlock(client);


			// Have client block and is player alive and in right team?
			if (clientBlock > 0 && IsPlayerAlive(client) && (GetClientTeam(client) == 2 || GetClientTeam(client) == 3))
			{
				// Get max Health and add regenerate HP
				new maxHealth = GetEntProp(client, Prop_Data, "m_iMaxHealth");

				new oldHP = GetClientHealth(client);
				new newHP = oldHP + GetConVarInt(g_hHP) * clientBlock;
				
				// Only if not higher than max Health
				if (newHP > maxHealth)
				{
					if (oldHP < maxHealth) 
					{
						newHP = maxHealth;
					}
					else 
					{
						continue;
					}
				}
				
				SetEntityHealth(client, newHP);
			}
		}
	}
	
	return Plugin_Continue;
}
