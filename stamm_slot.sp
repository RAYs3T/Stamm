/**
 * -----------------------------------------------------
 * File        stamm_slot.sp
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




new Handle:g_hLetFree;
new Handle:g_hVIPKickMessage;
new Handle:g_hVIPKickMessage2;
new Handle:g_hVIPSlots;

new let_free;
new vip_slots;

new String:vip_kick_message[128];
new String:vip_kick_message2[128];




// Information
public Plugin:myinfo =
{
	name = "Stamm Feature VIP Slot",
	author = "Popoklopsi",
	version = "${-version-}", // Version is replaced by GitLab runner due the build phase
	description = "Give VIP's a VIP Slot",
	url = "https://gitlab.com/PushTheLimits/Sourcemod/Stamm/wikis"
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


	STAMM_LoadTranslation();
	STAMM_RegisterFeature("VIP Slot");
}




// Add descriptions
public STAMM_OnClientRequestFeatureInfo(client, block, &Handle:array)
{
	decl String:fmt[256];
	
	Format(fmt, sizeof(fmt), "%T", "GetSlot", client);
	
	PushArrayString(array, fmt);
}




// Create cvars
public OnPluginStart()
{
	AutoExecConfig_SetFile("slot", "stamm/features");
	AutoExecConfig_SetCreateFile(true);

	g_hLetFree = AutoExecConfig_CreateConVar("slot_let_free", "1", "1 = Let a Slot always free and kick a random Player  0 = Off");
	g_hVIPKickMessage = AutoExecConfig_CreateConVar("slot_vip_kick_message", "You joined on a Reserve Slot", "Message, when someone join on a Reserve Slot");
	g_hVIPKickMessage2 = AutoExecConfig_CreateConVar("slot_vip_kick_message2", "You get kicked, to let a VIP slot free", "Message for the random kicked person");
	g_hVIPSlots = AutoExecConfig_CreateConVar("slot_vip_slots", "2", "How many Reserve Slots should there be ?");
	
	AutoExecConfig_CleanFile();
	AutoExecConfig_ExecuteFile();
}



// Load Config
public OnConfigsExecuted()
{
	let_free = GetConVarInt(g_hLetFree);
	
	GetConVarString(g_hVIPKickMessage, vip_kick_message, sizeof(vip_kick_message));
	GetConVarString(g_hVIPKickMessage2, vip_kick_message2, sizeof(vip_kick_message2));
	
	vip_slots = GetConVarInt(g_hVIPSlots);
}



// A Client is ready
public STAMM_OnClientReady(client)
{
	VipSlotCheck(client);
}



// Check him
public VipSlotCheck(client)
{
	new max_players = MaxClients;
	new current_players = GetClientCount(false);
	new max_slots = max_players - current_players;
	


	// vip slots greater than max slots?
	if (vip_slots > max_slots)
	{
		// -> Kick non VIP's
		if (!STAMM_HaveClientFeature(client)) 
		{
			KickClient(client, vip_kick_message);
		}
	}
	
	
	// Check for let a slot free
	current_players = GetClientCount(false);
	max_slots = max_players - current_players;
	

	
	// Want let free?
	if (let_free)
	{
		// No slot is free?
		if (!max_slots)
		{
			new bool:playeringame = false;
			
			// Check all players
			while(!playeringame)
			{
				// Get random player
				new RandPlayer = GetRandomInt(1, MaxClients);
				
				// Check if client is valid
				if (STAMM_IsClientValid(RandPlayer))
				{
					// Only non admins and non vips
					if (!STAMM_HaveClientFeature(RandPlayer) && !STAMM_IsClientAdmin(RandPlayer))
					{
						// kick to let free
						KickClient(RandPlayer, vip_kick_message2);
						
						playeringame = true;
					}
				}
			}
		}
	}
}