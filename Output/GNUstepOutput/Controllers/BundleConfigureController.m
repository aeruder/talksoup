/***************************************************************************
                      BundleConfigureController.m
                          -------------------
    begin                : Mon Sep  8 00:16:46 CDT 2003
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

#import "Controllers/BundleConfigureController.h"
#import <TalkSoupBundles/TalkSoup.h>
#import "GNUstepOutput.h"
#import "Misc/NSAttributedStringAdditions.h"

#import <AppKit/NSPopUpButton.h>
#import <AppKit/NSTableView.h>
#import <AppKit/NSTextView.h>
#import <AppKit/NSTableColumn.h>
#import <AppKit/NSTextContainer.h>
#import <AppKit/NSPasteboard.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSButton.h>
#import <AppKit/NSImage.h>
#import <AppKit/NSTextStorage.h>
#import <AppKit/NSFont.h>

static NSString *bundlePboardType = @"bundlePboardType";
static NSString *big_description = nil;

@interface BundleConfigureController (PrivateStuff)
- (void)saveDefaults;
- (void)reloadDefaultsInList;
- (void)activateList;
- (void)refreshList;
- (void)setupList;
- (void)updateButton;
- (NSAttributedString *)descriptionForSelected: (int)row;
@end

@implementation BundleConfigureController (PrivateStuff)
- (void)saveDefaults
{
	defaults[0] = RETAIN([NSArray arrayWithArray: [_TS_ activatedInFilters]]);
	defaults[1] = RETAIN([NSArray arrayWithArray: [_TS_ activatedOutFilters]]);
}
- (void)reloadDefaultsInList
{
	SEL aSel;
	id data;

	aSel = (!currentShowing) ? @selector(setActivatedInFilters:) : 
	  @selector(setActivatedOutFilters:);
	data = (!currentShowing) ? defaults[0] : defaults[1];

	[_TS_ performSelector: aSel withObject: data];
}
- (void)activateList
{
	SEL aSel;

	aSel = (!currentShowing) ? @selector(setActivatedInFilters:) : 
	  @selector(setActivatedOutFilters:);

	[_TS_ performSelector: aSel withObject: loadData];
	[_TS_ savePluginList];
}
- (void)refreshList
{
	SEL aSel1, aSel2;

	aSel1 = (!currentShowing) ? @selector(activatedInFilters) : 
	  @selector(activatedOutFilters);
	aSel2 = (!currentShowing) ? @selector(allInFilters) : 
	  @selector(allOutFilters);

	loadData = RETAIN([NSMutableArray arrayWithArray: 
	  [_TS_ performSelector: aSel1]]);
	
	availData = RETAIN([NSMutableArray arrayWithArray: 
	  [[_TS_ performSelector: aSel2] allKeys]]);
	[availData removeObjectsInArray: loadData];

	[availableTable reloadData];
	[loadedTable reloadData];
}
- (void)setupList
{
	[self refreshList];
	[preferencesButton setEnabled: NO];
	[preferencesButton setBordered: NO];
	
	[availableTable deselectAll: nil];
	[loadedTable deselectAll: nil];
	[availableTable setNeedsDisplay: YES];
	[loadedTable setNeedsDisplay: YES];

	[[descriptionText textStorage] setAttributedString: 
	  S2AS(big_description)];
	[descriptionText scrollPoint: NSMakePoint(0, 0)];
}
- (void)updateButton
{
	if (currentTable == loadedTable)
	{
		[preferencesButton setEnabled: NO];
		[preferencesButton setBordered: YES];
	}
	else
	{
		[preferencesButton setEnabled: NO];
		[preferencesButton setBordered: NO];
	}
}
- (NSAttributedString *)descriptionForSelected: (int)row
{
	id object = nil;
	SEL aSel;

	object = (currentTable == loadedTable) ? [loadData objectAtIndex: row]
	  : [availData objectAtIndex: row];
	aSel = (!currentShowing) ? @selector(pluginForInFilter:)
	  : @selector(pluginForOutFilter:);

	object = [_TS_ performSelector: aSel withObject: object];

	if ([object respondsToSelector: @selector(pluginDescription)] &&
	  (object = [object pluginDescription]))
	{
		return [object substituteColorCodesIntoAttributedStringWithFont:
		  [NSFont systemFontOfSize: 0.0]];
	}

	return S2AS(_l(@"No description available."));
}
@end

@implementation BundleConfigureController
+ (void)initialize
{
	 big_description = 
	 _l((@"Welcome to the TalkSoup Bundle Configuration Interface.\n\n"
	 @"TalkSoup is a highly-modular IRC client, and parts of it "
	 @"can be loaded and unloaded while it is running.  These "
	 @"optional parts are called bundles.  There are two sets "
	 @"of bundles.  The first set, the input bundles, affect "
	 @"data coming into the IRC client. The second set, the output "
	 @"bundles, affect the data leaving the IRC client.  The pop up "
	 @"button located at the top is used to change which of these "
	 @"sets are being configured.\n\n"
	 
	 @"Above are two tables of bundles.  On the left, there is a "
	 @"table showing the loaded bundles and the order they are loaded "
	 @"in.  On the right, there is a table showing the bundles which can "
	 @"be loaded but currently are not.  You may click and drag these "
	 @"various bundles to/from the table on the left to load/unload them.\n\n"

	 @"All the changes will be automatically applied to TalkSoup.  If "
	 @"you should want to revert to the bundles that were loaded when you "
	 @"opened the bundle setup dialog, just hit the button in the bottom "
	 @"left.\n\n"
	 
	 @"Clicking on any bundle will show information about "
	 @"that bundle in this text area."));
}
- (void)awakeFromNib
{
	NSCell *x;
	id availCol, loadCol;
	id aFont;
	
	aFont = [NSFont systemFontOfSize: 0.0];

	x = AUTORELEASE([[NSCell alloc] initTextCell: @""]);
	[x setFont: aFont];

	[availableTable setDelegate: self];
	[availableTable setDataSource: self];
	[availableTable setRowHeight: [aFont pointSize] * 1.5];
	[availableTable registerForDraggedTypes: [NSArray arrayWithObject:
	  bundlePboardType]];
	availCol = [availableTable tableColumnWithIdentifier: @"available"];
	[availCol setDataCell: x];
	[[availCol headerCell] setFont: aFont];
	
	[loadedTable setDelegate: self];
	[loadedTable setDataSource: self];
	[loadedTable setRowHeight: [aFont pointSize] * 1.5];
	[loadedTable registerForDraggedTypes: [NSArray arrayWithObject:
	  bundlePboardType]];
	loadCol = [loadedTable tableColumnWithIdentifier: @"loaded"];
	[loadCol setDataCell: x];
	[[loadCol headerCell] setFont: aFont];

	[showingPopUp selectItemAtIndex: 0];
	[showingPopUp setEnabled: YES];
	
	[self saveDefaults];
	[self setupList];

	[descriptionText setHorizontallyResizable: NO];
	[descriptionText setVerticallyResizable: YES];
	[descriptionText setMinSize: NSMakeSize(0, 0)];
	[descriptionText setMaxSize: NSMakeSize(1e7, 1e7)];
	[[descriptionText textContainer] setWidthTracksTextView: YES];
	[descriptionText setTextContainerInset: NSMakeSize(2, 2)];
	[descriptionText setAutoresizingMask: NSViewHeightSizable | NSViewWidthSizable];

	[window makeKeyAndOrderFront: nil];
}	
- (void)dealloc
{
	[availableTable setDataSource: nil];
	[loadedTable setDataSource: nil];
	
	RELEASE(availData);
	RELEASE(loadData);
	RELEASE(defaults[0]);
	RELEASE(defaults[1]);
	RELEASE(window);

	[super dealloc];
}
- (NSWindow *)window
{
	return window;
}
- (void)refreshHit: (id)sender
{
	[_TS_ refreshPluginList];
	[self reloadDefaultsInList];
	[self setupList];
}
- (void)preferencesHit: (id)sender
{
}
- (void)showingSelected: (id)sender
{
	int index = [sender indexOfSelectedItem];

	if (index < 0) index = 0;
	if (index > 1) index = 1;

	currentShowing = index;
	[self setupList];
}
- (BOOL)tableView: (NSTableView *)aTableView shouldSelectRow: (int)aRow
{
	if (aTableView == availableTable)
	{
		if ([availData count] == 0) return NO;
		otherTable = loadedTable;
	}
	else
	{
		if ([loadData count] == 0) return NO;
		otherTable = availableTable;
	}

	currentTable = aTableView;

	[self updateButton];
	[otherTable deselectAll: nil];
	[otherTable setNeedsDisplay: YES];
	[currentTable setNeedsDisplay: YES];

	[[descriptionText textStorage] setAttributedString: 
	  [self descriptionForSelected: aRow]];
	[descriptionText scrollPoint: NSMakePoint(0, 0)];

	return YES;
}
- (int)numberOfRowsInTableView: (NSTableView *)aTableView
{
	id data;

	data = (aTableView == availableTable) ? availData : loadData;

	if ([data count] == 0) return 1;
	return [data count];
}
- (id)tableView: (NSTableView *)aTableView
  objectValueForTableColumn: (NSTableColumn *)aTableColumn
  row: (int)rowIndex
{
	id data;

	data = (aTableView == availableTable) ? availData : loadData;
	
	if ([data count] == 0) return _l(@"Drag to here");

	return [data objectAtIndex: rowIndex];
}
- (BOOL)tableView: (NSTableView *)tableView writeRows: (NSArray *)rows
 toPasteboard: (NSPasteboard *)pboard
{
	NSMutableArray *theData;
	id data;

	data = (tableView == availableTable) ? availData : loadData;
	
	if ([data count] == 0) return NO;

	theData = [[NSMutableArray alloc] initWithCapacity: 1];

	[theData addObject: AUTORELEASE([[data objectAtIndex: 
	  [[rows objectAtIndex: 0] intValue]] copy])];

	[pboard declareTypes: [NSArray arrayWithObject: bundlePboardType]
	  owner: nil];
	[pboard setPropertyList: theData forType: bundlePboardType];

	NSLog(@"Copying...");
	RELEASE(theData);

	return YES;
}
- (NSDragOperation) tableView: (NSTableView *)aTableView
  validateDrop: (id <NSDraggingInfo>) info
  proposedRow: (int)row 
  proposedDropOperation: (NSTableViewDropOperation)operation
{
	if ([info draggingSourceOperationMask] & 
	  (NSDragOperationGeneric | NSDragOperationCopy)) 
	{
		NSLog(@"Validating good...");
		return NSDragOperationGeneric;
	}
	NSLog(@"Validating bad...");

	return NSDragOperationNone;
}
- (BOOL)tableView: (NSTableView *)aTableView 
  acceptDrop: (id <NSDraggingInfo>)info
  row: (int)row dropOperation: (NSTableViewDropOperation)operation
{
	id origData;
	id data;
	id object;
	int where;

	data = (aTableView == availableTable) ? availData : loadData;

	object = AUTORELEASE(RETAIN([[[info draggingPasteboard] 
	  propertyListForType: bundlePboardType] objectAtIndex: 0]));

	origData = ([availData containsObject: object]) ? availData : loadData;
	
	if ((data == origData) && (data == availData)) return NO;

	NSLog(@"Accepting...");
	
	where = [origData indexOfObject: object];
	[data insertObject: object atIndex: row % ([data count] + 1)];
	
	if (row <= where && origData == data) where++;

	[origData removeObjectAtIndex: where];
	
	[self activateList];
	[self refreshList];
	
	where = [data indexOfObject: object];
	if ([[aTableView delegate] tableView: aTableView
	  shouldSelectRow: where])
	{
		[aTableView selectRow: where byExtendingSelection: NO];
	}
	return YES;
}
@end
