include $(GNUSTEP_MAKEFILES)/common.make
APP_NAME = TalkSoup

TalkSoup_APPLICATION_ICON = irc.tiff

TalkSoup_RESOURCE_FILES = Images/irc.tiff

netclasses = netclasses/NetBase.m netclasses/NetTCP.m netclasses/LineObject.m \
             netclasses/IRCObject.m

main = TalkSoup.m

views = Views/ChannelView.m Views/ConsoleView.m Views/ScrollingTextView.m

windows = Windows/ChannelWindow.m

control = Controllers/ConnectionController.m Controllers/ChannelViewController.m

misc = Misc/Functions.m

models = Models/Channel.m

TalkSoup_OBJC_FILES = $(netclasses) $(main) $(views) $(windows) $(control) \
                      $(misc) $(models)

TalkSoup_INCLUDE_DIRS = -I.
ADDITIONAL_OBJCFLAGS = -Wall

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/application.make
-include GNUmakefile.postamble

