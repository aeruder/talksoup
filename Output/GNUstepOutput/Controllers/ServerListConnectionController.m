/***************************************************************************
                                ServerListConnectionController.m
                          -------------------
    begin                : Wed May  7 03:31:51 CDT 2003
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

#include "Controllers/ServerListConnectionController.h"
#include "Controllers/ServerListController.h"
#include "Controllers/InputController.h"
#include "Controllers/ContentController.h"
#include "TalkSoupBundles/TalkSoup.h"
#include "GNUstepOutput.h"

#include <Foundation/NSEnumerator.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSNotification.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSGeometry.h>

#include <AppKit/NSWindow.h>
#include <AppKit/NSView.h>

@implementation ServerListConnectionController
- initWithServerListDictionary: (NSDictionary *)aInfo
 inGroup: (int)group atRow: (int)row
{
	id tmp;
	id output = [_TS_ pluginForOutput];
	
	tmp = [NSMutableDictionary dictionaryWithDictionary: aInfo];
	if ([[tmp objectForKey: IRCDefaultsNick] length] == 0)
	{
		[tmp setObject: [output defaultsObjectForKey: IRCDefaultsNick]
		  forKey: IRCDefaultsNick];
	}
	if ([[tmp objectForKey: IRCDefaultsUserName] length] == 0)
	{
		[tmp setObject: [output defaultsObjectForKey: IRCDefaultsUserName]
		  forKey: IRCDefaultsUserName];
	}
	if ([[tmp objectForKey: IRCDefaultsRealName] length] == 0)
	{
		[tmp setObject: [output defaultsObjectForKey: IRCDefaultsRealName]
		  forKey: IRCDefaultsRealName];
	}
	if ([[tmp objectForKey: IRCDefaultsPassword] length] == 0)
	{
		[tmp setObject: [output defaultsObjectForKey: IRCDefaultsPassword]
		  forKey: IRCDefaultsPassword];
	}
	
	if (!(self = [super initWithIRCInfoDictionary: tmp])) return nil;
	
	serverInfo = RETAIN(aInfo);
	serverRow = row;
	serverGroup = group;
	
	[[NSNotificationCenter defaultCenter] addObserver: self
	  selector: @selector(saveWindowStats:) 
	  name: NSWindowWillCloseNotification object: 
	  [[self contentController] window]];

	if ((tmp = [aInfo objectForKey: ServerListInfoWindowFrame]))
	{
		NSRect a = NSRectFromString(tmp);
		
		[[[self contentController] window] setFrame: a display: YES];
	}
	
	if ((tmp = [aInfo objectForKey: ServerListInfoServer]))
	{
		int port = [[aInfo objectForKey: ServerListInfoPort] intValue];
		
		[self connectToServer: tmp onPort: port];
	}
	
	return self;
}	
- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	
	RELEASE(serverInfo);

	[super dealloc];
}
- registeredWithServerOnConnection: (id)aConnection 
   withNickname: (NSAttributedString *)aNick
	sender: aPlugin
{
	id tmp;
	
	if ([tmp = [serverInfo objectForKey: ServerListInfoCommands] length] > 0)
	{
		[[self inputController] lineTyped: tmp];
	}

	return [super registeredWithServerOnConnection: aConnection 
	  withNickname: aNick sender: aPlugin];
}
- (void)saveWindowStats: (NSNotification *)aNotification
{
	id window = [aNotification object];
	id tmp;
	
	if ([[ServerListController serverInGroup: serverGroup row: serverRow]
	  isEqual: serverInfo])
	{	
		tmp = [NSMutableDictionary dictionaryWithDictionary: serverInfo];
	
		[tmp setObject: NSStringFromRect([window frame]) 
		  forKey: ServerListInfoWindowFrame];
	
		[ServerListController setServer: tmp inGroup: serverGroup
		  row: serverRow];
	}
}
@end

