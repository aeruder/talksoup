include $(GNUSTEP_MAKEFILES)/common.make
BUNDLE_NAME = DCCSupport

BUNDLE_EXTENSION =

BUNDLE_INSTALL_DIR = $(GNUSTEP_INSTALLATION_DIR)/Library/ApplicationSupport/TalkSoup/InFilters

DCCSupport_PRINCIPAL_CLASS = DCCSupport

DCCSupport_FRAMEWORKS = -lTalkSoupBundles

DCCSupport_OBJC_FILES = DCCSupport.m netclasses/NetTCP.m \
                        netclasses/NetBase.m netclasses/DCCObject.m

GUI_LIBS = 

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/bundle.make
-include GNUmakefile.postamble

