include $(GNUSTEP_MAKEFILES)/common.make

BUNDLE_NAME = GNUstepOutput

GNUSTEP_INSTALLATION_DIR = $(GNUSTEP_LOCAL_ROOT)/Library/TalkSoup/Output

GNUstepOutput_RESOURCE_FILES = Images/irc.tiff
GNUstepOutput_LOCALIZED_RESOURCE_FILES = Channel.gorm Content.gorm Query.gorm \
                                         Localizable.strings
GNUstepOutput_LANGUAGES = English

GNUstepOutput_PRINCIPAL_CLASS = GNUstepOutput

Controllers = Controllers/ChannelController.m Controllers/QueryController.m\
                  Controllers/ContentController.m

Views = Views/AttributedTabViewItem.m Views/ScrollingTextView.m

GNUstepOutput_OBJC_FILES = GNUstepOutput.m $(Controllers) $(Views)

ADDITIONAL_INCLUDE_DIRS = -I.  -I../../../Source

ADDITIONAL_OBJCFLAGS = -Wall -Wno-protocol

BUNDLE_LIBS = $(GUI_LIBS)

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/bundle.make
-include GNUmakefile.postamble
