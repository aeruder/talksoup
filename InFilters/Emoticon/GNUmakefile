include $(GNUSTEP_MAKEFILES)/common.make
BUNDLE_NAME = Emoticon

BUNDLE_EXTENSION =

ifeq ($(OBJC_RUNTIME_LIB), apple)
BUNDLE_INSTALL_DIR = $(GNUSTEP_INSTALLATION_DIR)/Library/Application\ Support/TalkSoup/InFilters
else
BUNDLE_INSTALL_DIR = $(GNUSTEP_INSTALLATION_DIR)/Library/ApplicationSupport/TalkSoup/InFilters
endif

Emoticon_LANGUAGES = English
Emoticon_LOCALIZED_RESOURCE_FILES = Localizable.strings
Emoticon_RESOURCE_FILES = AllLanguages/*.tiff

Emoticon_PRINCIPAL_CLASS = Emoticon

Emoticon_OBJC_FILES = Emoticon.m

ifeq ($(OBJC_RUNTIME_LIB), apple)
Emoticon_BUNDLE_LIBS = -framework TalkSoupBundles $(ADDITIONAL_FRAMEWORK_DIRS)
else
Emoticon_BUNDLE_LIBS = -lTalkSoupBundles
endif

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/bundle.make
-include GNUmakefile.postamble
