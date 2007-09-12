include $(GNUSTEP_MAKEFILES)/common.make
BUNDLE_NAME = PrivateBeep

BUNDLE_EXTENSION =

BUNDLE_INSTALL_DIR = $(GNUSTEP_APPLICATION_SUPPORT)/TalkSoup/InFilters

PrivateBeep_LANGUAGES = English
PrivateBeep_LOCALIZED_RESOURCE_FILES = Localizable.strings

PrivateBeep_PRINCIPAL_CLASS = PrivateBeep

PrivateBeep_OBJC_FILES = PrivateBeep.m

ifeq ($(OBJC_RUNTIME_LIB), apple)
PrivateBeep_BUNDLE_LIBS = -framework TalkSoupBundles $(ADDITIONAL_FRAMEWORK_DIRS)
else
PrivateBeep_BUNDLE_LIBS = -lTalkSoupBundles
endif

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/bundle.make
-include GNUmakefile.postamble

