include $(GNUSTEP_MAKEFILES)/common.make

BUNDLE_NAME = GNUstepOutput

ifeq ($(OBJC_RUNTIME_LIB), apple)
BUNDLE_INSTALL_DIR = $(GNUSTEP_INSTALLATION_DIR)/Library/Application\ Support/TalkSoup/Output
else
BUNDLE_INSTALL_DIR = $(GNUSTEP_INSTALLATION_DIR)/Library/ApplicationSupport/TalkSoup/Output
endif

BUNDLE_EXTENSION =

Pref_Nibs = Preferences.nib \
FontPreferences.nib \
GeneralPreferences.nib \
ColorPreferences.nib \
BundlePreferences.nib

All_Localized_Nibs = $(Pref_Nibs) \
ServerEditor.nib \
ServerList.nib \
NamePrompt.nib \
GroupEditor.nib \
ServerEditor.nib \
TopicInspector.nib \
GNUstepOutput.nib

ifeq ($(OBJC_RUNTIME_LIB), apple)
GNUstepOutput_LOCALIZED_RESOURCE_FILES = Localizable.strings \
$(All_Localized_Nibs)
else
GNUstepOutput_LOCALIZED_RESOURCE_FILES = Localizable.strings \
$(shell \
echo "$(All_Localized_Nibs)" | \
sed -e 's/\.nib/\.gorm/g')
endif

Pref_Images = Images/bundle_prefs.tiff \
Images/color_prefs.tiff \
Images/font_prefs.tiff \
Images/general_prefs.tiff

GNUstepOutput_RESOURCE_FILES = Images/common_ret.tiff Images/common_retH.tiff \
 AllLanguages/Defaults.plist AllLanguages/ServerList.plist $(Pref_Images)

All_NonLocalized_Nibs = \
AllLanguages/StandardChannel.nib \
AllLanguages/StandardQuery.nib \
AllLanguages/TabContent.nib

ifeq ($(OBJC_RUNTIME_LIB), apple)
Extra_Resources = $(All_NonLocalized_Nibs)
else
Extra_Resources = $(shell \
  echo "$(All_NonLocalized_Nibs)" | \
  sed -e 's/\.nib/\.gorm/g')
endif

GNUstepOutput_RESOURCE_FILES += $(Extra_Resources)
	
GNUstepOutput_LANGUAGES = English

GNUstepOutput_PRINCIPAL_CLASS = GNUstepOutput

ifeq ($(OBJC_RUNTIME_LIB), apple)
GNUstepOutput_BUNDLE_LIBS = -framework TalkSoupBundles $(ADDITIONAL_FRAMEWORK_DIRS)
else
GNUstepOutput_BUNDLE_LIBS = -lTalkSoupBundles $(GUI_LIBS)
endif

ConnectionController = Controllers/ConnectionController/ConnectionController.m \
Controllers/ConnectionController/ConnectionControllerCtcp.m \
Controllers/ConnectionController/ConnectionControllerDelegate.m \
Controllers/ConnectionController/ConnectionControllerInFilter.m \
Controllers/ConnectionController/ConnectionControllerNumericCommands.m \
Controllers/ConnectionController/ConnectionControllerOutFilter.m

ContentController = Controllers/ContentControllers/StandardContentController.m \
Controllers/ContentControllers/ContentController.m \
Controllers/ContentControllers/Tab/TabContentController.m \
Controllers/ContentControllers/Tab/TabMasterController.m \
Controllers/ContentControllers/StandardChannelController.m \
Controllers/ContentControllers/StandardQueryController.m

Preferences = Controllers/Preferences/GeneralPreferencesController.m \
Controllers/Preferences/BundlePreferencesController.m \
Controllers/Preferences/ColorPreferencesController.m \
Controllers/Preferences/FontPreferencesController.m \
Controllers/Preferences/PreferencesController.m

Controllers = \
Controllers/NamePromptController.m \
Controllers/ServerListController.m \
Controllers/InputController.m \
Controllers/GroupEditorController.m \
Controllers/ServerEditorController.m \
Controllers/ServerListConnectionController.m \
Controllers/TopicInspectorController.m \
$(Preferences) \
$(ConnectionController) \
$(ContentController)

Views = Views/AttributedTabViewItem.m \
Views/ScrollingTextView.m \
Views/KeyTextView.m

Misc = Misc/NSColorAdditions.m \
Misc/NSObjectAdditions.m \
Misc/NSAttributedStringAdditions.m

Models = Models/Channel.m

GNUstepOutput_OBJC_FILES = GNUstepOutput.m $(Controllers) $(Views) $(Misc)\
                           $(Models)
						   
-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/bundle.make
-include GNUmakefile.postamble
