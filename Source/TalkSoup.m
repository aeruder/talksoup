/***************************************************************************
                               TalkSoup.m
                          -------------------
    begin                : Sat Oct  5 02:22:30 CDT 2002
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

#import "TalkSoup.h"
#import "Controllers/ConnectionController.h"

#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSString.h>
#import <Foundation/NSException.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSMenu.h>

int main(void)
{
	CREATE_AUTORELEASE_POOL(arp);
	
	[NSApplication sharedApplication];
	
	[NSApp setDelegate: AUTORELEASE([[TalkSoup alloc] init])];
	[NSApp run];

	DESTROY(arp);

	return 0;
}

/*
@implementation NSException (blah)
- (void)raise
{
	abort();
}
@end
*/

static TalkSoup *talksoup_instance = nil;

@implementation TalkSoup
+ sharedInstance
{
	talksoup_instance = (!talksoup_instance) ? [[TalkSoup alloc] init] 
	  : talksoup_instance;

	return talksoup_instance;
}
- init
{
	if (talksoup_instance)
	{
		return nil;
	}

	if (!(self = [super init])) return nil;

	connectionList = [NSMutableArray new];

	return self;
}
- addConnection: (ConnectionController *)aConnection
{
	[connectionList addObject: aConnection];
	return self;
}
- removeConnection: (ConnectionController *)aConnection
{
	[connectionList removeObject: aConnection];
	return self;
}
- (void)applicationWillFinishLaunching: (NSNotification *)aNotification
{
	NSMenu *menu;
	NSMenuItem *item;
	NSMenu *tempMenu;

	menu = AUTORELEASE([NSMenu new]);
	
	item = [menu addItemWithTitle: @"Info"
	  action: 0
	  keyEquivalent: @""];
	tempMenu = AUTORELEASE([NSMenu new]);
	[menu setSubmenu: tempMenu forItem: item];

	[tempMenu addItemWithTitle: @"Info Panel..."
	  action: @selector(orderFrontStandardInfoPanel:)
	  keyEquivalent: @""];
	
	[menu addItemWithTitle: @"Hide"
	  action: @selector(hide:)
	  keyEquivalent: @"h"];
	
	[menu addItemWithTitle: @"Quit" action: @selector(terminate:)
	  keyEquivalent: @"q"];
	
	[menu addItemWithTitle: @"New Window" action: @selector(connectToServer:)
	  keyEquivalent: @"n"];
	
	[NSApp setMainMenu: menu];
}
- (void)applicationDidFinishLaunching: (NSNotification *)aNotification
{
}
- (void)connectToServer: (NSNotification *)aNotification
{
	id object = AUTORELEASE([ConnectionController new]);

	[[TCPSystem sharedInstance] connectNetObjectInBackground: object
	  toHost: @"irc.openprojects.net" onPort: 6667 withTimeout: 30];
}	
@end

