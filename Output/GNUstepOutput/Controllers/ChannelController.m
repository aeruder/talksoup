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
#include "Misc/NSColorAdditions.h"
#include "GNUstepOutput.h"
#include "TalkSoupBundles/TalkSoup.h"

#include <AppKit/NSWindow.h>
#include <AppKit/NSSplitView.h>
#include <AppKit/NSTextView.h>
#include <AppKit/NSTableView.h>
#include <AppKit/NSTextContainer.h>

@implementation ChannelController
- (void)awakeFromNib
{
	id x;
	[splitView setVertical: YES];

	[chatView setHorizontallyResizable: NO];
	[chatView setVerticallyResizable: YES];
	[chatView setMinSize: NSMakeSize(0, 0)];
	[chatView setMaxSize: NSMakeSize(1e7, 1e7)];
	[[chatView textContainer] setContainerSize:
	  NSMakeSize([chatView frame].size.width, 1e7)];
	[[chatView textContainer] setWidthTracksTextView: YES];
	[chatView setTextContainerInset: NSMakeSize(2, 0)];
	
	[chatView setBackgroundColor: [NSColor colorFromEncodedData:
	  [[_TS_ output] defaultsObjectForKey: GNUstepOutputBackgroundColor]]];
	[chatView setTextColor: [NSColor colorFromEncodedData:
	  [[_TS_ output] defaultsObjectForKey: GNUstepOutputTextColor]]];

	x = RETAIN([window contentView]);
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
- (NSTextView *)chatView
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
