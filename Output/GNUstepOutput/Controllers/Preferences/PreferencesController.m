/***************************************************************************
                         PreferencesController.m
                          -------------------
    begin                : Thu Apr  3 08:09:15 CST 2003
    copyright            : (C) 2003 by Andy Ruder
	                       w/ much of the code borrowed from Preferences.app
						   by Jeff Teunissen
    email                : aeruder@yahoo.com
 ***************************************************************************/

/***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/

#import "Controllers/Preferences/PreferencesController.h"
#import "Controllers/ConnectionController.h"
#import "Controllers/ContentControllers/ContentController.h"
#import "Controllers/QueryController.h"
#import "Misc/NSColorAdditions.h"
#import "GNUstepOutput.h"
#import "Views/ScrollingTextView.h"

#import <TalkSoupBundles/TalkSoup.h>

#import <Foundation/NSNotification.h>
#import <Foundation/NSString.h>
#import <Foundation/NSEnumerator.h>
#import <Foundation/NSArray.h>
#import <AppKit/NSScrollView.h>
#import <AppKit/NSTextField.h>
#import <AppKit/NSColorWell.h>
#import <AppKit/NSButton.h>
#import <AppKit/NSTextView.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSView.h>
#import <AppKit/NSFontPanel.h>
#import <AppKit/NSFontManager.h>
#import <AppKit/NSFont.h>
#import <AppKit/NSMatrix.h>
#import <AppKit/NSNibLoading.h>

#import "Controllers/Preferences/ColorPreferencesController.h"

/* object: the preferences module */
NSString *PreferencesModuleAdditionNotification = @"PreferencesModuleAdditionNotification";

/* object: the preferences module */
NSString *PreferencesModuleRemovalNotification = @"PreferencesModuleRemovalNotification";

NSString *GNUstepOutputPersonalBracketColor = @"GNUstepOutputPersonalBracketColor";
NSString *GNUstepOutputOtherBracketColor = @"GNUstepOutputOtherBracketColor";
NSString *GNUstepOutputTextColor = @"GNUstepOutputTextColor";
NSString *GNUstepOutputBackgroundColor = @"GNUstepOutputBackgroundColor";
NSString *GNUstepOutputServerList = @"GNUstepOutputServerList";
NSString *GNUstepOutputChatFontSize = @"GNUstepOutputChatFontSize";
NSString *GNUstepOutputChatFontName = @"GNUstepOutputChatFontName";
NSString *GNUstepOutputUserListFontName = @"GNUstepOutputUserListFontName";
NSString *GNUstepOutputUserListFontSize = @"GNUstepOutputUserListFontSize";
NSString *GNUstepOutputTextFieldFontName = @"GNUstepOutputTextFieldFontName";
NSString *GNUstepOutputTextFieldFontSize = @"GNUstepOutputTextFieldFontSize";
NSString *GNUstepOutputScrollBack = @"GNUstepOutputScrollBack";
NSString *GNUstepOutputAliases = @"GNUstepOutputAliases";
NSString *GNUstepOutputUserListStyle = @"GNUstepOutputUserListStyle";

@interface PreferencesController (PrivateMethods)
- (void)buttonClicked: (NSMatrix *)aCell;

- (void)registerPreferencesModule: aPreferencesModule;
- (void)unregisterPreferencesModule: aPreferencesModule;

- (void)preferencesModuleAdded: (NSNotification *)aNotification;
- (void)preferencesModuleRemoved: (NSNotification *)aNotification;
@end

@implementation PreferencesController
- init
{
	if (!(self = [super init])) return self;

	prefsModules = [NSMutableArray new];

	if (![NSBundle loadNibNamed: @"Preferences" owner: self])
	{
		[self dealloc];
		return nil;
	}

	[[NSNotificationCenter defaultCenter] addObserver: self
	  selector: @selector(preferencesModuleAdded:)
	  name: PreferencesModuleAdditionNotification
	  object: nil];

	[[NSNotificationCenter defaultCenter] addObserver: self
	  selector: @selector(preferencesModuleRemoved:)
	  name: PreferencesModuleRemovalNotification
	  object: nil];
	
	return self;
}	
- (void)awakeFromNib
{
	/* much of this setup code was shamelessly ripped
	 * from preferences.app.  Why redo what works
	 * so nicely? 
	 */
	prefsList = AUTORELEASE([[NSMatrix alloc] initWithFrame: 
	  NSMakeRect(0, 0, 64*30, 64)]);
	[prefsList setCellClass: [NSButtonCell class]];
	[prefsList setCellSize: NSMakeSize(64, 64)];
	[prefsList setMode: NSRadioModeMatrix];
	[prefsList setIntercellSpacing: NSZeroSize];

	[prefsList setTarget: self];
	[prefsList setAction: @selector(buttonClicked:)];
	
	[scrollView setDocumentView: prefsList];
	[scrollView setHasHorizontalScroller: YES];
	[scrollView setHasVerticalScroller: NO];
	[scrollView setBorderType: NSBezelBorder];
}
- (void)dealloc
{
	DESTROY(window);
	DESTROY(prefsModules);

	[super dealloc];
}
- (NSWindow *)window 
{
	return window;
}
- (BOOL)setCurrentModule: aPrefsModule
{
	// FIXME
}
- (void)refreshCurrentPanel
{
	// FIXME
}
/*	
	
- (void)awakeFromNib
{
	[nick setNextKeyView: realName];
	[realName setNextKeyView: password];
	[password setNextKeyView: userName];
	[userName setNextKeyView: nick];
	[window makeKeyAndOrderFront: nil];
	[window makeFirstResponder: nick];
	[window setDelegate: self];
	[_GS_ setPreferencesController: self];
}
- (void)dealloc
{
	[nick setTarget: nil];
	[nick setDelegate: nil];
	[realName setTarget: nil];
	[realName setDelegate: nil];
	[password setTarget: nil];
	[password setDelegate: nil];
	[userName setTarget: nil];
	[userName setDelegate: nil];
	[window setDelegate: nil];
	[setFontButton setTarget: nil];
	[resetButton setTarget: nil];
	RELEASE(window);
	[super dealloc];
}
- (void)loadCurrentDefaults
{	
	id y;
	
	y = [NSColor colorFromEncodedData: 
	  [_GS_ defaultsObjectForKey: GNUstepOutputPersonalBracketColor]];
	[personalBracketColor setColor: y];
	[self personalBracketColorSet: personalBracketColor];
	 
	y = [NSColor colorFromEncodedData: 
	  [_GS_ defaultsObjectForKey: GNUstepOutputOtherBracketColor]];
	[otherBracketColor setColor: y];
	[self otherBracketColorSet: otherBracketColor];

	y = [NSColor colorFromEncodedData: 
	  [_GS_ defaultsObjectForKey: GNUstepOutputBackgroundColor]];
	[backgroundColor setColor: y];
	[self backgroundColorSet: backgroundColor];
	 
	y = [NSColor colorFromEncodedData: 
	  [_GS_ defaultsObjectForKey: GNUstepOutputTextColor]];
	[textColor setColor: y];
	[self textColorSet: textColor];
	 
	y = [_GS_ defaultsObjectForKey: IRCDefaultsNick];
	[nick setStringValue: y];
	[self nickSet: nick];
	[nick setDelegate: self];
	
	y = [_GS_ defaultsObjectForKey: IRCDefaultsRealName];
	[realName setStringValue: y];
	[self realNameSet: realName];
	[realName setDelegate: self];
	
	y = [_GS_ defaultsObjectForKey: IRCDefaultsUserName];
	[userName setStringValue: y];
	[self userNameSet: userName];
	[userName setDelegate: self];
	
	y = [_GS_ defaultsObjectForKey: IRCDefaultsPassword];
	[password setStringValue: y];
	[self passwordSet: password];
	[password setDelegate: self];
	
	[fontField setStringValue: [NSString stringWithFormat: @"%@ %@",
	  [_GS_ defaultsObjectForKey: GNUstepOutputFontName],
	  [_GS_ defaultsObjectForKey: GNUstepOutputFontSize]]];
}
- nickSet: (NSTextField *)sender
{
	id array = [[sender stringValue] separateIntoNumberOfArguments: 2];
	
	if ([array count] != 0)
	{
		[_GS_ setDefaultsObject: [array objectAtIndex: 0] forKey:
		  IRCDefaultsNick];
	}
	else
	{
		[_GS_ setDefaultsObject: nil forKey: IRCDefaultsNick];
	}
	  	
	return self;
}
- passwordSet: (NSTextField *)sender
{
	id array = [[sender stringValue] separateIntoNumberOfArguments: 2];
	
	if ([array count] != 0)
	{
		[_GS_ setDefaultsObject: [array objectAtIndex: 0] forKey:
		  IRCDefaultsPassword];
	}
	else
	{
		[_GS_ setDefaultsObject: nil forKey: IRCDefaultsPassword];
	}
	
	return self;
}
- userNameSet: (NSTextField *)sender
{
	id array = [[sender stringValue] separateIntoNumberOfArguments: 2];
	
	if ([array count] != 0)
	{
		[_GS_ setDefaultsObject: [array objectAtIndex: 0] forKey:
		  IRCDefaultsUserName];
	}
	else
	{
		[_GS_ setDefaultsObject: nil forKey: IRCDefaultsUserName];
	}
	
	return self;
}
- realNameSet: (NSTextField *)sender
{
	id array = [[sender stringValue] separateIntoNumberOfArguments: 1];

	if ([array count] != 0)
	{
		[_GS_ setDefaultsObject: [array objectAtIndex: 0] forKey:
		  IRCDefaultsRealName];
	}
	else
	{
		[_GS_ setDefaultsObject: nil forKey: IRCDefaultsRealName];
	}
	
	return self;
}
- personalBracketColorSet: (NSColorWell *)sender
{
	NSEnumerator *iter;
	id object;
	id old;

	old = [_GS_ defaultsObjectForKey: GNUstepOutputPersonalBracketColor];		
	[_GS_ setDefaultsObject: [[sender color] encodeToData] forKey:
	  GNUstepOutputPersonalBracketColor];
	
	iter = [[_GS_ connectionControllers] objectEnumerator];
	
	while ((object = [iter nextObject]))
	{
		[[object contentController] updatedColor: GNUstepOutputPersonalBracketColor
		  old: old];
	}
	
	return self;
}
- backgroundColorSet: (NSColorWell *)sender
{
	NSEnumerator *iter;
	id object;
	id old;
	
	old = [_GS_ defaultsObjectForKey: GNUstepOutputBackgroundColor]; 		
	[_GS_ setDefaultsObject: [[sender color] encodeToData] forKey:
	  GNUstepOutputBackgroundColor];
	
	iter = [[_GS_ connectionControllers] objectEnumerator];
	
	while ((object = [iter nextObject]))
	{
		[[object contentController] updatedColor: GNUstepOutputBackgroundColor
		 old: old];
	}

	return self;
}
- otherBracketColorSet: (NSColorWell *)sender
{
	NSEnumerator *iter;
	id object;
	id old;

	old = [_GS_ defaultsObjectForKey: GNUstepOutputOtherBracketColor];
	[_GS_ setDefaultsObject: [[sender color] encodeToData] forKey:
	  GNUstepOutputOtherBracketColor];
	
	iter = [[_GS_ connectionControllers] objectEnumerator];
	
	while ((object = [iter nextObject]))
	{
		[[object contentController] updatedColor: GNUstepOutputOtherBracketColor
		  old: old];
	}
	
	return self;
}
- textColorSet: (NSColorWell *)sender
{
	NSEnumerator *iter;
	id object;
	id old;
	
	old = [_GS_ defaultsObjectForKey: GNUstepOutputTextColor];
	[_GS_ setDefaultsObject: [[sender color] encodeToData] 
	  forKey: GNUstepOutputTextColor];
	
	iter = [[_GS_ connectionControllers] objectEnumerator];
	
	while ((object = [iter nextObject]))
	{
		[[object contentController] updatedColor: GNUstepOutputTextColor
		 old: old];
	}

	return self;
}
- resetColors: (NSButton *)sender
{
	id output = _GS_;
	id y;
	
	y = [NSColor colorFromEncodedData: 
	  [output defaultDefaultsForKey: GNUstepOutputPersonalBracketColor]];
	[personalBracketColor setColor: y];
	[self personalBracketColorSet: personalBracketColor];
	 
	y = [NSColor colorFromEncodedData: 
	  [output defaultDefaultsForKey: GNUstepOutputOtherBracketColor]];
	[otherBracketColor setColor: y];
	[self otherBracketColorSet: otherBracketColor];

	y = [NSColor colorFromEncodedData: 
	  [output defaultDefaultsForKey: GNUstepOutputBackgroundColor]];
	[backgroundColor setColor: y];
	[self backgroundColorSet: backgroundColor];
	 
	y = [NSColor colorFromEncodedData: 
	  [output defaultDefaultsForKey: GNUstepOutputTextColor]];
	[textColor setColor: y];
	[self textColorSet: textColor];

	return self;
}
- fontSet: (NSButton *)aButton
{
	id font = [NSFont fontWithName: [_GS_ defaultsObjectForKey: GNUstepOutputFontName]
	  size: (float)[[_GS_ defaultsObjectForKey: GNUstepOutputFontSize] intValue]];
	id panel;
	
	if (!font)
	{
		font = [NSFont userFontOfSize: (float)[[_GS_ defaultsObjectForKey:
		  GNUstepOutputFontSize] intValue]];
	}

	panel = [NSFontPanel sharedFontPanel];
	
	[[NSFontManager sharedFontManager] setSelectedFont: font
	  isMultiple: NO];
	  
	[panel orderFront: self];
	
	return self;
}
- (NSWindow *)window
{
	return window;
}
- (void)controlTextDidChange: (NSNotification *)aNotification
{
	id obj;
	
	obj = [aNotification object];
	
	if (obj == realName)
	{
		[self realNameSet: realName];
	}
	else if (obj == userName)
	{
		[self userNameSet: userName];
	}
	else if (obj == password)
	{
		[self passwordSet: password];
	}
	else if (obj == nick)
	{
		[self nickSet: nick];
	}
}
- (void)changeFont: (id)sender
{
	NSEnumerator *iter;
	id object;
	NSFont *font;

	font = [NSFont fontWithName: [_GS_ defaultsObjectForKey: GNUstepOutputFontName]
	  size: (float)[[_GS_ defaultsObjectForKey: GNUstepOutputFontSize] intValue]];
	
	if (!font)
	{
		font = [NSFont userFontOfSize: (float)[[_GS_ defaultsObjectForKey:
		  GNUstepOutputFontSize] intValue]];
	}
	  
	font = [sender convertFont: font];
	
	[_GS_ setDefaultsObject: [font fontName] forKey: GNUstepOutputFontName];
	[_GS_ setDefaultsObject: [NSString stringWithFormat: @"%d", (int)[font pointSize]]
	  forKey: GNUstepOutputFontSize];
	  
	iter = [[_GS_ connectionControllers] objectEnumerator];
	
	while ((object = [iter nextObject]))
	{
		[[object contentController] setChatFont: font];
	}

	[fontField setStringValue: [NSString stringWithFormat: @"%@ %@",
	  [_GS_ defaultsObjectForKey: GNUstepOutputFontName],
	  [_GS_ defaultsObjectForKey: GNUstepOutputFontSize]]];
}
@end

@interface PreferencesController (WindowDelegate)
@end

@implementation PreferencesController (WindowDelegate)
- (void)windowWillClose: (NSNotification *)aNotification
{
	AUTORELEASE(RETAIN(self));
	[_GS_ setPreferencesController: nil];
}
*/
@end

@implementation PreferencesController (PrivateMethods)
- (void)buttonClicked: (NSMatrix *)aMatrix
{
	id array = [prefsList cells];
	int index;
	id module;
	id object;
	NSView *view;
	NSArray *subviews;
	NSEnumerator *iter;
	NSButtonCell *aCell;

	aCell = [aMatrix selectedCell];
	NSLog(@"Button clicked in preferences: %@", aCell);

	if (![array containsObject: aCell])
		return;

	index = [array indexOfObject: aCell];

	if (index >= [prefsModules count])
		return;

	module = [prefsModules objectAtIndex: index];

	if (currentPrefs == module) 
		return;

	view = [module preferencesView];
	if (!view) 
		return;

	[currentPrefs deactivate];
	iter = [[preferencesView subviews] objectEnumerator];
	while ((object = [iter nextObject])) 
	{
		[preferencesView removeSubview: object];
	}

	[view setFrame: [preferencesView frame]];
	[view setFrameOrigin: NSMakePoint(0,0)];
	[preferencesView addSubview: view];
	currentPrefs = module;
	[module activate];
}
- (void)registerPreferencesModule: aPreferencesModule
{
	id bCell;
	id icon;
	id name;
	
	if (!(aPreferencesModule)) 
		return;
	
	if (!(icon = [aPreferencesModule preferencesIcon]))
		return;

	if (!(name = [aPreferencesModule preferencesName]))
		return;

	bCell = AUTORELEASE([NSButtonCell new]);
	if (!(bCell))
		return;

	[bCell setImage: icon];
	[bCell setButtonType: NSOnOffButton];
	[bCell setTitle: name];
	[bCell setImagePosition: NSImageOnly];
	[bCell setShowsStateBy: NSPushInCellMask];
	[bCell setBordered: YES];
	[bCell setBezelStyle: NSThickerSquareBezelStyle];

	NSLog(@"button cell created: %@", bCell);

	[prefsModules addObject: aPreferencesModule];
	[prefsList addColumnWithCells: [NSArray arrayWithObject: bCell]];
	[prefsList sizeToCells];
	[prefsList setNeedsDisplay: YES];

	// If its the first one, we should auto-click it
	if ([prefsModules count] == 1)
	{
		[prefsList selectCellAtRow: 0 column: 0];
		[self buttonClicked: prefsList];
	}
}
- (void)unregisterPreferencesModule: aPreferencesModule
{
	int index;
	if (!(aPreferencesModule))
		return;

	if (!([prefsModules containsObject: aPreferencesModule]))
		return;

	index = [prefsModules indexOfObject: aPreferencesModule];

	[prefsModules removeObjectAtIndex: index];
	[prefsList removeColumn: index];
	[prefsList sizeToCells];
	[prefsList setNeedsDisplay: YES];
}
- (void)preferencesModuleAdded: (NSNotification *)aNotification
{
	id object;

	if (![[aNotification name] isEqualToString: PreferencesModuleAdditionNotification])
		return;

	if (!(object = [aNotification object]))
		return;

	[self registerPreferencesModule: object];
}	
- (void)preferencesModuleRemoved: (NSNotification *)aNotification;
{
	id object;

	if (![[aNotification name] isEqualToString: PreferencesModuleRemovalNotification])
		return;

	if (!(object = [aNotification object]))
		return;

	[self unregisterPreferencesModule: object];
}
@end
