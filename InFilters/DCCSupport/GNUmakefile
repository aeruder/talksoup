include $(GNUSTEP_MAKEFILES)/common.make
BUNDLE_NAME = DCCSupport

BUNDLE_EXTENSION =

ifeq ($(USE_APPKIT),)
USE_APPKIT = yes
endif

ifeq ($(OBJC_RUNTIME_LIB), apple)
BUNDLE_INSTALL_DIR = $(GNUSTEP_INSTALLATION_DIR)/Library/Application\ Support/TalkSoup/InFilters
else
BUNDLE_INSTALL_DIR = $(GNUSTEP_INSTALLATION_DIR)/Library/ApplicationSupport/TalkSoup/InFilters
endif

DCCSupport_OBJC_FILES = DCCSupport.m DCCObject.m DCCSender.m DCCGetter.m

ifeq ($(USE_APPKIT), yes)
DCCSupport_OBJC_FILES += DCCSupportPreferencesController.m
ifeq ($(OBJC_RUNTIME_LIB), apple)
DCCSupport_LOCALIZED_RESOURCE_FILES = DCCSupportPreferences.nib
else
DCCSupport_LOCALIZED_RESOURCE_FILES = DCCSupportPreferences.gorm
endif
else
GUI_LIB =
endif

DCCSupport_LANGUAGES = English
DCCSupport_LOCALIZED_RESOURCE_FILES += Localizable.strings
DCCSupport_RESOURCE_FILES = AllLanguages/Defaults.plist AllLanguages/dccsupport_prefs.tiff

DCCSupport_PRINCIPAL_CLASS = DCCSupport

ifeq ($(OBJC_RUNTIME_LIB), apple)
DCCSupport_BUNDLE_LIBS = -framework netclasses -framework TalkSoupBundles $(ADDITIONAL_FRAMEWORK_DIRS)
else
DCCSupport_BUNDLE_LIBS = -lTalkSoupBundles -lnetclasses
endif

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/bundle.make
-include GNUmakefile.postamble
