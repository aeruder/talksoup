/*
copyright 2002 Alexander Malmberg <alexander@malmberg.org>
*/

#ifndef TerminalViewPrefs_h
#define TerminalViewPrefs_h

#include "PrefBox.h"


@class NSString,NSFont,NSColor;
@class GSVbox,NSTextField,NSColorWell,NSPopUpButton;

extern NSString *TerminalViewDisplayPrefsDidChangeNotification;

@interface TerminalViewDisplayPrefs : NSObject <PrefBox>
{
	GSVbox *top;
	NSTextField *f_terminalFont,*f_boldTerminalFont;
	NSColorWell *w_cursorColor;
	NSPopUpButton *pb_cursorStyle;

	NSTextField *f_cur;
}

+(NSFont *) terminalFont;
+(NSFont *) boldTerminalFont;

+(const float *) brightnessForIntensities;
+(const float *) saturationForIntensities;

#define CURSOR_LINE          0
#define CURSOR_BLOCK_STROKE  1
#define CURSOR_BLOCK_FILL    2
#define CURSOR_BLOCK_INVERT  3
+(int) cursorStyle;
+(NSColor *) cursorColor;

@end


@interface TerminalViewShellPrefs : NSObject <PrefBox>
{
	GSVbox *top;

	NSTextField *tf_shell;
	NSButton *b_loginShell;
}

+(NSString *) shell;
+(BOOL) loginShell;

@end


@interface TerminalViewKeyboardPrefs : NSObject <PrefBox>
{
	GSVbox *top;

	NSButton *b_commandAsMeta;
	NSButton *b_doubleEscape;
}

+(BOOL) commandAsMeta;
+(BOOL) doubleEscape;

@end

#endif

