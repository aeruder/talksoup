/***************************************************************************
                                ServerListController.m
                          -------------------
    begin                : Wed Apr 30 14:30:59 CDT 2003
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

#include "Controllers/ServerListController.h"

#include <AppKit/NSButton.h>
#include <AppKit/NSOutlineView.h>
#include <AppKit/NSWindow.h>
#include <AppKit/NSTableColumn.h>
#include <AppKit/NSScrollView.h>

@implementation ServerListController
- (void)awakeFromNib
{
	NSRect a;
	
	a = [scrollView frame];
	
	outline = [[NSOutlineView alloc] initWithFrame: 
	  NSMakeRect(0, 0, a.size.width, a.size.height)];
	[outline setDrawsGrid: NO];
	[outline setIndentationPerLevel: 25];
	[outline setHeaderView: nil];
	[outline setCornerView: nil];
	
	serverColumn = [[NSTableColumn alloc] initWithIdentifier: @"Servers"];
	[serverColumn setEditable: NO];
	
	[outline addTableColumn: serverColumn];
	[outline setOutlineTableColumn: serverColumn];
	
	[scrollView setHasHorizontalScroller: YES];
	[scrollView setHasVerticalScroller: YES];
	[scrollView setDocumentView: outline];
	[scrollView setAutoresizingMask: 
	 NSViewWidthSizable | NSViewHeightSizable];
	
	[window setDelegate: self];
}
- (void)dealloc
{
	RELEASE(scrollView);
	RELEASE(addGroupButton);
	RELEASE(removeButton);
	RELEASE(addEntryButton);
	RELEASE(editButton);
	RELEASE(serverColumn);
	RELEASE(connectButton);
	
	[super dealloc];
}
- (void)editHit: (NSButton *)sender
{
	NSLog(@"Edit button hit!");
}
- (void)addEntryHit: (NSButton *)sender
{
	NSLog(@"Add Entry button hit!");
}
- (void)removeHit: (NSButton *)sender
{
	NSLog(@"Remove button hit!");
}
- (void)connectHit: (NSButton *)sender
{
	NSLog(@"Connect button hit!");
}
- (void)addGroupHit: (NSButton *)sender
{
	NSLog(@"Add Group button hit!");
}
- (NSOutlineView *)outlineView
{
	return outline;
}
- (NSWindow *)window
{
	return window;
}
@end

@interface ServerListController (WindowDelegate)
@end

@implementation ServerListController (WindowDelegate)
- (void)windowWillClose: (NSNotification *)aNotification
{
	[window setDelegate: nil];
	DESTROY(window);
	RELEASE(self);
}
@end

