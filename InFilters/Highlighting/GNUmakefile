include $(GNUSTEP_MAKEFILES)/common.make
BUNDLE_NAME = Highlighting

BUNDLE_EXTENSION =

ifeq ($(USE_APPKIT),)
USE_APPKIT = yes
endif

ifeq ($(OBJC_RUNTIME_LIB), apple)
BUNDLE_INSTALL_DIR = $(GNUSTEP_INSTALLATION_DIR)/Library/Application\ Support/TalkSoup/InFilters
else
BUNDLE_INSTALL_DIR = $(GNUSTEP_INSTALLATION_DIR)/Library/ApplicationSupport/TalkSoup/InFilters
endif

Highlighting_OBJC_FILES = Highlighting.m 

ifeq ($(USE_APPKIT), yes)
Highlighting_OBJC_FILES += HighlightingPreferencesController.m
ifeq ($(OBJC_RUNTIME_LIB), apple)
Highlighting_LOCALIZED_RESOURCE_FILES = HighlightingPreferences.nib
else
Highlighting_LOCALIZED_RESOURCE_FILES = HighlightingPreferences.gorm
endif
else
GUI_LIB =
endif

Highlighting_LANGUAGES = English
Highlighting_LOCALIZED_RESOURCE_FILES += Localizable.strings
Highlighting_RESOURCE_FILES = AllLanguages/Defaults.plist AllLanguages/highlighting_prefs.tiff

Highlighting_PRINCIPAL_CLASS = Highlighting

Highlighting_OBJC_FILES = Highlighting.m HighlightingPreferencesController.m

ifeq ($(OBJC_RUNTIME_LIB), apple)
Highlighting_BUNDLE_LIBS = -framework TalkSoupBundles $(ADDITIONAL_FRAMEWORK_DIRS)
else
Highlighting_BUNDLE_LIBS = -lTalkSoupBundles
endif

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/bundle.make
-include GNUmakefile.postamble

