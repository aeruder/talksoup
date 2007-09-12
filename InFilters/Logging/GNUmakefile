include $(GNUSTEP_MAKEFILES)/common.make
BUNDLE_NAME = Logging

BUNDLE_EXTENSION =

BUNDLE_INSTALL_DIR = $(GNUSTEP_APPLICATION_SUPPORT)/TalkSoup/InFilters

Logging_LANGUAGES = English
Logging_LOCALIZED_RESOURCE_FILES = Localizable.strings

Logging_PRINCIPAL_CLASS = Logging

Logging_OBJC_FILES = Logging.m

ifeq ($(OBJC_RUNTIME_LIB), apple)
Logging_BUNDLE_LIBS = -framework TalkSoupBundles $(ADDITIONAL_FRAMEWORK_DIRS)
else
Logging_BUNDLE_LIBS = -lTalkSoupBundles
endif

GUI_LIB = 

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/bundle.make
-include GNUmakefile.postamble

