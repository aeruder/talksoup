include $(GNUSTEP_MAKEFILES)/common.make
BUNDLE_NAME = Skeleton

BUNDLE_EXTENSION =

BUNDLE_INSTALL_DIR = $(GNUSTEP_INSTALLATION_DIR)/Library/ApplicationSupport/TalkSoup/InFilters

Skeleton_PRINCIPAL_CLASS = Skeleton

Skeleton_OBJC_FILES = Skeleton.m

ifeq ($(OBJC_RUNTIME_LIB), apple)
Skeleton_BUNDLE_LIBS = -framework TalkSoupBundles $(ADDITIONAL_FRAMEWORK_DIRS)
else
Skeleton_BUNDLE_LIBS = -lTalkSoupBundles
endif

GUI_LIBS = 

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/bundle.make
-include GNUmakefile.postamble

