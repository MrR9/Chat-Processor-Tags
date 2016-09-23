/**
 * This is the include file for Chat Processor Tags
 * https://forums.alliedmods.net/showthread.php?t=186695
 * To check that Chat Processor Tags is installed and running, verify that the "cpt" library exists
 */

#if defined _cpt_included
  #endinput
#endif
#define _cpt_included

enum CPT_ColorType {
	CPT_TagColor,
	CPT_NameColor,
	CPT_TextColor
};

#define COLOR_NONE		-1
#define COLOR_GREEN		-2
#define COLOR_OLIVE		-3
#define COLOR_TEAM		-4

/**
 * Gets a client's color as a hexadecimal integer.
 * 
 * @param iClient		Client index
 * @param tType			Color type to retreive
 * @param bAlpha			Pass a boolean variable by reference here and it will be true if the color has alpha specified or false if it doesn't (or is a stock color)
 * @return				Color as a hexadecimal integer (use %X in formatting to get a hexadecimal string)
 * 
 * On error/errors:		Invalid client index or client is not in game
 */
native int CPT_GetColor(int iClient, CPT_ColorType tType, bool& bAlpha = false);

/**
 * Sets a client's color as a hexadecimal integer.
 * 
 * @param iClient		Client index
 * @param tType			Color type to set
 * @param iColor			Integer representation of the color (use StringToInt(input, 16) to convert a hexadecimal string) or one of the color defines
 * @param bAlpha			Are you specifying a color with alpha?
 * @return				True if the color is updated successfully, false otherwise
 * 
 * On error/errors:		Invalid client index or client is not in game
 */
native bool CPT_SetColor(int iClient, CPT_ColorType tType, int iColor, bool bAlpha);

/**
 * Gets a client's tag
 * 
 * @param iClient		Client index
 * @param strBuffer	Buffer to store the tag in
 * @param iMaxLen		Maximum buffer length
 * @noreturn
 * 
 * On error/errors:		Invalid client index or client is not in game
 */
native void CPT_GetTag(int iClient, char[] strBuffer, int iMaxLen);

/**
 * Sets a client's tag
 * 
 * @param iClient		Client index
 * @param strTag		String containing the new tag
 * @noreturn
 * 
 * On error/errors:		Invalid client index or client is not in game
 */
native void CPT_SetTag(int iClient, const char[] strTag);

/**
 * Resets a client's color to the value in the config file.
 * 
 * @param iClient		Client index
 * @param tType		Color type to restore
 * @noreturn
 * 
 * On error/errors:		Invalid client index or client is not in game
 */
native void CPT_ResetColor(int iClient, CPT_ColorType tType);

/**
 * Resets a client's tag to the value in the config file.
 * 
 * @param iClient		Client index
 * @noreturn
 * 
 * On error/errors:		Invalid client index or client is not in game
 */
native void CPT_ResetTag(int iClient);

/**
 * Called when a client's name is about to be tagged
 * DO NOT START A NEW USERMESSAGE (i.e. PrintToChat, PrintToChatAll) WITHIN THIS FORWARD
 * 
 * @param iClient		Client index
 * @param strMessage	Chat message that will be printed
 * @param tType		What type of color will be applied. If this is CPT_TagColor, it controls whether the tag will be applied at all, not whether the tag will be colored.
 * @return			Plugin_Handled to prevent coloring, Plugin_Continue to allow coloring
 */
forward Action CPT_OnColor(int iClient, const char[] strMessage, CPT_ColorType tType);

/**
 * Called when a message has been fully colored and will be sent, unless further plugins modify it through Simple Chat Processor
 * 
 * @param iAuthor		Author client index
 * @param strMessage	Message
 * @param iMaxLen		Maximum length of message buffer
 * @noreturn
 */
forward void CPT_OnChatMessage(int iAuthor, char[] strMessage, int iMaxLen);

/**
 * Called when a client's colors and tag are about to be loaded from the config file
 * At this point, the client has NO COLORS
 * 
 * @param iClient		Client index
 * @return				Plugin_Handled or Plugin_Stop to prevent loading, Plugin_Continue or Plugin_Changed to allow
 */
forward Action CPT_OnUserConfigPreLoaded(int iClient);

/**
 * Called when a client's colors and tag have been loaded from the config file
 * 
 * @param iClient		Client index
 * @noreturn
 */
forward void CPT_OnUserConfigLoaded(int iClient);

/**
 * Called when the configuration file is reloaded with the sm_reloadccc command
 * 
 * @noreturn
 */
forward void CPT_OnConfigReloaded();

public SharedPlugin __pl_cpt = {
	name = "cpt",
	file = "chat-processor-tags.smx",
#if defined REQUIRE_PLUGIN
	required = 1
#else
	required = 0
#endif
};

#if !defined REQUIRE_PLUGIN
public __pl_cpt_SetNTVOptional() {
	MarkNativeAsOptional("CPT_GetColor");
	MarkNativeAsOptional("CPT_SetColor");
	MarkNativeAsOptional("CPT_GetTag");
	MarkNativeAsOptional("CPT_ResetTag");
	MarkNativeAsOptional("CPT_ResetColor");
	MarkNativeAsOptional("CPT_ResetTag");
}
#endif