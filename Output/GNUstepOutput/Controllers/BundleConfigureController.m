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

#include "Controllers/BundleConfigureController.h"
#include "TalkSoupBundles/TalkSoup.h"
#include "GNUstepOutput.h"
#include "Misc/NSAttributedStringAdditions.h"

#include <AppKit/NSPopUpButton.h>
#include <AppKit/NSTableView.h>
#include <AppKit/NSTextView.h>
#include <AppKit/NSTableColumn.h>
#include <AppKit/NSTextContainer.h>
#include <AppKit/NSWindow.h>
#include <AppKit/NSButton.h>
#include <AppKit/NSImage.h>
#include <AppKit/NSTextStorage.h>

@interface BundleDataSource : NSObject
	{
		NSMutableArray *bundleList;
	}
- setBundleList: (NSArray *)aList;
- (NSMutableArray *)bundleList;
@end

@interface BundleConfigureController (PrivateStuff)
- (void)refreshList: (int)aList;
- (void)updateButtons;
- (NSAttributedString *)descriptionForSelected: (int)row;
@end

@implementation BundleConfigureController (PrivateStuff)
- (void)refreshList: (int)aList
{
	id x;
	id y;
	
	if (aList == 0)
	{
		x = [_TS_ activatedInFilters];

		[loadData[0] setBundleList: x];
		y = [NSMutableArray arrayWithArray: 
		  [[_TS_ allInFilters] allKeys]];

		[y removeObjectsInArray: x];

		[availData[0] setBundleList: y];
	}
	else
	{
		x = [_TS_ activatedOutFilters];

		[loadData[1] setBundleList: x];
		y = [NSMutableArray arrayWithArray: 
		  [[_TS_ allOutFilters] allKeys]];

		[y removeObjectsInArray: x];

		[availData[1] setBundleList: y];
	}

	[availableTable reloadData];
	[loadedTable reloadData];
}	
- (void)updateButtons
{
	if (currentTable == loadedTable)
	{
		[middleButton setImage: [NSImage imageNamed: @"RightArrow.tiff"]];
		[middleButton setEnabled: YES];
		[middleButton setBordered: YES];
		[upButton setEnabled: YES];
		[upButton setBordered: YES];
		[downButton setEnabled: YES];
		[downButton setBordered: YES];
	}
	else if (currentTable == availableTable)
	{
		[middleButton setImage: [NSImage imageNamed: @"LeftArrow.tiff"]];
		[middleButton setEnabled: YES];
		[middleButton setBordered: YES];
		[upButton setEnabled: NO];
		[upButton setBordered: NO];
		[downButton setEnabled: NO];
		[downButton setBordered: NO];
	}
	else
	{
		[middleButton setEnabled: NO];
		[middleButton setBordered: NO];
		[upButton setEnabled: NO];
		[upButton setBordered: NO];
		[downButton setEnabled: NO];
		[downButton setBordered: NO];
	}
}
- (NSAttributedString *)descriptionForSelected: (int)row
{
	id object = nil;

	if (currentTable == loadedTable)
	{
		object = [[loadData[currentShowing] bundleList] 
		  objectAtIndex: row];
	}
	else if (currentTable == availableTable)
	{
		object = [[availData[currentShowing] bundleList]
		 objectAtIndex: row];
	}
	
	if (object && currentShowing == 0)
	{
		object = [_TS_ pluginForInFilter: object];
	}
	else
	{
		object = [_TS_ pluginForOutFilter: object];
	}
		
	if ([object respondsToSelector: @selector(pluginDescription)] && 
	    (object = [object pluginDescription]))
	{
		return  [object substituteColorCodesIntoAttributedStringWithFont:
		  [NSFont systemFontOfSize: 0.0]];
	}
	
	return S2AS(@"No description available.");
}
@end

static NSString *big_description = nil;

@implementation BundleConfigureController
+ (void)initialize
{
	 big_description = 
	 @"Welcome to the TalkSoup Bundle Configuration Interface.\n\n"
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
	 @"in.  The arrows on the left can be used to move the selected "
	 @"bundle up and down throughout the list of loaded bundles.  On "
	 @"the right is the bundles which can be loaded but currently are "
	 @"not.  Use the arrow in the center to move bundles between "
	 @"the two tables.\n\n"

	 @"Clicking on any bundle will show information about "
	 @"that bundle in this text area.";
}
- (void)awakeFromNib
{
	NSFont *aFont;
	NSCell *x;
	
	[availableTable setDelegate: self];
	[loadedTable setDelegate: self];
	
	availCol = [availableTable tableColumnWithIdentifier: @"available"];
	loadCol = [loadedTable tableColumnWithIdentifier: @"loaded"];

	loadData[0] = [BundleDataSource new];
	availData[0] = [BundleDataSource new];
	loadData[1] = [BundleDataSource new];
	availData[1] = [BundleDataSource new];

	[self refreshList: 0];
	[self refreshList: 1];

	x = AUTORELEASE([[NSCell alloc] initTextCell: @""]);
	
	aFont = [NSFont systemFontOfSize: 0.0];

	[x setFont: aFont];
	[availableTable setRowHeight: [aFont pointSize] * 1.5];
	[loadedTable setRowHeight: [aFont pointSize] * 1.5];
	
	[availCol setDataCell: x];
	[loadCol setDataCell: x];
	[[availCol headerCell] setFont: aFont];
	[[loadCol headerCell] setFont: aFont];

	[descriptionText setHorizontallyResizable: NO];
	[descriptionText setVerticallyResizable: YES];
	[descriptionText setMinSize: NSMakeSize(0, 0)];
	[descriptionText setMaxSize: NSMakeSize(1e7, 1e7)];
	[[descriptionText textContainer] setWidthTracksTextView: YES];
	[descriptionText setTextContainerInset: NSMakeSize(2, 0)];
	[descriptionText setAutoresizingMask: NSViewHeightSizable | NSViewWidthSizable];

	[showingPopUp selectItemAtIndex: 0];
	[self showingSelected: showingPopUp];

	[window makeKeyAndOrderFront: nil];
}	
- (void)dealloc
{
	[availableTable setDataSource: nil];
	[loadedTable setDataSource: nil];
	[availableTable setDelegate: nil];
	[loadedTable setDelegate: nil];
	
	RELEASE(availData[0]);
	RELEASE(loadData[0]);
	RELEASE(availData[1]);
	RELEASE(loadData[1]);
	RELEASE(availCol);
	RELEASE(loadCol);
	RELEASE(window);
	RELEASE(availableTable);
	RELEASE(loadedTable);
	RELEASE(descriptionText);
	RELEASE(showingPopUp);
	RELEASE(middleButton);
	RELEASE(upButton);
	RELEASE(downButton);

	[super dealloc];
}
- (NSWindow *)window
{
	return window;
}
- (void)upHit: (id)sender
{
	int row;
	NSMutableArray *x;
	id object;
	
	if (currentTable != loadedTable) return;

	row = [currentTable selectedRow];

	if (row == 0) return;

	x = [loadData[currentShowing] bundleList];

	object = [x objectAtIndex: row];
	[x removeObjectAtIndex: row];
	[x insertObject: object atIndex: row - 1];
	
	[loadedTable reloadData];

	[loadedTable selectRow: row - 1 byExtendingSelection: NO];
}
- (void)refreshHit: (id)sender
{
	[_TS_ refreshPluginList];
	[self refreshList: currentShowing];
	[self showingSelected: showingPopUp];
}
- (void)cancelHit: (id)sender
{
	[window close];
}
- (void)okHit: (id)sender
{
	[_TS_ setActivatedInFilters: [loadData[0] bundleList]];
	[_TS_ setActivatedOutFilters: [loadData[1] bundleList]];
	[_TS_ savePluginList];

	[window close];
}
- (void)downHit: (id)sender
{	
	int row;
	NSMutableArray *x;
	id object;
	
	if (currentTable != loadedTable) return;

	row = [currentTable selectedRow];

	x = [loadData[currentShowing] bundleList];
	
	if (row == ([x count] - 1)) return;

	object = [x objectAtIndex: row];
	[x removeObjectAtIndex: row];
	[x insertObject: object atIndex: row + 1];
	
	[loadedTable reloadData];

	[loadedTable selectRow: row + 1 byExtendingSelection: NO];
}
- (void)middleHit: (id)sender
{
	id from = [currentTable dataSource];
	id to = [otherTable dataSource];
	int row = [currentTable selectedRow];
	int rows;
	id object;

	object = [[from bundleList] objectAtIndex: row];
	[[from bundleList] removeObjectAtIndex: row];

	[[to bundleList] addObject: object];

	[loadedTable reloadData];
	[availableTable reloadData];

	rows = [[from bundleList] count];

	if (rows == 0)
	{
		[loadedTable deselectAll: nil];
		[availableTable deselectAll: nil];
		[availableTable setNeedsDisplay: YES];
		[loadedTable setNeedsDisplay: YES];
		currentTable = nil;
		[self updateButtons];
	}
	else
	{
		if (row == rows) row--;
		[currentTable selectRow: row 
		  byExtendingSelection: NO];
	}	
}	
- (void)showingSelected: (id)sender
{
	int index = [sender indexOfSelectedItem];

	if (index < 0) index = 0;
	if (index > 1) index = 1;

	[availableTable setDataSource: 
	  availData[index]];
	[loadedTable setDataSource: 
	  loadData[index]];
	
	currentShowing = index;
	currentTable = nil;
	
	[availableTable deselectAll: nil];
	[loadedTable deselectAll: nil];
	[availableTable setNeedsDisplay: YES];
	[loadedTable setNeedsDisplay: YES];

	[[descriptionText textStorage] setAttributedString: 
	  S2AS(big_description)];
	[descriptionText scrollPoint: NSMakePoint(0, 0)];
	
	[self updateButtons];
}
- (BOOL)tableView: (NSTableView *)aTableView shouldSelectRow: (int)aRow
{
	currentTable = aTableView;

	if (currentTable == availableTable)
	{
		otherTable = loadedTable;
	}
	else
	{
		otherTable = availableTable;
	}

	[self updateButtons];
	[otherTable deselectAll: nil];
	[otherTable setNeedsDisplay: YES];
	[currentTable setNeedsDisplay: YES];

	[[descriptionText textStorage] setAttributedString: 
	  [self descriptionForSelected: aRow]];
	[descriptionText scrollPoint: NSMakePoint(0, 0)];

	return YES;
}
@end

@implementation BundleDataSource
- init
{
	if (!(self = [super init])) return nil;

	bundleList = [NSMutableArray new];

	return self;
}
- (void)dealloc
{
	RELEASE(bundleList);

	[super dealloc];
}
- setBundleList: (NSArray *)aList
{
	[bundleList removeAllObjects];
	[bundleList addObjectsFromArray: aList];

	return self;
}
- (NSMutableArray *)bundleList
{
	return bundleList;
}
- (int)numberOfRowsInTableView: (NSTableView *)aTableView
{
	return [bundleList count];
}
- (id)tableView: (NSTableView *)aTableView
  objectValueForTableColumn: (NSTableColumn *)aTableColumn
  row: (int)rowIndex
{
	return [bundleList objectAtIndex: rowIndex];
}
@end


