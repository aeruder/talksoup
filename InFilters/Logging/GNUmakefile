include $(GNUSTEP_MAKEFILES)/common.make
BUNDLE_NAME = Logging

BUNDLE_EXTENSION =

ifeq ($(OBJC_RUNTIME_LIB), apple)
BUNDLE_INSTALL_DIR = $(GNUSTEP_INSTALLATION_DIR)/Library/Application\ Support/TalkSoup/InFilters
else
BUNDLE_INSTALL_DIR = $(GNUSTEP_INSTALLATION_DIR)/Library/ApplicationSupport/TalkSoup/InFilters
endif

Logging_LANGUAGES = English
Logging_LOCALIZED_RESOURCE_FILES = Localizable.strings

Logging_PRINCIPAL_CLASS = Logging

Logging_OBJC_FILES = Logging.m

ifeq ($(OBJC_RUNTIME_LIB), apple)
Logging_BUNDLE_LIBS = -framework TalkSoupBundles $(ADDITIONAL_FRAMEWORK_DIRS)
else
Logging_BUNDLE_LIBS = -lTalkSoupBundles
endif

GUI_LIB = 

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/bundle.make
-include GNUmakefile.postamble

