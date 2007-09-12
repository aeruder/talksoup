include $(GNUSTEP_MAKEFILES)/common.make
BUNDLE_NAME = MessageOutTab

BUNDLE_EXTENSION =

BUNDLE_INSTALL_DIR = $(GNUSTEP_APPLICATION_SUPPORT)/TalkSoup/InFilters

MessageOutTab_LANGUAGES = English
MessageOutTab_LOCALIZED_RESOURCE_FILES = Localizable.strings

MessageOutTab_PRINCIPAL_CLASS = MessageOutTab

main = MessageOutTab.m

MessageOutTab_OBJC_FILES = $(main)

ifeq ($(OBJC_RUNTIME_LIB), apple)
MessageOutTab_BUNDLE_LIBS = -framework TalkSoupBundles $(ADDITIONAL_FRAMEWORK_DIRS)
else
MessageOutTab_BUNDLE_LIBS = -lTalkSoupBundles
endif

GUI_LIB = 

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/bundle.make
-include GNUmakefile.postamble

