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

#import "GNUstepOutput.h"

#import "Controllers/ConnectionController.h"
#import "Controllers/PreferencesController.h"
#import "Controllers/ServerListController.h"
#import "Controllers/NamePromptController.h"
#import "Controllers/ContentController.h"
#import "Controllers/TopicInspectorController.h"
#import "Controllers/BundleConfigureController.h"
#import "Misc/NSColorAdditions.h"
#import "Views/KeyTextView.h"

#import <AppKit/NSAttributedString.h>
#import <AppKit/NSNibLoading.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSMenu.h>
#import <AppKit/NSFont.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSColor.h>
#import <AppKit/NSEvent.h>
#import <AppKit/NSTextField.h>
#import <AppKit/NSImage.h>
#import <Foundation/NSInvocation.h>
#import <Foundation/NSRunLoop.h>
#import <Foundation/NSAttributedString.h>
#import <Foundation/NSString.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSHost.h>
#import <Foundation/NSUserDefaults.h>
#import <Foundation/NSNotification.h>
#import <Foundation/NSEnumerator.h>

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

NSString *GNUstepOutputPersonalBracketColor = @"GNUstepOutputPersonalBracketColor";
NSString *GNUstepOutputOtherBracketColor = @"GNUstepOutputOtherBracketColor";
NSString *GNUstepOutputTextColor = @"GNUstepOutputTextColor";
NSString *GNUstepOutputBackgroundColor = @"GNUstepOutputBackgroundColor";
NSString *GNUstepOutputServerList = @"GNUstepOutputServerList";
NSString *GNUstepOutputFontSize = @"GNUstepOutputFontSize";
NSString *GNUstepOutputFontName = @"GNUstepOutputFontName";
NSString *GNUstepOutputScrollBack = @"GNUstepOutputScrollBack";

GNUstepOutput *_GS_ = nil;

@interface GNUstepOutputBundle : NSBundle
@end

@implementation GNUstepOutput
- init
{
	id x;
	id fontName = nil;
	id fontSize = nil;
	
	if (!(self = [super init])) return nil;
	
	[NSApplication sharedApplication]; // Make sure NSApp is allocated..

	connectionToConnectionController = NSCreateMapTable(NSObjectMapKeyCallBacks,
	  NSObjectMapValueCallBacks, 10);
	
	connectionControllers = [NSMutableArray new];
	serverLists = [NSMutableArray new];

	pendingIdentToConnectionController = [NSMutableDictionary new];
	
	x = [NSFont userFontOfSize: 0.0];
	
	if (x)
	{
		fontName = [x fontName];
		fontSize = [NSString stringWithFormat: @"%d", (int)[x pointSize]];
	}
	
	if (!fontName) fontName = @"Helvetica";
	if ([fontSize intValue] < 0 || !fontSize) fontSize = @"12";	
	
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
	  [NSArray arrayWithObjects: nil], GNUstepOutputServerList,
	  fontName, GNUstepOutputFontName,
	  fontSize, GNUstepOutputFontSize,
	  @"75000", GNUstepOutputScrollBack,
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
- addServerList: (ServerListController *)aCont
{
	[serverLists addObject: aCont];
	return self;
}
- removeServerList: (ServerListController *)aCont
{
	[serverLists removeObject: aCont];
	return self;
}
- setPreferencesController: (PreferencesController *)aPrefs
{
	if (prefs == aPrefs) return self;

	RELEASE(prefs);
	prefs = RETAIN(aPrefs);
	
	return self;
}		
- (NSArray *)connectionControllers
{
	return [NSArray arrayWithArray: connectionControllers];
}
- newConnection: (id)connection withNickname: (NSAttributedString *)aNick
   sender: aPlugin
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

	[controller newConnection: connection withNickname: aNick
	  sender: aPlugin];
	
	return self;
}
- lostConnection: (id)connection withNickname: (NSAttributedString *)aNick
   sender: aPlugin
{
	id control;
	
	if ((control = 
		  [pendingIdentToConnectionController objectForKey: [connection identification]]))
	{
		[control systemMessage: BuildAttributedString(_l(@"Error: "), 
		  [connection errorMessage], nil) onConnection: nil];
		[control lostConnection: connection withNickname: aNick
		  sender: aPlugin];
		[pendingIdentToConnectionController removeObjectForKey: [connection identification]];
	}
	else
	{
		control = NSMapGet(connectionToConnectionController, connection);
	
		[control lostConnection: connection withNickname: aNick
		  sender: aPlugin];
	
		NSMapRemove(connectionToConnectionController, connection);
		NSMapRemove(connectionToConnectionController, control);
	}
	
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
	NSString *selS;
	
	if (!aSel) return NO;
	
	selS = NSStringFromSelector(aSel);
	
	if ([selS hasSuffix: @"nConnection:withNickname:sender:"] && 
	    [ConnectionController instancesRespondToSelector: aSel]) return YES;
	
	if ([prefs respondsToSelector: aSel]) return YES;
	
	return [super respondsToSelector: aSel];
}
- (NSMethodSignature *)methodSignatureForSelector: (SEL)aSel
{
	id x;
	
	if ((x = [ConnectionController instanceMethodSignatureForSelector: aSel]))
	{
		return x;
	}
	
	if ((x = [prefs methodSignatureForSelector: aSel]))
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
	
	if ([selS hasSuffix: @"nConnection:withNickname:sender:"])
	{
		int num;
		id connection;
		id object;
		
		num = [[selS componentsSeparatedByString: @":"] count] - 1;
		
		[aInvoc getArgument: &connection atIndex: num + 2 - 1 - 1 - 1];
		
		object = NSMapGet(connectionToConnectionController, connection);
		
		if (sel && [object respondsToSelector: sel])
		{
			[aInvoc invokeWithTarget: object]; }
	}
	else if (sel && [prefs respondsToSelector: sel])
	{
		[aInvoc invokeWithTarget: prefs];
	}
}
- (TopicInspectorController *)topicInspectorController
{
	return topic;
}
- (void)run
{
	[GNUstepOutputBundle poseAsClass: [NSBundle class]];
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

	[tempMenu addItemWithTitle: _l(@"About TalkSoup")
	  action: @selector(orderFrontStandardInfoPanel:)
	  keyEquivalent: @""];
	
	[tempMenu addItemWithTitle: _l(@"Preferences...")
	  action: @selector(loadPreferencesPanel:)
	  keyEquivalent: @"P"];
	
	[tempMenu addItemWithTitle: _l(@"Bundle Setup...")
	  action: @selector(loadBundleConfigurator:)
	  keyEquivalent: @"B"];

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
}
- (void)applicationDidFinishLaunching: (NSNotification *)aNotification
{
	topic = [TopicInspectorController new];
	[NSBundle loadNibNamed: @"TopicInspector" owner: topic];
	[[topic topicText] setKeyTarget: self];
	[[topic topicText] setKeyAction: @selector(topicKeyHit:sender:)]; 

	if (![ServerListController startAutoconnectServers])
	{
		AUTORELEASE([ConnectionController new]);
	}
}
- (void)applicationWillTerminate: (NSNotification *)aNotification
{
	NSArray *x;
	NSEnumerator *iter;
	id object;
	
	terminating = YES;
	
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
	}
	else
	{
		[[prefs window] makeKeyAndOrderFront: nil];
	}
}
- (void)loadBundleConfigurator: (NSNotification *)aNotification
{
	if (!bundle)
	{
		bundle = [BundleConfigureController new];
		[NSBundle loadNibNamed: @"BundleConfigure" owner: bundle];
		[[bundle window] setDelegate: self];
	}
	else
	{
		[[bundle window] makeKeyAndOrderFront: nil];
	}
}
@end

@interface GNUstepOutput (Delegate)
@end

@implementation GNUstepOutput (Delegate)
- (void)windowWillClose: (NSNotification *)aNotification
{
	if ([aNotification object] == [topic window])
	{
		[[topic topicText] setKeyTarget: nil];
		DESTROY(topic);
	}
	if ([aNotification object] == [bundle window])
	{
		DESTROY(bundle);
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
		connection = [connection connection];
		[_TS_ setTopicForChannel: S2AS(channel) to: 
		 S2AS([sender string]) onConnection: connection
		 withNickname: S2AS([connection nick])
		 sender: self];
		[_TS_ setTopicForChannel: S2AS(channel) to:
		 nil onConnection: connection
		 withNickname: S2AS([connection nick])
		 sender: self];
	}
	
	return NO;
}
@end

@implementation GNUstepOutputBundle
- (NSString *)pathForImageResource: (NSString *)name
{
	id obj;
	id bundle = [NSBundle bundleForClass: [GNUstepOutput class]];
	
	if (!(obj = [super pathForImageResource: name]) && bundle != self)
	{
		return [bundle pathForImageResource: name];
	}

	return obj;
}
- (NSString *)pathForResource: (NSString *)name 
   ofType: (NSString *)extension
{
	id obj;
	id bundle = [NSBundle bundleForClass: [GNUstepOutput class]];

	if (!(obj = [super pathForResource: name ofType: extension]) && bundle != self)
	{
		return [bundle pathForResource: name ofType: extension];
	}

	return obj;
}
- (NSString *)pathForResource: (NSString *)name ofType: (NSString *)ext
  inDirectory: (NSString *)bundlePath
{
	id obj;
	id bundle = [NSBundle bundleForClass: [GNUstepOutput class]];

	if (!(obj = [super pathForResource: name ofType: ext
	  inDirectory: bundlePath]) && bundle != self)
	{
		return [bundle pathForResource: name ofType: ext 
		  inDirectory: bundlePath];
	}

	return obj;
}
@end
