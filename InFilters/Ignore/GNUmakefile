include $(GNUSTEP_MAKEFILES)/common.make
BUNDLE_NAME = Ignore

BUNDLE_EXTENSION =

ifeq ($(USE_APPKIT),)
USE_APPKIT = yes
endif

ifeq ($(OBJC_RUNTIME_LIB), apple)
BUNDLE_INSTALL_DIR = $(GNUSTEP_INSTALLATION_DIR)/Library/Application\ Support/TalkSoup/InFilters
else
BUNDLE_INSTALL_DIR = $(GNUSTEP_INSTALLATION_DIR)/Library/ApplicationSupport/TalkSoup/InFilters
endif

Ignore_OBJC_FILES = Ignore.m 

Ignore_LANGUAGES = English
Ignore_LOCALIZED_RESOURCE_FILES += Localizable.strings
Ignore_RESOURCE_FILES = 

Ignore_PRINCIPAL_CLASS = Ignore

Ignore_OBJC_FILES = Ignore.m

ifeq ($(OBJC_RUNTIME_LIB), apple)
Ignore_BUNDLE_LIBS = -framework TalkSoupBundles $(ADDITIONAL_FRAMEWORK_DIRS)
else
Ignore_BUNDLE_LIBS = -lTalkSoupBundles
endif

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/bundle.make
-include GNUmakefile.postamble

