include $(GNUSTEP_MAKEFILES)/common.make
BUNDLE_NAME = PrivateBeep

BUNDLE_EXTENSION =

ifeq ($(OBJC_RUNTIME_LIB), apple)
BUNDLE_INSTALL_DIR = $(GNUSTEP_INSTALLATION_DIR)/Library/Application\ Support/TalkSoup/InFilters
else
BUNDLE_INSTALL_DIR = $(GNUSTEP_INSTALLATION_DIR)/Library/ApplicationSupport/TalkSoup/InFilters
endif

PrivateBeep_LANGUAGES = English
PrivateBeep_LOCALIZED_RESOURCE_FILES = Localizable.strings

PrivateBeep_PRINCIPAL_CLASS = PrivateBeep

PrivateBeep_OBJC_FILES = PrivateBeep.m

ifeq ($(OBJC_RUNTIME_LIB), apple)
PrivateBeep_BUNDLE_LIBS = -framework TalkSoupBundles $(ADDITIONAL_FRAMEWORK_DIRS)
else
PrivateBeep_BUNDLE_LIBS = -lTalkSoupBundles
endif

GUI_LIB = 

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/bundle.make
-include GNUmakefile.postamble

