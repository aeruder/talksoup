include $(GNUSTEP_MAKEFILES)/common.make

APP_NAME = TalkSoup

SUBPROJECTS = TalkSoupBundles

TalkSoup_OBJC_FILES = TalkSoup.m main.m Dummy.m Functions.m

TalkSoup_RESOURCE_FILES = Images/TalkSoup.tiff Defaults.plist
TalkSoup_LOCALIZED_RESOURCE_FILES = Localizable.strings

TalkSoup_LANGUAGES = English

TalkSoup_FRAMEWORKS = -lTalkSoupBundles

GUI_LIBS =

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/aggregate.make
include $(GNUSTEP_MAKEFILES)/application.make
-include GNUmakefile.postamble

