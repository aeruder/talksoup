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
#include <Foundation/NSAttributedString.h>
#include <Foundation/NSString.h>
#include <Foundation/NSDictionary.h>

NSString *GNUstepOutputLowercase(NSString *aString)
{
	return [aString lowercaseString];
}

NSString *GNUstepOutputIdentificationForController(id controller)
{
	id string;
	string = [NSString stringWithFormat: @"%p", controller];
	return string;
}

@implementation GNUstepOutput
- init
{
	if (!(self = [super init])) return nil;
	
	connectionToInformation = NSCreateMapTable(NSObjectMapKeyCallBacks,
	  NSObjectMapValueCallBacks, 10);

	connectionToContent = NSCreateMapTable(NSObjectMapKeyCallBacks,
	  NSObjectMapValueCallBacks, 10);
	  
	pendingIdentToContent = [NSMutableDictionary new];
	
	return self;
}
- (id)openNewContentWindow
{
	id content = AUTORELEASE([ContentController new]);
	
	if (![NSBundle loadNibNamed: @"Content" owner: content])
	{
		return nil;
	}
	
	return content;
}
- makeConnectionForContentController: (id)controller
{
	[pendingIdentToContent setObject: controller forKey: 
	  GNUstepOutputIdentificationForController(controller)];
	
	[[_TS_ input] initiateConnectionToHost: [NSHost hostWithAddress:
	  @"127.0.0.1"] onPort: 6667 withTimeout: 30 withNickname: @"Andy"
	  withUserName: @"Bill" withRealName: @"Blah Blah" withPassword: @"" 
	  withIdentification: GNUstepOutputIdentificationForController(controller)];
	  
	return self;
}
- registeredWithServerOnConnection: (id)connection sender: aPlugin
{
	NSLog(@"It worked!!!!");
	return self;
}
- newConnection: (id)connection sender: aPlugin
{
	NSLog(@"It worked?");
	id ident = [connection identification];
	id content;
	
	content = [pendingIdentToContent objectForKey: ident];

	if (!(content))
	{
		NSLog(@"Connection came through but there is no related"
		      @"content view... closing connection...");
		[[_TS_ input] closeConnection: connection];
	}
	
	[pendingIdentToContent removeObjectForKey: ident];
	NSMapInsert(connectionToContent, connection, content);
	NSMapInsert(connectionToContent, content, connection);
	
	[content putMessage: @"Connecting..." in: ContentConsoleName];
	[content setLabel: AUTORELEASE([[NSAttributedString alloc] initWithString:
	  @"Connecting..."]) forViewWithName: ContentConsoleName];
	
	return self;
}
#if 0
- couldNotRegister: (NSAttributedString *)reason onConnection: (id)connection 
   sender: aPlugin;

- CTCPRequestReceived: (NSAttributedString *)aCTCP 
   withArgument: (NSAttributedString *)argument 
   from: (NSAttributedString *)aPerson onConnection: (id)connection 
   sender: aPlugin;

- CTCPReplyReceived: (NSAttributedString *)aCTCP
   withArgument: (NSAttributedString *)argument 
   from: (NSAttributedString *)aPerson 
   onConnection: (id)connection sender: aPlugin;

- errorReceived: (NSAttributedString *)anError onConnection: (id)connection 
   sender: aPlugin;

- wallopsReceived: (NSAttributedString *)message 
   from: (NSAttributedString *)sender 
   onConnection: (id)connection sender: aPlugin;

- userKicked: (NSAttributedString *)aPerson 
   outOf: (NSAttributedString *)aChannel 
   for: (NSAttributedString *)reason from: (NSAttributedString *)kicker 
   onConnection: (id)connection sender: aPlugin;
		 
- invitedTo: (NSAttributedString *)aChannel from: (NSAttributedString *)inviter 
   onConnection: (id)connection sender: aPlugin;

- modeChanged: (NSAttributedString *)mode on: (NSAttributedString *)anObject 
   withParams: (NSArray *)paramList from: (NSAttributedString *)aPerson 
   onConnection: (id)connection sender: aPlugin;
   
- numericCommandReceived: (NSAttributedString *)command 
   withParams: (NSArray *)paramList from: (NSAttributedString *)sender 
   onConnection: (id)connection sender: aPlugin;

- nickChangedTo: (NSAttributedString *)newName 
   from: (NSAttributedString *)aPerson 
   onConnection: (id)connection sender: aPlugin;

- channelJoined: (NSAttributedString *)channel 
   from: (NSAttributedString *)joiner 
   onConnection: (id)connection sender: aPlugin;

- channelParted: (NSAttributedString *)channel 
   withMessage: (NSAttributedString *)aMessage
   from: (NSAttributedString *)parter onConnection: (id)connection 
   sender: aPlugin;

- quitIRCWithMessage: (NSAttributedString *)aMessage 
   from: (NSAttributedString *)quitter onConnection: (id)connection 
   sender: aPlugin;

- topicChangedTo: (NSAttributedString *)aTopic in: (NSAttributedString *)channel
   from: (NSAttributedString *)aPerson onConnection: (id)connection 
   sender: aPlugin;

- messageReceived: (NSAttributedString *)aMessage to: (NSAttributedString *)to
   from: (NSAttributedString *)sender onConnection: (id)connection 
   sender: aPlugin;

- noticeReceived: (NSAttributedString *)aMessage to: (NSAttributedString *)to
   from: (NSAttributedString *)sender onConnection: (id)connection 
   sender: aPlugin;

- actionReceived: (NSAttributedString *)anAction to: (NSAttributedString *)to
   from: (NSAttributedString *)sender onConnection: (id)connection 
   sender: aPlugin;

- pingReceivedWithArgument: (NSAttributedString *)arg 
   from: (NSAttributedString *)sender onConnection: (id)connection 
   sender: aPlugin;

- pongReceivedWithArgument: (NSAttributedString *)arg 
   from: (NSAttributedString *)sender onConnection: (id)connection 
   sender: aPlugin;

- newNickNeededWhileRegisteringOnConnection: (id)connection sender: aPlugin;
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
	id content = [self openNewContentWindow];
	[self makeConnectionForContentController: content];
}	
@end

