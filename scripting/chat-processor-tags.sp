#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>
#include <chat-processor>
#include <chat-processor-tags>
#include <colorvariables>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION		"1.0"

public Plugin myinfo = {
	name		= "Chat-Processor Tags",
	author	  = "404 (abrandnewday)",
	description = "Processes chat and provides colors and tags for Source 2013 games",
	version	 = PLUGIN_VERSION,
	url		 = "http://www.unfgaming.net"
};

Handle hColorForward;
Handle hNameForward;
Handle hTagForward;
Handle hApplicationForward;
Handle hMessageForward;
Handle hPreLoadedForward;
Handle hLoadedForward;
Handle hConfigReloadedForward;

#define MAXLENGTH_256 256
#define MAXLENGTH_32 32

char g_strTag[MAXPLAYERS+1][MAXLENGTH_256];
char g_strTagColor[MAXPLAYERS+1][MAXLENGTH_32];
char g_strUsernameColor[MAXPLAYERS+1][MAXLENGTH_32];
char g_strTextColor[MAXPLAYERS+1][MAXLENGTH_32];

char g_strDefaultTag[MAXPLAYERS+1][MAXLENGTH_256];
char g_strDefaultTagColor[MAXPLAYERS+1][MAXLENGTH_32];
char g_strDefaultUsernameColor[MAXPLAYERS+1][MAXLENGTH_32];
char g_strDefaultTextColor[MAXPLAYERS+1][MAXLENGTH_32];

KeyValues kvConfigFile = null;

public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] strError, int iErrMax)
{
	CreateNative("CPT_GetColor", Native_GetColor);
	CreateNative("CPT_SetColor", Native_SetColor);
	CreateNative("CPT_GetTag", Native_GetTag);
	CreateNative("CPT_SetTag", Native_SetTag);
	CreateNative("CPT_ResetColor", Native_ResetColor);
	CreateNative("CPT_ResetTag", Native_ResetTag);
	
	RegPluginLibrary("cpt");
	
	return APLRes_Success;
} 

public void OnPluginStart()
{
	CreateConVar("sm_cpt_version", PLUGIN_VERSION, "Chat-Processor Tags version", FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegAdminCmd("sm_reloadtags", Command_ReloadConfig, ADMFLAG_CONFIG, "Reloads Custom Chat Colors config file");
	hColorForward = CreateGlobalForward("CPT_OnTextColor", ET_Event, Param_Cell);
	hNameForward = CreateGlobalForward("CPT_OnNameColor", ET_Event, Param_Cell);
	hTagForward = CreateGlobalForward("CPT_OnTagApplied", ET_Event, Param_Cell);
	hApplicationForward = CreateGlobalForward("CPT_OnColor", ET_Event, Param_Cell, Param_String, Param_Cell);
	hMessageForward = CreateGlobalForward("CPT_OnChatMessage", ET_Ignore, Param_Cell, Param_String, Param_Cell);
	hPreLoadedForward = CreateGlobalForward("CPT_OnUserConfigPreLoaded", ET_Event, Param_Cell);
	hLoadedForward = CreateGlobalForward("CPT_OnUserConfigLoaded", ET_Ignore, Param_Cell);
	hConfigReloadedForward = CreateGlobalForward("CPT_OnConfigReloaded", ET_Ignore);
	LoadConfig();
}

void LoadConfig()
{
	if(kvConfigFile != null)
	{
		delete kvConfigFile;
	}
	kvConfigFile = new KeyValues("chat_processor_tags");
	char strPath[64];
	BuildPath(Path_SM, strPath, sizeof(strPath), "configs/chat-processor-tags.cfg");
	if(!kvConfigFile.ImportFromFile(strPath))
	{
		SetFailState("Config file missing");
	}
	for(int i = 1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i) || IsFakeClient(i))
		{
			continue;
		}
		ClearValues(i);
		OnClientPostAdminCheck(i);
	}
}

public Action Command_ReloadConfig(int iClient, int iArgs)
{
	LoadConfig();
	LogAction(iClient, -1, "Reloaded Chat-Processor Tags config file");
	ReplyToCommand(iClient, "[CPT] Reloaded config file.");
	Call_StartForward(hConfigReloadedForward);
	Call_Finish();
	return Plugin_Handled;
}

stock void ClearValues(int iClient)
{
	Format(g_strTag[iClient], sizeof(g_strTag[]), "");
	Format(g_strTagColor[iClient], sizeof(g_strTagColor[]), "");
	Format(g_strUsernameColor[iClient], sizeof(g_strUsernameColor[]), "");
	Format(g_strTextColor[iClient], sizeof(g_strTextColor[]), "");

	Format(g_strDefaultTag[iClient], sizeof(g_strDefaultTag[]), "");
	Format(g_strDefaultTagColor[iClient], sizeof(g_strDefaultTagColor[]), "");
	Format(g_strDefaultUsernameColor[iClient], sizeof(g_strDefaultUsernameColor[]), "");
	Format(g_strDefaultTextColor[iClient], sizeof(g_strDefaultTextColor[]), "");
}

public void OnClientConnected(int iClient)
{
	ClearValues(iClient);
}

public void OnClientDisconnect(int iClient)
{
	ClearValues(iClient);
}

public void OnClientPostAdminCheck(int iClient)
{
	if(!ConfigForward(iClient))
	{
		return;
	}
	
	char strAuthId2[32];
	GetClientAuthId(iClient, AuthId_Steam2, strAuthId2, sizeof(strAuthId2));
	kvConfigFile.Rewind();
	if(!kvConfigFile.JumpToKey(strAuthId2))
	{
		kvConfigFile.Rewind();
		kvConfigFile.GotoFirstSubKey();
		AdminId iAdmin = GetUserAdmin(iClient);
		AdminFlag fFlag;
		char strConfigFlag[2];
		char strSection[32];
		bool bFound = false;
		do
		{
			kvConfigFile.GetSectionName(strSection, sizeof(strSection));
			kvConfigFile.GetString("flag", strConfigFlag, sizeof(strConfigFlag));
			if(strlen(strConfigFlag) > 1)
			{
				LogError("Multiple flags given in section \"%s\", which is not allowed. Using first character.", strSection);
			}
			if(strlen(strConfigFlag) == 0 && StrContains(strSection, "STEAM_", false) == -1 && StrContains(strSection, "[U:1:", false) == -1)
			{
				bFound = true;
				break;
			}
			if(!FindFlagByChar(strConfigFlag[0], fFlag))
			{
				if(strlen(strConfigFlag) > 0)
				{
					LogError("Invalid flag given for section \"%s\", skipping", strSection);
				}
				continue;
			}
			if(GetAdminFlag(iAdmin, fFlag))
			{
				bFound = true;
				break;
			}
		} while(kvConfigFile.GotoNextKey());
		if(!bFound)
		{
			return;
		}
	}
	
	char strClientTagColor[12];
	char strClientNameColor[12];
	char strClientTextColor[12];
	
	kvConfigFile.GetString("tag", g_strTag[iClient], sizeof(g_strTag[]));
	kvConfigFile.GetString("tagcolor", strClientTagColor, sizeof(strClientTagColor));
	kvConfigFile.GetString("namecolor", strClientNameColor, sizeof(strClientNameColor));
	kvConfigFile.GetString("textcolor", strClientTextColor, sizeof(strClientTextColor));
	
	ReplaceString(strClientTagColor, sizeof(strClientTagColor), "#", "");
	ReplaceString(strClientNameColor, sizeof(strClientNameColor), "#", "");
	ReplaceString(strClientTextColor, sizeof(strClientTextColor), "#", "");
	
	int iTagColorLength = strlen(strClientTagColor);
	int iNameColorLength = strlen(strClientNameColor);
	int iTextColorLength = strlen(strClientTextColor);
	
	if(iTagColorLength == 6 || iTagColorLength == 8 || StrEqual(strClientTagColor, "T", false) || StrEqual(strClientTagColor, "G", false) || StrEqual(strClientTagColor, "O", false))
	{
		strcopy(g_strTagColor[iClient], sizeof(g_strTagColor[]), strClientTagColor);
	}
	if(iNameColorLength == 6 || iNameColorLength == 8 || StrEqual(strClientNameColor, "G", false) || StrEqual(strClientNameColor, "O", false))
	{
		strcopy(g_strUsernameColor[iClient], sizeof(g_strUsernameColor[]), strClientNameColor);
	}
	if(iTextColorLength == 6 || iTextColorLength == 8 || StrEqual(strClientTextColor, "T", false) || StrEqual(strClientTextColor, "G", false) || StrEqual(strClientTextColor, "O", false))
	{
		strcopy(g_strTextColor[iClient], sizeof(g_strTextColor[]), strClientTextColor);
	}
	strcopy(g_strDefaultTag[iClient], sizeof(g_strDefaultTag[]), g_strTag[iClient]);
	strcopy(g_strDefaultTagColor[iClient], sizeof(g_strDefaultTagColor[]), g_strTagColor[iClient]);
	strcopy(g_strDefaultUsernameColor[iClient], sizeof(g_strDefaultUsernameColor[]), g_strUsernameColor[iClient]);
	strcopy(g_strDefaultTextColor[iClient], sizeof(g_strDefaultTextColor[]), g_strTextColor[iClient]);
	Call_StartForward(hLoadedForward);
	Call_PushCell(iClient);
	Call_Finish();
}

public Action OnChatMessage(int& iAuthor, ArrayList hRecipients, eChatFlags& fFlag, char[] strName, char[] strMessage, bool& bProcessColors, bool& bRemoveColors)
{
	bRemoveColors = true;
	
	return Plugin_Handled;
}
 
public void OnChatMessagePost(int iAuthor, ArrayList hRecipients, eChatFlags fFlag, const char[] strName, const char[] strMessage, bool bProcessColors, bool bRemoveColors)
{
	char strNewName[MAXLENGTH_256];
	strcopy(strNewName, sizeof(strNewName), strName);
	
	char strNewMessage[MAXLENGTH_256];
	strcopy(strNewMessage, sizeof(strNewMessage), strMessage);
	
	if(CheckForward(iAuthor, strNewMessage, CPT_NameColor))
	{
		if(StrEqual(g_strUsernameColor[iAuthor], "G", false))
		{
			Format(strNewName, MAXLENGTH_256, "\x04%s", strNewName);
		}
		else if(StrEqual(g_strUsernameColor[iAuthor], "O", false))
		{
			Format(strNewName, MAXLENGTH_256, "\x05%s", strNewName);
		}
		else if(strlen(g_strUsernameColor[iAuthor]) == 6)
		{
			Format(strNewName, MAXLENGTH_256, "\x07%s%s", g_strUsernameColor[iAuthor], strNewName);
		}
		else if(strlen(g_strUsernameColor[iAuthor]) == 8)
		{
			Format(strNewName, MAXLENGTH_256, "\x08%s%s", g_strUsernameColor[iAuthor], strNewName);
		}
		else
		{
			Format(strNewName, MAXLENGTH_256, "\x03%s", strNewName);
		}
	}
	else
	{
		Format(strNewName, MAXLENGTH_256, "\x03%s", strNewName);
	}
	
	// Check tag length to make sure it exists.
	if(strlen(g_strTag[iAuthor]) > 0)
	{
		// Check tag color.
		if(strlen(g_strTagColor[iAuthor]) > 0 && CheckForward(iAuthor, strNewMessage, CPT_TagColor))
		{
			if(StrEqual(g_strTagColor[iAuthor], "T", false))
			{
				Format(strNewName, MAXLENGTH_256, "\x03%s%s", g_strTag[iAuthor], strNewName);
			}
			else if(StrEqual(g_strTagColor[iAuthor], "G", false))
			{
				Format(strNewName, MAXLENGTH_256, "\x04%s%s", g_strTag[iAuthor], strNewName);
			}
			else if(StrEqual(g_strTagColor[iAuthor], "O", false))
			{
				Format(strNewName, MAXLENGTH_256, "\x05%s%s", g_strTag[iAuthor], strNewName);
			}
			else if(strlen(g_strTagColor[iAuthor]) == 6)
			{
				Format(strNewName, MAXLENGTH_256, "\x07%s%s%s", g_strTagColor[iAuthor], g_strTag[iAuthor], strNewName);
			}
			else if(strlen(g_strTagColor[iAuthor]) == 8)
			{
				Format(strNewName, MAXLENGTH_256, "\x08%s%s%s", g_strTagColor[iAuthor], g_strTag[iAuthor], strNewName);
			}
		}
		
		// This is where things function differently than Custom Chat Colors
		// This bit needs to be outside the above so that the tag actually displays in chat.
		// If it was up above, just after line 311, the tag would never show up in chat.
		// Why? Well, for TF2, you don't really *need* to use the 'tagcolor' config option.
		// So because no "tagcolor" line, it never proceeds to display the tag.
		// Seriously, just stick the "{valve}"-style color codes from ColorVariables.inc right into the "tag" line in your config file.
		// I modified this plugin to work that way for a reason.
		Format(strNewName, MAXLENGTH_256, "%s%s", g_strTag[iAuthor], strNewName);
	}
   
	if(strlen(g_strTextColor[iAuthor]) > 0 && CheckForward(iAuthor, strNewMessage, CPT_TextColor))
	{
		if(StrEqual(g_strTextColor[iAuthor], "T", false))
		{
			Format(strNewMessage, MAXLENGTH_256, "\x03%s", strNewMessage);
		}
		else if(StrEqual(g_strTextColor[iAuthor], "G", false))
		{
			Format(strNewMessage, MAXLENGTH_256, "\x04%s", strNewMessage);
		}
		else if(StrEqual(g_strTextColor[iAuthor], "O", false))
		{
			Format(strNewMessage, MAXLENGTH_256, "\x05%s", strNewMessage);
		}
		else if(strlen(g_strTextColor[iAuthor]) == 6)
		{
			Format(strNewMessage, MAXLENGTH_256, "\x07%s%s", g_strTextColor[iAuthor], strNewMessage);
		}
		else if(strlen(g_strTextColor[iAuthor]) == 8)
		{
			Format(strNewMessage, MAXLENGTH_256, "\x08%s%s", g_strTextColor[iAuthor], strNewMessage);
		}
	}
	else
	{
		Format(strNewMessage, MAXLENGTH_256, "\x01%s", strNewMessage);
	}
   
	char strGame[64];
	GetGameFolderName(strGame, sizeof(strGame));
	if(StrEqual(strGame, "csgo"))
	{
		// I don't even know what this fucking does or if it even fucking works.
		// Someone please tell me if this fucking thing works in CS:GO
		// I can't be bothered to test it in CS:GO because I think CS:GO is a boring game.
		// Sorry CS:GO, I just prefer Insurgency: Modern Infantry Combat and Insurgency 2.
		Format(strNewName, MAXLENGTH_256, "\x01\x0B%s", strNewName);
	}
	
	// For loop to send the message individually to each recipient.
	// Thank you Drixevel for helping me see this solution in your Chat-Processor plugin.
	// I simply emulated how Chat-Processor sends the message out.
	// Imitation is the sincerest form of flattery.
	for (int i = 0; i < GetArraySize(hRecipients); i++)
	{
		int client = GetArrayCell(hRecipients, i);

		if (IsClientInGame(client))
		{
			// Now we print the final message out to everyone via CPrintToChat
			// Why this way? Because we've now bypassed the 64 character limit on player names
			// That allows us to have way longer tags or tags with multiple colors, something CCC didn't support.
			// If we stuck to using strName and the 64 character limit, longer/multicolored tags would cut
			// half the player name off or in worse cases, only display like the first four letters of the tag
			// (for example "[OWN" out of "[OWNER]")
			CSetNextAuthor(iAuthor);
			CPrintToChat(client, "%s \x01: %s", strNewName, strNewMessage);
		}
	}
   
	Call_StartForward(hMessageForward);
	Call_PushCell(iAuthor);
	Call_PushStringEx(strNewMessage, MAXLENGTH_256, SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
	Call_PushCell(MAXLENGTH_256);
	Call_Finish();
}

stock bool CheckForward(int iAuthor, const char[] strMessage, CPT_ColorType tType)
{
	Action aResult = Plugin_Continue;
	Call_StartForward(hApplicationForward);
	Call_PushCell(iAuthor);
	Call_PushString(strMessage);
	Call_PushCell(tType);
	Call_Finish(aResult);
	if(aResult >= Plugin_Handled)
	{
		return false;
	}
	
	switch(tType)
	{
		case CPT_TagColor:
		{
			return TagForward(iAuthor);
		}
		case CPT_NameColor:
		{
			return NameForward(iAuthor);
		}
		case CPT_TextColor:
		{
			return ColorForward(iAuthor);
		}
	}
	
	return true;
}

stock bool ColorForward(int iAuthor)
{
	Action aResult = Plugin_Continue;
	Call_StartForward(hColorForward);
	Call_PushCell(iAuthor);
	Call_Finish(aResult);
	if(aResult >= Plugin_Handled)
	{
		return false;
	}
	
	return true;
}

stock bool NameForward(int iAuthor)
{
	Action aResult = Plugin_Continue;
	Call_StartForward(hNameForward);
	Call_PushCell(iAuthor);
	Call_Finish(aResult);
	if(aResult >= Plugin_Handled)
	{
		return false;
	}
	
	return true;
}

stock bool TagForward(int iAuthor)
{
	Action aResult = Plugin_Continue;
	Call_StartForward(hTagForward);
	Call_PushCell(iAuthor);
	Call_Finish(aResult);
	if(aResult >= Plugin_Handled)
	{
		return false;
	}
	
	return true;
}

stock bool ConfigForward(int iClient)
{
	Action aResult = Plugin_Continue;
	Call_StartForward(hPreLoadedForward);
	Call_PushCell(iClient);
	Call_Finish(aResult);
	if(aResult >= Plugin_Handled)
	{
		return false;
	}
	
	return true;
}

public int Native_GetColor(Handle hPlugin, int NumParams)
{
	int iClient = GetNativeCell(1);
	if(iClient < 1 || iClient > MaxClients || !IsClientInGame(iClient))
	{
		ThrowNativeError(SP_ERROR_PARAM, "Invalid client or client is not in game");
		return COLOR_NONE;
	}
	switch(GetNativeCell(2))
	{
		case CPT_TagColor:
		{
			if(StrEqual(g_strTagColor[iClient], "T", false))
			{
				SetNativeCellRef(3, false);
				return COLOR_TEAM;
			}
			else if(StrEqual(g_strTagColor[iClient], "G", false))
			{
				SetNativeCellRef(3, false);
				return COLOR_GREEN;
			}
			else if(StrEqual(g_strTagColor[iClient], "O", false))
			{
				SetNativeCellRef(3, false);
				return COLOR_OLIVE;
			}
			else if(strlen(g_strTagColor[iClient]) == 6 || strlen(g_strTagColor[iClient]) == 8)
			{
				SetNativeCellRef(3, strlen(g_strTagColor[iClient]) == 8);
				return StringToInt(g_strTagColor[iClient], 16);
			}
			else
			{
				SetNativeCellRef(3, false);
				return COLOR_NONE;
			}
		}
		case CPT_NameColor:
		{
			if(StrEqual(g_strUsernameColor[iClient], "G", false))
			{
				SetNativeCellRef(3, false);
				return COLOR_GREEN;
			}
			else if(StrEqual(g_strUsernameColor[iClient], "O", false))
			{
				SetNativeCellRef(3, false);
				return COLOR_OLIVE;
			}
			else if(strlen(g_strUsernameColor[iClient]) == 6 || strlen(g_strUsernameColor[iClient]) == 8)
			{
				SetNativeCellRef(3, strlen(g_strUsernameColor[iClient]) == 8);
				return StringToInt(g_strUsernameColor[iClient], 16);
			}
			else
			{
				SetNativeCellRef(3, false);
				return COLOR_TEAM;
			}
		}
		case CPT_TextColor:
		{
			if(StrEqual(g_strTextColor[iClient], "T", false))
			{
				SetNativeCellRef(3, false);
				return COLOR_TEAM;
			}
			else if(StrEqual(g_strTextColor[iClient], "G", false))
			{
				SetNativeCellRef(3, false);
				return COLOR_GREEN;
			}
			else if(StrEqual(g_strTextColor[iClient], "O", false))
			{
				SetNativeCellRef(3, false);
				return COLOR_OLIVE;
			}
			else if(strlen(g_strTextColor[iClient]) == 6 || strlen(g_strTextColor[iClient]) == 8)
			{
				SetNativeCellRef(3, strlen(g_strTextColor[iClient]) == 8);
				return StringToInt(g_strTextColor[iClient], 16);
			}
			else
			{
				SetNativeCellRef(3, false);
				return COLOR_NONE;
			}
		}
	}
	return COLOR_NONE;
}

public int Native_SetColor(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);
	if(iClient < 1 || iClient > MaxClients || !IsClientInGame(iClient))
	{
		ThrowNativeError(SP_ERROR_PARAM, "Invalid client or client is not in game");
		return false;
	}
	char strColor[32];
	if(GetNativeCell(3) < 0)
	{
		switch(GetNativeCell(3))
		{
			case COLOR_GREEN:
			{
				Format(strColor, sizeof(strColor), "G");
			}
			case COLOR_OLIVE:
			{
				Format(strColor, sizeof(strColor), "O");
			}
			case COLOR_TEAM:
			{
				Format(strColor, sizeof(strColor), "T");
			}
			case COLOR_NONE:
			{
				Format(strColor, sizeof(strColor), "");
			}
		}
	}
	else
	{
		if(!GetNativeCell(4))
		{
			Format(strColor, sizeof(strColor), "%06X", GetNativeCell(3));
		}
		else
		{
			Format(strColor, sizeof(strColor), "%08X", GetNativeCell(3));
		}
	}
	if(strlen(strColor) != 6 && strlen(strColor) != 8 && !StrEqual(strColor, "G", false) && !StrEqual(strColor, "O", false) && !StrEqual(strColor, "T", false))
	{
		return false;
	}
	switch(GetNativeCell(2))
	{	
		case CPT_TagColor:
		{
			strcopy(g_strTagColor[iClient], sizeof(g_strTagColor[]), strColor);
		}
		case CPT_NameColor:
		{
			strcopy(g_strUsernameColor[iClient], sizeof(g_strUsernameColor[]), strColor);
		}
		case CPT_TextColor:
		{
			strcopy(g_strTextColor[iClient], sizeof(g_strTextColor[]), strColor);
		}
	}
	return true;
}

public int Native_GetTag(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);
	if(iClient < 1 || iClient > MaxClients || !IsClientInGame(iClient))
	{
		ThrowNativeError(SP_ERROR_PARAM, "Invalid client or client is not in game");
		return;
	}
	SetNativeString(2, g_strTag[iClient], GetNativeCell(3));
}

public int Native_SetTag(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);
	if(iClient < 1 || iClient > MaxClients || !IsClientInGame(iClient))
	{
		ThrowNativeError(SP_ERROR_PARAM, "Invalid client or client is not in game");
		return;
	}
	GetNativeString(2, g_strTag[iClient], sizeof(g_strTag[]));
}

public int Native_ResetColor(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);
	if(iClient < 1 || iClient > MaxClients || !IsClientInGame(iClient))
	{
		ThrowNativeError(SP_ERROR_PARAM, "Invalid client or client is not in game");
		return;
	}
	switch(GetNativeCell(2))
	{
		case CPT_TagColor:
		{
			strcopy(g_strTagColor[iClient], sizeof(g_strTagColor[]), g_strDefaultTagColor[iClient]);
		}
		case CPT_NameColor:
		{
			strcopy(g_strUsernameColor[iClient], sizeof(g_strUsernameColor[]), g_strDefaultUsernameColor[iClient]);
		}
		case CPT_TextColor:
		{
			strcopy(g_strTextColor[iClient], sizeof(g_strTextColor[]), g_strDefaultTextColor[iClient]);
		}
	}
}

public int Native_ResetTag(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);
	if(iClient < 1 || iClient > MaxClients || !IsClientInGame(iClient))
	{
		ThrowNativeError(SP_ERROR_PARAM, "Invalid client or client is not in game");
		return;
	}
	strcopy(g_strTag[iClient], sizeof(g_strTag[]), g_strDefaultTag[iClient]);
}