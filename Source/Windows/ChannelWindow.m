/***************************************************************************
                                ChannelWindow.m
                          -------------------
    begin                : Tue Oct  8 12:51:07 CDT 2002
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

#import "Windows/ChannelWindow.h"
#import "Controllers/TalkController.h"

#import <AppKit/AppKit.h>

#define SIZE_X 100
#define SIZE_Y 100

@implementation ChannelWindow
- init
{
	NSView *content = AUTORELEASE([[NSView alloc] initWithFrame: 
	  NSMakeRect(0,0, SIZE_X, SIZE_Y)]);
	NSRect size;
	NSRect typeSize;
	
	if (!(self = [super initWithContentRect: 
	   NSMakeRect(100, 100, 600, 350)
	 styleMask: NSClosableWindowMask | NSTitledWindowMask |
	            NSResizableWindowMask | NSMiniaturizableWindowMask
	 backing: NSBackingStoreRetained defer: YES])) return nil;

/* Setup NickView */
	nickView = [[NSTextField alloc] init];
	[nickView setEditable: NO];
	[nickView setDrawsBackground: NO];
	[nickView setBordered: NO];
	[nickView setBezeled: NO];
	[nickView setSelectable: NO];
	[nickView setFont: [NSFont userFontOfSize: 12.0]];
	[nickView setAutoresizingMask: 0];
/* End Setup NickView */

/* Setup TypeView */
	typeView = [[NSTextField alloc] init];
	
	[typeView setEditable: YES];
	[typeView setDrawsBackground: YES];
	[typeView setBordered: NO];
	[typeView setBezeled: YES];
	[typeView setFont: [NSFont userFontOfSize: 12.0]];
	[typeView setAutoresizingMask: NSViewWidthSizable];
	[typeView sizeToFit];
/* End Setup TypeView */

/* Setup TabView */
	tabView = [[NSTabView alloc] init];
	typeSize = [typeView frame];
	size = [tabView frame];
	size.origin.x = 4;
	size.origin.y = NSMaxY(typeSize) + 8;
	size.size.width = SIZE_X - 8;
	size.size.height = SIZE_Y - 4 - size.origin.y;
	[tabView setFrame: size];
	[tabView setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
	[tabView setAutoresizesSubviews: YES];
/* End Setup TabView */

	[content addSubview: typeView];
	[content addSubview: nickView];
	[content addSubview: tabView];
	
	[self setContentView: content];
	
	[self updateNick: @"- - -"];

	return self;
}
- (void)dealloc
{
	DESTROY(tabView);
	DESTROY(typeView);
	DESTROY(nickView);

	[super dealloc];
}
- (NSTabView *)tabView
{
	return tabView;
}
- (NSTextField *)nickView
{
	return nickView;
}
- (NSTextField *)typeView
{
	return typeView;
}
- updateNick: (NSString *)aNick
{
	NSRect nick;
	NSRect type;

	[nickView setStringValue: aNick];
	[nickView sizeToFit];
	
	nick = [nickView frame];

	nick.origin.x = 4;
	nick.origin.y = 4;

	type = [typeView frame];
	type.origin.y = 4;
	type.origin.x = NSMaxX(nick) + 4;
	type.size.width = [[self contentView] frame].size.width - 4 - type.origin.x;
	
	[nickView setFrame: nick];
	[typeView setFrame: type];
	
	[[self contentView] setNeedsDisplay: YES];

	return self;
}
@end
