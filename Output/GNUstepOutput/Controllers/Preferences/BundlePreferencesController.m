/***************************************************************************
                      BundlePreferencesController.m
                          -------------------
    begin                : Sat Aug 14 19:19:31 CDT 2004
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

#import "Controllers/Preferences/BundlePreferencesController.h"
#import "Controllers/Preferences/PreferencesController.h"
#import "Misc/NSAttributedStringAdditions.h"
#import "Misc/NSViewAdditions.h"
#import "GNUstepOutput.h"

#import <AppKit/NSCell.h>
#import <AppKit/NSImage.h>
#import <AppKit/NSNibLoading.h>
#import <AppKit/NSPasteboard.h>
#import <AppKit/NSPopUpButton.h>
#import <AppKit/NSTableColumn.h>
#import <AppKit/NSTableView.h>
#import <AppKit/NSTableHeaderView.h>
#import <AppKit/NSTextContainer.h>
#import <AppKit/NSTextStorage.h>
#import <AppKit/NSTextView.h>
#import <AppKit/NSView.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSFont.h>
#import <AppKit/NSDragging.h>
#import <Foundation/NSNotification.h>
#import <Foundation/NSString.h>
#import <Foundation/NSAttributedString.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSDebug.h>
#import <Foundation/NSGeometry.h>

static NSString *bundlePboardType = @"bundlePboardType";
static NSString *big_description = nil;

@interface BundlePreferencesController (PrivateStuff)
- (void)activateList;
- (void)refreshList;
- (void)setupList;
- (NSAttributedString *)descriptionForSelected: (int)row;

- (BOOL)tableView: (NSTableView *)aTableView shouldSelectRow: (int)aRow;
- (int)numberOfRowsInTableView: (NSTableView *)aTableView;
- (id)tableView: (NSTableView *)aTableView
  objectValueForTableColumn: (NSTableColumn *)aTableColumn
  row: (int)rowIndex;
- (BOOL)tableView: (NSTableView *)tableView writeRows: (NSArray *)rows
  toPasteboard: (NSPasteboard *)pboard;
- (NSDragOperation) tableView: (NSTableView *)aTableView
  validateDrop: (id <NSDraggingInfo>) info
  proposedRow: (int)row 
  proposedDropOperation: (NSTableViewDropOperation)operation;
- (BOOL)tableView: (NSTableView *)aTableView 
  acceptDrop: (id <NSDraggingInfo>)info
  row: (int)row dropOperation: (NSTableViewDropOperation)operation;

- (void)prefsWindowResized: (NSNotification *)aNotification;
@end

@implementation BundlePreferencesController
+ (void)initialize
{
	if (big_description) return;

	big_description = 
	 RETAIN([NSString stringWithContentsOfFile: [[NSBundle bundleForClass:
	  [GNUstepOutput class]]
	  pathForResource: @"BundlePreferences" ofType: @"txt"]]);
}
- init
{
	id path;
	if (!(self = [super init])) return nil;

	if (!([NSBundle loadNibNamed: @"BundlePreferences" owner: self]))
	{
		NSLog(@"Couldn't load BundlePreferences nib");
		[self dealloc];
		return nil;
	}

	path = [[NSBundle bundleForClass: [GNUstepOutput class]] 
	  pathForResource: @"bundle_prefs" ofType: @"tiff"];
	if (!path) 
	{
		NSLog(@"Could not find bundle_prefs.tiff");
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

	[[NSNotificationCenter defaultCenter]
	 postNotificationName: PreferencesModuleAdditionNotification 
	 object: self];

	return self;
}
- (void)awakeFromNib
{
	NSWindow *tempWindow;
	NSCell *x;
	id availCol, loadCol;
	id aFont;

	aFont = [NSFont userFontOfSize: 0.0];
	x = AUTORELEASE([[NSCell alloc] initTextCell: @""]);
	[x setFont: aFont];

	[availableTable setDelegate: self];
	[availableTable setDataSource: self];
	[availableTable setRowHeight: [aFont pointSize] * 1.5];
	[availableTable registerForDraggedTypes: [NSArray arrayWithObject:
	  bundlePboardType]];
	availCol = [availableTable tableColumnWithIdentifier: @"available"];
	[availCol setResizable: YES];
	[availCol setDataCell: x];
	[[availCol headerCell] setFont: aFont];
	[availCol sizeToFit];
	
	[loadedTable setDelegate: self];
	[loadedTable setDataSource: self];
	[loadedTable setRowHeight: [aFont pointSize] * 1.5];
	[loadedTable registerForDraggedTypes: [NSArray arrayWithObject:
	  bundlePboardType]];
	loadCol = [loadedTable tableColumnWithIdentifier: @"loaded"];
	[loadCol setDataCell: x];
	[[loadCol headerCell] setFont: aFont];
	[loadCol sizeToFit];

	[descriptionText setHorizontallyResizable: NO];
	[descriptionText setVerticallyResizable: YES];
	[descriptionText setMinSize: NSMakeSize(0, 0)];
	[descriptionText setMaxSize: NSMakeSize(1e7, 1e7)];
	[descriptionText setTextContainerInset: NSMakeSize(2, 2)];
	[[descriptionText textContainer] setWidthTracksTextView: YES];
	[[descriptionText textContainer] setHeightTracksTextView: NO];

	[descriptionText setNeedsDisplay: YES];

	tempWindow = (NSWindow *)preferencesView;
	preferencesView = RETAIN([tempWindow contentView]);
	RELEASE(tempWindow);
	[preferencesView setAutoresizingMask:
	  NSViewWidthSizable | NSViewHeightSizable];
}
- (void)dealloc
{
	[availableTable setDataSource: nil];
	[loadedTable setDataSource: nil];
	
	RELEASE(availData);
	RELEASE(loadData);
	RELEASE(preferencesView);
	RELEASE(preferencesIcon);
	[super dealloc];
}
- (NSString *)preferencesName
{
	return @"Plugins";
}
- (NSImage *)preferencesIcon
{
	return preferencesIcon;
}
- (NSView *)preferencesView
{
	return preferencesView;
}
- (void)activate: (PreferencesController *)aPrefs
{
	[showingPopUp selectItemAtIndex: 0];
	[showingPopUp setEnabled: YES];
	[self showingSelected: showingPopUp];
}
- (void)deactivate
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
@end

@implementation BundlePreferencesController (PrivateStuff)
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

	RELEASE(loadData);
	loadData = RETAIN([NSMutableArray arrayWithArray: 
	  [_TS_ performSelector: aSel1]]);
	
	RELEASE(availData);
	availData = RETAIN([NSMutableArray arrayWithArray: 
	  [[_TS_ performSelector: aSel2] allKeys]]);
	[availData removeObjectsInArray: loadData];

	[availableTable reloadData];
	[loadedTable reloadData];
}
- (void)setupList
{
	[self refreshList];

	currentlySelected = -1;
	currentTable = nil;
	otherTable = nil;
	
	[availableTable deselectAll: nil];
	[loadedTable deselectAll: nil];
	[availableTable setNeedsDisplay: YES];
	[loadedTable setNeedsDisplay: YES];

	[[descriptionText textStorage] setAttributedString: 
	  S2AS(big_description)];
	[descriptionText scrollPoint: NSMakePoint(0, 0)];
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
		  [NSFont systemFontOfSize: 0.0] withBoldFont: [NSFont boldSystemFontOfSize: 0.0]];
	}

	return S2AS(_l(@"No description available."));
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

	[otherTable deselectAll: nil];
	[otherTable setNeedsDisplay: YES];
	[currentTable setNeedsDisplay: YES];

	[[descriptionText textStorage] setAttributedString: 
	  [self descriptionForSelected: aRow]];
	[descriptionText scrollPoint: NSMakePoint(0, 0)];

	currentlySelected = aRow;

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
		return NSDragOperationGeneric;
	}

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

	where = [origData indexOfObject: object];
	if (row >= [data count])
	{
		[data addObject: object];
	}
	else
	{
		[data insertObject: object atIndex: row];
	}
	
	if (row <= where && origData == data) where++;

	[origData removeObjectAtIndex: where];
	
	[self activateList];
	[self refreshList];
	
	data = (aTableView == availableTable) ? availData : loadData;
	where = [data indexOfObject: object];
	if ([[aTableView delegate] tableView: aTableView
	  shouldSelectRow: where])
	{
		[aTableView selectRow: where byExtendingSelection: NO];
	}
	return YES;
}
- (void)prefsWindowResized: (NSNotification *)aNotification
{
	id availCol, loadCol;

	availCol = [availableTable tableColumnWithIdentifier: @"available"];
// [availableTable sizeToFit];
	
	loadCol = [loadedTable tableColumnWithIdentifier: @"loaded"];
//	[loadedTable sizeToFit];
}
@end
