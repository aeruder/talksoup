include $(GNUSTEP_MAKEFILES)/common.make
BUNDLE_NAME = MessageInTab

BUNDLE_EXTENSION =

BUNDLE_INSTALL_DIR = $(GNUSTEP_INSTALLATION_DIR)/Library/ApplicationSupport/TalkSoup/InFilters

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

GUI_LIBS = 

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/bundle.make
-include GNUmakefile.postamble

