/***************************************************************************
                                ConsoleView.m
                          -------------------
    begin                : Thu Oct 24 13:05:09 CDT 2002
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

#import "Views/ScrollingTextView.h"
#import "Views/ConsoleView.h"
#import <math.h>

@implementation ConsoleView
- init
{
	return [self initWithBorder: YES];
}
- initWithBorder: (BOOL)border;
{
	int origx;
	int origy;
	
	if (border)
	{
		origx = origy = 4;
	}
	else
	{
		origx = origy = 0;
	}
	
	if (!(self = [super initWithFrame: 
	  NSMakeRect(0,0,origx * 2 + 200, origy * 2 + 200)])) return nil;
	
	chatScroll = [[NSScrollView alloc] initWithFrame: 
	  NSMakeRect(origx, origy, 200, 200)];
	
	chatView = [[ScrollingTextView alloc] 
	   initWithFrame: NSMakeRect(0, 0, 200, 200)];
	
	[chatView setRichText: YES];
	[chatView setUsesFontPanel: NO];
	[chatView setHorizontallyResizable: NO];
	[chatView setVerticallyResizable: YES];
	[chatView setMinSize: NSMakeSize (0, 0)];
	[chatView setMaxSize: NSMakeSize (1E7, 1E7)];
	[chatView setEditable: NO];
	[chatView setFont: [NSFont userFontOfSize: 12.0]];
	[chatView setAutoresizingMask: NSViewHeightSizable | NSViewWidthSizable];
	[[chatView textContainer] setContainerSize: 
	  NSMakeSize([chatScroll frame].size.width, 1E7)];
	[[chatView textContainer] setWidthTracksTextView: YES];
	[chatView setTextContainerInset: NSMakeSize(2,0)];
	
	[chatScroll setDocumentView: chatView];
	[chatScroll setHasHorizontalScroller: NO];
	[chatScroll setHasVerticalScroller: YES];
	[chatScroll setBorderType: NSBezelBorder];
	[chatScroll setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
	[chatScroll setAutoresizesSubviews: YES];

	[self addSubview: chatScroll];

	[self setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
	[self setAutoresizesSubviews: YES];

	return self;
}
- (void)dealloc
{
	DESTROY(chatScroll);
	DESTROY(chatView);
	[super dealloc];
}
- putMessage: message
{
	[chatView appendText: message];
	
	return self;
}
- (NSTextView *)chatView
{
	return chatView;
}
- (NSScrollView *)chatScroll
{
	return chatScroll;
}
@end

@implementation NSTextView (appendText)
- appendText: aText
{
	if ([aText isKindOf: [NSString class]])
	{
		[[self textStorage] appendAttributedString: 
		  AUTORELEASE([[NSAttributedString alloc] initWithString: aText
		     attributes: [self typingAttributes]])];
	}
	else if ([aText isKindOf: [NSAttributedString class]])
	{
		[[self textStorage] appendAttributedString: aText];
	}
	return self;
}
@end


