include $(GNUSTEP_MAKEFILES)/common.make
BUNDLE_NAME = NetclassesInput

BUNDLE_EXTENSION = .bundle

BUNDLE_INSTALL_DIR = $(GNUSTEP_INSTALLATION_DIR)/ApplicationSupport/TalkSoup/Input

NetclassesInput_PRINCIPAL_CLASS = NetclassesInput

NetclassesInput_FRAMEWORKS = -lTalkSoupBundles

netclasses = netclasses/NetBase.m netclasses/NetTCP.m netclasses/LineObject.m \
             netclasses/IRCObject.m

main = main.m Functions.m

NetclassesInput_OBJC_FILES = $(netclasses) $(main)

ADDITIONAL_INCLUDE_DIRS = -I. -Inetclasses -I../../../Source

ADDITIONAL_OBJCFLAGS = -Wall -Wno-protocol

GUI_LIBS = 

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/bundle.make
-include GNUmakefile.postamble

