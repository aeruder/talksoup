/***************************************************************************
                                QueryController.m
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

#import "Controllers/QueryController.h"

#import "Controllers/ConnectionController.h"
#import "Views/ScrollingTextView.h"

#import <AppKit/NSView.h>
#import <AppKit/NSScrollView.h>
#import <AppKit/NSTextContainer.h>

#define SIZE_X 200
#define SIZE_Y 200

@implementation QueryController
- init
{
	if (!(self = [super init])) return nil;

	contentView = [[NSView alloc] initWithFrame:
	  NSMakeRect(0, 0, SIZE_X, SIZE_Y)];
	
	talkScroll = [[NSScrollView alloc] initWithFrame:
	  NSMakeRect(4, 4, SIZE_X - 8, SIZE_Y - 8)];
	
	talkView = [[ScrollingTextView alloc] initWithFrame:
	  NSMakeRect(0, 0, SIZE_X - 8, SIZE_Y - 8)];
	
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

	[talkScroll setDocumentView: talkView];
	[talkScroll setHasHorizontalScroller: NO];
	[talkScroll setHasVerticalScroller: YES];
	[talkScroll setBorderType: NSBezelBorder];
	[talkScroll setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
	[talkScroll setAutoresizesSubviews: YES];

	[contentView setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
	[contentView setAutoresizesSubviews: YES];
	
	[contentView addSubview: talkScroll];

	return self;
}
@end

#undef SIZE_X
#undef SIZE_Y
