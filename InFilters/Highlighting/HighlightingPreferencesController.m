/***************************************************************************
                                HighlightingPreferencesController.m
                          -------------------
    begin                : Mon Dec 29 12:11:34 CST 2003
    copyright            : (C) 2003 by Andy Ruder
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

#import "HighlightingPreferencesController.h"
#import "Highlighting.h"

#ifdef USE_APPKIT
#import <AppKit/NSTableView.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSButton.h>
#import <AppKit/NSNibLoading.h>
#import <AppKit/NSColorWell.h>
#import <AppKit/NSColor.h>
#endif

#import <Foundation/NSDictionary.h>
#import <Foundation/NSUserDefaults.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSString.h>

#define get_pref(__x) [Highlighting defaultsObjectForKey: (__x)]
#define set_pref(__x,__y) [Highlighting setDefaultsObject: (__y) forKey: (__x)]

#ifdef USE_APPKIT
@protocol HighlightingPreferencesControllerNeedsSomeGNUstepOutputStuff
+ (NSColor *)colorFromEncodedData: (id)aData;
- (id)encodeToData;
@end
#endif

@implementation HighlightingPreferencesController
#ifndef USE_APPKIT
- (void)reloadData
{
	return;
}
- (void)shouldDisplay
{
	return;
}
- (void)shouldHide
{
	return;
}
#else
- (void)awakeFromNib
{
	[extraTable setDataSource: self];
	[extraTable setDelegate: self];
	[extraTable setRowHeight: 
	  [[NSFont systemFontOfSize: 0.0] pointSize] * 1.5];
	[self reloadData];
}
- (void)reloadData
{
	id temp;
	Class aClass;

	if (!window) return;

	aClass = [NSColor class];

	RELEASE(extraNames);
	extraNames = (!(temp = get_pref(HighlightingExtraWords))) ? 
	  [NSMutableArray new] : 
	  RETAIN([NSMutableArray arrayWithArray: temp]);
	[extraTable reloadData];

	temp = get_pref(HighlightingShouldDoNick);

	if (!temp || [temp isEqualToString: @"YES"])
	{
		[highlightButton setState: NSOnState];
	}

	[highlightInChannelColor setColor: 
	  [aClass colorFromEncodedData: get_pref(HighlightingUserColor)]];
	[messageInTabColor setColor: 
	  [aClass colorFromEncodedData: get_pref(HighlightingTabAnythingColor)]];
	[highlightInTabColor setColor: 
	  [aClass colorFromEncodedData: get_pref(HighlightingTabReferenceColor)]];
}
- (void)dealloc
{
	[self shouldHide];
	[super dealloc];
}
- (void)shouldHide
{
	[window close];
	DESTROY(window);
	
	highlightButton = nil;
	removeButton = nil;
	extraTable = nil;
	highlightInChannelColor = nil;
	highlightInTabColor = nil;
	messageInTabColor = nil;

	DESTROY(extraNames);
}
- (void)shouldDisplay
{
	id bundle;
	
	if (window)
	{
		[window makeKeyAndOrderFront: nil];
		return;
	}
	
	bundle = [NSBundle bundleForClass: [Highlighting class]];

	if (![bundle loadNibFile: @"HighlightingPreferences"
	  externalNameTable: [NSDictionary dictionaryWithObjectsAndKeys:
	    self, @"NSOwner",
	    nil] withZone: 0])
	{
		return;
	}

	[window makeKeyAndOrderFront: nil];
}
- (void)highlightingHit: (id)sender
{
	NSLog(@"Testing: %@", sender);
	if ([sender state] == NSOffState)
	{
		NSLog(@"Setting to no");
		set_pref(HighlightingShouldDoNick, @"NO");
	}
	else
	{
		NSLog(@"Setting to yes");
		set_pref(HighlightingShouldDoNick, @"YES");
	}
}
- (void)removeHit: (id)sender
{
	if (currentlySelected >= [extraNames count]) return;
	
	[extraNames removeObjectAtIndex: currentlySelected];
	[extraTable reloadData];
}
- (void)highlightInChannelHit: (id)sender
{
	id temp = [sender color];
	
	set_pref(HighlightingUserColor, [temp encodeToData]);
}
- (void)highlightInTabHit: (id)sender
{
	id temp = [sender color];
	
	set_pref(HighlightingTabReferenceColor, [temp encodeToData]);
}
- (void)messageInTabHit: (id)sender
{
	id temp = [sender color];
	
	set_pref(HighlightingTabAnythingColor, [temp encodeToData]);
}
- (BOOL)tableView: (NSTableView *)aTableView shouldSelectRow: (int)aRow
{
	currentlySelected = aRow;
	return YES;
}
- (int)numberOfRowsInTableView: (NSTableView *)aTableView
{
	return [extraNames count] + 1;
}
- (id)tableView: (NSTableView *)aTableView
 objectValueForTableColumn: (NSTableColumn *)aTableColumn
 row: (int)rowIndex
{
	if (rowIndex >= [extraNames count])
	{
		return _l(@"Double-click to add");
	}
	return [extraNames objectAtIndex: rowIndex];
}
- (BOOL)tableView: (NSTableView *)aTableView
 shouldEditTableColumn: (NSTableColumn *)aTableColumn row: (int)rowIndex
{
	if (rowIndex == [extraNames count]) return YES;
	return NO;
}
- (void)tableView: (NSTableView *)aTableView setObjectValue: (id)anObject
 forTableColumn: (NSTableColumn *)aTableColumn row: (int)rowIndex
{
	[extraNames addObject: anObject];
	set_pref(HighlightingExtraWords, AUTORELEASE([extraNames copy]));
	[aTableView reloadData];
}
#endif
@end
