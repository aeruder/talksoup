include $(GNUSTEP_MAKEFILES)/common.make
BUNDLE_NAME = Decolorizer

BUNDLE_EXTENSION =

BUNDLE_INSTALL_DIR = $(GNUSTEP_INSTALLATION_DIR)/Library/ApplicationSupport/TalkSoup/InFilters

Decolorizer_LANGUAGES = English
Decolorizer_LOCALIZED_RESOURCE_FILES = Localizable.strings

Decolorizer_PRINCIPAL_CLASS = Decolorizer

Decolorizer_OBJC_FILES = Decolorizer.m

ifeq ($(OBJC_RUNTIME_LIB), apple)
Decolorizer_BUNDLE_LIBS = -framework TalkSoupBundles $(ADDITIONAL_FRAMEWORK_DIRS)
else
Decolorizer_BUNDLE_LIBS = -lTalkSoupBundles
endif

GUI_LIBS = 

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/bundle.make
-include GNUmakefile.postamble

