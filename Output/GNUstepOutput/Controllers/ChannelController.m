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

#import "Controllers/Preferences/ColorPreferencesController.h"
#import "Controllers/Preferences/PreferencesController.h"
#import "Controllers/ChannelController.h"
#import "Views/ScrollingTextView.h"
#import "Misc/NSColorAdditions.h"
#import "Models/Channel.h"
#import "GNUstepOutput.h"
#import <TalkSoupBundles/TalkSoup.h>

#import <AppKit/NSWindow.h>
#import <AppKit/NSSplitView.h>
#import <AppKit/NSTextView.h>
#import <AppKit/NSTableView.h>
#import <AppKit/NSTextContainer.h>
#import <AppKit/NSTableColumn.h>
#import <AppKit/NSScrollView.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSFont.h>
#import <AppKit/NSView.h>

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
	[chatView setTextContainerInset: NSMakeSize(2, 2)];
	[chatView setAutoresizingMask: NSViewHeightSizable | NSViewWidthSizable];
	[chatView setFrameSize: [[chatView enclosingScrollView] contentSize]];
	[chatView setEditable: NO];
	[chatView setSelectable: YES];
	[chatView setRichText: NO];

	userColumn = AUTORELEASE([[NSTableColumn alloc] 
	  initWithIdentifier: @"User List"]);
	
	[userColumn setEditable: NO];
	
	frame = [tableView frame];
	AUTORELEASE(RETAIN(tableView));
	[tableView removeFromSuperview];
	
	userScroll = AUTORELEASE([[NSScrollView alloc] initWithFrame: frame]); 
	tableView = AUTORELEASE([[NSTableView alloc] initWithFrame: 
	  NSMakeRect(0, 0, frame.size.width, frame.size.height)]);

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
	
	font = [NSFont systemFontOfSize: 0.0];
	[x setFont: font];
	[tableView setRowHeight: [font pointSize] * 1.5];
	
	[userColumn setDataCell: x];
	
	[chatView setBackgroundColor: [NSColor colorFromEncodedData:
	  [_PREFS_ preferenceForKey: GNUstepOutputBackgroundColor]]];
	[chatView setTextColor: [NSColor colorFromEncodedData:
	  [_PREFS_ preferenceForKey: GNUstepOutputTextColor]]];
	 
	[splitView addSubview: userScroll];
	[splitView setDelegate: self];
	
	frame = [userScroll frame];
	frame.size.width = 120;
	[userScroll setFrame: frame];
	[self splitView: splitView resizeSubviewsWithOldSize:
	  [splitView frame].size];

	x = RETAIN([(NSWindow *)window contentView]);
	[window close];
	AUTORELEASE(window);
	window = x;
	[window setAutoresizingMask: NSViewHeightSizable | NSViewWidthSizable];
}
- (void)dealloc
{
	RELEASE(window);
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

