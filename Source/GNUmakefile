include $(GNUSTEP_MAKEFILES)/common.make

APP_NAME = TalkSoup

TalkSoup_OBJC_FILES = main.m

TalkSoup_RESOURCE_FILES = Defaults.plist Images/TalkSoup.tiff

ifeq ($(OBJC_RUNTIME_LIB), apple)
TalkSoup_GUI_LIBS = -framework TalkSoupBundles $(ADDITIONAL_FRAMEWORK_DIRS)
else
TalkSoup_GUI_LIBS = -lTalkSoupBundles
endif

GUI_LIBS =

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/application.make
-include GNUmakefile.postamble

