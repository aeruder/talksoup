include $(GNUSTEP_MAKEFILES)/common.make
BUNDLE_NAME = MessageInTab

BUNDLE_EXTENSION =

ifeq ($(OBJC_RUNTIME_LIB), apple)
BUNDLE_INSTALL_DIR = $(GNUSTEP_INSTALLATION_DIR)/Library/Application\ Support/TalkSoup/InFilters
else
BUNDLE_INSTALL_DIR = $(GNUSTEP_INSTALLATION_DIR)/Library/ApplicationSupport/TalkSoup/InFilters
endif

MessageInTab_LANGUAGES = English
MessageInTab_LOCALIZED_RESOURCE_FILES = Localizable.strings

MessageInTab_PRINCIPAL_CLASS = MessageInTab

main = MessageInTab.m

MessageInTab_OBJC_FILES = $(main)

ifeq ($(OBJC_RUNTIME_LIB), apple)
MessageInTab_BUNDLE_LIBS = -framework TalkSoupBundles $(ADDITIONAL_FRAMEWORK_DIRS)
else
MessageInTab_BUNDLE_LIBS = -lTalkSoupBundles
endif

GUI_LIB = 

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/bundle.make
-include GNUmakefile.postamble

