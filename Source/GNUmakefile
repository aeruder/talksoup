include $(GNUSTEP_MAKEFILES)/common.make
APP_NAME = TalkSoup

SUBPROJECTS = TalkSoupBundles

TalkSoup_OBJC_FILES = TalkSoup.m main.m Dummy.m Functions.m
TalkSoup_RESOURCE_FILES = Defaults.plist
TalkSoup_INCLUDE_FILES = TalkSoup.h

TalkSoup_FRAMEWORKS = -lTalkSoupApp

ADDITIONAL_OBJCFLAGS = -Wall

ADDITIONAL_INCLUDE_DIRS += -ITalkSoupBundles

GUI_LIBS =

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/aggregate.make
include $(GNUSTEP_MAKEFILES)/application.make
-include GNUmakefile.postamble

