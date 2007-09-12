include $(GNUSTEP_MAKEFILES)/common.make
BUNDLE_NAME = Autorename

BUNDLE_EXTENSION =

BUNDLE_INSTALL_DIR = $(GNUSTEP_APPLICATION_SUPPORT)/TalkSoup/InFilters

Autorename_LANGUAGES = English
Autorename_LOCALIZED_RESOURCE_FILES = Localizable.strings

Autorename_PRINCIPAL_CLASS = Autorename

Autorename_OBJC_FILES = Autorename.m

ifeq ($(OBJC_RUNTIME_LIB), apple)
Autorename_BUNDLE_LIBS = -framework TalkSoupBundles $(ADDITIONAL_FRAMEWORK_DIRS)
else
Autorename_BUNDLE_LIBS = -lTalkSoupBundles
endif

GUI_LIB = 

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/bundle.make
-include GNUmakefile.postamble

