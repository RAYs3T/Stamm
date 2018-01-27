/**
 * -----------------------------------------------------
 * File        stamm_holy.sp
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
#include <autoexecconfig>

#undef REQUIRE_PLUGIN
#include <stamm>

#pragma semicolon 1



new Handle:g_hHearAll;
new bool:g_hUseNew = false;




public Plugin:myinfo =
{
	name = "Stamm Feature Holy Granade",
	author = "Popoklopsi",
	version = "1.4.1",
	description = "Give VIP's a holy granade",
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
	STAMM_RegisterFeature("VIP Holy Grenade");
}




// Add descriptions
public STAMM_OnClientRequestFeatureInfo(client, block, &Handle:array)
{
	decl String:fmt[256];
	
	Format(fmt, sizeof(fmt), "%T", "GetHoly", client);
	
	PushArrayString(array, fmt);
}




// Create Config
public OnPluginStart()
{
	AutoExecConfig_SetFile("holy_grenade", "stamm/features");
	AutoExecConfig_SetCreateFile(true);

	g_hHearAll = AutoExecConfig_CreateConVar("holy_hear", "1", "0=Every one hear Granade, 1=Only Player who throw it");
	
	AutoExecConfig_CleanFile();
	AutoExecConfig_ExecuteFile();
	
	HookEvent("weapon_fire", eventWeaponFire);
	HookEvent("hegrenade_detonate", eventHeDetonate);
}




// Load configs and download and precache files
public OnConfigsExecuted()
{
	// Check new Sound path
	if (FileExists("sound/stamm/throw.mp3"))
	{
		g_hUseNew = true;
	}
	

	// Download all files
	if (!g_hUseNew)
	{
		AddFileToDownloadsTable("sound/music/stamm/throw.mp3");
		AddFileToDownloadsTable("sound/music/stamm/explode.mp3");
	}
	else
	{
		AddFileToDownloadsTable("sound/stamm/throw.mp3");
		AddFileToDownloadsTable("sound/stamm/explode.mp3");
	}
	

	AddFileToDownloadsTable("materials/models/stamm/holy_grenade.vtf");
	AddFileToDownloadsTable("models/stamm/holy_grenade.mdl");
	AddFileToDownloadsTable("materials/models/stamm/holy_grenade.vmt");
	AddFileToDownloadsTable("models/stamm/holy_grenade.vvd");
	AddFileToDownloadsTable("models/stamm/holy_grenade.sw.vtx");
	AddFileToDownloadsTable("models/stamm/holy_grenade.phy");
	AddFileToDownloadsTable("models/stamm/holy_grenade.dx80.vtx");
	AddFileToDownloadsTable("models/stamm/holy_grenade.dx90.vtx");
	

	// Precache
	PrecacheModel("models/stamm/holy_grenade.mdl");
	PrecacheModel("materials/sprites/splodesprite.vmt");

	// Sound Stuff
	if (!g_hUseNew)
	{
		if (STAMM_GetGame() == GameCSGO)
		{
			AddToStringTable(FindStringTable("soundprecache"), "music/stamm/throw.mp3");
			AddToStringTable(FindStringTable("soundprecache"), "music/stamm/explode.mp3");
		}
		else
		{
			PrecacheSound("music/stamm/throw.mp3");
			PrecacheSound("music/stamm/explode.mp3");
		}
	}
	else
	{
		if (STAMM_GetGame() == GameCSGO)
		{
			AddToStringTable(FindStringTable("soundprecache"), "stamm/throw.mp3");
			AddToStringTable(FindStringTable("soundprecache"), "stamm/explode.mp3");
		}
		else
		{
			PrecacheSound("stamm/throw.mp3");
			PrecacheSound("stamm/explode.mp3");
		}
	}
}




public OnMapStart()
{
	OnConfigsExecuted();
}




// A weapon fired
public Action:eventWeaponFire(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);
	decl String:weapon[256];
	

	GetEventString(event, "weapon", weapon, sizeof(weapon));
	
	if (STAMM_IsClientValid(client))
	{
		// Was it a grenade?
		if (StrEqual(weapon, "hegrenade")) 
		{
			// Client is VIP?
			if (STAMM_HaveClientFeature(client))
			{
				// Play a sound to client or to all?
				if (GetConVarInt(g_hHearAll)) 
				{
					if (!g_hUseNew)
					{
						EmitSoundToClient(client, "music/stamm/throw.mp3");
					}

					else 
					{
						EmitSoundToClient(client, "stamm/throw.mp3");
					}
				}
				else
				{
					if (STAMM_GetGame() != GameCSGO)
					{
						EmitSoundToAll("music/stamm/throw.mp3");
					}

					else
					{
						for (new i=0; i <= MaxClients; i++)
						{
							if (STAMM_IsClientValid(i))
							{
								ClientCommand(i, "play music/stamm/throw.mp3");
							}
						}
					}
				}
				
				// Change model of HE
				CreateTimer(0.25, change, client);
			}
		}
	}
}





// Grenade detonate
public Action:eventHeDetonate(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);
	new Float:origin[3];
	

	// Dest. location
	origin[0] = float(GetEventInt(event, "x"));
	origin[1] = float(GetEventInt(event, "y"));
	origin[2] = float(GetEventInt(event, "z"));
	

	// Client valid and is VIP?
	if (STAMM_IsClientValid(client))
	{
		if (STAMM_HaveClientFeature(client))
		{
			// Create a shake and a explosion
			new explode = CreateEntityByName("env_explosion");
			new shake = CreateEntityByName("env_shake");
			
			if (explode != -1 && shake != -1)
			{
				// Set up the explode and shake
				DispatchKeyValue(explode, "fireballsprite", "sprites/splodesprite.vmt");
				DispatchKeyValue(explode, "iMagnitude", "20");
				DispatchKeyValue(explode, "iRadiusOverride", "500");
				DispatchKeyValue(explode, "rendermode", "5");
				DispatchKeyValue(explode, "spawnflags", "2");
				
				DispatchKeyValue(shake, "amplitude", "4");
				DispatchKeyValue(shake, "duration", "5");
				DispatchKeyValue(shake, "frequency", "255");
				DispatchKeyValue(shake, "radius", "500");
				DispatchKeyValue(shake, "spawnflags", "0");
				
				// Spawn them
				DispatchSpawn(explode);
				DispatchSpawn(shake);
				
				// Teleport them
				TeleportEntity(explode, origin, NULL_VECTOR, NULL_VECTOR);
				TeleportEntity(shake, origin, NULL_VECTOR, NULL_VECTOR);
				
				// LETS GO!
				AcceptEntityInput(explode, "Explode");
				AcceptEntityInput(shake, "StartShake");
				
			}
			

			// Play sound
			if (GetConVarInt(g_hHearAll)) 
			{
				if (!g_hUseNew)
				{
					EmitSoundToClient(client, "music/stamm/explode.mp3");
				}

				else 
				{
					EmitSoundToClient(client, "stamm/explode.mp3");
				}
			}
			else
			{
				if (!g_hUseNew)
				{
					EmitSoundToAll("music/stamm/explode.mp3");
				}

				else
				{
					EmitSoundToAll("stamm/explode.mp3");
				}
			}
		}
	}
}





// Change the model
public Action:change(Handle:timer, any:client)
{
	new ent = -1;
	
	ent = FindEntityByClassname(ent, "hegrenade_projectile");
	
	// Found projectile?
	if (ent > -1)
	{
		new owner = GetEntPropEnt(ent, Prop_Send, "m_hThrower");
		
		// Everything is valid?
		if (IsValidEntity(ent) && owner == client) 
		{
			// Change the model
			SetEntityModel(ent, "models/stamm/holy_grenade.mdl");
		}
	}
}
