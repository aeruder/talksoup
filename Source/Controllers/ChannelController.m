/***************************************************************************
                                ChannelController.m
                          -------------------
    begin                : Sun Nov 10 13:03:07 CST 2002
    copyright            : (C) 2002 by Andy Ruder
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

#import "Controllers/ChannelController.h"

#import "Controllers/ConnectionController.h"
#import "Views/ScrollingTextView.h"
#import "Models/Channel.h"

#import <AppKit/AppKit.h>

#define SIZE_X 208
#define SIZE_Y 208

#define SPLIT_X SIZE_X - 8
#define SPLIT_Y SIZE_Y - 8

#define TABLE_WIDTH     110

@implementation ChannelController
- init
{
	id cell;
	
	if (!(self = [super init])) return nil;

	contentView = [[NSView alloc] initWithFrame:
	  NSMakeRect(0, 0, SIZE_X, SIZE_Y)];
	  
	splitView = [[NSSplitView alloc] initWithFrame:
	  NSMakeRect(4, 4, SPLIT_X, SPLIT_Y)];
	
	talkScroll = [[NSScrollView alloc] initWithFrame:
	  NSMakeRect(0, 0, SPLIT_X - TABLE_WIDTH - 4, SPLIT_Y)];
	
	userScroll = [[NSScrollView alloc] initWithFrame:
	  NSMakeRect(SPLIT_X - TABLE_WIDTH, 0, TABLE_WIDTH, SPLIT_Y)];
	
	talkView = [[ScrollingTextView alloc] initWithFrame:
	  NSMakeRect(0, 0, SPLIT_X - TABLE_WIDTH - 4, SPLIT_Y)];

	userTable = [[NSTableView alloc] initWithFrame:
	  NSMakeRect(0, 0, TABLE_WIDTH, SPLIT_Y)];
	
	userColumn = [[NSTableColumn alloc] initWithIdentifier: @"User List"];
	
	cell = AUTORELEASE([[NSCell alloc] initTextCell: @""]);
	
	[talkView setRichText: YES];
	[talkView setUsesFontPanel: NO];
	[talkView setHorizontallyResizable: NO];
	[talkView setVerticallyResizable: YES];
	[talkView setMinSize: NSMakeSize(0, 0)];
	[talkView setMaxSize: NSMakeSize(1e7, 1e7)];
	[talkView setEditable: NO];
	[talkView setFont: [NSFont userFontOfSize: 12.0]];
	[talkView setAutoresizingMask: NSViewHeightSizable | NSViewWidthSizable];
	[[talkView textContainer] setContainerSize:
	  NSMakeSize([talkView frame].size.width, 1e7)];
	[[talkView textContainer] setWidthTracksTextView: YES];
	[talkView setTextContainerInset: NSMakeSize(2, 0)];
	[talkView setBackgroundColor: [NSColor colorWithCalibratedRed: 1.0
	  green: 0.9725 blue: 0.8627 alpha: 1.0]];

	[talkScroll setDocumentView: talkView];
	[talkScroll setHasHorizontalScroller: NO];
	[talkScroll setHasVerticalScroller: YES];
	[talkScroll setBorderType: NSBezelBorder];
	[talkScroll setAutoresizesSubviews: YES];

	[userColumn setEditable: NO];
	
	[userTable setCornerView: nil];
	[userTable setHeaderView: nil];
	[userTable addTableColumn: userColumn];
	
	[userScroll setDocumentView: userTable];
	[userScroll setHasHorizontalScroller: NO];
	[userScroll setHasVerticalScroller: YES];
	[userScroll setBorderType: NSBezelBorder];
	
	[splitView setVertical: YES];
	[splitView setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
	[splitView setAutoresizesSubviews: YES];
	[splitView setDelegate: self];
	
	[contentView setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
	[contentView setAutoresizesSubviews: YES];

	[cell setFormatter: AUTORELEASE([ChannelFormatter new])];
	
	[userColumn setDataCell: cell];
	
	[splitView addSubview: talkScroll];
	[splitView addSubview: userScroll];

	[contentView addSubview: splitView];

	return self;
}
- (void)dealloc
{
	DESTROY(splitView);
	DESTROY(userTable);
	DESTROY(userColumn);
	DESTROY(userScroll);

	[super dealloc];
}
- (NSSplitView *)splitView
{
	return splitView;
}
- (NSTableView *)userTable
{
	return userTable;
}
- (NSTableColumn *)userColumn
{
	return userColumn;
}
- (NSScrollView *)userScroll
{
	return userScroll;
}
- (void)splitView: (NSSplitView *)sender
    resizeSubviewsWithOldSize: (NSSize)oldSize
{
	NSRect frame1;  // talkScroll
	NSRect frame2 = [userScroll frame];
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
	[userScroll setFrame: frame2];

	[talkScroll setFrame: frame1];
}
@end

#undef SIZE_X
#undef SIZE_Y
#undef SPLIT_X
#undef SPLIT_Y
#undef TABLE_WIDTH
