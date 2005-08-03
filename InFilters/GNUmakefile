include $(GNUSTEP_MAKEFILES)/common.make

ifeq ($(USE_APPKIT),)
USE_APPKIT=yes
endif

SUBPROJECTS = Highlighting MessageInTab KeepAlive Debold \
              Decolorizer Deunderline Dereverse Logging \
			  DCCSupport MessageOutTab

ifeq ($(USE_APPKIT), yes)
SUBPROJECTS += Emoticon
endif

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/aggregate.make
-include GNUmakefile.postamble
