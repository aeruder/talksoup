/*
copyright 2002 Alexander Malmberg <alexander@malmberg.org>
*/

#include <Foundation/NSString.h>
#include <Foundation/NSUserDefaults.h>
#include <AppKit/NSColor.h>
#include <AppKit/NSColorPanel.h>
#include <AppKit/NSGraphics.h>
#include <AppKit/NSFont.h>
#include <AppKit/NSTextField.h>
#include <AppKit/NSColorWell.h>
#include <AppKit/NSPopUpButton.h>
#include <AppKit/NSBox.h>
#include <AppKit/GSVbox.h>
#include <AppKit/GSHbox.h>
#include "Label.h"

#include "TerminalViewPrefs.h"


NSString *TerminalViewDisplayPrefsDidChangeNotification=
	@"TerminalViewDisplayPrefsDidChangeNotification";

static NSUserDefaults *ud;


static NSString
	*TerminalFontKey=@"TerminalFont",
	*TerminalFontSizeKey=@"TerminalFontSize",
	*BoldTerminalFontKey=@"BoldTerminalFont",
	*BoldTerminalFontSizeKey=@"BoldTerminalFontSize",
	*CursorStyleKey=@"CursorStyle",

	*CursorColorRKey=@"CursorColorR",
	*CursorColorGKey=@"CursorColorG",
	*CursorColorBKey=@"CursorColorB",
	*CursorColorAKey=@"CursorColorA";


static NSFont *terminalFont,*boldTerminalFont;

static float brightness[3]={0.6,0.8,1.0};
static float saturation[3]={1.0,1.0,0.75};

static int cursorStyle;
static NSColor *cursorColor;


@implementation TerminalViewDisplayPrefs

+(void) initialize
{
	if (!ud)
		ud=[NSUserDefaults standardUserDefaults];

	if (!cursorColor)
	{
		NSString *s;
		float size;


		size=[ud floatForKey: TerminalFontSizeKey];
		s=[ud stringForKey: TerminalFontKey];
		if (!s)
			terminalFont=[NSFont userFixedPitchFontOfSize: size];
		else
			terminalFont=[NSFont fontWithName: s  size: size];

		size=[ud floatForKey: BoldTerminalFontSizeKey];
		s=[ud stringForKey: BoldTerminalFontKey];
		if (!s)
			boldTerminalFont=[NSFont userFixedPitchFontOfSize: size];
		else
			boldTerminalFont=[NSFont fontWithName: s  size: size];

		cursorStyle=[ud integerForKey: CursorStyleKey];
		if ([ud objectForKey: CursorColorRKey])
		{
			float r,g,b,a;
			r=[ud floatForKey: CursorColorRKey];
			g=[ud floatForKey: CursorColorGKey];
			b=[ud floatForKey: CursorColorBKey];
			a=[ud floatForKey: CursorColorAKey];
			cursorColor=[[NSColor colorWithCalibratedRed: r
				green: g
				blue: b
				alpha: a] retain];
		}
		else
		{
			cursorColor=[[NSColor whiteColor] retain];
		}
	}
}

+(NSFont *) terminalFont
{
	return terminalFont;
}

+(NSFont *) boldTerminalFont
{
	return boldTerminalFont;
}

+(const float *) brightnessForIntensities
{
	return brightness;
}
+(const float *) saturationForIntensities
{
	return saturation;
}

+(int) cursorStyle
{
	return cursorStyle;
}

+(NSColor *) cursorColor
{
	return cursorColor;
}


-(void) save
{
	if (!top) return;

	cursorStyle=[pb_cursorStyle indexOfSelectedItem];
	[ud setInteger: cursorStyle
		forKey: CursorStyleKey];

	{
		DESTROY(cursorColor);
		cursorColor=[w_cursorColor color];
		cursorColor=[[cursorColor colorUsingColorSpaceName: NSCalibratedRGBColorSpace] retain];
		[ud setFloat: [cursorColor redComponent]
			forKey: CursorColorRKey];
		[ud setFloat: [cursorColor greenComponent]
			forKey: CursorColorGKey];
		[ud setFloat: [cursorColor blueComponent]
			forKey: CursorColorBKey];
		[ud setFloat: [cursorColor alphaComponent]
			forKey: CursorColorAKey];
	}

	terminalFont=[f_terminalFont font];
	[ud setFloat: [terminalFont pointSize]
		forKey: TerminalFontSizeKey];
	[ud setObject: [terminalFont fontName]
		forKey: TerminalFontKey];

	boldTerminalFont=[f_boldTerminalFont font];
	[ud setFloat: [boldTerminalFont pointSize]
		forKey: BoldTerminalFontSizeKey];
	[ud setObject: [boldTerminalFont fontName]
		forKey: BoldTerminalFontKey];

	/* TODO: actually use this somewhere */
	[[NSNotificationCenter defaultCenter]
		postNotificationName: TerminalViewDisplayPrefsDidChangeNotification
		object: self];
}

-(void) revert
{
	NSFont *f;

	[pb_cursorStyle selectItemAtIndex: [[self class] cursorStyle]];
	[w_cursorColor setColor: [[self class] cursorColor]];

	f=[[self class] terminalFont];
	[f_terminalFont setStringValue: [NSString stringWithFormat: @"%@ %0.1f",[f fontName],[f pointSize]]];
	[f_terminalFont setFont: f];

	f=[[self class] boldTerminalFont];
	[f_boldTerminalFont setStringValue: [NSString stringWithFormat: @"%@ %0.1f",[f fontName],[f pointSize]]];
	[f_boldTerminalFont setFont: f];
}


-(NSString *) name
{
	return _(@"Display");
}

-(void) setupButton: (NSButton *)b
{
	[b setTitle: _(@"Display")];
	[b sizeToFit];
}

-(void) willHide
{
}

-(NSView *) willShow
{
	if (!top)
	{
		top=[[GSVbox alloc] init];
		[top setDefaultMinYMargin: 4];
		[top addView: [[[NSView alloc] init] autorelease] enablingYResizing: YES];

		{
			NSTextField *f;
			NSButton *b;
			GSHbox *hb;

			{
				NSBox *b;
				GSTable *t;
				NSPopUpButton *pb;
				NSColorWell *w;

				b=[[NSBox alloc] init];
//				[b setAutoresizingMask: NSViewWidthSizable];
				[b setTitle: _(@"Cursor")];

				t=[[GSTable alloc] initWithNumberOfRows: 2 numberOfColumns: 2];
				[t setAutoresizingMask: NSViewWidthSizable|NSViewHeightSizable];

				f=[NSTextField newLabel: _(@"Style:")];
				[f setAutoresizingMask: NSViewMinXMargin|NSViewMinYMargin|NSViewMaxYMargin];
				[t putView: f  atRow: 0 column: 0  withXMargins: 2 yMargins: 2];
				DESTROY(f);

				pb_cursorStyle=pb=[[NSPopUpButton alloc] init];
				[pb setAutoenablesItems: NO];
				[pb addItemWithTitle: _(@"Line")];
				[pb addItemWithTitle: _(@"Stroked block")];
				[pb addItemWithTitle: _(@"Filled block")];
				[pb addItemWithTitle: _(@"Inverted block")];
				[pb sizeToFit];
				[t putView: pb  atRow: 0 column: 1  withXMargins: 2 yMargins: 2];
				DESTROY(pb);


				f=[NSTextField newLabel: _(@"Color:")];
				[f setAutoresizingMask: NSViewMinXMargin|NSViewMinYMargin|NSViewMaxYMargin];
				[t putView: f  atRow: 1 column: 0  withXMargins: 2 yMargins: 2];
				DESTROY(f);

				w_cursorColor=w=[[NSColorWell alloc] initWithFrame: NSMakeRect(0,0,40,30)];
				[t putView: w  atRow: 1 column: 1  withXMargins: 2 yMargins: 2];
				DESTROY(w);

				[[NSColorPanel sharedColorPanel] setShowsAlpha: YES];


				[t sizeToFit];
				[b setContentView: t];
				[b sizeToFit];
				[top addView: b enablingYResizing: NO];
				DESTROY(b);
			}

			hb=[[GSHbox alloc] init];
			[hb setDefaultMinXMargin: 4];
			[hb setAutoresizingMask: NSViewWidthSizable];

			f=[NSTextField newLabel: _(@"Bold font:")];
			[f setAutoresizingMask: 0];
			[hb addView: f  enablingXResizing: NO];
			DESTROY(f);

			f_boldTerminalFont=f=[[NSTextField alloc] init];
			[f setAutoresizingMask: NSViewWidthSizable|NSViewHeightSizable];
			[f setEditable: NO];
			[hb addView: f  enablingXResizing: YES];
			DESTROY(f);

			b=[[NSButton alloc] init];
			[b setTitle: _(@"Pick font...")];
			[b setTarget: self];
			[b setAction: @selector(_pickBoldTerminalFont:)];
			[b sizeToFit];
			[hb addView: b  enablingXResizing: NO];
			DESTROY(b);

			[top addView: hb enablingYResizing: NO];
			DESTROY(hb);


			hb=[[GSHbox alloc] init];
			[hb setDefaultMinXMargin: 4];
			[hb setAutoresizingMask: NSViewWidthSizable];

			f=[NSTextField newLabel: _(@"Normal font:")];
			[f setAutoresizingMask: 0];
			[hb addView: f  enablingXResizing: NO];
			DESTROY(f);

			f_terminalFont=f=[[NSTextField alloc] init];
			[f setAutoresizingMask: NSViewWidthSizable|NSViewHeightSizable];
			[f setEditable: NO];
			[hb addView: f  enablingXResizing: YES];
			DESTROY(f);

			b=[[NSButton alloc] init];
			[b setTitle: _(@"Pick font...")];
			[b setTarget: self];
			[b setAction: @selector(_pickTerminalFont:)];
			[b sizeToFit];
			[hb addView: b  enablingXResizing: NO];
			DESTROY(b);

			[top addView: hb enablingYResizing: NO];
			DESTROY(hb);
		}

		[self revert];
	}
	return top;
}

-(void) dealloc
{
	DESTROY(top);
	[super dealloc];
}


-(void) _pickFont
{
	NSFontManager *fm=[NSFontManager sharedFontManager];
	[fm setSelectedFont: [f_cur font] isMultiple: NO];
	[fm orderFrontFontPanel: self];
}

-(void) _pickTerminalFont: (id)sender
{
	f_cur=f_terminalFont;
	[self _pickFont];
}

-(void) _pickBoldTerminalFont: (id)sender
{
	f_cur=f_boldTerminalFont;
	[self _pickFont];
}

-(void) changeFont: (id)sender
{
	NSFont *f;

	if (!f_cur) return;
	f=[sender convertFont: [f_cur font]];
	if (!f) return;

	[f_cur setStringValue: [NSString stringWithFormat: @"%@ %0.1f",[f fontName],[f pointSize]]];
	[f_cur setFont: f];
}

@end


static NSString
	*LoginShellKey=@"LoginShell",
	*ShellKey=@"Shell";

static NSString *shell;
static BOOL loginShell;

@implementation TerminalViewShellPrefs

+(void) initialize
{
	if (!ud)
		ud=[NSUserDefaults standardUserDefaults];

	if (!shell)
	{
		loginShell=[ud boolForKey: LoginShellKey];
		shell=[ud stringForKey: ShellKey];
		if (!shell && getenv("SHELL"))
			shell=[NSString stringWithCString: getenv("SHELL")];
		if (!shell)
			shell=@"/bin/sh";
		shell=[shell retain];
	}
}

+(NSString *) shell
{
	return shell;
}

+(BOOL) loginShell
{
	return loginShell;
}


-(void) save
{
	if (!top) return;

	if ([b_loginShell state])
		loginShell=YES;
	else
		loginShell=NO;
	[ud setBool: loginShell forKey: LoginShellKey];

	DESTROY(shell);
	shell=[[tf_shell stringValue] copy];
	[ud setObject: shell forKey: ShellKey];
}

-(void) revert
{
	[b_loginShell setState: loginShell];
	[tf_shell setStringValue: shell];
}


-(NSString *) name
{
	return _(@"Shell");
}

-(void) setupButton: (NSButton *)b
{
	[b setTitle: _(@"Shell")];
	[b sizeToFit];
}

-(void) willHide
{
}

-(NSView *) willShow
{
	if (!top)
	{
		top=[[GSVbox alloc] init];
		[top setDefaultMinYMargin: 4];

		[top addView: [[[NSView alloc] init] autorelease] enablingYResizing: YES];

		{
			NSTextField *f;
			NSButton *b;

			b=b_loginShell=[[NSButton alloc] init];
			[b setAutoresizingMask: NSViewWidthSizable];
			[b setTitle: _(@"Start as login-shell")];
			[b setButtonType: NSSwitchButton];
			[b sizeToFit];
			[top addView: b enablingYResizing: NO];
			DESTROY(b);

			tf_shell=f=[[NSTextField alloc] init];
			[f sizeToFit];
			[f setAutoresizingMask: NSViewWidthSizable];
			[top addView: f enablingYResizing: NO];
			DESTROY(f);

			f=[NSTextField newLabel: _(@"Shell:")];
			[f setAutoresizingMask: NSViewWidthSizable];
			[f sizeToFit];
			[top addView: f enablingYResizing: NO];
			DESTROY(f);
		}

		[self revert];
	}
	return top;
}

-(void) dealloc
{
	DESTROY(top);
	[super dealloc];
}

@end


static NSString
	*CommandAsMetaKey=@"CommandAsMeta",
	*DoubleEscapeKey=@"DoubleEscape";

static BOOL commandAsMeta,doubleEscape;

@implementation TerminalViewKeyboardPrefs

+(void) initialize
{
	if (!ud)
		ud=[NSUserDefaults standardUserDefaults];

	commandAsMeta=[ud boolForKey: CommandAsMetaKey];
	doubleEscape=[ud boolForKey: DoubleEscapeKey];
}

+(BOOL) commandAsMeta
{
	return commandAsMeta;
}

+(BOOL) doubleEscape
{
	return doubleEscape;
}


-(void) save
{
	if (!top) return;

	if ([b_commandAsMeta state])
		commandAsMeta=YES;
	else
		commandAsMeta=NO;
	[ud setBool: commandAsMeta forKey: CommandAsMetaKey];

	if ([b_doubleEscape state])
		doubleEscape=YES;
	else
		doubleEscape=NO;
	[ud setBool: doubleEscape forKey: DoubleEscapeKey];
}

-(void) revert
{
	[b_commandAsMeta setState: commandAsMeta];
	[b_doubleEscape setState: doubleEscape];
}


-(NSString *) name
{
	return _(@"Keyboard");
}

-(void) setupButton: (NSButton *)b
{
	[b setTitle: _(@"Keyboard")];
	[b sizeToFit];
}

-(void) willHide
{
}

-(NSView *) willShow
{
	if (!top)
	{
		top=[[GSVbox alloc] init];
		[top setDefaultMinYMargin: 8];

		[top addView: [[[NSView alloc] init] autorelease] enablingYResizing: YES];

		{
			NSButton *b;

			b=b_commandAsMeta=[[NSButton alloc] init];
			[b setAutoresizingMask: NSViewWidthSizable];
			[b setTitle:
				_(@"Treat the command key as meta.\n"
				  @"\n"
				  @"Note that with this enabled, you won't be\n"
				  @"able to access menu entries with the\n"
				  @"keyboard.")];
			[b setButtonType: NSSwitchButton];
			[b sizeToFit];
			[top addView: b enablingYResizing: NO];
			DESTROY(b);

			[top addView: [[[NSView alloc] init] autorelease] enablingYResizing: YES];
			[top addSeparator];
			[top addView: [[[NSView alloc] init] autorelease] enablingYResizing: YES];

			b=b_doubleEscape=[[NSButton alloc] init];
			[b setAutoresizingMask: NSViewWidthSizable];
			[b setTitle:
				_(@"Send a double escape for the escape key.\n"
				  @"\n"
				  @"This means that the escape key will be\n"
				  @"recognized faster by many programs, but\n"
				  @"you can't use it as a substitute for meta.")];
			[b setButtonType: NSSwitchButton];
			[b sizeToFit];
			[top addView: b enablingYResizing: NO];
			DESTROY(b);
		}

		[top addView: [[[NSView alloc] init] autorelease] enablingYResizing: YES];

		[self revert];
	}
	return top;
}

-(void) dealloc
{
	DESTROY(top);
	[super dealloc];
}

@end

