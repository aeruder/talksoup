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
#import <AppKit/NSWindow.h>
#import <AppKit/NSButton.h>
#import <AppKit/NSImage.h>
#import <AppKit/NSTextStorage.h>
#import <AppKit/NSFont.h>

@interface BundleDataSource : NSObject
	{
		NSMutableArray *bundleList;
	}
- setBundleList: (NSArray *)aList;
- (NSMutableArray *)bundleList;
@end

@interface BundleConfigureController (PrivateStuff)
- (void)reloadDefaultsInList: (int)aList;
- (void)updateButtons;
- (NSAttributedString *)descriptionForSelected: (int)row;
- (void)loadBundlesInList: (int)aList;
- (void)setupLists;
@end

@implementation BundleConfigureController (PrivateStuff)
- (void)loadBundlesInList: (int)aList
{
	if (!aList)
	{
		[_TS_ setActivatedInFilters: [loadData[0] bundleList]];
	}
	else
	{
		[_TS_ setActivatedOutFilters: [loadData[1] bundleList]];
	}
	[_TS_ savePluginList];
}
- (void)setupLists
{
	id y;
	
	defaults[0] = RETAIN([NSArray arrayWithArray: [_TS_ activatedInFilters]]);

	[loadData[0] setBundleList: defaults[0]];
	y = [NSMutableArray arrayWithArray: 
	  [[_TS_ allInFilters] allKeys]];

	[y removeObjectsInArray: defaults[0]];

	[availData[0] setBundleList: y];
	
	defaults[1] = RETAIN([NSArray arrayWithArray: [_TS_ activatedOutFilters]]);

	[loadData[1] setBundleList: defaults[1]];
	y = [NSMutableArray arrayWithArray: 
	  [[_TS_ allOutFilters] allKeys]];

	[y removeObjectsInArray: defaults[1]];

	[availData[1] setBundleList: y];

	[availableTable reloadData];
	[loadedTable reloadData];
}	
- (void)reloadDefaultsInList: (int)aList
{
	id x;
	
	[loadData[aList] setBundleList: defaults[aList]];
	x = (!aList) ? [NSMutableArray arrayWithArray: 
	  [[_TS_ allInFilters] allKeys]] : [NSMutableArray arrayWithArray:
	  [[_TS_ allOutFilters] allKeys]];

	[x removeObjectsInArray: defaults[aList]];

	[availData[aList] setBundleList: x];

	if (!aList)
	{
		[_TS_ setActivatedInFilters: defaults[0]];
	}
	else
	{
		[_TS_ setActivatedOutFilters: defaults[1]];
	}
	
	[availableTable reloadData];
	[loadedTable reloadData];
}
- (void)updateButtons
{
	if (currentTable == loadedTable)
	{
		[middleButton setImage: rightImage];
		[middleButton setEnabled: YES];
		[middleButton setBordered: YES];
		[upButton setEnabled: YES];
		[upButton setBordered: YES];
		[downButton setEnabled: YES];
		[downButton setBordered: YES];
	}
	else if (currentTable == availableTable)
	{
		[middleButton setImage: leftImage];
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
	 @"in.  The arrows on the left can be used to move the selected "
	 @"bundle up and down throughout the list of loaded bundles.  On "
	 @"the right is the bundles which can be loaded but currently are "
	 @"not.  Use the arrow in the center to move bundles between "
	 @"the two tables.\n\n"

	 @"All the changes will be automatically applied to TalkSoup.  If "
	 @"you should want to revert to the bundles that were loaded when you "
	 @"opened the bundle setup dialog, just hit the button in the bottom "
	 @"left.\n\n"
	 
	 @"Clicking on any bundle will show information about "
	 @"that bundle in this text area."));
}
- (void)awakeFromNib
{
	NSFont *aFont;
	NSCell *x;
	id bundle;
	
	bundle = [NSBundle bundleForClass: [GNUstepOutput class]];

	rightImage = [[NSImage alloc] initWithContentsOfFile: 
	  [bundle pathForImageResource: @"RightArrow.tiff"]];
	leftImage = [[NSImage alloc] initWithContentsOfFile: 
	  [bundle pathForImageResource: @"LeftArrow"]];
	upImage = [[NSImage alloc] initWithContentsOfFile: 
	  [bundle pathForImageResource: @"UpArrow"]];
	downImage = [[NSImage alloc] initWithContentsOfFile: 
	  [bundle pathForImageResource: @"DownArrow"]];
	[upButton setImage: upImage];
	[downButton setImage: downImage];

	[availableTable setDelegate: self];
	[loadedTable setDelegate: self];
	
	availCol = RETAIN([availableTable tableColumnWithIdentifier: @"available"]);
	loadCol = RETAIN([loadedTable tableColumnWithIdentifier: @"loaded"]);

	loadData[0] = [BundleDataSource new];
	availData[0] = [BundleDataSource new];
	loadData[1] = [BundleDataSource new];
	availData[1] = [BundleDataSource new];

	[self setupLists];

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
	[showingPopUp setEnabled: YES];

	[window makeKeyAndOrderFront: nil];
}	
- (void)dealloc
{
	[availableTable setDataSource: nil];
	[loadedTable setDataSource: nil];
	[availableTable setDelegate: nil];
	[loadedTable setDelegate: nil];
	
	RELEASE(upImage);
	RELEASE(downImage);
	RELEASE(leftImage);
	RELEASE(rightImage);
	RELEASE(availData[0]);
	RELEASE(loadData[0]);
	RELEASE(availData[1]);
	RELEASE(loadData[1]);
	RELEASE(defaults[0]);
	RELEASE(defaults[1]);
	RELEASE(availCol);
	RELEASE(loadCol);
	RELEASE(window);

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
	[self loadBundlesInList: currentShowing];

	[loadedTable selectRow: row - 1 byExtendingSelection: NO];
}
- (void)refreshHit: (id)sender
{
	[_TS_ refreshPluginList];
	[self reloadDefaultsInList: currentShowing];
	[self showingSelected: showingPopUp];
}
- (void)downHit: (id)sender
{	
	int row;
	NSMutableArray *x;
	id object;
	
	if (currentTable != loadedTable) return;

	row = [currentTable selectedRow];

	x = [loadData[currentShowing] bundleList];
	
	if (row == (int)([x count] - 1)) return;

	object = [x objectAtIndex: row];
	[x removeObjectAtIndex: row];
	[x insertObject: object atIndex: row + 1];
	
	[loadedTable reloadData];
	[self loadBundlesInList: currentShowing];

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
	[self loadBundlesInList: currentShowing];

	rows = [[from bundleList] count];

	if (rows == 0)
	{
		[self showingSelected: showingPopUp];
	}
	else
	{
		if (row == rows) row--;
		if ([[currentTable delegate] tableView: currentTable
		   shouldSelectRow: row])
		{
			[currentTable selectRow: row 
			  byExtendingSelection: NO];
		}
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


