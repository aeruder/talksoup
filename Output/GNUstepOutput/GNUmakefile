include $(GNUSTEP_MAKEFILES)/common.make

BUNDLE_NAME = GNUstepOutput

BUNDLE_INSTALL_DIR = $(GNUSTEP_INSTALLATION_DIR)/Library/ApplicationSupport/TalkSoup/Output

BUNDLE_EXTENSION =

GNUstepOutput_LOCALIZED_RESOURCE_FILES = Channel.gorm Content.gorm Query.gorm\
                                         Localizable.strings Preferences.gorm \
                                         ServerEditor.gorm ServerList.gorm \
                                         NamePrompt.gorm GroupEditor.gorm \
                                         ServerEditor.gorm TopicInspector.gorm \
                                         BundleConfigure.gorm

GNUstepOutput_RESOURCE_FILES = Images/UpArrow.tiff \
 Images/RightArrow.tiff Images/LeftArrow.tiff \
 Images/DownArrow.tiff Images/TalkSoup.tiff \
 Images/common_ret.tiff Images/common_retH.tiff

GNUstepOutput_LANGUAGES = English

GNUstepOutput_PRINCIPAL_CLASS = GNUstepOutput

GNUstepOutput_FRAMEWORKS = -lTalkSoupBundles

ConnectionController = Controllers/ConnectionController/ConnectionController.m \
Controllers/ConnectionController/ConnectionControllerCtcp.m \
Controllers/ConnectionController/ConnectionControllerDelegate.m \
Controllers/ConnectionController/ConnectionControllerInFilter.m \
Controllers/ConnectionController/ConnectionControllerNumericCommands.m \
Controllers/ConnectionController/ConnectionControllerOutFilter.m \
Controllers/ConnectionController/ConnectionControllerTabCompletion.m

Controllers = Controllers/ChannelController.m Controllers/QueryController.m\
              Controllers/ContentController.m Controllers/InputController.m\
              Controllers/PreferencesController.m \
              Controllers/NamePromptController.m \
              Controllers/ServerListController.m \
              Controllers/GroupEditorController.m \
              Controllers/ServerEditorController.m \
              Controllers/ServerListConnectionController.m \
              Controllers/TopicInspectorController.m \
              Controllers/BundleConfigureController.m \
              $(ConnectionController)


Views = Views/AttributedTabViewItem.m Views/ScrollingTextView.m \
        Views/KeyTextView.m

Misc = Misc/NSColorAdditions.m Misc/NSObjectAdditions.m\
       Misc/NSAttributedStringAdditions.m

Models = Models/Channel.m

GNUstepOutput_OBJC_FILES = GNUstepOutput.m $(Controllers) $(Views) $(Misc)\
                           $(Models)
BUNDLE_LIBS = $(GUI_LIBS)

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/bundle.make
-include GNUmakefile.postamble
