include $(GNUSTEP_MAKEFILES)/common.make

BUNDLE_NAME = GNUstepOutput

BUNDLE_INSTALL_DIR = $(GNUSTEP_INSTALLATION_DIR)/Library/ApplicationSupport/TalkSoup/Output

BUNDLE_EXTENSION =

GNUstepOutput_RESOURCE_FILES = Images/TalkSoup.tiff
GNUstepOutput_LOCALIZED_RESOURCE_FILES = Channel.gorm Content.gorm Query.gorm\
                                         Localizable.strings Preferences.gorm \
                                         ServerEditor.gorm ServerList.gorm \
                                         NamePrompt.gorm GroupEditor.gorm \
										 ServerEditor.gorm TopicInspector.gorm
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
			  $(ConnectionController)


Views = Views/AttributedTabViewItem.m Views/ScrollingTextView.m \
        Views/KeyTextView.m

Misc = Misc/NSColorAdditions.m Misc/NSObjectAdditions.m\
       Misc/NSAttributedStringAdditions.m

Models = Models/Channel.m

GNUstepOutput_OBJC_FILES = GNUstepOutput.m $(Controllers) $(Views) $(Misc)\
                           $(Models)

ADDITIONAL_INCLUDE_DIRS = -I.  -I../../../Source

ADDITIONAL_OBJCFLAGS = -Wall -Wno-protocol

BUNDLE_LIBS = $(GUI_LIBS)

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/bundle.make
-include GNUmakefile.postamble
