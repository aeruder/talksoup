/**************************************************************************
                                ChannelView.m
                          -------------------
    begin                : Sun Oct  6 01:33:50 CDT 2002
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

#import <Foundation/NSGeometry.h>
#import <AppKit/AppKit.h>

#import "Views/ChannelView.h"
#import "Views/ConsoleView.h"

@interface ChannelView (NSSplitViewDelegate)
@end

@implementation ChannelView
- init
{
	if (!(self = [super initWithFrame: 
	  NSMakeRect(0,0,208,208)])) return nil;
	
	splitView = [[NSSplitView alloc] initWithFrame:
	  NSMakeRect(4, 4, 200, 200)];
	
	[splitView setVertical: YES];
	[splitView setAutoresizesSubviews: YES];
	[splitView setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
	[splitView setDelegate: self];
	
	consoleView = [[ConsoleView alloc] initWithBorder: NO];
	[consoleView setFrame: NSMakeRect(0, 0, 100, 200)]; 
	
	userTable = [[NSTableView alloc] initWithFrame: 
	  NSMakeRect(104, 0, 96, 200)];
	[userTable setCornerView: nil];
	[userTable setHeaderView: nil];
	
	userColumn = [[NSTableColumn alloc] initWithIdentifier: @"User List"];
	[userColumn setEditable: NO];
	[userColumn setMinWidth: 96];
	
	[userTable addTableColumn: userColumn];
	
	userScroll = [[NSScrollView alloc]
	  initWithFrame: NSMakeRect(104, 0, 96, 200)];
	[userScroll setDocumentView: userTable];
	[userScroll setHasHorizontalScroller: NO];
	[userScroll setHasVerticalScroller: YES];
	[userScroll setBorderType: NSBezelBorder];
	[userScroll setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
	
	[splitView addSubview: consoleView];
	[splitView addSubview: userScroll];

	[self addSubview: splitView];
	[self setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
	[self setAutoresizesSubviews: YES];

	return self;
}
- (void)dealloc
{
	[splitView setDelegate: nil];
	DESTROY(userTable);
	DESTROY(userColumn);
	DESTROY(splitView);
	DESTROY(userScroll);
	DESTROY(consoleView);
	[super dealloc];
}	
- (ConsoleView *)consoleView
{
	return consoleView;
}
- (NSScrollView *)userScroll
{
	return userScroll;
}
- (NSSplitView *)splitView
{
	return splitView;
}
- (NSTableColumn *)userColumn
{
	return userColumn;
}
- (NSTableView *)userTable
{
	return userTable;
}
@end

@implementation ChannelView (NSSplitViewDelegate)
- (void)splitView: (NSSplitView *)sender 
    resizeSubviewsWithOldSize: (NSSize)oldSize
{
	NSRect frame1; // console view
	NSRect frame2 = [userScroll frame]; // user table
	NSRect frame3 = [splitView frame];
	//id chatView = [consoleView chatView];
	
	if (frame3.size.width > frame2.size.width)
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
	[userColumn setMinWidth: frame2.size.width];
	
	[consoleView setFrame: frame1];
}
@end
