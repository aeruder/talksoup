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
#include "Controllers/ServerListController.h"
#include "Controllers/NamePromptController.h"
#include "Controllers/ContentController.h"
#include "Controllers/TopicInspectorController.h"
#include "Misc/NSColorAdditions.h"
#include "Views/KeyTextView.h"

#include <AppKit/NSAttributedString.h>
#include <AppKit/NSNibLoading.h>
#include <AppKit/NSApplication.h>
#include <AppKit/NSMenu.h>
#include <AppKit/NSWindow.h>
#include <AppKit/NSColor.h>
#include <AppKit/NSEvent.h>
#include <AppKit/NSTextField.h>
#include <AppKit/NSImage.h>
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

BOOL GNUstepOutputCompare(NSString *aString, NSString *aString2)
{
	return [GNUstepOutputLowercase(aString) isEqualToString: 
	  GNUstepOutputLowercase(aString2)];
}

NSColor *GNUstepOutputColor(NSColor *aColor)
{
	return [aColor colorUsingColorSpaceName: [NSColor commonColorSpaceName]];
}

NSString *GNUstepOutputPersonalBracketColor = @"GNUstepOutputPersonalBracketColor";
NSString *GNUstepOutputOtherBracketColor = @"GNUstepOutputOtherBracketColor";
NSString *GNUstepOutputTextColor = @"GNUstepOutputTextColor";
NSString *GNUstepOutputBackgroundColor = @"GNUstepOutputBackgroundColor";
NSString *GNUstepOutputServerList = @"GNUstepOutputServerList";

GNUstepOutput *_GS_ = nil;

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
	  [GNUstepOutputColor([NSColor colorWithCalibratedRed: 1.0 green: 0.9725 
	    blue: 0.8627 alpha: 1.0]) encodeToData], GNUstepOutputBackgroundColor,
	  [GNUstepOutputColor([NSColor colorWithCalibratedRed: 0.0 green: 0.0
	    blue: 0.0 alpha: 1.0]) encodeToData], GNUstepOutputTextColor,
	  [GNUstepOutputColor([NSColor colorWithCalibratedRed: 1.0 green: 0.0
	    blue: 0.0 alpha: 1.0]) encodeToData], GNUstepOutputPersonalBracketColor,
	  [GNUstepOutputColor([NSColor colorWithCalibratedRed: 0.0 green: 0.0
	    blue: 1.0 alpha: 1.0]) encodeToData], GNUstepOutputOtherBracketColor,
	  [NSArray arrayWithObjects: nil], GNUstepOutputServerList,
	  nil];
	
	RELEASE(_GS_);
	_GS_ = RETAIN(self);
	
	return self;
}
- (void)dealloc
{
	[[topic topicText] setKeyTarget: nil];
	RELEASE(topic);
	RELEASE(defaultDefaults);
	RELEASE(connectionControllers);
	RELEASE(pendingIdentToConnectionController);
	NSFreeMapTable(connectionToConnectionController);
	
	[super dealloc];
}
- setDefaultsObject: aObject forKey: (NSString *)aKey
{
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
		
		if (aObject)
		{
			[aDict setObject: aObject forKey: newKey];
		}
		else
		{
			[aDict removeObjectForKey: newKey];
		}
		
		[[NSUserDefaults standardUserDefaults]
		   setObject: aDict forKey: @"GNUstepOutput"];
	}
	else
	{
		if (aObject)
		{
			[[NSUserDefaults standardUserDefaults]
			  setObject: aObject forKey: aKey];
		}
		else
		{
			[[NSUserDefaults standardUserDefaults]
			  removeObjectForKey: aKey];
		}
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
	[pendingIdentToConnectionController removeObjectsForKeys: 
	  [pendingIdentToConnectionController allKeysForObject: controller]]; 
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
		[[_TS_ pluginForInput] closeConnection: connection];
		return self;
	}
	
	[pendingIdentToConnectionController removeObjectForKey: ident];
	
	NSMapInsert(connectionToConnectionController, connection, controller);
	NSMapInsert(connectionToConnectionController, controller, connection);

	[controller newConnection: connection sender: aPlugin];
	
	return self;
}
- lostConnection: (id)connection sender: aPlugin
{
	id control;
	control = NSMapGet(connectionToConnectionController, connection);
	
	[control lostConnection: connection sender: aPlugin];
	
	NSMapRemove(connectionToConnectionController, connection);
	NSMapRemove(connectionToConnectionController, control);
	
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
- (TopicInspectorController *)topicInspectorController
{
	return topic;
}
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
	id item;
	NSMenu *tempMenu;
	unichar leftKey = NSLeftArrowFunctionKey;
	unichar rightKey = NSRightArrowFunctionKey;

	menu = AUTORELEASE([NSMenu new]);

// Info	
	item = [menu addItemWithTitle: _l(@"Info") action: 0 keyEquivalent: @""];
	tempMenu = AUTORELEASE([NSMenu new]);
	[menu setSubmenu: tempMenu forItem: item];

	[tempMenu addItemWithTitle: _l(@"Info Panel...")
	  action: @selector(orderFrontStandardInfoPanel:)
	  keyEquivalent: @""];
	
	[tempMenu addItemWithTitle: _l(@"Preferences...")
	  action: @selector(loadPreferencesPanel:)
	  keyEquivalent: @"P"];

// Connection
	item = [menu addItemWithTitle: _l(@"Connection") action: 0
	  keyEquivalent: @""];
	tempMenu = AUTORELEASE([NSMenu new]);
	[menu setSubmenu: tempMenu forItem: item];
	
	[tempMenu addItemWithTitle: _l(@"Open Server List...") 
	  action: @selector(openServerList:)
	  keyEquivalent: @"o"];
	
	[tempMenu addItemWithTitle: _l(@"Connected Window...") 
	  action: @selector(openNamePrompt:)
	  keyEquivalent: @"N"];
	
	[tempMenu addItemWithTitle: _l(@"Unconnected Window") 
	  action: @selector(openEmptyWindow:)
	  keyEquivalent: @"n"];

// Tabs
	item = [menu addItemWithTitle: _l(@"Tab") action: 0
	  keyEquivalent: @""];
	tempMenu = AUTORELEASE([NSMenu new]);
	[menu setSubmenu: tempMenu forItem: item];

	item = [tempMenu addItemWithTitle: _l(@"Next Tab")
	  action: @selector(selectNextTab:)
	  keyEquivalent: [NSString stringWithCharacters: &rightKey
	    length: 1]];
	
	item = [tempMenu addItemWithTitle: _l(@"Previous Tab")
	  action: @selector(selectPreviousTab:)
	  keyEquivalent: [NSString stringWithCharacters: &leftKey
	    length: 1]];
	
	item = [tempMenu addItemWithTitle: _l(@"Close Tab")
	  action: @selector(closeCurrentTab:)
	  keyEquivalent: @"X"];

// Tools
	item = [menu addItemWithTitle: _l(@"Tools")
	  action: 0 keyEquivalent: @""];
	tempMenu = AUTORELEASE([NSMenu new]);
	[menu setSubmenu: tempMenu forItem: item];
	
	item = [tempMenu addItemWithTitle: _l(@"Topic Inspector")
	  action: @selector(openTopicInspector:)
	  keyEquivalent: @"t"];
	
// Edit	
	item = [menu addItemWithTitle: _l(@"Edit") action: 0 keyEquivalent: @""];
	tempMenu = AUTORELEASE([NSMenu new]);
	[menu setSubmenu: tempMenu forItem: item];

	[tempMenu addItemWithTitle: _l(@"Cut")
	  action: @selector(cut:)
	  keyEquivalent: @"x"];
	[tempMenu addItemWithTitle: _l(@"Copy")
	  action: @selector(copy:)
	  keyEquivalent: @"c"];
	[tempMenu addItemWithTitle: _l(@"Paste")
	  action: @selector(paste:)
	  keyEquivalent: @"v"];
	[tempMenu addItemWithTitle: _l(@"Delete")
	  action: @selector(delete:)
	  keyEquivalent: @""];
	[tempMenu addItemWithTitle: _l(@"Select All")
	  action: @selector(selectAll:)
	  keyEquivalent: @"a"];

// Windows
	item = [menu addItemWithTitle: _l(@"Windows") action: 0 keyEquivalent: @""];
	tempMenu = AUTORELEASE([NSMenu new]);
	[menu setSubmenu: tempMenu forItem: item];
	[NSApp setWindowsMenu: tempMenu];

// Services
	item = [menu addItemWithTitle: _l(@"Services") action: 0 keyEquivalent: @""];
	tempMenu = AUTORELEASE([NSMenu new]);
	[menu setSubmenu: tempMenu forItem: item];
	[NSApp setServicesMenu: tempMenu];

// Hide
	[menu addItemWithTitle: _l(@"Hide")
	  action: @selector(hide:)
	  keyEquivalent: @"h"];

// Quit
	[menu addItemWithTitle: _l(@"Quit") action: @selector(terminate:)
	  keyEquivalent: @"q"];
	
	[NSApp setMainMenu: menu];
	[NSApp setApplicationIconImage: 
	  AUTORELEASE([[NSImage alloc] initWithContentsOfFile:
	  [[NSBundle bundleForClass: [self class]]
	    pathForResource: @"TalkSoup" ofType: @"tiff"]])];
}
- (void)applicationDidFinishLaunching: (NSNotification *)aNotification
{
	topic = [TopicInspectorController new];
	[NSBundle loadNibNamed: @"TopicInspector" owner: topic];
	[[topic topicText] setKeyTarget: self];
	[[topic topicText] setKeyAction: @selector(topicKeyHit:sender:)]; 

	[ServerListController startAutoconnectServers];
}
- (void)applicationWillTerminate: (NSNotification *)aNotification
{
	NSArray *x;
	NSEnumerator *iter;
	id object;
	
	[[prefs window] close];
	x = [NSArray arrayWithArray: connectionControllers];
	
	iter = [x objectEnumerator];
	
	while ((object = [iter nextObject]))
	{
		[[[object contentController] window] close];
	}
	
	[[prefs window] close]; 
}
- (void)openEmptyWindow: (NSNotification *)aNotification
{
	AUTORELEASE([ConnectionController new]);
}
- (void)openServerList: (NSNotification *)aNotification
{
	[NSBundle loadNibNamed: _l(@"ServerList") owner: 
	  AUTORELEASE([ServerListController new])];
}
- (void)openNamePrompt: (NSNotification *)aNotification
{
	[NSBundle loadNibNamed: _l(@"NamePrompt") owner:
	  AUTORELEASE([NamePromptController new])];
}
- (void)openTopicInspector: (NSNotification *)aNotification
{
		[[topic window] makeKeyAndOrderFront: nil];
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

@interface GNUstepOutput (Delegate)
@end

@implementation GNUstepOutput (Delegate)
- (void)windowWillClose: (NSNotification *)aNotification
{
	if ([aNotification object] == [prefs window])
	{
		DESTROY(prefs);
	}
	if ([aNotification object] == [topic window])
	{
		[[topic topicText] setKeyTarget: nil];
		DESTROY(topic);
	}
}
- (BOOL)topicKeyHit: (NSEvent *)aEvent sender: (id)sender
{
	id connection;
	id channel;
	NSString *characters = [aEvent characters];
	unichar character = 0;
	
	if ([characters length] == 0)
	{
		return YES;
	}

   character = [characters characterAtIndex: 0];
	
	if (character != NSCarriageReturnCharacter) return YES;
	
	connection = [topic connectionController];
	channel = [[topic channelField] stringValue];
	
	if (connection)
	{
		[_TS_ setTopicForChannel: S2AS(channel) to: 
		 S2AS([sender string]) onConnection: [connection connection]
		 sender: self];
		[_TS_ setTopicForChannel: S2AS(channel) to:
		 nil onConnection: [connection connection]
		 sender: self];
	}
	
	return NO;
}
@end

