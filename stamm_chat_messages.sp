#include <sourcemod>
#include <colors>
#undef REQUIRE_PLUGIN
#include <stamm>
#include <updater>

#pragma semicolon 1

public Plugin:myinfo =
{
	name = "Stamm Feature Chat Messages",
	author = "Popoklopsi",
	version = "1.2.0",
	description = "Give VIP's VIP Chat and Message",
	url = "https://forums.alliedmods.net/showthread.php?t=142073"
};

public OnAllPluginsLoaded()
{
	if (!LibraryExists("stamm")) 
		SetFailState("Can't Load Feature, Stamm is not installed!");

	if (!CColorAllowed(Color_Lightgreen))
	{
		if (CColorAllowed(Color_Lime))
			CReplaceColor(Color_Lightgreen, Color_Lime);
		else if (CColorAllowed(Color_Olive))
			CReplaceColor(Color_Lightgreen, Color_Olive);
	}
		
	STAMM_LoadTranslation();
		
	STAMM_AddFeature("VIP Chat Messages", "");
}

public STAMM_OnFeatureLoaded(String:basename[])
{
	decl String:description[64];
	decl String:urlString[256];

	Format(urlString, sizeof(urlString), "http://popoklopsi.de/stamm/updater/update.php?plugin=%s", basename);

	if (LibraryExists("updater"))
		Updater_AddPlugin(urlString);

	Format(description, sizeof(description), "%T", "GetWelcomeMessages", LANG_SERVER);
	STAMM_AddFeatureText(STAMM_GetLevel(STAMM_GetBlockOfName("welcome")), description);

	Format(description, sizeof(description), "%T", "GetLeaveMessages", LANG_SERVER);
	STAMM_AddFeatureText(STAMM_GetLevel(STAMM_GetBlockOfName("leave")), description);
}

public STAMM_OnClientReady(client)
{
	decl String:name[MAX_NAME_LENGTH + 1];
	
	GetClientName(client, name, sizeof(name));
	
	if (STAMM_IsClientValid(client) && STAMM_HaveClientFeature(client, STAMM_GetBlockOfName("welcome")))
		CPrintToChatAll("{lightgreen}[ {green}Stamm {lightgreen}] %T", "WelcomeMessage", LANG_SERVER, name);
}

public OnClientDisconnect(client)
{
	if (STAMM_IsClientValid(client))
	{
		decl String:name[MAX_NAME_LENGTH + 1];
		
		GetClientName(client, name, sizeof(name));

		if (STAMM_HaveClientFeature(client, STAMM_GetBlockOfName("leave")))
			CPrintToChatAll("{lightgreen}[ {green}Stamm {lightgreen}] %T", "LeaveMessage", LANG_SERVER, name);
	}
}