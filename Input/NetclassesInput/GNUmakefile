include $(GNUSTEP_MAKEFILES)/common.make
BUNDLE_NAME = NetclassesInput

BUNDLE_EXTENSION =

BUNDLE_INSTALL_DIR = $(GNUSTEP_INSTALLATION_DIR)/Library/ApplicationSupport/TalkSoup/Input

NetclassesInput_PRINCIPAL_CLASS = NetclassesInput

NetclassesInput_FRAMEWORKS = -lTalkSoupBundles

netclasses = netclasses/NetBase.m netclasses/NetTCP.m netclasses/LineObject.m \
             netclasses/IRCObject.m

main = main.m Functions.m

NetclassesInput_OBJC_FILES = $(netclasses) $(main)

GUI_LIBS = 

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/bundle.make
-include GNUmakefile.postamble

