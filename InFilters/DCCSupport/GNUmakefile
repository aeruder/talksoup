include $(GNUSTEP_MAKEFILES)/common.make
BUNDLE_NAME = DCCSupport

BUNDLE_EXTENSION =

BUNDLE_INSTALL_DIR = $(GNUSTEP_INSTALLATION_DIR)/Library/ApplicationSupport/TalkSoup/InFilters

DCCSupport_LANGUAGES = English
DCCSupport_LOCALIZED_RESOURCE_FILES = Localizable.strings

DCCSupport_PRINCIPAL_CLASS = DCCSupport

DCCSupport_OBJC_FILES = DCCSupport.m DCCObject.m

ifeq ($(OBJC_RUNTIME_LIB), apple)
DCCSupport_BUNDLE_LIBS = -framework netclasses -framework TalkSoupBundles $(ADDITIONAL_FRAMEWORK_DIRS)
else
DCCSupport_BUNDLE_LIBS = -lTalkSoupBundles -lnetclasses
endif

GUI_LIB = 

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/bundle.make
-include GNUmakefile.postamble

