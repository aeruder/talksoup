include $(GNUSTEP_MAKEFILES)/common.make
BUNDLE_NAME = Piper

BUNDLE_EXTENSION =

BUNDLE_INSTALL_DIR = $(GNUSTEP_APPLICATION_SUPPORT)/TalkSoup/OutFilters

Piper_LANGUAGES = English
Piper_LOCALIZED_RESOURCE_FILES = Localizable.strings

Piper_PRINCIPAL_CLASS = Piper

Piper_OBJC_FILES = Piper.m

ifeq ($(OBJC_RUNTIME_LIB), apple)
Piper_BUNDLE_LIBS = -framework TalkSoupBundles $(ADDITIONAL_FRAMEWORK_DIRS)
else
Piper_BUNDLE_LIBS = -lTalkSoupBundles
endif

GUI_LIB = 

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/bundle.make
-include GNUmakefile.postamble

