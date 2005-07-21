include $(GNUSTEP_MAKEFILES)/common.make

PACKAGE_NAME=TalkSoup
VERSION=1.0beta

ifneq ($(USE_DMALLOC),)
ADDITIONAL_OBJCFLAGS += -include stdlib.h -include dmalloc.h
ADDITIONAL_LDFLAGS += -ldmalloc
endif

ifeq ($(USE_APPKIT),)
USE_APPKIT = yes
endif

ifneq ($(USE_APPKIT),yes)
USE_APPKIT = no
endif

export ADDITIONAL_LDFLAGS
export ADDITIONAL_OBJCFLAGS
export USE_APPKIT

SUBPROJECTS = TalkSoupBundles Source Input Output InFilters OutFilters

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/aggregate.make
-include GNUmakefile.postamble
