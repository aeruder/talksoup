include $(GNUSTEP_MAKEFILES)/common.make
BUNDLE_NAME = Debold

BUNDLE_EXTENSION =

ifeq ($(OBJC_RUNTIME_LIB), apple)
BUNDLE_INSTALL_DIR = $(GNUSTEP_INSTALLATION_DIR)/Library/Application\ Support/TalkSoup/InFilters
else
BUNDLE_INSTALL_DIR = $(GNUSTEP_INSTALLATION_DIR)/Library/ApplicationSupport/TalkSoup/InFilters
endif

Debold_LANGUAGES = English
Debold_LOCALIZED_RESOURCE_FILES = Localizable.strings

Debold_PRINCIPAL_CLASS = Debold

Debold_OBJC_FILES = Debold.m

ifeq ($(OBJC_RUNTIME_LIB), apple)
Debold_BUNDLE_LIBS = -framework TalkSoupBundles $(ADDITIONAL_FRAMEWORK_DIRS)
else
Debold_BUNDLE_LIBS = -lTalkSoupBundles
endif

GUI_LIB = 

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/bundle.make
-include GNUmakefile.postamble

