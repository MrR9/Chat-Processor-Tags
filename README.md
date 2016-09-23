# Chat-Processor-Tags
Processes chat and provides colors and longer optionally-multicolored tags for Source 2013 games

To compile your own build, or to run the plugin on your server, you will also need to download/install [Chat-Processor](https://forums.alliedmods.net/showthread.php?t=286913) by Redwerewolf.

If you already have a copy of colorvariables.inc in your "scripting/includes" folder of wherever you write your plugins, be aware as this plugin comes with its own version of colorvariables.inc that has been updated to new 1.8 syntax by Redwerewolf that it requires to compile. If you do have an older copy, you can either remove it, or just back it up elsewhere if you plan on modifying this plugin.


# Commands
sm_reloadtags - Reloads the config file


# ConVars
sm_cpt_version - Standard version ConVar, do not touch.


# About This Plugin
* __Chat-Processor Tags__ was created by [404](http://www.steamcommunity.com/id/404UNFGaming) ([abrandnewday](https://forums.alliedmods.net/member.php?u=165383) on AlliedMods)
* __Chat-Processor Tags__ started life as a copy of [Custom Chat Colors](https://forums.alliedmods.net/showthread.php?t=186695) by Dr. McKay (http://www.doctormckay.com)
* __Chat-Processor__ was created by Keith Warren ([Drixevel](http://steamcommunity.com/profiles/76561198036794478/)) ([redwerewolf](https://forums.alliedmods.net/member.php?u=59694) on AlliedMods)
* __Chat-Processor__ started life as a copy of __[Simple Chat Colors (Redux)](https://forums.alliedmods.net/showthread.php?p=1820365)__ by minimoney and updated to new 1.8 syntax by 404


# Converting custom-chatcolors.cfg entries for use in chat-processor-tags.cfg
Simply copy your the entries over to this config file. The easiest way to do this is to change the "admin_colors" bit at the top of custom-chatcolors.cfg to "chat_processor_tags". Then copy the entirety of the now-named "chat_processor_tags" code into chat-processor-tags.cfg.

From there, you can modify the tags as you see fit. For the most part you can just leave everything alone in the config file.

If you want to make your tags have multiple colors, then you can remove the "tagcolor" line from the specific tag entry and add the proper coloring into the "tag" line.


# CS:GO Usage
-This might be entirely untrue. I'm not 100% sure because I haven't tested this plugin in CS:GO yet. Someone really should test it out and then get back to me. As far as I know, colors you define in the "tag" entry may not show up in CS:GO because of how it handles colors. I might be entirely wrong. If I am however correct, and CS:GO supports colors poorly, then there are some engine colors that you can use._

For CS:GO, you will need to format your entries a little differently:

    "STEAM_0:1:1234567" // Here is a steamid example with a tag (don't duplicate steamids)
    {
      "tag"			"[ADMIN] " // This is the text for the tag. Do not add any colors into this field.
      "tagcolor"		"G" // This is the color for the tag. Choose from T (teamcolor), G (green), or O (olive)
      "namecolor"		"T" // This is the color for the name. Choose from T (teamcolor), G (green), or O (olive)
      "textcolor"		"O" // This is the color of the text. Choose from T (teamcolor), G (green), or O (olive)
    }

Yes, I know, CS:GO really sucks for chat color support right now. Deal with it. And FYI, I was originally planning on adding in an APLRes check to prevent this plugin from running on CS:GO. However I would've had to deal with hordes of people asking/demanding for CS:GO support, so this was the next best solution.


# Order of Operations
The order in which you place items in the config file matters.  Here is what determins what color they get:

1. SteamID
 1. If there is a Steam ID present, it will always override everything.
 1. If you put a Steam ID in twice then the first entry _(top to bottom)_ will be used. _(I think, just don't do it!)_
2. Groups
 2. The plugin will search _(top to bottom)_ for a postitive match for the flag string.
 2. The player' flags will be compared with the group flag character _(NOTE: only one flag per group! "a" is okay, "ab" is NOT)_, and if the player has the flag, it will stop there.
  2. For example: Let's say that Admins have the "ad" flags and donators have the "a" flag. If you place the "a" flag group above the "d" flag group then the admin will get the "a" colors. Order matters.


# Example config file setup
    "chat_processor_tags"                      // Leave this alone
    {                                          // Add all groups/steamids after first bracket (Leave this alone)
        "STEAM_0:1:1234567"                    // Here is a steamid example with a tag (don't duplicate steamids)
        {                                      // Open the steamid
            "tag"        "{community}[ADMIN] " // This is the text for the tag. Include color values for your tag here
    		"namecolor"  "#RRGGBB"             // This is the color for the name (#RRGGBB in hex notation or #RRGGBBAA with alpha)
    		"textcolor"  "#RRGGBBAA"           // This is the color of the text
        }                                      // Close the steamid
     
        "groupname"                            // This can either be a steamid for a specific player, or a group name
        {                                      // Open the group
            "flag"       "z"                   // This is the flag(s) assoicated with the group. This field doesn't matter if the group name is a steamid
            "tag"        "[ADMIN] "            // This is the text for the tag. Personal preference of mine is to add a space after the tag
            "namecolor"  "G"                   // This is the color for the name
            "textcolor"  "T"                   // This is the color of the text
    	}                                      // Close the group
    }                                          // Add all groups/steamids before last bracket (Leave this alone)

__NOTES:__

1. If you don't enter a steamid then the group name does not matter, it's just for your reference.
2. If you want to use multiple color strings in the "tag" field, go right ahead.
3. Here's a perfect example for you to try. It results in a tag that says [HOT] and looks like it's a fireball:
 3. "tag"			"{red}[{orange}H{yellow}O{orange}T{red}] "
4. If you want to use symbols and alt codes and unicode shit, try saving the chat-processor-tags.cfg file in a different Unicode format.
5. For a list of colors, download the "colorvariables.inc" file and view it in Notepad
6. For name/text colors, either a hex notation of a color (#RRGGBB or #RRGGBBAA) or a supported shortcut (O - Olive, G - Green, T - Team) are required
