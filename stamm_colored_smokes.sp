/**
 * -----------------------------------------------------
 * File        stamm_colored_smokes.sp
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



new Handle:g_hColors;
new Handle:g_hModeSmoke;




public Plugin:myinfo =
{
	name = "Stamm Feature Colored Smokes",
	author = "Popoklopsi",
	version = "${-version-}", // Version is replaced by GitLab runner due the build phase
	description = "Give VIP's colored smokes",
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

	if (STAMM_GetGame() != GameCSS && STAMM_GetGame() != GameCSGO) 
	{
		SetFailState("Can't Load Feature, not Supported for your game!");
	}


	STAMM_LoadTranslation();
	STAMM_RegisterFeature("VIP Colored Smokes");
}




// Add descriptions
public STAMM_OnClientRequestFeatureInfo(client, block, &Handle:array)
{
	decl String:fmt[256];
	
	Format(fmt, sizeof(fmt), "%T", "GetColoredSmokes", client);
	
	PushArrayString(array, fmt);
}



// Create config
public OnPluginStart()
{
	AutoExecConfig_SetFile("colored_smokes", "stamm/features");
	AutoExecConfig_SetCreateFile(true);

	g_hModeSmoke = AutoExecConfig_CreateConVar("smoke_mode", "0", "The Mode: 0=Team Colors, 1=Random, 2=Party, 3=Custom");
	g_hColors = AutoExecConfig_CreateConVar("smoke_color", "255 255 255", "When mode = 3: RGB colors of the smoke");
	
	AutoExecConfig_CleanFile();
	AutoExecConfig_ExecuteFile();
	

	HookEvent("smokegrenade_detonate", eventHeDetonate);
}





// Smoke grenade Detonate
public Action:eventHeDetonate(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:colors[64];

	new client = GetClientOfUserId(GetEventInt(event, "userid"));


	GetConVarString(g_hColors, colors, sizeof(colors));
	

	if (STAMM_IsClientValid(client))
	{
		if (STAMM_HaveClientFeature(client))
		{
			new Float:origin[3];
			decl String:sBuffer[64];
			
			// Get origin
			origin[0] = GetEventFloat(event, "x");
			origin[1] = GetEventFloat(event, "y");
			origin[2] = GetEventFloat(event, "z");


			// Create a light ;D
			new ent_light = CreateEntityByName("light_dynamic");


			// Could we create it?
			if (ent_light != -1)
			{
				// Switch Mode
				switch (GetConVarInt(g_hModeSmoke))
				{
					case 0:
					{
						// Team color
						new team = GetClientTeam(client);
						
						if (team == 2) 
						{
							DispatchKeyValue(ent_light, "_light", "255 0 0");
						}
						else if (team == 3) 
						{
							DispatchKeyValue(ent_light, "_light", "0 0 255");
						}
					}
					case 1:
					{
						// Random color
						new color_r = GetRandomInt(0, 255);
						new color_g = GetRandomInt(0, 255);
						new color_b = GetRandomInt(0, 255);
						
						Format(sBuffer, sizeof(sBuffer), "%i %i %i", color_r, color_g, color_b);
						DispatchKeyValue(ent_light, "_light", sBuffer);
					}			
					case 2:
					{
						// Party Mode
						CreateTimer(0.2, PartyLight, ent_light, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
					}
					case 3:
					{
						// Own color
						DispatchKeyValue(ent_light, "_light", sBuffer);
					}
				}	
				
				// Set it up
				DispatchKeyValue(ent_light, "pitch", "-90");
				DispatchKeyValue(ent_light, "distance", "256");
				DispatchKeyValue(ent_light, "spotlight_radius", "96");
				DispatchKeyValue(ent_light, "brightness", "3");
				DispatchKeyValue(ent_light, "style", "6");
				DispatchKeyValue(ent_light, "spawnflags", "1");
				DispatchSpawn(ent_light);
				
				AcceptEntityInput(ent_light, "DisableShadow");
				AcceptEntityInput(ent_light, "TurnOn");
				
				// Create and teleport to smoke
				TeleportEntity(ent_light, origin, NULL_VECTOR, NULL_VECTOR);
				
				CreateTimer(20.0, Timer_Delete, ent_light, TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
}




// Party Mode
public Action:PartyLight(Handle:timer, any:light)
{
	// finish
	if (!IsValidEntity(light)) 
	{
		return Plugin_Stop;
	}


	// Always set up with random color
	decl String:sBuffer[64];
				
	new color_r = GetRandomInt(0, 255);
	new color_g = GetRandomInt(0, 255);
	new color_b = GetRandomInt(0, 255);
	

	Format(sBuffer, sizeof(sBuffer), "%i %i %i 200", color_r, color_g, color_b);
	DispatchKeyValue(light, "_light", sBuffer);
	
	return Plugin_Continue;
}




// Delete the light on finish
public Action:Timer_Delete(Handle:timer, any:light)
{
	if (IsValidEntity(light))
	{
		decl String:class[128];
		
		GetEdictClassname(light, class, sizeof(class));
		
		
		if (StrEqual(class, "light_dynamic")) 
		{
			RemoveEdict(light);
		}
	}
} 
