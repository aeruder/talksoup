include $(GNUSTEP_MAKEFILES)/common.make
APP_NAME = TalkSoup

TalkSoup_APPLICATION_ICON = irc.tiff

TalkSoup_RESOURCE_FILES = Images/irc.tiff

netclasses = netclasses/NetBase.m netclasses/NetTCP.m netclasses/LineObject.m \
             netclasses/IRCObject.m

main = TalkSoup.m

views = Views/ScrollingTextView.m Views/ColoredTabViewItem.m \
        Views/TabTextField.m

windows = Windows/ChannelWindow.m

control = Controllers/ConnectionController.m Controllers/ChannelController.m \
          Controllers/TalkController.m Controllers/QueryController.m

misc = Misc/Functions.m

ifeq ($(debug),yes)
  misc += Misc/Debug.m
endif

models = Models/Channel.m

TalkSoup_OBJC_FILES = $(netclasses) $(main) $(views) $(windows) $(control) \
                      $(misc) $(models)

TalkSoup_INCLUDE_DIRS = -I.
ADDITIONAL_OBJCFLAGS = -Wall

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/application.make
-include GNUmakefile.postamble

