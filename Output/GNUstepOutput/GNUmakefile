include $(GNUSTEP_MAKEFILES)/common.make

APP_NAME = GNUstepOutput

GNUstepOutput_LOCALIZED_RESOURCE_FILES = Preferences.gorm GNUstepOutput.gorm

GNUstepOutput_RESOURCE_FILES = Images/common_ret.tiff Images/common_retH.tiff \
 AllLanguages/Defaults.plist

GNUstepOutput_LANGUAGES = English

GNUstepOutput_PRINCIPAL_CLASS = GNUstepOutput

ifeq ($(OBJC_RUNTIME_LIB), apple)
GNUstepOutput_BUNDLE_LIBS = -framework TalkSoupBundles $(ADDITIONAL_FRAMEWORK_DIRS)
else
GNUstepOutput_BUNDLE_LIBS = -lTalkSoupBundles $(GUI_LIBS)
endif

Controllers = Controllers/Preferences/PreferencesController.m

GNUstepOutput_OBJC_FILES = GNUstepOutput.m $(Controllers)
						   
-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/application.make
-include GNUmakefile.postamble
