/***************************************************************************
                                HighlightingPreferencesController.m
                          -------------------
    begin                : Mon Dec 29 12:11:34 CST 2003
    copyright            : (C) 2005 by Andrew Ruder
    email                : aeruder@ksu.edu
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

#import <AppKit/NSTableView.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSButton.h>
#import <AppKit/NSNibLoading.h>
#import <AppKit/NSColorWell.h>
#import <AppKit/NSImage.h>
#import <AppKit/NSColor.h>

#import <Foundation/NSDictionary.h>
#import <Foundation/NSUserDefaults.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSString.h>
#import <Foundation/NSDebug.h>
#import <AppKit/NSView.h>
#import <AppKit/NSFont.h>
#import <AppKit/NSCell.h>
#import <AppKit/NSTableColumn.h>

#define get_pref(__x) [Highlighting defaultsObjectForKey: (__x)]
#define set_pref(__x,__y) [Highlighting setDefaultsObject: (__y) forKey: (__x)]

@protocol HighlightingPreferencesControllerNeedsSomeGNUstepOutputStuff
+ (NSColor *)colorFromEncodedData: (id)aData;
- (id)encodeToData;
@end

@implementation HighlightingPreferencesController
- init
{
	id bundle, path;

	if (!(self = [super init])) return nil;

	bundle = [NSBundle bundleForClass: [Highlighting class]];

	if (![NSBundle loadNibNamed: @"HighlightingPreferences" owner: self])
	{
		[super dealloc];
		return nil;
	}

	path = [bundle pathForResource: @"highlighting_prefs" ofType: @"tiff"];
	if (!path) 
	{
		NSLog(@"Could not find highlighting_prefs.tiff");
		[self dealloc];
		return nil;
	}

	preferencesIcon = [[NSImage alloc] initWithContentsOfFile:
	  path];
	if (!preferencesIcon)
	{
		NSLog(@"Could not load image %@", path);
		[self dealloc];
		return nil;
	}

	return self;
}
- (NSView *)preferencesView
{
	return window;
}
- (NSImage *)preferencesIcon
{
	return preferencesIcon;
}
- (NSString *)preferencesName
{
	return _l(@"Highlighting");
}
- (void)activate: aPrefs
{
	isActive = YES;	

	[self reloadData];
}
- (void)deactivate
{
	isActive = NO;
}
- (void)awakeFromNib
{
	NSWindow *tempWindow;

	tempWindow = (NSWindow *)window;
	window = RETAIN([tempWindow contentView]);
	RELEASE(tempWindow);

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

	if (!window || !isActive) return;

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
	RELEASE(preferencesIcon);
	DESTROY(extraNames);
	DESTROY(window);
	[super dealloc];
}
- (void)highlightingHit: (id)sender
{
	if ([sender state] == NSOffState)
	{
		set_pref(HighlightingShouldDoNick, @"NO");
	}
	else
	{
		set_pref(HighlightingShouldDoNick, @"YES");
	}
}
- (void)removeHit: (id)sender
{
	if (currentlySelected >= [extraNames count]) return;
	
	[extraNames removeObjectAtIndex: currentlySelected];
	[self tableView: extraTable shouldSelectRow: currentlySelected];
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
	if (currentlySelected >= [extraNames count])
	{
		[removeButton setEnabled: NO];
	}
	else
	{
		[removeButton setEnabled: YES];
	}
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
	if (rowIndex <= [extraNames count]) return YES;
	return NO;
}
- (void)tableView: (NSTableView *)aTableView setObjectValue: (id)anObject
 forTableColumn: (NSTableColumn *)aTableColumn row: (int)rowIndex
{
	if (rowIndex >= [extraNames count])
	{
		[extraNames addObject: anObject];
	}
	else
	{
		[extraNames insertObject: anObject atIndex: rowIndex];
		[extraNames removeObjectAtIndex: rowIndex + 1];
	}
	
	set_pref(HighlightingExtraWords, AUTORELEASE([extraNames copy]));
	[aTableView reloadData];
}
@end
