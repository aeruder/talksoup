include $(GNUSTEP_MAKEFILES)/common.make

BUNDLE_NAME = GNUstepOutput

ifeq ($(OBJC_RUNTIME_LIB), apple)
BUNDLE_INSTALL_DIR = $(GNUSTEP_INSTALLATION_DIR)/Library/Application\ Support/TalkSoup/Output
else
BUNDLE_INSTALL_DIR = $(GNUSTEP_INSTALLATION_DIR)/Library/ApplicationSupport/TalkSoup/Output
endif

BUNDLE_EXTENSION =

ifeq ($(OBJC_RUNTIME_LIB), apple)
GNUstepOutput_LOCALIZED_RESOURCE_FILES = Localizable.strings Preferences.nib \
                                         ServerEditor.nib ServerList.nib \
                                         NamePrompt.nib GroupEditor.nib \
                                         ServerEditor.nib TopicInspector.nib \
                                         BundleConfigure.nib GNUstepOutput.nib
else
GNUstepOutput_LOCALIZED_RESOURCE_FILES = Localizable.strings Preferences.gorm \
                                         ServerEditor.gorm ServerList.gorm \
                                         NamePrompt.gorm GroupEditor.gorm \
                                         ServerEditor.gorm TopicInspector.gorm \
                                         BundleConfigure.gorm GNUstepOutput.gorm
endif

GNUstepOutput_RESOURCE_FILES = Images/common_ret.tiff Images/common_retH.tiff \
 AllLanguages/Defaults.plist

ifeq ($(OBJC_RUNTIME_LIB), apple)
GNUstepOutput_RESOURCE_FILES += AllLanguages/Channel.nib AllLanguages/Query.nib \
                                AllLanguages/Content.nib
else
GNUstepOutput_RESOURCE_FILES += AllLanguages/Channel.gorm AllLanguages/Query.gorm \
                                AllLanguages/Content.gorm
endif
	
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
Controllers/ConnectionController/ConnectionControllerOutFilter.m \
Controllers/ConnectionController/ConnectionControllerTabCompletion.m

ContentController = Controllers/ContentControllers/StandardContentController.m \
Controllers/ContentControllers/ContentController.m \
Controllers/ContentControllers/Tab/TabContentController.m \
Controllers/ContentControllers/Tab/TabMasterController.m

Controllers = Controllers/ChannelController.m Controllers/QueryController.m\
              Controllers/InputController.m\
              Controllers/PreferencesController.m \
              Controllers/NamePromptController.m \
              Controllers/ServerListController.m \
              Controllers/GroupEditorController.m \
              Controllers/ServerEditorController.m \
              Controllers/ServerListConnectionController.m \
              Controllers/TopicInspectorController.m \
              Controllers/BundleConfigureController.m \
              $(ConnectionController) \
			  $(ContentController)


Views = Views/AttributedTabViewItem.m Views/ScrollingTextView.m \
        Views/KeyTextView.m

Misc = Misc/NSColorAdditions.m Misc/NSObjectAdditions.m\
       Misc/NSAttributedStringAdditions.m

Models = Models/Channel.m

GNUstepOutput_OBJC_FILES = GNUstepOutput.m $(Controllers) $(Views) $(Misc)\
                           $(Models)
						   
-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/bundle.make
-include GNUmakefile.postamble
