include $(GNUSTEP_MAKEFILES)/common.make
APP_NAME = Charla

Charla_APPLICATION_ICON = irc.tiff

Charla_RESOURCE_FILES = Images/irc.tiff

netclasses = netclasses/NetBase.m netclasses/NetTCP.m netclasses/LineObject.m \
             netclasses/IRCObject.m

main = Charla.m

views = Views/ChannelView.m

windows = Windows/ChannelWindow.m

control = Controllers/ConnectionController.m

misc = Misc/Functions.m

Charla_OBJC_FILES = $(netclasses) $(main) $(views) $(windows) $(control) $(misc)

Charla_INCLUDE_DIRS = -I.
ADDITIONAL_OBJCFLAGS = -Wall

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/application.make
-include GNUmakefile.postamble

