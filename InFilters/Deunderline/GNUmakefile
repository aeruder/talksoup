include $(GNUSTEP_MAKEFILES)/common.make
BUNDLE_NAME = Deunderline

BUNDLE_EXTENSION =

ifeq ($(OBJC_RUNTIME_LIB), apple)
BUNDLE_INSTALL_DIR = $(GNUSTEP_INSTALLATION_DIR)/Library/Application\ Support/TalkSoup/InFilters
else
BUNDLE_INSTALL_DIR = $(GNUSTEP_INSTALLATION_DIR)/Library/ApplicationSupport/TalkSoup/InFilters
endif

Deunderline_LANGUAGES = English
Deunderline_LOCALIZED_RESOURCE_FILES = Localizable.strings

Deunderline_PRINCIPAL_CLASS = Deunderline

Deunderline_OBJC_FILES = Deunderline.m

ifeq ($(OBJC_RUNTIME_LIB), apple)
Deunderline_BUNDLE_LIBS = -framework TalkSoupBundles $(ADDITIONAL_FRAMEWORK_DIRS)
else
Deunderline_BUNDLE_LIBS = -lTalkSoupBundles
endif

GUI_LIB = 

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/bundle.make
-include GNUmakefile.postamble

