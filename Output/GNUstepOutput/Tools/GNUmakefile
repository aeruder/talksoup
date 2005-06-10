include $(GNUSTEP_MAKEFILES)/common.make

TOOL_NAME = exec_helper dns_helper

TOOL_INSTALL_DIR = ../GNUstepOutput/Resources/Tools

ifeq ($(OBJC_RUNTIME_LIB), apple)
exec_helper_BUNDLE_LIBS = -framework TalkSoupBundles $(ADDITIONAL_FRAMEWORK_DIRS)
dns_helper_BUNDLE_LIBS = -framework TalkSoupBundles $(ADDITIONAL_FRAMEWORK_DIRS)
else
exec_helper_BUNDLE_LIBS = -lTalkSoupBundles
dns_helper_BUNDLE_LIBS = -lTalkSoupBundles
endif

exec_helper_OBJC_FILES = exec_helper.m
dns_helper_OBJC_FILES = dns_helper.m

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/tool.make
-include GNUmakefile.postamble
