include $(GNUSTEP_MAKEFILES)/common.make

PACKAGE_NAME=TalkSoup
VERSION=0.82pre8

ifeq ($(USE_APPKIT),)
USE_APPKIT = y
else
USE_APPKIT = n
endif

export USE_APPKIT

SUBPROJECTS = TalkSoupBundles Source Input Output InFilters OutFilters

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/aggregate.make
-include GNUmakefile.postamble
