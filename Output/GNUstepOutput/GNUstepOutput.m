/***************************************************************************
                                GNUStepOutput.m
                          -------------------
    begin                : Sat Jan 18 01:31:16 CST 2003
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

#include "GNUstepOutput.h"

#include "Controllers/ContentController.h"
#include <AppKit/NSNibLoading.h>
#include <AppKit/NSApplication.h>
#include <AppKit/NSMenu.h>
#include <Foundation/NSRunLoop.h>

@implementation GNUstepOutput
- init
{
	if (!(self = [super init])) return nil;

	connectionToContent = NSCreateMapTable(NSObjectMapKeyCallBacks,
	  NSObjectMapValueCallBacks, 10);

	return self;
}
#if 0
- newConnection: (id)connection;

- registeredWithServerOnConnection: (id)connection;

- couldNotRegister: (NSAttributedString *)reason onConnection: (id)connection;

- CTCPRequestReceived: (NSAttributedString *)aCTCP 
   withArgument: (NSAttributedString *)argument 
   from: (NSAttributedString *)aPerson onConnection: (id)connection;

- CTCPReplyReceived: (NSAttributedString *)aCTCP
   withArgument: (NSAttributedString *)argument 
   from: (NSAttributedString *)aPerson 
   onConnection: (id)connection;

- errorReceived: (NSAttributedString *)anError onConnection: (id)connection;

- wallopsReceived: (NSAttributedString *)message 
   from: (NSAttributedString *)sender 
   onConnection: (id)connection;

- userKicked: (NSAttributedString *)aPerson 
   outOf: (NSAttributedString *)aChannel 
   for: (NSAttributedString *)reason from: (NSAttributedString *)kicker 
   onConnection: (id)connection;
		 
- invitedTo: (NSAttributedString *)aChannel from: (NSAttributedString *)inviter 
   onConnection: (id)connection;

- modeChanged: (NSAttributedString *)mode on: (NSAttributedString *)anObject 
   withParams: (NSArray *)paramList from: (NSAttributedString *)aPerson 
   onConnection: (id)connection;
   
- numericCommandReceived: (NSAttributedString *)command 
   withParams: (NSArray *)paramList from: (NSAttributedString *)sender 
   onConnection: (id)connection;

- nickChangedTo: (NSAttributedString *)newName 
   from: (NSAttributedString *)aPerson 
   onConnection: (id)connection;

- channelJoined: (NSAttributedString *)channel 
   from: (NSAttributedString *)joiner 
   onConnection: (id)connection;

- channelParted: (NSAttributedString *)channel 
   withMessage: (NSAttributedString *)aMessage
   from: (NSAttributedString *)parter onConnection: (id)connection;

- quitIRCWithMessage: (NSAttributedString *)aMessage 
   from: (NSAttributedString *)quitter onConnection: (id)connection;

- topicChangedTo: (NSAttributedString *)aTopic in: (NSAttributedString *)channel
   from: (NSAttributedString *)aPerson onConnection: (id)connection;

- messageReceived: (NSAttributedString *)aMessage to: (NSAttributedString *)to
   from: (NSAttributedString *)sender onConnection: (id)connection;

- noticeReceived: (NSAttributedString *)aMessage to: (NSAttributedString *)to
   from: (NSAttributedString *)sender onConnection: (id)connection;

- actionReceived: (NSAttributedString *)anAction to: (NSAttributedString *)to
   from: (NSAttributedString *)sender onConnection: (id)connection;

- pingReceivedWithArgument: (NSAttributedString *)arg 
   from: (NSAttributedString *)sender onConnection: (id)connection;

- pongReceivedWithArgument: (NSAttributedString *)arg 
   from: (NSAttributedString *)sender onConnection: (id)connection;

- newNickNeededWhileRegisteringOnConnection: (id)connection;

- consoleMessage: (NSAttributedString *)arg;

- systemMessage: (NSAttributedString *)arg;

- showMessage: (NSAttributedString *)arg;
#endif

- (void)run
{
	[NSApplication sharedApplication];
	[NSApp setDelegate: self];
	[NSApp run];
}
@end

@interface GNUstepOutput (NSApplicationDelegate)
@end

@implementation GNUstepOutput (NSApplicationDelegate)
- (void)applicationWillFinishLaunching: (NSNotification *)aNotification
{
	NSMenu *menu;
	NSMenuItem *item;
	NSMenu *tempMenu;

	menu = AUTORELEASE([NSMenu new]);

// Info	
	item = [menu addItemWithTitle: @"Info" action: 0 keyEquivalent: @""];
	tempMenu = AUTORELEASE([NSMenu new]);
	[menu setSubmenu: tempMenu forItem: item];

	[tempMenu addItemWithTitle: @"Info Panel..."
	  action: @selector(orderFrontStandardInfoPanel:)
	  keyEquivalent: @""];

// Edit	
	item = [menu addItemWithTitle: @"Edit" action: 0 keyEquivalent: @""];
	tempMenu = AUTORELEASE([NSMenu new]);
	[menu setSubmenu: tempMenu forItem: item];

	[tempMenu addItemWithTitle: @"Cut"
	  action: @selector(cut:)
	  keyEquivalent: @"x"];
	[tempMenu addItemWithTitle: @"Copy"
	  action: @selector(copy:)
	  keyEquivalent: @"c"];
	[tempMenu addItemWithTitle: @"Paste"
	  action: @selector(paste:)
	  keyEquivalent: @"v"];
	[tempMenu addItemWithTitle: @"Delete"
	  action: @selector(delete:)
	  keyEquivalent: @""];
	[tempMenu addItemWithTitle: @"Select All"
	  action: @selector(selectAll:)
	  keyEquivalent: @"a"];

// Windows
	item = [menu addItemWithTitle: @"Windows" action: 0 keyEquivalent: @""];
	tempMenu = AUTORELEASE([NSMenu new]);
	[menu setSubmenu: tempMenu forItem: item];
	[tempMenu addItemWithTitle: @"New Window" action: 
	  @selector(connectToServer:) keyEquivalent: @"n"];

	[NSApp setWindowsMenu: tempMenu];

// Services
	item = [menu addItemWithTitle: @"Services" action: 0 keyEquivalent: @""];
	tempMenu = AUTORELEASE([NSMenu new]);
	[menu setSubmenu: tempMenu forItem: item];
	[NSApp setServicesMenu: tempMenu];

// Hide
	[menu addItemWithTitle: @"Hide"
	  action: @selector(hide:)
	  keyEquivalent: @"h"];

// Quit
	[menu addItemWithTitle: @"Quit" action: @selector(terminate:)
	  keyEquivalent: @"q"];
	
	[NSApp setMainMenu: menu];
}
- (void)applicationDidFinishLaunching: (NSNotification *)aNotification
{
}
- (void)connectToServer: (NSNotification *)aNotification
{
	id content = AUTORELEASE([ContentController new]);
	[NSBundle loadNibNamed: @"Content" owner: content];
}	
@end

