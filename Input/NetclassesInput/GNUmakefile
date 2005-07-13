include $(GNUSTEP_MAKEFILES)/common.make
BUNDLE_NAME = NetclassesInput

BUNDLE_EXTENSION =

ifeq ($(OBJC_RUNTIME_LIB), apple)
BUNDLE_INSTALL_DIR = $(GNUSTEP_INSTALLATION_DIR)/Library/Application\ Support/TalkSoup/Input
else
BUNDLE_INSTALL_DIR = $(GNUSTEP_INSTALLATION_DIR)/Library/ApplicationSupport/TalkSoup/Input
endif

ifeq ($(OBJC_RUNTIME_LIB), apple)
NetclassesInput_BUNDLE_LIBS = -framework netclasses -framework TalkSoupBundles $(ADDITIONAL_FRAMEWORK_DIRS)
else
NetclassesInput_BUNDLE_LIBS = -lnetclasses -lTalkSoupBundles
endif

NetclassesInput_PRINCIPAL_CLASS = NetclassesInput

main = main.m Functions.m

NetclassesInput_OBJC_FILES = $(main) NetclassesInputSendThenDieTransport.m

GUI_LIB = 

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/bundle.make
-include GNUmakefile.postamble

