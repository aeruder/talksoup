include $(GNUSTEP_MAKEFILES)/common.make
BUNDLE_NAME = Dereverse

BUNDLE_EXTENSION =

BUNDLE_INSTALL_DIR = $(GNUSTEP_INSTALLATION_DIR)/Library/ApplicationSupport/TalkSoup/InFilters

Dereverse_PRINCIPAL_CLASS = Dereverse

Dereverse_OBJC_FILES = Dereverse.m

ifeq ($(OBJC_RUNTIME_LIB), apple)
Dereverse_BUNDLE_LIBS = -framework TalkSoupBundles $(ADDITIONAL_FRAMEWORK_DIRS)
else
Dereverse_BUNDLE_LIBS = -lTalkSoupBundles
endif

GUI_LIBS = 

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/bundle.make
-include GNUmakefile.postamble

