include $(GNUSTEP_MAKEFILES)/common.make

APP_NAME = Charla 
IRCClient_APPLICATION_ICON = irc.tiff
VERSION = 0.0.9

ADDITIONAL_OBJCFLAGS += -Wall -O2 -D$(subst -,_,$(GNUSTEP_HOST_OS))

Charla_OBJC_FILES    = Source/main.m \
                       Source/IRCApp.m \
				       Source/IRCWindow.m \
				       Source/ChannelView.m \
				       Source/CommandView.m \
					   Source/HistoryCommands.m \
				       Source/ServersManager.m \
				       Source/ServerInfo.m \
				       Source/TerminalView/TerminalView.m \
				       Source/TerminalView/TerminalViewPrefs.m \
				       Source/TerminalView/Label.m \
				       Source/TerminalView/TerminalParser_Linux.m \
					   Source/NetClasses/IRCObject.m \
		       		   Source/NetClasses/IRCClient.m \
		       		   Source/NetClasses/IRCClientOut.m \
		 		       Source/NetClasses/LineObject.m \
		       		   Source/NetClasses/NetBase.m \
		       		   Source/NetClasses/NetTCP.m \
					   Source/Preferences/PreferencesWindowController.m \
					   Source/Preferences/autokeyviewchain.m \
					   Source/Preferences/GeneralPrefs.m

Charla_RESOURCE_FILES=Images/common_outlineCollapsed.tiff \
					  Images/common_outlineUnexpandable.tiff \
					  Images/common_outlineExpanded.tiff	\
					  Images/irc.tiff	\
					  Resources/Serverlist.txt

Charla_LDFLAGS = -lutil 


-include GNUmakefile.preamble
-include GNUmakefile.local
include $(GNUSTEP_MAKEFILES)/aggregate.make
include $(GNUSTEP_MAKEFILES)/application.make
-include GNUmakefile.postamble
