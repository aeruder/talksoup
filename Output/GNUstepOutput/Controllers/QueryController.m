/***************************************************************************
                                QueryController.m
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

#import "Controllers/QueryController.h"
#import "Views/ScrollingTextView.h"
#import "Misc/NSColorAdditions.h"
#import "GNUstepOutput.h"
#import <TalkSoupBundles/TalkSoup.h>

#import <AppKit/NSWindow.h>
#import <AppKit/NSTextView.h>
#import <AppKit/NSTextContainer.h>
#import <AppKit/NSScrollView.h>

@implementation QueryController
- (void)awakeFromNib
{	
	id x;
	
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
	
	[chatView setBackgroundColor: [NSColor colorFromEncodedData:
	  [_GS_ defaultsObjectForKey: GNUstepOutputBackgroundColor]]];
	[chatView setTextColor: [NSColor colorFromEncodedData:
	  [_GS_ defaultsObjectForKey: GNUstepOutputTextColor]]];
		  
	x = RETAIN([(NSWindow *)window contentView]);
	[window close];
	AUTORELEASE(window);
	window = x;
	[window setAutoresizingMask: NSViewHeightSizable | NSViewWidthSizable];
}
- (void)dealloc
{
	DESTROY(window);
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
@end
