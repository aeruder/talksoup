include $(GNUSTEP_MAKEFILES)/common.make
BUNDLE_NAME = NetclassesInput

BUNDLE_EXTENSION =

BUNDLE_INSTALL_DIR = $(GNUSTEP_INSTALLATION_DIR)/Library/ApplicationSupport/TalkSoup/Input

ifeq ($(OBJC_RUNTIME_LIB), apple)
NetclassesInput_BUNDLE_LIBS = -framework netclasses -framework TalkSoupBundles
else
NetclassesInput_BUNDLE_LIBS = -lnetclasses -lTalkSoupBundles
endif

NetclassesInput_PRINCIPAL_CLASS = NetclassesInput

main = main.m Functions.m

NetclassesInput_OBJC_FILES = $(main)

GUI_LIBS = 

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/bundle.make
-include GNUmakefile.postamble

