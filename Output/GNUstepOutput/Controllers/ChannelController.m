/***************************************************************************
                                ChannelController.m
                          -------------------
    begin                : Sat Jan 18 01:38:06 CST 2003
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

#include "Controllers/ChannelController.h"
#include "Views/ScrollingTextView.h"
#include "Misc/NSColorAdditions.h"
#include "Models/Channel.h"
#include "GNUstepOutput.h"
#include "TalkSoupBundles/TalkSoup.h"

#include <AppKit/NSWindow.h>
#include <AppKit/NSSplitView.h>
#include <AppKit/NSTextView.h>
#include <AppKit/NSTableView.h>
#include <AppKit/NSTextContainer.h>
#include <AppKit/NSTableColumn.h>
#include <AppKit/NSScrollView.h>
#include <AppKit/NSWindow.h>

@implementation ChannelController
- (void)awakeFromNib
{
	id x;
	id userColumn;
	id userScroll;
	id font;
	NSRect frame;
	
	[splitView setVertical: YES];

	[chatView setHorizontallyResizable: NO];
	[chatView setVerticallyResizable: YES];
	[chatView setMinSize: NSMakeSize(0, 0)];
	[chatView setMaxSize: NSMakeSize(1e7, 1e7)];
	[[chatView textContainer] setContainerSize:
	  NSMakeSize([chatView frame].size.width, 1e7)];
	[[chatView textContainer] setWidthTracksTextView: YES];
	[chatView setTextContainerInset: NSMakeSize(2, 0)];
	[chatView setAutoresizingMask: NSViewHeightSizable | NSViewWidthSizable];

	userColumn = AUTORELEASE([[NSTableColumn alloc] 
	  initWithIdentifier: @"User List"]);
	
	[userColumn setEditable: NO];
	
	frame = [tableView frame];
	[splitView removeSubview: tableView];
	RELEASE(tableView);
	
	userScroll = AUTORELEASE([[NSScrollView alloc] initWithFrame: frame]); 
	tableView = [[NSTableView alloc] initWithFrame: 
	  NSMakeRect(0, 0, frame.size.width, frame.size.height)];

	[tableView setCornerView: nil];
	[tableView setHeaderView: nil];

	[tableView addTableColumn: userColumn];
	[tableView setDrawsGrid: NO];
	
	[userScroll setDocumentView: tableView];
	[userScroll setHasHorizontalScroller: NO];
	[userScroll setHasVerticalScroller: YES];
	[userScroll setBorderType: NSBezelBorder];
	
	x = AUTORELEASE([[NSCell alloc] initTextCell: @""]);
	[x setFormatter: AUTORELEASE([ChannelFormatter new])];
	
	font = [NSFont userFontOfSize: 0.0];
	[x setFont: font];
	[tableView setRowHeight: [font pointSize] * 1.5];
	
	[userColumn setDataCell: x];
	
	[chatView setBackgroundColor: [NSColor colorFromEncodedData:
	  [_GS_ defaultsObjectForKey: GNUstepOutputBackgroundColor]]];
	[chatView setTextColor: [NSColor colorFromEncodedData:
	  [_GS_ defaultsObjectForKey: GNUstepOutputTextColor]]];
	 
	[splitView addSubview: userScroll];
	[splitView setDelegate: self];
	
	frame = [userScroll frame];
	frame.size.width = 120;
	[userScroll setFrame: frame];
	[self splitView: splitView resizeSubviewsWithOldSize:
	  [splitView frame].size];

	x = RETAIN([(NSWindow *)window contentView]);
	[window close];
	RELEASE(window);
	window = RETAIN(x);
	[window setAutoresizingMask: NSViewHeightSizable | NSViewWidthSizable];
}
- (void)dealloc
{
	RELEASE(window);
	RELEASE(chatView);
	RELEASE(splitView);
	RELEASE(tableView);
	[super dealloc];
}
- (ScrollingTextView *)chatView
{
	return chatView;
}
- (NSView *)contentView
{
	return window;
}
- (NSSplitView *)splitView
{
	return splitView;
}
- (NSTableView *)tableView
{
	return tableView;
}
@end

@interface ChannelController (NSSplitViewDelegate)
- (void)splitView: (NSSplitView *)sender
    resizeSubviewsWithOldSize: (NSSize)oldSize;
@end

@implementation ChannelController (NSSplitViewDelegate)
- (void)splitView: (NSSplitView *)sender
    resizeSubviewsWithOldSize: (NSSize)oldSize
{
	id tableScroll = [tableView enclosingScrollView];
	id chatScroll = [chatView enclosingScrollView];
	NSRect frame1;  // talkScroll
	NSRect frame2 = [tableScroll frame];
	NSRect frame3 = [splitView frame];

	if ((frame3.size.width - [sender dividerThickness]) > frame2.size.width)
	{
		// Width of this view is constant(assuming it fits)
		frame2.origin.x = frame3.size.width - frame2.size.width;
		frame2.origin.y = 0;
		frame2.size.height = frame3.size.height;

		frame1.origin.x = 0;
		frame1.origin.y = 0;
		frame1.size.width = frame2.origin.x - [sender dividerThickness];
		frame1.size.height = frame3.size.height;
	}
	else
	{
		frame1.origin.x = 0;
		frame1.origin.y = 0;
		frame1.size.width = 0;
		frame1.size.height = frame3.size.height;

		frame2.origin.x = 0;
		frame2.origin.y = 0;
		frame2.size.width = frame3.size.width;
		frame2.size.height = frame3.size.height;
	}
	[tableScroll setFrame: frame2];
	[chatScroll setFrame: frame1];
}
@end

