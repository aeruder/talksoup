include $(GNUSTEP_MAKEFILES)/common.make
BUNDLE_NAME = MessageInTab

BUNDLE_EXTENSION = .bundle

BUNDLE_INSTALL_DIR = $(GNUSTEP_INSTALLATION_DIR)/Library/TalkSoup/InFilters

MessageInTab_PRINCIPAL_CLASS = MessageInTab

MessageInTab_FRAMEWORKS = -lTalkSoupBundles

main = MessageInTab.m

MessageInTab_OBJC_FILES = $(main)

ADDITIONAL_INCLUDE_DIRS = -I. -I../../Source

ADDITIONAL_OBJCFLAGS = -Wall -Wno-protocol

GUI_LIBS = 

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/bundle.make
-include GNUmakefile.postamble

