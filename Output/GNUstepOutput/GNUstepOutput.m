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

#include "Controllers/ConnectionController.h"
#include "Controllers/PreferencesController.h"
#include "Misc/NSColorAdditions.h"

#include <AppKit/NSNibLoading.h>
#include <AppKit/NSApplication.h>
#include <AppKit/NSMenu.h>
#include <AppKit/NSWindow.h>
#include <Foundation/NSInvocation.h>
#include <Foundation/NSRunLoop.h>
#include <Foundation/NSAttributedString.h>
#include <Foundation/NSString.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSHost.h>
#include <Foundation/NSUserDefaults.h>
#include <Foundation/NSNotification.h>

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

NSString *GNUstepOutputPersonalBracketColor = @"GNUstepOutputPersonalBracketColor";
NSString *GNUstepOutputOtherBracketColor = @"GNUstepOutputOtherBracketColor";
NSString *GNUstepOutputTextColor = @"GNUstepOutputTextColor";
NSString *GNUstepOutputBackgroundColor = @"GNUstepOutputBackgroundColor";

@implementation GNUstepOutput
- init
{
	if (!(self = [super init])) return nil;

	connectionToConnectionController = NSCreateMapTable(NSObjectMapKeyCallBacks,
	  NSObjectMapValueCallBacks, 10);
	
	connectionControllers = [NSMutableArray new];

	pendingIdentToConnectionController = [NSMutableDictionary new];
	
	defaultDefaults = [[NSDictionary alloc] initWithObjectsAndKeys:
	  @"TalkSoup", IRCDefaultsNick,
	  @"", IRCDefaultsRealName,
	  @"", IRCDefaultsUserName,
	  @"", IRCDefaultsPassword,
	  [[NSColor colorWithCalibratedRed: 1.0 green: 0.9725 
	    blue: 0.8627 alpha: 1.0] encodeToData], GNUstepOutputBackgroundColor,
	  [[NSColor colorWithCalibratedRed: 0.0 green: 0.0
	    blue: 0.0 alpha: 1.0] encodeToData], GNUstepOutputTextColor,
	  [[NSColor colorWithCalibratedRed: 1.0 green: 0.0
	    blue: 0.0 alpha: 1.0] encodeToData], GNUstepOutputPersonalBracketColor,
	  [[NSColor colorWithCalibratedRed: 0.0 green: 0.0
	    blue: 1.0 alpha: 1.0] encodeToData], GNUstepOutputOtherBracketColor,
	  nil];

	return self;
}
- (void)dealloc
{
	RELEASE(defaultDefaults);
	RELEASE(connectionControllers);
	RELEASE(pendingIdentToConnectionController);
	NSFreeMapTable(connectionToConnectionController);
	
	[super dealloc];
}
- setDefaultsObject: aObject forKey: (NSString *)aKey
{
	if (!aObject) return nil;
	
	if ([aKey hasPrefix: @"GNUstepOutput"])
	{
		NSMutableDictionary *aDict = AUTORELEASE([NSMutableDictionary new]);
		id newKey = [aKey substringFromIndex: 13];
		id y;
		
		if ((y = [[NSUserDefaults standardUserDefaults] 
			  objectForKey: @"GNUstepOutput"]))
		{
			[aDict addEntriesFromDictionary: y];
		}
		
		[aDict setObject: aObject forKey: newKey];
		
		[[NSUserDefaults standardUserDefaults]
		   setObject: aDict forKey: @"GNUstepOutput"];
	}
	else
	{
		[[NSUserDefaults standardUserDefaults]
		  setObject: aObject forKey: aKey];
	}
	
	return self;
}		
- (id)defaultsObjectForKey: (NSString *)aKey
{
	id z;
	
	if ([aKey hasPrefix: @"GNUstepOutput"])
	{
		id y;
		id newKey = [aKey substringFromIndex: 13];
		
		y = [[NSUserDefaults standardUserDefaults] 
		   objectForKey: @"GNUstepOutput"];
		
		if ((z = [y objectForKey: newKey]))
		{
			return z;
		}
		
		z = [defaultDefaults objectForKey: aKey];
		
		[self setDefaultsObject: z forKey: aKey];
		
		return z;
	}
	
	if ((z = [[NSUserDefaults standardUserDefaults]
	     objectForKey: aKey]))
	{
		return z;
	}
	
	z = [defaultDefaults objectForKey: aKey];
	
	[self setDefaultsObject: z forKey: aKey];
	
	return z;
}
- (id)defaultDefaultsForKey: aKey
{
	return [defaultDefaults objectForKey: aKey];
}	  
- (id)connectionToConnectionController: (id)aObject
{
	return NSMapGet(connectionToConnectionController, aObject);
}
- waitingForConnection: (NSString *)aIdent onConnectionController: (id)controller
{
	[pendingIdentToConnectionController setObject: controller forKey: aIdent];
	return self;
}
- addConnectionController: (ConnectionController *)aCont
{
	[connectionControllers addObject: aCont];
	return self;
}
- removeConnectionController: (ConnectionController *)aCont
{
	[connectionControllers removeObject: aCont];
	return self;
}
- (NSArray *)connectionControllers
{
	return [NSArray arrayWithArray: connectionControllers];
}
- newConnection: (id)connection sender: aPlugin
{
	id controller;
	id ident = [connection identification];
	
	controller = AUTORELEASE(RETAIN([pendingIdentToConnectionController 
	  objectForKey: ident]));
	
	if (!(controller))
	{
		NSLog(@"Connection came through but there is no related"
		      @"connection controller waiting for that connection..."
		      @"closing connection...");
		[[_TS_ input] closeConnection: connection];
		return self;
	}
	
	[pendingIdentToConnectionController removeObjectForKey: ident];
	
	NSMapInsert(connectionToConnectionController, connection, controller);
	NSMapInsert(connectionToConnectionController, controller, connection);

	[controller newConnection: connection sender: aPlugin];
	
	return self;
}
- consoleMessage: (NSAttributedString *)arg onConnection: (id)aConnection
{
	id controller = NSMapGet(connectionToConnectionController, aConnection);
	
	if ([controller respondsToSelector: _cmd])
	{
		[controller performSelector: _cmd withObject: arg withObject: aConnection];
	}
	return self;
}
- systemMessage: (NSAttributedString *)arg onConnection: (id)aConnection
{
	id controller = NSMapGet(connectionToConnectionController, aConnection);
	
	if ([controller respondsToSelector: _cmd])
	{
		[controller performSelector: _cmd withObject: arg withObject: aConnection];
	}
	return self;
}
- showMessage: (NSAttributedString *)arg onConnection: (id)aConnection
{
	id controller = NSMapGet(connectionToConnectionController, aConnection);
	
	if ([controller respondsToSelector: _cmd])
	{
		[controller performSelector: _cmd withObject: arg withObject: aConnection];
	}
	return self;
}
- (BOOL)respondsToSelector: (SEL)aSel
{
	NSString *selS = NSStringFromSelector(aSel);
	
	if ([selS hasSuffix: @"nConnection:sender:"]) return YES;
	
	return [super respondsToSelector: aSel];
}
- (NSMethodSignature *)methodSignatureForSelector: (SEL)aSel
{
	id x;
	
	if ((x = [ConnectionController instanceMethodSignatureForSelector: aSel]))
	{
		return x;
	}
	
	return [super methodSignatureForSelector: aSel];
}
- (void)forwardInvocation: (NSInvocation *)aInvoc
{
	SEL sel = [aInvoc selector];
	NSString *selS = NSStringFromSelector(sel);
	
	[aInvoc retainArguments];
	
	if ([selS hasSuffix: @"nConnection:sender:"])
	{
		int num;
		id connection;
		id object;
		
		num = [[selS componentsSeparatedByString: @":"] count] - 1;
		
		[aInvoc getArgument: &connection atIndex: num + 2 - 1 - 1];
		
		object = NSMapGet(connectionToConnectionController, connection);
		
		if ([object respondsToSelector: sel])
		{
			[aInvoc invokeWithTarget: object];
		}
	}
}
- (void)run
{
	[NSObject enableDoubleReleaseCheck: YES];
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
	
	[tempMenu addItemWithTitle: @"Preferences"
	  action: @selector(loadPreferencesPanel:)
	  keyEquivalent: @"p"];

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
	id x = [ConnectionController new];
	[x connectToServer: @"localhost" onPort: 6667];
}
- (void)loadPreferencesPanel: (NSNotification *)aNotification
{
	if (!prefs)
	{
		prefs = [PreferencesController new];
		[NSBundle loadNibNamed: @"Preferences" owner: prefs];
		[prefs loadCurrentDefaults];
		[[prefs window] setDelegate: self];
	}
	else
	{
		[[prefs window] makeKeyAndOrderFront: nil];
	}
}
@end

@interface GNUstepOutput (WindowDelegate)
@end

@implementation GNUstepOutput (WindowDelegate)
- (void)windowWillClose: (NSNotification *)aNotification
{
	if ([aNotification object] == [prefs window])
	{
		DESTROY(prefs);
	}
}
@end

