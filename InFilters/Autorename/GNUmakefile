include $(GNUSTEP_MAKEFILES)/common.make
BUNDLE_NAME = Autorename

BUNDLE_EXTENSION =

ifeq ($(OBJC_RUNTIME_LIB), apple)
BUNDLE_INSTALL_DIR = $(GNUSTEP_INSTALLATION_DIR)/Library/Application\ Support/TalkSoup/InFilters
else
BUNDLE_INSTALL_DIR = $(GNUSTEP_INSTALLATION_DIR)/Library/ApplicationSupport/TalkSoup/InFilters
endif

Autorename_LANGUAGES = English
Autorename_LOCALIZED_RESOURCE_FILES = Localizable.strings

Autorename_PRINCIPAL_CLASS = Autorename

Autorename_OBJC_FILES = Autorename.m

ifeq ($(OBJC_RUNTIME_LIB), apple)
Autorename_BUNDLE_LIBS = -framework TalkSoupBundles $(ADDITIONAL_FRAMEWORK_DIRS)
else
Autorename_BUNDLE_LIBS = -lTalkSoupBundles
endif

GUI_LIB = 

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/bundle.make
-include GNUmakefile.postamble

