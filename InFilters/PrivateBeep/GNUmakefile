include $(GNUSTEP_MAKEFILES)/common.make
BUNDLE_NAME = Skeleton

BUNDLE_EXTENSION =

ifeq ($(OBJC_RUNTIME_LIB), apple)
BUNDLE_INSTALL_DIR = $(GNUSTEP_INSTALLATION_DIR)/Library/Application\ Support/TalkSoup/InFilters
else
BUNDLE_INSTALL_DIR = $(GNUSTEP_INSTALLATION_DIR)/Library/ApplicationSupport/TalkSoup/InFilters
endif

Skeleton_LANGUAGES = English
Skeleton_LOCALIZED_RESOURCE_FILES = Localizable.strings

Skeleton_PRINCIPAL_CLASS = Skeleton

Skeleton_OBJC_FILES = Skeleton.m

ifeq ($(OBJC_RUNTIME_LIB), apple)
Skeleton_BUNDLE_LIBS = -framework TalkSoupBundles $(ADDITIONAL_FRAMEWORK_DIRS)
else
Skeleton_BUNDLE_LIBS = -lTalkSoupBundles
endif

GUI_LIB = 

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/bundle.make
-include GNUmakefile.postamble

