include $(GNUSTEP_MAKEFILES)/common.make
BUNDLE_NAME = NetclassesInput

BUNDLE_EXTENSION =

BUNDLE_INSTALL_DIR = $(GNUSTEP_APPLICATION_SUPPORT)/TalkSoup/Input

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

