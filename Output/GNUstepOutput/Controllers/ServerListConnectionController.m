/***************************************************************************
                                ServerListConnectionController.m
                          -------------------
    begin                : Wed May  7 03:31:51 CDT 2003
    copyright            : (C) 2005 by Andrew Ruder
    email                : aeruder@ksu.edu
 ***************************************************************************/

/***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/

#import "Controllers/ServerListConnectionController.h"
#import "Controllers/ServerListController.h"
#import "Controllers/InputController.h"
#import "Controllers/Preferences/PreferencesController.h"
#import "Controllers/ContentControllers/ContentController.h"
#import <TalkSoupBundles/TalkSoup.h>
#import "GNUstepOutput.h"

#import <Foundation/NSEnumerator.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSNotification.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSGeometry.h>
#import <Foundation/NSInvocation.h>

#import <AppKit/NSWindow.h>
#import <AppKit/NSView.h>

@implementation ServerListConnectionController
- initWithServerListDictionary: (NSDictionary *)aInfo
 inGroup: (int)group atRow: (int)row withContentController: (id)aContent
{
	id tmp;
	id tmppref;
	
	tmp = [NSMutableDictionary dictionaryWithDictionary: aInfo];
	if ([[tmp objectForKey: IRCDefaultsNick] length] == 0)
	{
		tmppref = [_PREFS_ preferenceForKey: IRCDefaultsNick];
		if (tmppref)
			[tmp setObject: [_PREFS_ preferenceForKey: IRCDefaultsNick]
			  forKey: IRCDefaultsNick];
	}
	if ([[tmp objectForKey: IRCDefaultsUserName] length] == 0)
	{
		tmppref = [_PREFS_ preferenceForKey: IRCDefaultsUserName];
		if (tmppref)
			[tmp setObject: [_PREFS_ preferenceForKey: IRCDefaultsUserName]
			  forKey: IRCDefaultsUserName];
	}
	if ([[tmp objectForKey: IRCDefaultsRealName] length] == 0)
	{
		tmppref = [_PREFS_ preferenceForKey: IRCDefaultsRealName];
		if (tmppref)
			[tmp setObject: [_PREFS_ preferenceForKey: IRCDefaultsRealName]
			  forKey: IRCDefaultsRealName];
	}
	if ([[tmp objectForKey: IRCDefaultsPassword] length] == 0)
	{
		tmppref = [_PREFS_ preferenceForKey: IRCDefaultsPassword];
		if (tmppref)
			[tmp setObject: [_PREFS_ preferenceForKey: IRCDefaultsPassword]
			  forKey: IRCDefaultsPassword];
	}
	
	if (!(self = [super initWithIRCInfoDictionary: tmp 
	 withContentController: aContent])) return nil;
	
	oldInfo = RETAIN(aInfo);
	newInfo = [[NSMutableDictionary alloc] initWithDictionary: aInfo];
	
	serverRow = row;
	serverGroup = group;

	if ((tmp = [aInfo objectForKey: ServerListInfoWindowFrame]) && !aContent)
	{
		NSRect a = NSRectFromString(tmp);
		
		[[[[self contentController] primaryMasterController] window] 
		  setFrame: a display: YES];
	}
	
	if ((tmp = [aInfo objectForKey: ServerListInfoServer]))
	{
		int port = [[aInfo objectForKey: ServerListInfoPort] intValue];
		
		[self connectToServer: tmp onPort: port];
	}
	
	return self;
}	
- newConnection: (id)aConnection withNickname: (NSAttributedString *)aNick
   sender: aPlugin
{
	id tmp, invoc;
	
	if ((tmp = [newInfo objectForKey: ServerListInfoEncoding]))
	{
		invoc = [_TS_ invocationForCommand: @"encoding"];
		[invoc setArgument: &tmp atIndex: 2];
		[invoc setArgument: &aConnection atIndex: 3]; 
		[invoc invoke];
		tmp = nil;
		[invoc setArgument: &tmp atIndex: 2];
		[invoc setArgument: &tmp atIndex: 3];
	}		
	
	[[NSNotificationCenter defaultCenter] addObserver: self
	  selector: @selector(windowWillClose:)
	  name: NSWindowWillCloseNotification 
	  object: nil];

	[super newConnection: aConnection withNickname: aNick sender: aPlugin];
	
	return self;
}
- lostConnection: (id)aConnection withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	id tmp = StringFromEncoding([aConnection encoding]);
	
	[newInfo setObject: tmp forKey: ServerListInfoEncoding];
	
	[super lostConnection: aConnection withNickname: aNick
	  sender: aPlugin];

	[[NSNotificationCenter defaultCenter] removeObserver: self];
	
	return self;
}
- (void)dealloc
{	
	RELEASE(newInfo);
	RELEASE(oldInfo);

	[super dealloc];
}
- registeredWithServerOnConnection: (id)aConnection 
   withNickname: (NSAttributedString *)aNick
	sender: aPlugin
{
	id tmp;
	
	if ([tmp = [newInfo objectForKey: ServerListInfoCommands] length] > 0)
	{
		id views = [[content primaryMasterController]
		  viewControllerListForContentController: content];
		id view = ([views count]) ? [view objectAtIndex: 0] : nil;
		id input = [content typingControllerForViewController: view];

		if (input) 
		{
			[input commandTyped: tmp];
		}
	}

	return [super registeredWithServerOnConnection: aConnection 
	  withNickname: aNick sender: aPlugin];
}
- (void)windowWillClose: (NSNotification *)aNotification
{	
	id window = [aNotification object];
	id master = [content masterControllerForName: ContentConsoleName];
	if ([master window] != window) return;
	
	[newInfo setObject: NSStringFromRect([window frame]) 
	  forKey: ServerListInfoWindowFrame];
	
	if (connection)
	{
		[newInfo setObject: StringFromEncoding([connection encoding]) 
		  forKey: ServerListInfoEncoding];
	}
	
	if ([[ServerListController serverInGroup: serverGroup row: serverRow] 
	  isEqual: oldInfo])
	{
		[ServerListController setServer: newInfo inGroup: serverGroup
		  row: serverRow];
	}

	[super windowWillClose: aNotification];
}
@end

