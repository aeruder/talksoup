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
#import "Controllers/Preferences/PreferencesController.h"
#import "Controllers/Preferences/ColorPreferencesController.h"
#import "Controllers/Preferences/FontPreferencesController.h"
#import "Controllers/Preferences/BundlePreferencesController.h"
#import "Controllers/Preferences/GeneralPreferencesController.h"
#import "Controllers/ServerListController.h"
#import "Controllers/NamePromptController.h"
#import "Controllers/ContentControllers/ContentController.h"
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

NSString *StandardLowercase(NSString *aString)
{
	return [aString lowercaseString];
}
NSString *IRCLowercase(NSString *aString)
{
	NSMutableString *newString = [NSMutableString 
	  stringWithString: [aString lowercaseString]];
	NSRange aRange = {0, [newString length]};

	[newString replaceOccurrencesOfString: @"[" withString: @"{" options: 0
	  range: aRange];
	[newString replaceOccurrencesOfString: @"]" withString: @"}" options: 0
	  range: aRange];
	[newString replaceOccurrencesOfString: @"\\" withString: @"|" options: 0
	  range: aRange];
	[newString replaceOccurrencesOfString: @"~" withString: @"^" options: 0
	  range: aRange];
	
	return [newString lowercaseString];
}
NSString *(*GNUstepOutputLowercase)(NSString *aString) = StandardLowercase;

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

GNUstepOutput *_GS_ = nil;
PreferencesController *_PREFS_ = nil;

@implementation GNUstepOutput
- init
{
	id x;
	id fontName = nil;
	id fontSize = nil;
	
	if (!(self = [super init])) return nil;
	
	[NSApplication sharedApplication]; // Make sure NSApp is allocated..
	
	if (![NSBundle loadNibNamed: @"GNUstepOutput" owner: self])
	{
		NSLog(@"Could not load GNUstepOutput, exiting...");
		[self dealloc];
		return nil;
	}

	[NSApp setMainMenu: menu];

	connectionToConnectionController = NSCreateMapTable(NSObjectMapKeyCallBacks,
	  NSObjectMapValueCallBacks, 10);
	
	connectionControllers = [NSMutableArray new];
	serverLists = [NSMutableArray new];

	pendingIdentToConnectionController = [NSMutableDictionary new];
	bundlePreferences = [NSMutableDictionary new];
	
	x = [NSFont userFontOfSize: 0.0];
	
	if (x)
	{
		fontName = [x fontName];
		fontSize = [NSString stringWithFormat: @"%d", (int)[x pointSize]];
	}
	
	if (!fontName) fontName = @"Helvetica";
	if ([fontSize intValue] < 0 || !fontSize) fontSize = @"12";	
	

	/*
	[defaultPreferences setObject: fontName
	  forKey: [GNUstepOutputFontName substringFromIndex: 13]];
	[defaultPreferences setObject: fontSize
	  forKey: [GNUstepOutputFontSize substringFromIndex: 13]];
	  */
	
	RELEASE(_GS_);
	_GS_ = RETAIN(self);
	
	return self;
}
- (void)dealloc
{
	[[topic topicText] setKeyTarget: nil];
	RELEASE(topic);
	RELEASE(connectionControllers);
	RELEASE(pendingIdentToConnectionController);
	NSFreeMapTable(connectionToConnectionController);
	
	[super dealloc];
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
- (NSArray *)unconnectedConnectionControllers
{
	NSEnumerator *iter;
	id object;
	NSMutableArray *arr;

	arr = AUTORELEASE([NSMutableArray new]);

	iter = [connectionControllers objectEnumerator];

	while ((object = [iter nextObject]))
	{
		if ([[pendingIdentToConnectionController allKeysForObject: object] count] == 0 && 
		  ![object connection])
		{
			[arr addObject: object];
		}
	}
	
	return arr;
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
	ASSIGN(prefs, aPrefs);
	
	return self;
}		
- controllerForBundlePreferences: (NSString *)aString
{
	return [bundlePreferences objectForKey: aString];
}
- (NSArray *)connectionControllers
{
	return [NSArray arrayWithArray: connectionControllers];
}
/*
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
}*/
/*- lostConnection: (id)connection withNickname: (NSAttributedString *)aNick
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
}*/
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
- controlObject: (NSDictionary *)aControl onConnection: aConnection
  withNickname: aNick sender: aSender
{
	id process;
	process = [aControl objectForKey: @"Process"];
	
	if ([process isEqualToString: @"AddBundlePreferencesController"])
	{
		id name, controller;
		name = [aControl objectForKey: @"Name"];
		controller = [aControl objectForKey: @"Controller"];

		if (!controller || !name) return self;

		[bundlePreferences setObject: controller forKey: name];
	}
	else if ([process isEqualToString: @"RemoveBundlePreferencesController"])
	{
		id name;
		name = [aControl objectForKey: @"Name"];

		if (!name) return self;

		[bundlePreferences removeObjectForKey: name];
	}
	else if (aConnection)
	{
		id object;

		object = NSMapGet(connectionToConnectionController, aConnection);
		[object controlObject: aControl onConnection: aConnection
		  withNickname: aNick sender: aSender];
	}

	return self;
}	
- (BOOL)respondsToSelector: (SEL)aSel
{
	NSString *selS;
	NSString *tmp;
	SEL tmpSel;
	
	if (!aSel) return NO;
	
	selS = NSStringFromSelector(aSel);
	
	if ([selS hasPrefix: @"doApplication"])
	{
		tmp = [selS substringFromIndex: 13];
		tmp = [NSString stringWithFormat: @"%@%@", 
		  [[tmp substringToIndex: 1] lowercaseString],
		  [tmp substringFromIndex: 1]];
		tmpSel = NSSelectorFromString(tmp);
		if (tmpSel != 0 && [NSApp respondsToSelector: tmpSel])
		{
			return YES;
		}
	}
		
	if ([prefs respondsToSelector: aSel]) return YES;
	
	return [super respondsToSelector: aSel];
}
- (NSMethodSignature *)methodSignatureForSelector: (SEL)aSel
{
	id x;
	NSString *selS;

	selS = NSStringFromSelector(aSel);
	
	if ([selS hasPrefix: @"doApplication"])
	{
		SEL tmpSel;

		x = [selS substringFromIndex: 13];
		x = [NSString stringWithFormat: @"%@%@", 
		  [[x substringToIndex: 1] lowercaseString],
		  [x substringFromIndex: 1]];
		tmpSel = NSSelectorFromString(x);
		if (tmpSel != 0 && (x = [NSApp methodSignatureForSelector: tmpSel]))
		{
			return x;
		}
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
	
	if ([selS hasPrefix: @"doApplication"])
	{
		SEL tmpSel;
		NSString *x;
		
		x = [selS substringFromIndex: 13];
		x = [NSString stringWithFormat: @"%@%@", 
		  [[x substringToIndex: 1] lowercaseString],
		  [x substringFromIndex: 1]];
		tmpSel = NSSelectorFromString(x);
		
		if (tmpSel != 0 && [NSApp respondsToSelector: tmpSel])
		{
			[aInvoc setSelector: tmpSel];
			[aInvoc invokeWithTarget: NSApp];
			return;
		}
	}

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
	[NSApp setDelegate: self];
	[NSApp run];
}
@end

@interface GNUstepOutput (NSApplicationDelegate)
@end

@implementation GNUstepOutput (NSApplicationDelegate)
- (void)applicationDidFinishLaunching: (NSNotification *)aNotification
{
		_PREFS_ = [PreferencesController new];
		AUTORELEASE([GeneralPreferencesController new]);
		AUTORELEASE([ColorPreferencesController new]);
		AUTORELEASE([FontPreferencesController new]);
		AUTORELEASE([BundlePreferencesController new]);
}
- (void)applicationWillTerminate: (NSNotification *)aNotification
{
}
- (void)doApplicationTerminate: (id)sender
{
}
- (void)doApplicationHide: (id)sender
{
}
- (void)doApplicationOrderFrontStandardAboutPanel: (id)sender
{
	[NSApp orderFrontStandardAboutPanel: sender];
}
- (void)openEmptyWindow: (NSNotification *)aNotification
{
}
- (void)openServerList: (NSNotification *)aNotification
{
}
- (void)openNamePrompt: (NSNotification *)aNotification
{
}
- (void)openTopicInspector: (NSNotification *)aNotification
{
		[[topic window] makeKeyAndOrderFront: nil];
}
- (void)loadPreferencesPanel: (NSNotification *)aNotification
{
	if (!_PREFS_)
	{
	}
	else
	{
		NSLog(@"It works!\n");
		[[_PREFS_ window] makeKeyAndOrderFront: nil];
	}
}
@end

int main() {
	id apr = [NSAutoreleasePool new];
	id gnustepoutput = [GNUstepOutput new];
	[gnustepoutput run];
	return 0;
}
