include $(GNUSTEP_MAKEFILES)/common.make
BUNDLE_NAME = Highlighting

BUNDLE_EXTENSION =

BUNDLE_INSTALL_DIR = $(GNUSTEP_INSTALLATION_DIR)/Library/ApplicationSupport/TalkSoup/InFilters

Highlighting_LANGUAGES = English
Highlighting_LOCALIZED_RESOURCE_FILES = Localizable.strings

Highlighting_PRINCIPAL_CLASS = Highlighting

main = Highlighting.m

Highlighting_OBJC_FILES = $(main)

ifeq ($(OBJC_RUNTIME_LIB), apple)
Highlighting_BUNDLE_LIBS = -framework TalkSoupBundles $(ADDITIONAL_FRAMEWORK_DIRS)
else
Highlighting_BUNDLE_LIBS = -lTalkSoupBundles
endif

GUI_LIB =

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/bundle.make
-include GNUmakefile.postamble

