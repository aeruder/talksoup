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

static NSFont *standard_font = nil;

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

@implementation ChannelView
+ (void)initialize
{
	standard_font = [NSFont userFontOfSize: 12.0];
}
- init
{
	
	if (!(self = [super initWithFrame: 
	  NSMakeRect(0,0,108,108)])) return nil;
	
	scrollView = [[NSScrollView alloc] initWithFrame: 
	  NSMakeRect(4, 4, 100, 100)];
	
	chatView = [[NSTextView alloc] initWithFrame: NSMakeRect(0, 0, 100, 100)];
	
/*	[chatView setBackgroundColor: [NSColor blackColor]];
	[chatView setTextColor: [NSColor whiteColor]];
	[chatView setInsertionPointColor: [NSColor whiteColor]];
	[chatView setSelectedTextAttributes:
	 [NSDictionary dictionaryWithObjectsAndKeys:
	  [NSColor whiteColor], NSForegroundColorAttributeName,
	  [NSColor blueColor], NSBackgroundColorAttributeName,
	  nil]];*/
	
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
	  NSMakeSize([scrollView frame].size.width, 1E7)];
	[[chatView textContainer] setWidthTracksTextView: YES];
	
	[scrollView setDocumentView: chatView];
	[scrollView setHasHorizontalScroller: NO];
	[scrollView setHasVerticalScroller: YES];
	[scrollView setBorderType: NSNoBorder];
	[scrollView setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
	[scrollView setAutoresizesSubviews: YES];

	[self addSubview: scrollView];
	[self setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
	[self setAutoresizesSubviews: YES];

	return self;
}
- (NSString *)name
{
	return name;
}
- setName: (NSString *)newName
{
	if (newName == name) return self;

	RELEASE(name);
	name = RETAIN(newName);

	return self;
}
- putMessage: message
{
	[chatView appendText: message];
	return self;
}
- (NSTextField *)nickView
{
	return nickView;
}
- (NSTextField *)typeView;
{
	return typeView;
}
- (NSTextView *)chatView
{
	return chatView;
}
- (NSScrollView *)scrollView
{
	return scrollView;
}
@end
