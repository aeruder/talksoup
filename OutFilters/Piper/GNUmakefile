include $(GNUSTEP_MAKEFILES)/common.make
BUNDLE_NAME = Piper

BUNDLE_EXTENSION =

ifeq ($(OBJC_RUNTIME_LIB), apple)
BUNDLE_INSTALL_DIR = $(GNUSTEP_INSTALLATION_DIR)/Library/Application\ Support/TalkSoup/OutFilters
else
BUNDLE_INSTALL_DIR = $(GNUSTEP_INSTALLATION_DIR)/Library/ApplicationSupport/TalkSoup/OutFilters
endif

Piper_LANGUAGES = English
Piper_LOCALIZED_RESOURCE_FILES = Localizable.strings

Piper_PRINCIPAL_CLASS = Piper

Piper_OBJC_FILES = Piper.m

ifeq ($(OBJC_RUNTIME_LIB), apple)
Piper_BUNDLE_LIBS = -framework TalkSoupBundles $(ADDITIONAL_FRAMEWORK_DIRS)
else
Piper_BUNDLE_LIBS = -lTalkSoupBundles
endif

GUI_LIB = 

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/bundle.make
-include GNUmakefile.postamble

