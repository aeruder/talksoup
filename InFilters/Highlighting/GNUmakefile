include $(GNUSTEP_MAKEFILES)/common.make
BUNDLE_NAME = Highlighting

BUNDLE_EXTENSION =

BUNDLE_INSTALL_DIR = $(GNUSTEP_INSTALLATION_DIR)/Library/ApplicationSupport/TalkSoup/InFilters

Highlighting_PRINCIPAL_CLASS = Highlighting

Highlighting_FRAMEWORKS = -lTalkSoupBundles

main = Highlighting.m

Highlighting_OBJC_FILES = $(main)

ADDITIONAL_INCLUDE_DIRS = -I. -I../../Source

ADDITIONAL_OBJCFLAGS = -Wall -Wno-protocol

GUI_LIBS =

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/bundle.make
-include GNUmakefile.postamble

