include $(GNUSTEP_MAKEFILES)/common.make
BUNDLE_NAME = MessageOutTab

BUNDLE_EXTENSION =

ifeq ($(OBJC_RUNTIME_LIB), apple)
BUNDLE_INSTALL_DIR = $(GNUSTEP_INSTALLATION_DIR)/Library/Application\ Support/TalkSoup/InFilters
else
BUNDLE_INSTALL_DIR = $(GNUSTEP_INSTALLATION_DIR)/Library/ApplicationSupport/TalkSoup/InFilters
endif

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

