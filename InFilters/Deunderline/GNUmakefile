include $(GNUSTEP_MAKEFILES)/common.make
BUNDLE_NAME = Deunderline

BUNDLE_EXTENSION =

BUNDLE_INSTALL_DIR = $(GNUSTEP_APPLICATION_SUPPORT)/TalkSoup/InFilters

Deunderline_LANGUAGES = English
Deunderline_LOCALIZED_RESOURCE_FILES = Localizable.strings

Deunderline_PRINCIPAL_CLASS = Deunderline

Deunderline_OBJC_FILES = Deunderline.m

ifeq ($(OBJC_RUNTIME_LIB), apple)
Deunderline_BUNDLE_LIBS = -framework TalkSoupBundles $(ADDITIONAL_FRAMEWORK_DIRS)
else
Deunderline_BUNDLE_LIBS = -lTalkSoupBundles
endif

GUI_LIB = 

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/bundle.make
-include GNUmakefile.postamble

