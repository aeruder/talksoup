include $(GNUSTEP_MAKEFILES)/common.make

TOOL_NAME = IRCSwarm 
IRCSwarm_OBJC_FILES = main.m misc.m IRCSwarmBot.m

GUI_LIB =

ifeq ($(OBJC_RUNTIME_LIB), apple)
	IRCSwarm_TOOL_LIBS = -framework netclasses $(ADDITIONAL_FRAMEWORK_DIRS)
else
	IRCSwarm_TOOL_LIBS = -lnetclasses
endif

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/tool.make
