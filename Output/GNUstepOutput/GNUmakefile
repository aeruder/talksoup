include $(GNUSTEP_MAKEFILES)/common.make

APP_NAME = GNUstepOutput

GNUstepOutput_LOCALIZED_RESOURCE_FILES = ColorPreferences.gorm Preferences.gorm GNUstepOutput.gorm \
 FontPreferences.gorm BundlePreferences.gorm

GNUstepOutput_RESOURCE_FILES = Images/color_prefs.tiff Images/font_prefs.tiff \
 Images/bundle_prefs.tiff Images/common_ret.tiff\
 Images/common_retH.tiff AllLanguages/Defaults.plist

GNUstepOutput_LANGUAGES = English

GNUstepOutput_PRINCIPAL_CLASS = GNUstepOutput

ifeq ($(OBJC_RUNTIME_LIB), apple)
GNUstepOutput_BUNDLE_LIBS = -framework TalkSoupBundles $(ADDITIONAL_FRAMEWORK_DIRS)
else
GNUstepOutput_GUI_LIBS = -lTalkSoupBundles $(GUI_LIBS)
endif

Controllers = Controllers/Preferences/PreferencesController.m \
  Controllers/Preferences/ColorPreferencesController.m \
  Controllers/Preferences/FontPreferencesController.m \
  Controllers/Preferences/BundlePreferencesController.m
  

GNUstepOutput_OBJC_FILES = GNUstepOutput.m $(Controllers) Misc/NSColorAdditions.m
						   
-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/application.make
-include GNUmakefile.postamble
