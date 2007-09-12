include $(GNUSTEP_MAKEFILES)/common.make
BUNDLE_NAME = Ignore

BUNDLE_EXTENSION =

ifeq ($(USE_APPKIT),)
USE_APPKIT = yes
endif

BUNDLE_INSTALL_DIR = $(GNUSTEP_APPLICATION_SUPPORT)/TalkSoup/InFilters

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

